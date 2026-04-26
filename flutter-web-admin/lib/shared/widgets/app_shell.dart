import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../providers/auth_provider.dart';

/// Provider del estado del colmado
final colmadoProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

/// Proveedor de是否 el WhatsApp está conectado
final whatsappConectadoProvider = Provider<bool>((ref) {
  final colmado = ref.watch(colmadoProvider);
  return colmado?['meta_conectado'] == true;
});

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final whatsappConectado = ref.watch(whatsappConectadoProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar - 240px
          Container(
            width: 240,
            color: ColmariaColors.primaryDark,
            child: Column(
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'COLMARIA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Web Admin',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24),
                // Nav items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _NavItem(
                        icon: Icons.dashboard,
                        label: 'Dashboard',
                        path: '/dashboard',
                        isActive: location == '/dashboard',
                      ),
                      _NavItem(
                        icon: Icons.inventory_2,
                        label: 'Productos',
                        path: '/productos',
                        isActive: location.startsWith('/productos'),
                      ),
                      _NavItem(
                        icon: Icons.receipt_long,
                        label: 'Pedidos',
                        path: '/pedidos',
                        isActive: location.startsWith('/pedidos'),
                      ),
                      _NavItem(
                        icon: Icons.chat,
                        label: 'WhatsApp',
                        path: '/whatsapp',
                        isActive: location.startsWith('/whatsapp'),
                        indicador: whatsappConectado,
                      ),
                      _NavItem(
                        icon: Icons.people,
                        label: 'Clientes',
                        path: '/clientes',
                        isActive: location.startsWith('/clientes'),
                      ),
                      _NavItem(
                        icon: Icons.analytics,
                        label: 'Métricas',
                        path: '/metricas',
                        isActive: location.startsWith('/metricas'),
                      ),
                      _NavItem(
                        icon: Icons.settings,
                        label: 'Configuración',
                        path: '/configuracion',
                        isActive: location.startsWith('/configuracion'),
                      ),
                    ],
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white24,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Usuario',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  authState.userEmail ?? 'Sin email',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.logout, color: Colors.white70, size: 18),
                            onPressed: () {
                              ref.read(authProvider.notifier).signOut();
                            },
                            tooltip: 'Cerrar sesión',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                // Topbar - 64px
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: ColmariaColors.divider),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Breadcrumb
                      Text(
                        _getPageTitle(location),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: ColmariaColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      // WhatsApp indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: whatsappConectado
                              ? ColmariaColors.chipGreenBg
                              : ColmariaColors.chipGrayBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: whatsappConectado
                                    ? ColmariaColors.primary
                                    : ColmariaColors.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'WhatsApp',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: whatsappConectado
                                    ? ColmariaColors.chipGreenTx
                                    : ColmariaColors.chipGrayTx,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Avatar
                      CircleAvatar(
                        backgroundColor: ColmariaColors.primary,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                // Page content
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPageTitle(String location) {
    if (location == '/dashboard') return 'Dashboard';
    if (location.startsWith('/productos')) return 'Productos';
    if (location.startsWith('/pedidos')) return 'Pedidos';
    if (location.startsWith('/whatsapp')) return 'WhatsApp';
    if (location.startsWith('/clientes')) return 'Clientes';
    if (location.startsWith('/metricas')) return 'Métricas';
    if (location.startsWith('/configuracion')) return 'Configuración';
    return 'COLMARIA';
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final bool isActive;
  final bool? indicador;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    this.isActive = false,
    this.indicador,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(path),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: isActive
                  ? Border(
                      left: BorderSide(
                        color: ColmariaColors.primary,
                        width: 3,
                      ),
                    )
                  : null,
              color: isActive ? Colors.white.withValues(alpha: 0.15) : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? Colors.white : Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (indicador != null)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: indicador!
                          ? ColmariaColors.primary
                          : ColmariaColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}