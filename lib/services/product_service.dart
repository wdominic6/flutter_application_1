import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/product.dart';

class ProductService {
  final String baseUrl = 'http://67.205.173.252/api';
  final _storage = const FlutterSecureStorage();

  static const Duration _httpTimeout = Duration(seconds: 10);

  Future<List<Product>> getProducts() async {
    final url = Uri.parse('$baseUrl/products');
    final token = await _storage.read(key: 'access_token');

    try {
      final response = await http
          .get(
            url,
            headers: {
              if (token != null) 'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final productsJson = _extractProductsList(body);
        return productsJson.map(Product.fromJson).toList();
      }
      return [];
    } on TimeoutException {
      debugPrint('Error obteniendo productos: timeout de conexion');
      return [];
    } catch (error) {
      debugPrint('Error obteniendo productos: $error');
      return [];
    }
  }

  List<Map<String, dynamic>> _extractProductsList(dynamic body) {
    dynamic listBody = body;

    if (body is Map) {
      listBody = body['data'] ?? body['products'] ?? body['items'] ?? body;
    }

    if (listBody is Map) {
      listBody = listBody['data'] ?? listBody['products'] ?? listBody['items'] ?? listBody;
    }

    if (listBody is! List) return [];

    return listBody.whereType<Map>().map((item) {
      return item.map((key, value) => MapEntry(key.toString(), value));
    }).toList();
  }

  Future<bool> createProduct({
    required String name,
    required String description,
    required double price,
    File? imageFile,
    double? latitude,
    double? longitude,
  }) {
    return _sendProductRequest(
      method: 'POST',
      url: Uri.parse('$baseUrl/products'),
      name: name,
      description: description,
      price: price,
      imageFile: imageFile,
      latitude: latitude,
      longitude: longitude,
      expectedStatuses: const {200, 201},
    );
  }

  Future<bool> updateProduct({
    required int id,
    required String name,
    required String description,
    required double price,
    File? imageFile,
    double? latitude,
    double? longitude,
  }) {
    return _sendProductRequest(
      method: 'POST',
      url: Uri.parse('$baseUrl/products/$id'),
      name: name,
      description: description,
      price: price,
      imageFile: imageFile,
      latitude: latitude,
      longitude: longitude,
      methodOverride: 'PUT',
      expectedStatuses: const {200, 201},
    );
  }

  Future<bool> deleteProduct(int id) async {
    final url = Uri.parse('$baseUrl/products/$id');
    final token = await _storage.read(key: 'access_token');

    try {
      final response = await http
          .delete(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(_httpTimeout);
      return response.statusCode == 200 || response.statusCode == 204;
    } on TimeoutException {
      debugPrint('Error eliminando producto: timeout de conexion');
      return false;
    } catch (error) {
      debugPrint('Error eliminando producto: $error');
      return false;
    }
  }

  Future<bool> _sendProductRequest({
    required String method,
    required Uri url,
    required String name,
    required String description,
    required double price,
    required Set<int> expectedStatuses,
    File? imageFile,
    double? latitude,
    double? longitude,
    String? methodOverride,
  }) async {
    final token = await _storage.read(key: 'access_token');
    final request = http.MultipartRequest(method, url);

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (methodOverride != null) {
      request.fields['_method'] = methodOverride;
    }
    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['price'] = price.toString();
    if (latitude != null) request.fields['latitude'] = latitude.toString();
    if (longitude != null) request.fields['longitude'] = longitude.toString();

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
    }

    try {
      final streamedResponse = await request.send().timeout(_httpTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      if (!expectedStatuses.contains(response.statusCode)) {
        debugPrint('Error guardando producto: ${response.body}');
      }
      return expectedStatuses.contains(response.statusCode);
    } on TimeoutException {
      debugPrint('Error guardando producto: timeout de conexion');
      return false;
    } catch (error) {
      debugPrint('Error guardando producto: $error');
      return false;
    }
  }
}
