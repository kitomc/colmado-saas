import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:convex_flutter/convex_flutter.dart';

import '../../app/theme.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/boton_primario.dart';
import '../../shared/widgets/boton_secundario.dart';
import '../../shared/widgets/estado_chip.dart';

/// Mapa de connectionState → label para EstadoChip
String _connectionLabel(String state) {
  switch (state) {
    case 'connected':
      return 'conectado';
    case 'connecting':
      return 'imprimiendo'; // reusamos el chip animado (pulse)
    default:
      return 'inactivo';
  }
}

class WhatsAppPage extends ConsumerStatefulWidget {
  const WhatsAppPage({super.key});

  @override
  ConsumerState<WhatsAppPage> createState() => _WhatsAppPageState();
}

class _WhatsAppPageState extends ConsumerState<WhatsAppPage> {
  // ── Estado ──────────────────────────────────────────────────────────────
  bool _isLoading = false;
  String? _qrBase64;
  String? _instanceName;
  String _connectionState = 'disconnected'; // disconnected | connecting | connected
  Timer? _pollTimer;
  // ignore: unused_field
  String? _testNumber;
  bool _botActivo = true;
  // ignore: unused_field
  String _botPrompt = '';
  // ignore: unused_field
  bool _isPolling = false;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ── Acciones Convex ─────────────────────────────────────────────────────

  String? get _colmadoId => ref.read(authProvider).colmadoId;

