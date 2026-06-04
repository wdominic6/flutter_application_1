import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/product.dart';

class ProductService {
  final String baseUrl = "http://67.205.173.252/api";
  final _storage = const FlutterSecureStorage();

  static const Duration _httpTimeout = Duration(seconds: 10);

  // 1. LISTAR PRODUCTOS (Read)
  Future<List<Product>> getProducts() async {
    final url = Uri.parse('$baseUrl/products');
    final token = await _storage.read(key: 'access_token');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(_httpTimeout);

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => Product.fromJson(item)).toList();
      }
      return [];
    } on TimeoutException {
      debugPrint("Error obteniendo productos: timeout de conexión");
      return [];
    } catch (e) {
      debugPrint("Error obteniendo productos: $e");
      return [];
    }
  }

  // 2. CREAR PRODUCTO CON IMAGEN Y COORDENADAS (Create)
  Future<bool> createProduct({
    required String name,
    required String description,
    required double price,
    File? imageFile,
    double? latitude,
    double? longitude,
  }) async {
    final url = Uri.parse('$baseUrl/products');
    final token = await _storage.read(key: 'access_token');

    // Usamos MultipartRequest para poder enviar archivos físicos (Imágenes)
    var request = http.MultipartRequest('POST', url);
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    // Adjuntar campos de texto ordinarios
    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['price'] = price.toString();
    if (latitude != null) request.fields['latitude'] = latitude.toString();
    if (longitude != null) request.fields['longitude'] = longitude.toString();

    // Adjuntar el archivo de la imagen si el usuario tomó una foto
    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
    }

    try {
      final streamedResponse = await request.send().timeout(_httpTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      return response.statusCode == 201;
    } on TimeoutException {
      debugPrint("Error creando producto: timeout de conexión");
      return false;
    } catch (e) {
      debugPrint("Error creando producto: $e");
      return false;
    }
  }

  // 3. ELIMINAR PRODUCTO (Delete)
  Future<bool> deleteProduct(int id) async {
    final url = Uri.parse('$baseUrl/products/$id');
    final token = await _storage.read(key: 'access_token');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(_httpTimeout);
      return response.statusCode == 200;
    } on TimeoutException {
      debugPrint("Error eliminando producto: timeout de conexión");
      return false;
    } catch (e) {
      debugPrint("Error eliminando producto: $e");
      return false;
    }
  }
}

