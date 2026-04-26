import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:convex_flutter/convex_flutter.dart';

import '../services/auth_service.dart';

/// Estado de autenticación
enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? jwt;
  final String? colmadoId;
  final String? userEmail;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.loading,
    this.jwt,
    this.colmadoId,
    this.userEmail,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? jwt,
    String? colmadoId,
    String? userEmail,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      jwt: jwt ?? this.jwt,
      colmadoId: colmadoId ?? this.colmadoId,
      userEmail: userEmail ?? this.userEmail,
      errorMessage: errorMessage,
    );
  }
}

/// Provider del AuthService
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// AuthNotifier que maneja el estado de autenticación
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  /// Inicializa la sesión verificando tokens guardados
  Future<void> initialize() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      // Intentar refresh del token
      final newJwt = await _authService.refreshJwt();

      if (newJwt != null) {
        // Set auth token en ConvexClient para queries autenticadas
        await ConvexClient.instance.setAuth(token: newJwt);

        // Query el colmado real del usuario autenticado
        final result = await ConvexClient.instance
            .query("colmados:getMyColmado", {});
        final decoded = jsonDecode(result) as Map<String, dynamic>;

        final colmadoData = decoded['colmado'];
        final colmadoId = colmadoData is Map<String, dynamic>
            ? colmadoData['_id'] as String?
            : null;
        final userEmail = decoded['userEmail'] as String?;

        state = AuthState(
          status: AuthStatus.authenticated,
          jwt: newJwt,
          colmadoId: colmadoId,
          userEmail: userEmail,
        );
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Login con email y password
  Future<void> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final tokens = await _authService.signIn(email, password);
      final jwt = tokens['jwt']!;

      // Set auth token en ConvexClient para queries autenticadas
      await ConvexClient.instance.setAuth(token: jwt);

      // Query el colmado real del usuario autenticado
      final result = await ConvexClient.instance
          .query("colmados:getMyColmado", {});
      final decoded = jsonDecode(result) as Map<String, dynamic>;

      final colmadoData = decoded['colmado'];
      final colmadoId = colmadoData is Map<String, dynamic>
          ? colmadoData['_id'] as String?
          : null;
      final userEmail = decoded['userEmail'] as String? ?? email;

      state = AuthState(
        status: AuthStatus.authenticated,
        jwt: jwt,
        colmadoId: colmadoId,
        userEmail: userEmail,
      );
    } on AuthException catch (e) {
      String message;
      switch (e.code) {
        case 'InvalidCredentials':
          message = 'Correo o contraseña incorrectos';
          break;
        case 'AccountNotFound':
          message = 'Esta cuenta no existe';
          break;
        case 'NetworkError':
          message = 'Sin conexión. Verifica tu internet';
          break;
        default:
          message = 'Error de autenticación';
      }
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: message,
      );
    } catch (e) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Error inesperado',
      );
    }
  }

  /// Logout
  Future<void> signOut() async {
    final jwt = state.jwt;
    if (jwt != null) {
      try {
        await _authService.signOut(jwt);
      } catch (e) {
        // Ignorar errores de red en logout
      }
    }
    // Limpiar auth token de ConvexClient
    await ConvexClient.instance.clearAuth();

    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

/// Provider del AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

/// Provider de conveniencia para verificar si está autenticado
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).status == AuthStatus.authenticated;
});

/// Provider del JWT actual
final jwtProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).jwt;
});