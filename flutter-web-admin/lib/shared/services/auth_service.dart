import 'package:convex_flutter/convex_flutter.dart';

class AuthService {
  final ConvexClient _client = ConvexClient.instance;

  Future<bool> signIn(String email, String password) async {
    try {
      await _client.mutation(
        name: 'auth:signIn',
        args: {'email': email, 'password': password},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _client.mutation(name: 'auth:signOut', args: {});
    } catch (e) {
      // Ignorar errores
    }
  }

  Future<bool> checkSession() async {
    try {
      final result = await _client.query(name: 'auth:session', args: {});
      return result != null;
    } catch (e) {
      return false;
    }
  }
}