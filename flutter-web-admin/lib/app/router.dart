import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/auth/onboarding_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/productos/productos_page.dart';
import '../features/pedidos/pedidos_page.dart';
import '../features/whatsapp/whatsapp_page.dart';
import '../features/clientes/clientes_page.dart';
import '../features/metricas/metricas_page.dart';
import '../features/configuracion/configuracion_page.dart';
import '../shared/widgets/app_shell.dart';
import '../shared/providers/auth_provider.dart';

/// Router provider que usa Riverpod
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final status = authState.status;
      final isAuthenticated = status == AuthStatus.authenticated;
      final isLoading = status == AuthStatus.loading;
      final goingToPublicRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      final goingToSplash = state.matchedLocation == '/splash';
      
      // Mientras carga, mostrar splash
      if (isLoading && !goingToSplash) {
        return '/splash';
      }
      
      // Loading terminó + no autenticado → login (permitir /register sin auth)
      if (!isLoading && !isAuthenticated && !goingToPublicRoute) {
        return '/login';
      }
      
      // Si está autenticado y va a login/register, redirigir a dashboard
      if (isAuthenticated && goingToPublicRoute) {
        return '/dashboard';
      }
      
      return null;
    },
    refreshListenable: RouterRefreshNotifier(ref),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/productos',
            builder: (context, state) => const ProductosPage(),
          ),
          GoRoute(
            path: '/pedidos',
            builder: (context, state) => const PedidosPage(),
          ),
          GoRoute(
            path: '/whatsapp',
            builder: (context, state) => const WhatsAppPage(),
          ),
          GoRoute(
            path: '/clientes',
            builder: (context, state) => const ClientesPage(),
          ),
          GoRoute(
            path: '/metricas',
            builder: (context, state) => const MetricasPage(),
          ),
          GoRoute(
            path: '/configuracion',
            builder: (context, state) => const ConfiguracionPage(),
          ),
        ],
      ),
    ],
  );
});

/// Notificador para que el router reaccione a cambios en auth
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (previous, next) {
      notifyListeners();
    });
  }
}

/// Pantalla de splash mientras verifica auth
class _SplashScreen extends ConsumerStatefulWidget {
  const _SplashScreen();

  @override
  ConsumerState<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Inicializar auth al entrar al splash
    Future.microtask(() {
      ref.read(authProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F5132),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.storefront,
                size: 64,
                color: Color(0xFF0F5132),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'COLMARIA',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
