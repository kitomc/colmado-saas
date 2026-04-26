import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';

/// Estado de autenticación
enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? jwt;
  final String? userEmail;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.loading,
    this.jwt,
    this.userEmail,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? jwt,
    String? userEmail,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      jwt: jwt ?? this.jwt,
      userEmail: userEmail ?? this.userEmail,
      errorMessage: errorMessage,
    );
  }
}

/// Provider del AuthService
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// AuthNotifier que maneja el estado de autenticación
/// NO usa ConvexClient — solo AuthService con HTTP + SharedPreferences
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  /// Inicializa la sesión verificando tokens guardados
  Future<void> initialize() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final newJwt = await _authService.refreshJwt();

      if (newJwt != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          jwt: newJwt,
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
      state = AuthState(
        status: AuthStatus.authenticated,
        jwt: tokens['jwt'],
        userEmail: email,
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
        case 'ServerError':
          message = 'Error del servidor. Intenta de nuevo.';
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
    await _authService.signOut();
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
