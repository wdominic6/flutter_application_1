import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';
import 'location_picker_screen.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? productToEdit;

  const ProductFormScreen({super.key, this.productToEdit});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _productService = ProductService();

  File? _imageFile;
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;

  bool get _isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();

    final product = widget.productToEdit;
    if (product != null) {
      _nameController.text = product.name;
      _descriptionController.text = product.description ?? '';
      _priceController.text = product.price.toStringAsFixed(2);
      _latitude = product.latitude;
      _longitude = product.longitude;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);

    if (pickedFile == null) return;

    setState(() {
      _imageFile = File(pickedFile.path);
    });
  }

  Future<void> _pickLocation() async {
    final initialLocation = _latitude != null && _longitude != null 
        ? LatLng(_latitude!, _longitude!) 
        : null;

    final LatLng? selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(initialLocation: initialLocation),
      ),
    );

    if (selectedLocation != null) {
      setState(() {
        _latitude = selectedLocation.latitude;
        _longitude = selectedLocation.longitude;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final nav = Navigator.of(context);
    final scaffoldMsg = ScaffoldMessenger.of(context);
    final product = widget.productToEdit;
    final price = double.parse(_priceController.text.trim());

    setState(() => _isLoading = true);

    final success = _isEditing && product?.id != null
        ? await _productService.updateProduct(
            id: product!.id!,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            price: price,
            imageFile: _imageFile,
            latitude: _latitude,
            longitude: _longitude,
          )
        : await _productService.createProduct(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            price: price,
            imageFile: _imageFile,
            latitude: _latitude,
            longitude: _longitude,
          );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      scaffoldMsg.showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Producto actualizado correctamente'
                : 'Producto publicado correctamente',
          ),
        ),
      );
      nav.pop(true);
    } else {
      scaffoldMsg.showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el producto.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingImage = widget.productToEdit?.imagePath;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar articulo' : 'Publicar articulo'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del producto',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa el nombre'
                      : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _descriptionController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Descripcion',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _priceController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Precio',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    final price = double.tryParse(value?.trim() ?? '');
                    if (price == null || price <= 0) {
                      return 'Ingresa un precio valido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _ProductImagePreview(
                  imageFile: _imageFile,
                  existingImageUrl: existingImage,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camara'),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galeria'),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.map, color: Colors.teal),
                  title: Text(
                    _latitude != null
                        ? 'Ubicación seleccionada'
                        : 'Ubicación no establecida',
                  ),
                  subtitle: Text(
                    _latitude != null
                        ? 'Ubicación configurada en el mapa'
                        : 'Toca aquí para elegir en el mapa',
                  ),
                  onTap: _isLoading ? null : _pickLocation,
                  trailing: const Icon(Icons.chevron_right),
                ),
                const SizedBox(height: 30),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: Colors.teal,
                  ),
                  onPressed: _isLoading ? null : _handleSubmit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEditing ? 'Actualizar producto' : 'Guardar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductImagePreview extends StatelessWidget {
  final File? imageFile;
  final String? existingImageUrl;

  const _ProductImagePreview({
    required this.imageFile,
    required this.existingImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (imageFile != null) {
      return Image.file(
        imageFile!,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    if (existingImageUrl != null && existingImageUrl!.isNotEmpty) {
      return Image.network(
        existingImageUrl!,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      height: 160,
      color: Colors.grey[200],
      child: const Icon(Icons.image, size: 50, color: Colors.grey),
    );
  }
}
