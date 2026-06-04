import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: position,
                zoom: 16.0, // Nivel de acercamiento a las calles
              ),
              markers: {
                Marker(
                  markerId: MarkerId('vendedor_${product.id}'),
                  position: position,
                  infoWindow: InfoWindow(
                    title: 'Venta de: ${product.name}',
                    snippet: 'Precio: \$${product.price.toStringAsFixed(2)}',
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ),
                ),
              },
            ),
    );
  }
}
