import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/product.dart';

class MapScreen extends StatelessWidget {
  final Product product;

  const MapScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Verificamos si el producto tiene coordenadas guardadas
    final bool hasLocation =
        product.latitude != null && product.longitude != null;

    // Si tiene ubicación, creamos el objeto LatLng (Latitud, Longitud)
    final LatLng position = hasLocation
        ? LatLng(product.latitude!, product.longitude!)
        : const LatLng(0, 0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Ubicación: ${product.name}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: !hasLocation
          ? const Center(
              child: Text(
                'El vendedor no proporcionó la ubicación de este artículo.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: position,
                    initialZoom: 16.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.flutter_application_1',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: position,
                          width: 80,
                          height: 80,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                ),
                                child: Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Coordenadas:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text('Latitud: ${product.latitude}'),
                        Text('Longitud: ${product.longitude}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
