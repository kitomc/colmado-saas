import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../shared/widgets/kpi_card.dart';

/// Provider for WhatsApp connection status
final whatsappStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // TODO: Connect to Convex query
  return {
    'conectado': false,
    'phone': null,
    'nombre': null,
    'mensajes_hoy': 0,
    'ultimo_mensaje': null,
  };
});

/// Provider for bot enabled
final botEnabledProvider = StateProvider<bool>((ref) => true);

class WhatsAppPage extends ConsumerWidget {
  const WhatsAppPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(whatsappStatusProvider);
    final botEnabled = ref.watch(botEnabledProvider);

    return Scaffold(
      backgroundColor: ColmariaColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WhatsApp',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: ColmariaColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: statusAsync.when(
                data: (status) {
                  if (!(status['conectado'] as bool)) {
                    return _buildNotConnected(context, ref);
                  }
                  return _buildConnected(context, ref, status, botEnabled);
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (_, __) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: ColmariaColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al conectar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(whatsappStatusProvider),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotConnected(BuildContext context, WidgetRef ref) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColmariaColors.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColmariaColors.chipYellowBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat,
                size: 48,
                color: ColmariaColors.chipYellowTx,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Conecta tu WhatsApp',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: ColmariaColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ' vincula tu número de WhatsApp Business para recibir pedidos automáticos',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColmariaColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showConnectDialog(context, ref),
              icon: const Icon(Icons.link),
              label: const Text('Conectar WhatsApp'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Necesitas un número de WhatsApp Business verificado',
              style: TextStyle(
                fontSize: 12,
                color: ColmariaColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnected(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> status,
    bool botEnabled,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColmariaColors.divider),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColmariaColors.chipGreenBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: ColmariaColors.chipGreenTx,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conectado',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: ColmariaColors.textPrimary,
                      ),
                    ),
                    Text(
                      status['phone'] as String? ?? '',
                      style: TextStyle(
                        color: ColmariaColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => _showDisconnectDialog(context, ref),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColmariaColors.error,
                ),
                child: const Text('Desconectar'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // KPI Cards
        Row(
          children: [
            Expanded(
              child: KpiCard(
                title: 'Mensajes hoy',
                value: '${status['mensajes_hoy']}',
                icon: Icons.chat_bubble,
                color: ColmariaColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: KpiCard(
                title: 'Pedidos IA',
                value: '8',
                icon: Icons.auto_awesome,
                color: ColmariaColors.info,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: KpiCard(
                title: 'Pedidos manual',
                value: '4',
                icon: Icons.person,
                color: ColmariaColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Bot Control
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColmariaColors.divider),
          ),
          child: Row(
            children: [
              Icon(
                Icons.smart_toy,
                color: botEnabled
                    ? ColmariaColors.primary
                    : ColmariaColors.textMuted,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bot automático',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ColmariaColors.textPrimary,
                      ),
                    ),
                    Text(
                      botEnabled
                          ? 'El agente IA responde automáticamente'
                          : 'Las respuestas las manejas tú manualmente',
                      style: TextStyle(
                        fontSize: 12,
                        color: ColmariaColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: botEnabled,
                onChanged: (value) =>
                    ref.read(botEnabledProvider.notifier).state = value,
                activeColor: ColmariaColors.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Last message
        if (status['ultimo_mensaje'] != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColmariaColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Último mensaje',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColmariaColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Text(status['ultimo_mensaje'] as String),
              ],
            ),
          ),
      ],
    );
  }

  void _showConnectDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conectar WhatsApp'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Para conectar WhatsApp necesitas:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildRequirement(Icons.check, 'Una cuenta de WhatsApp Business'),
            const SizedBox(height: 8),
            _buildRequirement(Icons.check, 'Acceso a Meta for Developers'),
            const SizedBox(height: 8),
            _buildRequirement(Icons.check, 'Token de API de WhatsApp Cloud'),
            const SizedBox(height: 8),
            _buildRequirement(Icons.check, 'Número telefónico verificado'),
            const SizedBox(height: 24),
            Text(
              'Una vez que tengas tu token, ingrésalo abajo:',
              style: TextStyle(
                fontSize: 12,
                color: ColmariaColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Token de API',
                hintText: 'Ingresa tu token de WhatsApp',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.invalidate(whatsappStatusProvider);
            },
            child: const Text('Conectar'),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirement(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ColmariaColors.primary),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  void _showDisconnectDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desconectar WhatsApp'),
        content: const Text(
          '¿Estás seguro de que quieres desconectar WhatsApp? '
          'Los clientes ya no podrán contactarte por este canal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColmariaColors.error,
            ),
            onPressed: () {
              Navigator.pop(context);
              ref.invalidate(whatsappStatusProvider);
            },
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );
  }
}