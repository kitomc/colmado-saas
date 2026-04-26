import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/productos/productos_page.dart';
import '../features/pedidos/pedidos_page.dart';
import '../features/whatsapp/whatsapp_page.dart';
import '../features/clientes/clientes_page.dart';
import '../features/metricas/metricas_page.dart';
import '../features/configuracion/configuracion_page.dart';
import '../shared/widgets/app_shell.dart';

GoRouter createRouter(bool isAuthenticated, Function(bool) onAuthStateChanged) {
  return GoRouter(
    initialLocation: isAuthenticated ? '/dashboard' : '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginPage(
          onAuthStateChanged: onAuthStateChanged,
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(
          child: child,
          onAuthStateChanged: onAuthStateChanged,
        ),
        routes: [
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardPage()),
          GoRoute(path: '/productos', builder: (context, state) => const ProductosPage()),
          GoRoute(path: '/pedidos', builder: (context, state) => const PedidosPage()),
          GoRoute(path: '/whatsapp', builder: (context, state) => const WhatsAppPage()),
          GoRoute(path: '/clientes', builder: (context, state) => const ClientesPage()),
          GoRoute(path: '/metricas', builder: (context, state) => const MetricasPage()),
          GoRoute(path: '/configuracion', builder: (context, state) => const ConfiguracionPage()),
        ],
      ),
    ],
    redirect: (context, state) {
      if (!isAuthenticated && state.uri.toString() != '/login') {
        return '/login';
      }
      if (isAuthenticated && state.uri.toString() == '/login') {
        return '/dashboard';
      }
      return null;
    },
  );
}