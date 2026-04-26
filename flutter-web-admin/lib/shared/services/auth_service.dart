import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// AuthService para COLMARIA — usa HTTP directo a Convex (sin WebSocket)
/// Soluciona el error: missing field 'baseVersion' de convex_flutter
class AuthService {
  static const String _tokenKey = 'colmaria_jwt';
  static const String _refreshKey = 'colmaria_refresh';

  // URL del site de Convex (para HTTP Auth endpoints)
  static const String _convexSiteUrl = 'https://different-hare-762.convex.site';
  // URL del deployment de Convex (para mutations/queries/actions)
  static const String _convexDeployUrl = 'https://different-hare-762.convex.cloud';

  // ─── Persistencia de tokens ─────────────────────────────────

  Future<void> saveTokens(String jwt, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, jwt);
    await prefs.setString(_refreshKey, refreshToken);
  }

  Future<String?> getSavedJwt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getSavedRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshKey);
  }

  // ─── Refresh del token ──────────────────────────────────────

  /// Refresca el JWT usando el refreshToken guardado
  /// Retorna el nuevo JWT o null si no hay sesión activa
  Future<String?> refreshJwt() async {
    final refreshToken = await getSavedRefresh();
    if (refreshToken == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$_convexSiteUrl/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final tokens = data['tokens'] as Map<String, dynamic>?;
        final newJwt = tokens?['token'] as String?;
        final newRefresh = tokens?['refreshToken'] as String? ?? refreshToken;
        if (newJwt != null) {
          await saveTokens(newJwt, newRefresh);
          return newJwt;
        }
      }
    } catch (_) {}

    // Si el refresh falla, limpiar tokens
    await clearTokens();
    return null;
  }

  // ─── Sign In ────────────────────────────────────────────────

  /// Login con email y password
  /// Retorna {jwt, refreshToken} o lanza AuthException
  Future<Map<String, String>> signIn(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_convexSiteUrl/api/auth/signin/password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'flow': 'signIn',
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final tokens = data['tokens'] as Map<String, dynamic>?;
        final jwt = tokens?['token'] as String?;
        final refreshToken = tokens?['refreshToken'] as String?;

        if (jwt != null && refreshToken != null) {
          await saveTokens(jwt, refreshToken);
          return {'jwt': jwt, 'refreshToken': refreshToken};
        }
        throw AuthException('InvalidResponse');
      }

      // Manejar errores del servidor
      final body = jsonDecode(response.body);
      final errorCode = body['code'] as String? ?? '';
      final errorMsg = body['message'] as String? ?? '';

      if (errorCode.contains('InvalidCredentials') ||
          errorMsg.toLowerCase().contains('invalid') ||
          response.statusCode == 401) {
        throw AuthException('InvalidCredentials');
      }
      if (errorCode.contains('AccountNotFound') ||
          errorMsg.toLowerCase().contains('not found')) {
        throw AuthException('AccountNotFound');
      }
      throw AuthException('NetworkError');
    } on AuthException {
      rethrow;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('NetworkError');
    }
  }

  // ─── Sign Up ────────────────────────────────────────────────

  /// Registro de nuevo usuario
  /// Paso 1: crea cuenta en Convex Auth
  /// Paso 2: llama mutation usuarios:registrar con los datos del colmado
  Future<Map<String, String>> signUp(
    String email,
    String password,
    String name,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_convexSiteUrl/api/auth/signin/password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'flow': 'signUp',
          'email': email,
          'password': password,
          'name': name,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final tokens = data['tokens'] as Map<String, dynamic>?;
        final jwt = tokens?['token'] as String?;
        final refreshToken = tokens?['refreshToken'] as String?;

        if (jwt != null && refreshToken != null) {
          await saveTokens(jwt, refreshToken);
          return {'jwt': jwt, 'refreshToken': refreshToken};
        }
        throw AuthException('InvalidResponse');
      }

      final body = jsonDecode(response.body);
      final errorCode = body['code'] as String? ?? '';
      final errorMsg = body['message'] as String? ?? '';

      if (errorCode.contains('AccountAlreadyExists') ||
          errorMsg.toLowerCase().contains('already exists') ||
          errorMsg.toLowerCase().contains('already registered')) {
        throw AuthException('AccountAlreadyExists');
      }
      throw AuthException('NetworkError');
    } on AuthException {
      rethrow;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('NetworkError');
    }
  }

  // ─── Mutation HTTP (sin WebSocket) ──────────────────────────

  /// Llama una mutation de Convex vía HTTP
  /// jwt: token de autenticación (opcional para mutations públicas)
  Future<dynamic> mutation(
    String path,
    Map<String, dynamic> args, {
    String? jwt,
  }) async {
    final token = jwt ?? await getSavedJwt();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.post(
      Uri.parse('$_convexDeployUrl/api/mutation'),
      headers: headers,
      body: jsonEncode({'path': path, 'args': [args]}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('errorMessage')) {
        throw AuthException('MutationError: \${data['errorMessage']}');
      }
      return data['value'] ?? data;
    }
    throw AuthException('MutationFailed: HTTP \${response.statusCode} — \${response.body}');
  }

  // ─── Query HTTP ─────────────────────────────────────────────

  /// Llama una query de Convex vía HTTP
  Future<dynamic> query(
    String path,
    Map<String, dynamic> args, {
    String? jwt,
  }) async {
    final token = jwt ?? await getSavedJwt();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.post(
      Uri.parse('$_convexDeployUrl/api/query'),
      headers: headers,
      body: jsonEncode({'path': path, 'args': [args]}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('errorMessage')) {
        throw AuthException('QueryError: \${data['errorMessage']}');
      }
      return data['value'] ?? data;
    }
    throw AuthException('QueryFailed: HTTP \${response.statusCode} — \${response.body}');
  }

  // ─── Sign Out ────────────────────────────────────────────────

  Future<void> signOut([String? jwt]) async {
    // Solo limpiar tokens locales — Convex Auth maneja la expiración server-side
    await clearTokens();
  }

  // ─── Has active session ──────────────────────────────────────

  Future<bool> hasActiveSession() async {
    final jwt = await getSavedJwt();
    return jwt != null;
  }
}

/// Excepciones tipadas para auth
class AuthException implements Exception {
  final String code;
  AuthException(this.code);

  @override
  String toString() => 'AuthException: $code';
}
