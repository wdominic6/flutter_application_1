import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = 'http://67.205.173.252/api';
  final _storage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static const Duration _httpTimeout = Duration(seconds: 10);
  static Future<void>? _googleInitializeFuture;

  Future<void> _ensureGoogleInitialized() {
    _googleInitializeFuture ??= _googleSignIn.initialize();
    return _googleInitializeFuture!;
  }

  Future<String?> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'access_token', value: data['access_token']);
        await _saveUserId(data);
        return null;
      }
      return 'Error ${response.statusCode}: ${response.body}';
    } on TimeoutException {
      return 'Error de conexion: El servidor tardo mucho en responder.';
    } catch (error) {
      return 'Error inesperado: $error';
    }
  }

  Future<String?> loginWithGoogle() async {
    try {
      await _ensureGoogleInitialized();

      if (!_googleSignIn.supportsAuthenticate()) {
        return 'Google Sign-In no esta disponible en esta plataforma.';
      }

      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/google'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': googleUser.email,
              'name': googleUser.displayName ?? 'Usuario de Google',
              'google_id': googleUser.id,
              'avatar': googleUser.photoUrl,
              'id_token': googleAuth.idToken,
            }),
          )
          .timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String? token = data['access_token'];
        if (token != null && token.isNotEmpty) {
          await _storage.write(key: 'access_token', value: token);
          await _saveUserId(data);
          return null;
        }
        return 'Respuesta sin token desde el servidor';
      }
      return 'Error en el servidor Laravel: ${response.statusCode}';
    } on TimeoutException {
      return 'Error de conexion al servidor (Timeout)';
    } on GoogleSignInException catch (error) {
      debugPrint(
        'Google Sign-In fallo: ${error.code.name} - ${error.description}',
      );
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return 'No se pudo completar Google Sign-In. Revisa el SHA-1/SHA-256 de Firebase y vuelve a descargar google-services.json.';
      }
      return 'Error en Google Sign-In: ${error.description ?? error.code.name}';
    } catch (error) {
      return 'Error en Google Sign-In: $error';
    }
  }

  Future<String?> register(String name, String email, String password) async {
    final url = Uri.parse('$baseUrl/register');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
            }),
          )
          .timeout(_httpTimeout);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'access_token', value: data['access_token']);
        await _saveUserId(data);
        return null;
      }
      return 'Error ${response.statusCode}: ${response.body}';
    } on TimeoutException {
      return 'Error de conexion: El servidor tardo mucho en responder.';
    } catch (error) {
      return 'Error inesperado: $error';
    }
  }

  Future<String?> recoveryPassword(String email) async {
    final url = Uri.parse('$baseUrl/password-recovery');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email}),
          )
          .timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['temporary_password'];
      }
      return null;
    } on TimeoutException {
      debugPrint('Error en recuperacion: timeout de conexion');
      return null;
    } catch (error) {
      debugPrint('Error en recuperacion: $error');
      return null;
    }
  }

  Future<String?> getToken() async {
    return _storage.read(key: 'access_token');
  }

  /// Returns the current user ID. First tries local storage (fast),
  /// then falls back to the /api/user endpoint.
  Future<int?> getCurrentUserId() async {
    // Try local cache first
    final cachedId = await _storage.read(key: 'user_id');
    if (cachedId != null && cachedId.isNotEmpty) {
      return int.tryParse(cachedId);
    }

    // Fall back to API
    final token = await getToken();
    if (token == null || token.isEmpty) return null;

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/user'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_httpTimeout);

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data is Map) {
        final userId = _parseUserId(data);
        if (userId != null) {
          await _storage.write(key: 'user_id', value: userId.toString());
        }
        return userId;
      }
    } on TimeoutException {
      debugPrint('Error obteniendo usuario actual: timeout de conexion');
    } catch (error) {
      debugPrint('Error obteniendo usuario actual: $error');
    }

    return null;
  }

  Future<void> _saveUserId(Map<String, dynamic> data) async {
    final id = _parseUserId(data);
    if (id != null) {
      await _storage.write(key: 'user_id', value: id.toString());
    }
  }

  int? _parseUserId(Map data) {
    final user = data['user'];
    final nestedData = data['data'];
    final id =
        data['id'] ??
        data['user_id'] ??
        (user is Map ? user['id'] ?? user['user_id'] : null) ??
        (nestedData is Map ? nestedData['id'] ?? nestedData['user_id'] : null);

    if (id == null) return null;
    return id is int ? id : int.tryParse(id.toString());
  }

  Future<void> logout() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/logout');

    try {
      if (token != null) {
        await http
            .post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
            )
            .timeout(_httpTimeout);
      }
    } catch (error) {
      debugPrint('Error al notificar logout al servidor: $error');
    }

    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'user_id');
    try {
      await _ensureGoogleInitialized();
      await _googleSignIn.signOut();
    } catch (error) {
      debugPrint('Error al desconectar Google: $error');
    }
  }
}
