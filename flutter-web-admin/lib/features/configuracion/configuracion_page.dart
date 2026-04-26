import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';

/// Provider for settings
final settingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // TODO: Connect to Convex query
  return {
    'colmado_nombre': 'Colmado de Prueba',
    'colmado_direccion': 'Santo Domingo, RD',
    'telefono': '8091234567',
    'notificaciones_ordenes': true,
    'notificaciones_whatsapp': true,
    'notificaciones_critical': true,
    'impresora': 'POS-58',
    'moneda': 'DOP',
  };
});

class ConfiguracionPage extends ConsumerWidget {
  const ConfiguracionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: ColmariaColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuración',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: ColmariaColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            
            settingsAsync.when(
              data: (settings) => _buildSettings(context, ref, settings),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Text(
                  'Error al cargar configuración',
                  style: TextStyle(color: ColmariaColors.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> settings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información del colmado
        _buildSection(
          'Información del colmado',
          [
            _buildInfoRow('Nombre', settings['colmado_nombre']),
            _buildInfoRow('Dirección', settings['colmado_direccion']),
            _buildInfoRow('Teléfono', settings['telefono']),
            _buildActionRow(
              'Editar información',
              Icons.edit,
              () => _showEditInfoDialog(context, ref, settings),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Notificaciones
        _buildSection(
          'Notificaciones',
          [
            _buildSwitchRow(
              'Nuevos pedidos',
              settings['notificaciones_ordenes'],
              (value) {},
            ),
            _buildSwitchRow(
              'Mensajes de WhatsApp',
              settings['notificaciones_whatsapp'],
              (value) {},
            ),
            _buildSwitchRow(
              'Alertas críticas',
              settings['notificaciones_critical'],
              (value) {},
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Impresora
        _buildSection(
          'Impresora',
          [
            _buildInfoRow('Impresora configurada', settings['impresora']),
            _buildActionRow(
              'Configurar impresora',
              Icons.print,
              () => _showImpresoraDialog(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Moneda
        _buildSection(
          'Moneda',
          [
            _buildInfoRow('Moneda local', settings['moneda']),
            _buildActionRow(
              'Cambiar moneda',
              Icons.currency_exchange,
              () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColmariaColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: ColmariaColors.divider),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ColmariaColors.textPrimary,
              ),
            ),
          ),
          ...children.map((child) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: ColmariaColors.divider),
              ),
            ),
            child: child,
          )),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: ColmariaColors.textMuted,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: ColmariaColors.primary,
        ),
      ],
    );
  }

  Widget _buildActionRow(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Icon(icon, size: 20, color: ColmariaColors.primary),
        ],
      ),
    );
  }

  void _showEditInfoDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> settings,
  ) {
    final nombreController = TextEditingController(text: settings['colmado_nombre']);
    final direccionController = TextEditingController(text: settings['colmado_direccion']);
    final telefonoController = TextEditingController(text: settings['telefono']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar información'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(labelText: 'Nombre del colmado'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: direccionController,
              decoration: const InputDecoration(labelText: 'Dirección'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: telefonoController,
              decoration: const InputDecoration(labelText: 'Teléfono'),
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
              ref.invalidate(settingsProvider);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showImpresoraDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurar impressora'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Selecciona tu modelo de impresora',
              style: TextStyle(color: ColmariaColors.textMuted),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('POS-58'),
              subtitle: const Text('Impresora térmica estándar'),
              leading: const Icon(Icons.print),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('XP-58'),
              subtitle: const Text('Impresora térmica'),
              leading: const Icon(Icons.print),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}