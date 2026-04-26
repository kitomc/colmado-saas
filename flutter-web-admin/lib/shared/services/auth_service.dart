import 'dart:convert';
import 'package:convex_flutter/convex_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AuthService para Convex Auth v0.0.91
/// Usa Convex actions (NO HTTP) — signIn y signOut son actions de Convex
class AuthService {
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
      // Usar setAuthWithRefresh de convex_flutter para refresh automático
      final handle = await ConvexClient.instance.setAuthWithRefresh(
        refreshToken: refreshToken,
        onTokenRefresh: (token) async {
          await saveTokens(token, refreshToken);
        },
      );
      if (handle.authenticated) {
        return handle.token;
      }
    } catch (e) {
      await clearTokens();
    }
    return null;
  }

  /// Login con email y password vía Convex action
  /// Retorna {jwt, refreshToken} o lanza AuthException
  Future<Map<String, String>> signIn(String email, String password) async {
    try {
      final result = await ConvexClient.instance.action(
        name: 'auth:signIn',
        args: {
          'provider': 'password',
          'params': {'email': email, 'password': password, 'flow': 'signIn'},
        },
      );
      final data = jsonDecode(result) as Map<String, dynamic>;
      final tokens = data['tokens'] as Map<String, dynamic>?;
      if (tokens != null) {
        final jwt = tokens['token'] as String?;
        final refreshToken = tokens['refreshToken'] as String?;
        if (jwt != null && refreshToken != null) {
          await saveTokens(jwt, refreshToken);
          await ConvexClient.instance.setAuth(token: jwt);
          return {'jwt': jwt, 'refreshToken': refreshToken};
        }
      }
      throw AuthException('InvalidResponse');
    } on AuthException {
      rethrow;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('InvalidCredentials') || msg.contains('invalid credentials')) {
        throw AuthException('InvalidCredentials');
      }
      if (msg.contains('AccountNotFound') || msg.contains('account not found')) {
        throw AuthException('AccountNotFound');
      }
      throw AuthException('NetworkError');
    }
  }

  /// Registro vía Convex action
  Future<Map<String, String>> signUp(String email, String password, String name) async {
    try {
      final result = await ConvexClient.instance.action(
        name: 'auth:signIn',
        args: {
          'provider': 'password',
          'params': {'email': email, 'password': password, 'flow': 'signUp', 'name': name},
        },
      );
      final data = jsonDecode(result) as Map<String, dynamic>;
      final tokens = data['tokens'] as Map<String, dynamic>?;
      if (tokens != null) {
        final jwt = tokens['token'] as String?;
        final refreshToken = tokens['refreshToken'] as String?;
        if (jwt != null && refreshToken != null) {
          await saveTokens(jwt, refreshToken);
          await ConvexClient.instance.setAuth(token: jwt);
          return {'jwt': jwt, 'refreshToken': refreshToken};
        }
      }
      throw AuthException('InvalidResponse');
    } on AuthException {
      rethrow;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('AccountAlreadyExists') || msg.contains('account already exists')) {
        throw AuthException('AccountAlreadyExists');
      }
      throw AuthException('NetworkError');
    }
  }

  /// Logout: llama action de Convex y borra tokens
  Future<void> signOut() async {
    try {
      await ConvexClient.instance.action(name: 'auth:signOut', args: {});
    } catch (_) {}
    await ConvexClient.instance.clearAuth();
    await clearTokens();
  }

  /// Verifica si hay una sesión activa
  Future<bool> hasActiveSession() async {
    final jwt = await getSavedJwt();
    if (jwt == null) return false;
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
