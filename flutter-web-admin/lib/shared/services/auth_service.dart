import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// AuthService para Convex Auth
/// Maneja login, logout, refresh tokens y persistencia
class AuthService {
  static const String _baseUrl = 'https://different-hare-762.convex.cloud';
  static const String _tokenKey = 'colmaria_jwt';
  static const String _refreshKey = 'colmaria_refresh';

  /// Guarda los tokens en SharedPreferences
  Future<void> saveTokens(String jwt, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, jwt);
    await prefs.setString(_refreshKey, refreshToken);
  }

  /// Lee el JWT guardado
  Future<String?> getSavedJwt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Lee el refresh token guardado
  Future<String?> getSavedRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  /// Borra los tokens (logout)
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshKey);
  }

  /// Refresca el JWT usando el refresh token
  Future<String?> refreshJwt() async {
    final refreshToken = await getSavedRefresh();
    if (refreshToken == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tokens = data['tokens'];
        if (tokens != null) {
          final newJwt = tokens['token'] as String?;
          final newRefresh = tokens['refreshToken'] as String?;
          
          if (newJwt != null && newRefresh != null) {
            await saveTokens(newJwt, newRefresh);
            return newJwt;
          }
        }
      }
    } catch (e) {
      // Network error - return null
    }
    
    // Si falló, limpiar tokens
    await clearTokens();
    return null;
  }

  /// Login con email y password
  /// Retorna {jwt, refreshToken} o lanza AuthException
  Future<Map<String, String>> signIn(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/signin/password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'flow': 'signIn',
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tokens = data['tokens'];
        
        if (tokens != null) {
          final jwt = tokens['token'] as String?;
          final refreshToken = tokens['refreshToken'] as String?;
          
          if (jwt != null && refreshToken != null) {
            await saveTokens(jwt, refreshToken);
            return {'jwt': jwt, 'refreshToken': refreshToken};
          }
        }
        
        // Respuesta inesperada
        throw AuthException('InvalidResponse');
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        final data = jsonDecode(response.body);
        final code = data['code'] as String? ?? 'Unknown';
        
        switch (code) {
          case 'InvalidCredentials':
          case 'INVALID_CREDENTIALS':
            throw AuthException('InvalidCredentials');
          case 'AccountNotFound':
          case 'ACCOUNT_NOT_FOUND':
            throw AuthException('AccountNotFound');
          default:
            throw AuthException(code);
        }
      } else {
        throw AuthException('ServerError');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('NetworkError');
    }
  }

  /// Logout: llama al endpoint y borra tokens locales
  Future<void> signOut(String jwt) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/auth/signout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({}),
      );
    } catch (e) {
      // Ignorar errores de red en logout
    } finally {
      await clearTokens();
    }
  }

  /// Verifica si hay una sesión activa
  Future<bool> hasActiveSession() async {
    final jwt = await getSavedJwt();
    if (jwt == null) return false;
    
    // Intentar refresh si el JWT parece expirado
    final newJwt = await refreshJwt();
    return newJwt != null;
  }
}

/// Excepciones tipadas para auth
class AuthException implements Exception {
  final String code;
  
  AuthException(this.code);
  
  @override
  String toString() => 'AuthException: $code';
}