  Future<Map<String, dynamic>> _callAction(
    String name,
    Map<String, dynamic> args,
  ) async {
    final client = ConvexClient.instance;
    // El auth token ya se seteó vía setAuth() en el login
    final raw = await client.action(name: name, args: args);
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ── Generar QR ──────────────────────────────────────────────────────────

  Future<void> _generarQR() async {
    final colmadoId = _colmadoId;
    if (colmadoId == null) return;

    setState(() {
      _isLoading = true;
      _qrBase64 = null;
    });

    try {
      // 1. Crear instancia en Evolution API
      final instancia = await _callAction('evolution:crearInstancia', {
        'colmado_id': colmadoId,
      });
      final instanceName = instancia['instanceName'] as String? ??
          instancia['instance_name'] as String? ??
          'default';

      // 2. Obtener QR
      final qrResult = await _callAction('evolution:obtenerQR', {
        'instanceName': instanceName,
      });
      final qrBase64 = qrResult['base64'] as String? ??
          qrResult['qrcode'] as String?;

      setState(() {
        _instanceName = instanceName;
        _qrBase64 = qrBase64;
        _connectionState = 'connecting';
        _isLoading = false;
      });

      // 3. Iniciar polling de estado
      _iniciarPolling(instanceName);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar QR: $e'),
            backgroundColor: ColmariaColors.error,
          ),
        );
      }
    }
  }

  // ── Polling ─────────────────────────────────────────────────────────────

  void _iniciarPolling(String instanceName) {
    _pollTimer?.cancel();
    setState(() => _isPolling = true);

    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final result = await _callAction('evolution:verificarEstado', {
          'instanceName': instanceName,
        });
        final state = result['state'] as String? ?? '';

        if (state == 'open') {
          _pollTimer?.cancel();
          if (mounted) {
            setState(() {
              _connectionState = 'connected';
              _isPolling = false;
            });
          }
        }
      } catch (_) {
        // Ignorar errores de polling individuales
      }
    });
  }

  // ── Desconectar ─────────────────────────────────────────────────────────

  Future<void> _desconectar() async {
    final instanceName = _instanceName;
    if (instanceName == null) return;

    try {
      await _callAction('evolution:desconectar', {
        'instanceName': instanceName,
      });
    } catch (_) {
      // Si falla igual reseteamos el estado local
    }

    _pollTimer?.cancel();
    if (mounted) {
      setState(() {
        _qrBase64 = null;
        _instanceName = null;
        _connectionState = 'disconnected';
        _isPolling = false;
        _isLoading = false;
      });
    }
  }

  // ── Enviar prueba ───────────────────────────────────────────────────────

  Future<String?> _mostrarDialogoNumero() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enviar mensaje de prueba'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Número de teléfono',
            hintText: 'Ej: 18295551234',
            helperText: 'Incluye código de país sin +',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final numero = controller.text.trim();
              controller.dispose();
              Navigator.pop(ctx, numero);
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  Future<void> _enviarPrueba() async {
    final numero = await _mostrarDialogoNumero();
    if (numero == null || numero.isEmpty) return;

    final instanceName = _instanceName;
    if (instanceName == null) return;

    try {
      await _callAction('evolution:enviarMensajePrueba', {
        'instanceName': instanceName,
        'numero': numero,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Mensaje de prueba enviado'),
            backgroundColor: ColmariaColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar: $e'),
            backgroundColor: ColmariaColors.error,
          ),
        );
      }
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isConnected = _connectionState == 'connected';

    return Scaffold(
      backgroundColor: ColmariaColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.qr_code, color: Color(0xFF25D366), size: 28),
                const SizedBox(width: 12),
                Text(
                  'WhatsApp Business',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: ColmariaColors.textPrimary,
                  ),
                ),
                const Spacer(),
                EstadoChip(estado: _connectionLabel(_connectionState)),
              ],
            ),
            const SizedBox(height: 24),

            // ── Cuerpo ──────────────────────────────────────────────────
            Expanded(
              child: isConnected
                  ? _buildConnectedBody()
                  : _buildDisconnectedBody(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Body: Desconectado ──────────────────────────────────────────────────

  Widget _buildDisconnectedBody() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColmariaColors.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeaderIcon(),
            const SizedBox(height: 20),
            _buildTitle('Conecta tu WhatsApp',
                'Escanea el código QR con tu WhatsApp para empezar a recibir pedidos'),
            const SizedBox(height: 24),
            if (_qrBase64 != null) _buildQRImage(),
            if (_isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
            ],
            _buildGenerarBoton(),
            if (_qrBase64 != null) _buildActualizarSection(),
            if (_connectionState == 'connecting') ...[
              const SizedBox(height: 16),
              _buildConnectingBanner(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return const Icon(Icons.qr_code, size: 64, color: Color(0xFF25D366));
  }

  Widget _buildTitle(String title, String subtitle) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: ColmariaColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: ColmariaColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildQRImage() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            base64Decode(_qrBase64!),
            width: 256,
            height: 256,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGenerarBoton() {
    return BotonPrimario(
      label: 'Generar QR',
      icon: Icons.qr_code,
      isLoading: _isLoading,
      onPressed: _isLoading ? null : _generarQR,
    );
  }

  Widget _buildActualizarSection() {
    return Column(
      children: [
        const SizedBox(height: 12),
        BotonSecundario(
          label: 'Actualizar QR',
          icon: Icons.refresh,
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _generarQR,
        ),
        const SizedBox(height: 8),
        Text(
          'El QR expira en 60 segundos',
          style: TextStyle(fontSize: 12, color: ColmariaColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildConnectingBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ColmariaColors.chipBlueBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: ColmariaColors.chipBlueTx),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Escaneá el QR con tu WhatsApp',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ColmariaColors.chipBlueTx,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Body: Conectado ─────────────────────────────────────────────────────

  Widget _buildConnectedBody() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConexionCard(),
          const SizedBox(height: 24),
          _buildBotStatusCard(),
          const SizedBox(height: 24),
          _buildBotConfigCard(),
        ],
      ),
    );
  }

  Widget _buildConexionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColmariaColors.chipGreenBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColmariaColors.chipGreenTx, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConexionHeader(),
          const SizedBox(height: 16),
          _buildConexionInfo(),
          const SizedBox(height: 16),
          _buildConexionActions(),
        ],
      ),
    );
  }

  Widget _buildConexionHeader() {
    return Row(
      children: [
        Icon(Icons.check_circle, color: ColmariaColors.chipGreenTx, size: 24),
        const SizedBox(width: 12),
        Text(
          'WhatsApp conectado',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: ColmariaColors.chipGreenTx,
          ),
        ),
      ],
    );
  }

  Widget _buildConexionInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instancia: ${_instanceName ?? "—"}',
          style: TextStyle(fontSize: 14, color: ColmariaColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          'Conectado el: ${DateTime.now().toLocal().toString().split('.')[0]}',
          style: TextStyle(fontSize: 13, color: ColmariaColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildConexionActions() {
    return Row(
      children: [
        Expanded(
          child: BotonSecundario(
            label: 'Enviar mensaje de prueba',
            icon: Icons.send,
            onPressed: _enviarPrueba,
          ),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: _desconectar,
          style: TextButton.styleFrom(foregroundColor: ColmariaColors.error),
          child: const Text('Desconectar'),
        ),
      ],
    );
  }

  Widget _buildBotStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColmariaColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: ColmariaColors.chipGreenTx,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bot activo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ColmariaColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Última actividad: ahora',
                style: TextStyle(fontSize: 13, color: ColmariaColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBotConfigCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColmariaColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConfigTitle(),
          const SizedBox(height: 16),
          _buildBotToggle(),
          const SizedBox(height: 12),
          _buildPromptField(),
          const SizedBox(height: 16),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildConfigTitle() {
    return Text(
      'Configuración del bot',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: ColmariaColors.textPrimary,
      ),
    );
  }

  Widget _buildBotToggle() {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        _botActivo ? 'Bot activo' : 'Bot pausado',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ColmariaColors.textPrimary),
      ),
      subtitle: Text(
        _botActivo
            ? 'El agente IA responde automáticamente los mensajes'
            : 'Los mensajes entrantes se guardan sin respuesta automática',
        style: TextStyle(fontSize: 12, color: ColmariaColors.textMuted),
      ),
      value: _botActivo,
      activeColor: ColmariaColors.primary,
      onChanged: (v) => setState(() => _botActivo = v),
    );
  }

  Widget _buildPromptField() {
    return TextField(
      maxLines: 3,
      maxLength: 500,
      decoration: const InputDecoration(
        labelText: 'Prompt del bot',
        hintText: 'Instrucciones personalizadas para el agente IA...',
      ),
      onChanged: (v) => _botPrompt = v,
    );
  }

  Widget _buildSaveButton() {
    return BotonPrimario(
      label: 'Guardar cambios',
      icon: Icons.save,
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Configuración guardada'),
            backgroundColor: ColmariaColors.primary,
          ),
        );
      },
    );
  }
}
