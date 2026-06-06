import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';

class ListProductsScreen extends StatefulWidget {
  const ListProductsScreen({super.key});

  @override
  State<ListProductsScreen> createState() => _ListProductsScreenState();
}

class _ListProductsScreenState extends State<ListProductsScreen> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await _productService.getProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Productos'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final Uri url = Uri.parse('http://67.205.173.252/api/products/report/pdf');
              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No se pudo abrir el navegador para descargar.')),
                  );
                }
              }
            },
            tooltip: 'Descargar PDF',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error al cargar datos: $_errorMessage'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadProducts,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      )
                    ],
                  ),
                )
              : _products.isEmpty
                  ? const Center(child: Text('No hay productos disponibles para mostrar.'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStatePropertyAll(Colors.teal.shade50),
                          dataRowMinHeight: 40,
                          dataRowMaxHeight: 60,
                          columns: const [
                            DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Precio', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Dueño (ID)', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: _products.map((product) {
                            return DataRow(
                              cells: [
                                DataCell(Text(product.id?.toString() ?? '-')),
                                DataCell(Text(product.name)),
                                DataCell(Text('\$${product.price.toStringAsFixed(2)}')),
                                DataCell(Text(product.userId?.toString() ?? 'Sin dueño')),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
    );
  }
}