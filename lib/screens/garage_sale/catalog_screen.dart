import 'package:flutter/material.dart';
import 'dart:async'; // Necesario para el StreamSubscription
import 'dart:math'; // Necesario para calcular la fuerza del movimiento
import 'package:sensors_plus/sensors_plus.dart'; // El paquete de sensores
import '../../services/auth_service.dart';
import '../../services/product_service.dart';
import '../../models/product.dart';
import 'product_form_screen.dart';
import 'product_detail_screen.dart';
import 'list_products_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _productService = ProductService();
  final _authService = AuthService();
  List<Product> _products = [];
  bool _isLoading = true;
  int? _currentUserId;

  // Variables para el Acelerómetro
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DateTime _lastWarningTime =
      DateTime.now(); // Para no saturar al usuario con alertas

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _startAccelerometer();
  }

  void _contactSeller(String productName) async {
    // Número de prueba (reemplázalo por el tuyo con código de país, ej: 52 para México, 51 para Perú)
    // En un caso real, este número vendría del modelo 'product.seller_phone'
    const String phoneNumber = "51949769189";

    final String message =
        "Hola! Estoy interesado en tu artículo '$productName' que vi en la App de Venta de Garage.";

    // Creamos la URL codificada con el formato oficial de WhatsApp
    final Uri whatsappUri = Uri.parse(
      "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}",
    );

    // Verificamos si se puede abrir y la lanzamos
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir WhatsApp en este dispositivo.'),
        ),
      );
    }
  }
  // --- LÓGICA DEL SENSOR (ACELERÓMETRO) ---
  void _startAccelerometer() {
    _accelerometerSubscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      // Calculamos la magnitud total del movimiento (Fórmula matemática vectorial)
      // Restamos aprox 9.8 que es la gravedad de la tierra para obtener solo el movimiento del usuario
      double acceleration =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z) - 9.8;

      // Si la aceleración es mayor a 5 (un sacudón o caminar rápido)
      if (acceleration > 5.0 || acceleration < -5.0) {
        final now = DateTime.now();
        // Solo mostramos la advertencia si pasaron al menos 10 segundos desde la última vez
        if (now.difference(_lastWarningTime).inSeconds > 10) {
          _lastWarningTime = now;
          _showSafetyWarning();
        }
      }
    });
  }

  void _showSafetyWarning() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.yellow),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '¡Cuidado! Mantente alerta a tu entorno mientras caminas.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Al salir de la pantalla, apagamos el sensor para ahorrar batería
  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }
  // ----------------------------------------

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _productService.getProducts(),
      _authService.getCurrentUserId(),
    ]);
    final products = results[0] as List<Product>;
    final currentUserId = results[1] as int?;

    if (!mounted) return;
    setState(() {
      _products = products;
      _currentUserId = currentUserId;
      _isLoading = false;
    });
  }

  Future<void> _editProduct(Product product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(productToEdit: product),
      ),
    );
    if (result == true) _loadProducts();
  }

  void _deleteProduct(Product product) async {
    final id = product.id;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se puede eliminar este producto.')),
      );
      return;
    }

    bool success = await _productService.deleteProduct(id);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Producto eliminado')));
      _loadProducts(); // Recarga la lista
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas de Garage'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Ver Reporte',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ListProductsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              // 1. Llamamos al servicio para borrar el token
              final nav = Navigator.of(context);
              await _authService.logout();

              if (!mounted) return;

              // 2. Lo mandamos al Login y borramos el historial de pantallas
              // para que no pueda volver atrás con el botón del celular
              nav.pushNamedAndRemoveUntil('/login', (route) => false);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
          ? const Center(child: Text('No hay productos publicados aún.'))
          : ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                final canManage = product.canBeManagedBy(_currentUserId);
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(product: product),
                        ),
                      );
                    },
                    leading: product.imagePath != null
                        ? Image.network(
                            product.imagePath!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.image, size: 50),
                    title: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '\$${product.price.toStringAsFixed(2)}\n${product.description ?? ""}',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize
                          .min, // Evita que el renglón ocupe toda la pantalla
                      children: [
                        // Botón de WhatsApp 👇
                        IconButton(
                          icon: const Icon(Icons.chat, color: Colors.green),
                          tooltip: 'Contactar por WhatsApp',
                          onPressed: () => _contactSeller(product.name),
                        ),
                        if (canManage) ...[
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.teal),
                            tooltip: 'Editar producto',
                            onPressed: () => _editProduct(product),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Eliminar producto',
                            onPressed: () => _deleteProduct(product),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductFormScreen()),
          );
          if (result == true) _loadProducts();
        },
      ),
    );
  }
}
