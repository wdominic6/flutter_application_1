import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final String baseUrl = "http://67.205.173.252/api";
  final _storage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleInitialized = false;

  static const Duration _httpTimeout = Duration(seconds: 10);

  Future<String?> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'access_token', value: data['access_token']);
        return null; // Éxito
      }
      return 'Error ${response.statusCode}: ${response.body}';
    } on TimeoutException {
      return "Error de conexión: El servidor tardó mucho en responder.";
    } catch (e) {
      return "Error inesperado: $e";
    }
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleInitialized) return;
    await _googleSignIn.initialize();
    _googleInitialized = true;
  }

  Future<String?> loginWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();
      // Usar la API actual: authenticate() -> devuelve GoogleSignInAccount o lanza
      final googleUser = await _googleSignIn.authenticate();

      final payload = jsonEncode({
        'email': googleUser.email,
        'name': googleUser.displayName ?? 'Usuario de Google',
      });

      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: payload,
      ).timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String? token = data['access_token'];
        if (token != null && token.isNotEmpty) {
          await _storage.write(key: 'access_token', value: token);
          return null; // Éxito
        }
        return 'Respuesta sin token desde el servidor';
      }
      return 'Error en el servidor Laravel: ${response.statusCode}';
    } on GoogleSignInException catch (error) {
      // Casos esperados: cancelado, interrumpido o UI no disponible
      if (error.code == GoogleSignInExceptionCode.canceled ||
          error.code == GoogleSignInExceptionCode.interrupted ||
          error.code == GoogleSignInExceptionCode.uiUnavailable) {
        return 'Acción cancelada.';
      }
      return 'Error en Google Sign In: ${error.code}';
    } on TimeoutException {
      return "Error de conexión al servidor (Timeout)";
    } catch (error) {
      return 'Error crítico en Google Sign In: $error';
    }
  }

  Future<String?> register(String name, String email, String password) async {
    final url = Uri.parse('$baseUrl/register');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      ).timeout(_httpTimeout);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'access_token', value: data['access_token']);
        return null; // Éxito
      }
      return 'Error ${response.statusCode}: ${response.body}';
    } on TimeoutException {
      return "Error de conexión: El servidor tardó mucho en responder.";
    } catch (e) {
      return "Error inesperado: $e";
    }
  }

  Future<String?> recoveryPassword(String email) async {
    final url = Uri.parse('$baseUrl/password-recovery');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email}),
      ).timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['temporary_password'];
      }
      return null;
    } on TimeoutException {
      debugPrint("Error en recuperación: timeout de conexión");
      return null;
    } catch (e) {
      debugPrint("Error en recuperación: $e");
      return null;
    }
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<void> logout() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/logout');

    try {
      if (token != null) {
        await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(_httpTimeout);
      }
    } catch (e) {
      debugPrint('Error al notificar logout al servidor: $e');
    }

    await _storage.delete(key: 'access_token');
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Error al desconectar Google: $e');
    }
  }
}

