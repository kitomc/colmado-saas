import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _tokenKey = 'colmaria_jwt';
  static const _refreshKey = 'colmaria_refresh';
  static const _deployUrl = 'https://different-hare-762.convex.cloud';

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

  Future<String?> refreshJwt() async {
    return await getSavedJwt();
  }

  Future<Map<String, String>> signIn(String email, String password) async {
    final res = await http.post(
      Uri.parse('$_deployUrl/api/action'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'path': 'auth:signIn',
        'args': [{'provider': 'password', 'params': {'email': email, 'password': password, 'flow': 'signIn'}}],
      }),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final tokens = data['value']?['tokens'] ?? data['tokens'];
      final token = tokens['token'] as String?;
      final refresh = tokens['refreshToken'] as String? ?? '';
      if (token != null) {
        await saveTokens(token, refresh);
        return {'jwt': token, 'refreshToken': refresh};
      }
    }
    throw AuthException('InvalidCredentials');
  }

  Future<Map<String, String>> signUp(String email, String password, String name) async {
    final res = await http.post(
      Uri.parse('$_deployUrl/api/action'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'path': 'auth:signIn',
        'args': [{'provider': 'password', 'params': {'email': email, 'password': password, 'flow': 'signUp', 'name': name}}],
      }),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final tokens = data['value']?['tokens'] ?? data['tokens'];
      final token = tokens['token'] as String?;
      final refresh = tokens['refreshToken'] as String? ?? '';
      if (token != null) {
        await saveTokens(token, refresh);
        return {'jwt': token, 'refreshToken': refresh};
      }
    }
    throw AuthException('NetworkError');
  }

  Future<void> signOut() async {
    await clearTokens();
  }
}

class AuthException implements Exception {
  final String code;
  AuthException(this.code);
  @override
  String toString() => 'AuthException: $code';
}
