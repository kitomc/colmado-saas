import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// AuthNotifier — maneja el estado de auth usando HTTP puro (sin convex_flutter WebSocket)
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  /// Inicializa la sesión verificando tokens guardados
  Future<void> initialize() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final savedJwt = await _authService.getSavedJwt();

      if (savedJwt != null) {
        // Intentar cargar el colmado con el JWT guardado
        try {
          final result = await _authService.query(
            'colmados:getMyColmado',
            {},
            jwt: savedJwt,
          );

          String? colmadoId;
          String? userEmail;

          if (result is Map<String, dynamic>) {
            final colmadoData = result['colmado'];
            colmadoId = colmadoData is Map<String, dynamic>
                ? colmadoData['_id'] as String?
                : null;
            userEmail = result['userEmail'] as String?;
          }

          state = AuthState(
            status: AuthStatus.authenticated,
            jwt: savedJwt,
            colmadoId: colmadoId,
            userEmail: userEmail,
          );
        } catch (_) {
          // JWT expirado — intentar refresh
          final newJwt = await _authService.refreshJwt();
          if (newJwt != null) {
            state = AuthState(
              status: AuthStatus.authenticated,
              jwt: newJwt,
            );
          } else {
            state = const AuthState(status: AuthStatus.unauthenticated);
          }
        }
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Login con email y password
  Future<void> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final tokens = await _authService.signIn(email, password);
      final jwt = tokens['jwt']!;

      // Query el colmado del usuario autenticado vía HTTP
      String? colmadoId;
      String? userEmail = email;

      try {
        final result = await _authService.query(
          'colmados:getMyColmado',
          {},
          jwt: jwt,
        );
        if (result is Map<String, dynamic>) {
          final colmadoData = result['colmado'];
          colmadoId = colmadoData is Map<String, dynamic>
              ? colmadoData['_id'] as String?
              : null;
          userEmail = result['userEmail'] as String? ?? email;
        }
      } catch (_) {
        // Si la query falla, igual autenticar (colmado se cargará después)
      }

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
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Error inesperado',
      );
    }
  }

  /// Registro completo de nuevo usuario
  Future<void> signUp({
    required String email,
    required String password,
    required String nombre,
    required String nombreColmado,
    required String telefono,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      // Paso 1: Crear cuenta en Convex Auth
      final tokens = await _authService.signUp(email, password, nombre);
      final jwt = tokens['jwt']!;

      // Paso 2: Registrar en tabla usuarios con datos del colmado
      try {
        await _authService.mutation(
          'usuarios:registrar',
          {
            'nombre': nombre,
            'email': email,
            'nombre_colmado': nombreColmado,
            'telefono': telefono,
          },
          jwt: jwt,
        );
      } catch (mutErr) {
        // La cuenta se creó pero hubo error en la mutation
        // Igual autenticamos — el onboarding puede completar el perfil
      }

      state = AuthState(
        status: AuthStatus.authenticated,
        jwt: jwt,
        userEmail: email,
      );
    } on AuthException catch (e) {
      String message;
      switch (e.code) {
        case 'AccountAlreadyExists':
          message = 'Ya existe una cuenta con este correo';
          break;
        case 'NetworkError':
          message = 'Sin conexión. Verifica tu internet';
          break;
        default:
          message = 'Error al crear la cuenta';
      }
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: message,
      );
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Error inesperado. Intenta de nuevo',
      );
    }
  }

  /// Logout
  Future<void> signOut() async {
    final jwt = state.jwt;
    try {
      await _authService.signOut(jwt);
    } catch (_) {}
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
