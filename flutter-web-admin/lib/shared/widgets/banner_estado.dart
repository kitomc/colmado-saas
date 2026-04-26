import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'boton_primario.dart';

/// Estado de conexión
enum ConexionEstado {
  conectado,
  reconectando,
  sinConexion,
}

/// BannerEstado widget — 3 estados:
///
/// CONECTADO:
///   bg: #DCFCE7 · icono ✅ · text #16AA3A SemiBold
///   "Todo listo · Los pedidos de la IA se imprimirán automáticamente"
///
/// RECONECTANDO (estado intermedio, NO es error crítico):
///   bg: #FEF3C7 · icono ⚠️ · text #D97706 SemiBold
///   Row: "Reconectando..." + CircularProgressIndicator pequeño amarillo
///
/// SIN CONEXIÓN (fallo 3 veces consecutivas — estado crítico):
///   bg: #FEE2E2 · icono 🔴 · text #EF4444 SemiBold
///   "Sin conexión · Verifica tu internet"
///   BotónPrimario "Reintentar ahora" debajo
///   ADEMÁS: AppBar cambia su color a #EF4444
class BannerEstado extends StatelessWidget {
  final ConexionEstado estado;
  final VoidCallback? onReintentar;

  const BannerEstado({
    super.key,
    required this.estado,
    this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Estado de conexión: ${_getSemanticsLabel()}',
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildBanner(),
      ),
    );
  }

  String _getSemanticsLabel() {
    switch (estado) {
      case ConexionEstado.conectado:
        return 'Conectado. Todo listo para imprimir pedidos automáticamente.';
      case ConexionEstado.reconectando:
        return 'Reconectando. La conexión se está restaurando.';
      case ConexionEstado.sinConexion:
        return 'Sin conexión. Toca para reintentar.';
    }
  }

  Widget _buildBanner() {
    switch (estado) {
      case ConexionEstado.conectado:
        return _buildConectado();
      case ConexionEstado.reconectando:
        return _buildReconectando();
      case ConexionEstado.sinConexion:
        return _buildSinConexion();
    }
  }

  Widget _buildConectado() {
    return Container(
      key: const ValueKey('conectado'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF16AA3A),
            size: 20,
            semanticLabel: 'Conectado',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Todo listo · Los pedidos de la IA se imprimirán automáticamente',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF16AA3A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReconectando() {
    return Container(
      key: const ValueKey('reconectando'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber,
            color: Color(0xFFD97706),
            size: 20,
            semanticLabel: 'Reconectando',
          ),
          const SizedBox(width: 12),
          Text(
            'Reconectando...',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFD97706),
            ),
          ),
          const SizedBox(width: 12),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD97706)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinConexion() {
    return Container(
      key: const ValueKey('sinConexion'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error,
                color: Color(0xFFEF4444),
                size: 20,
                semanticLabel: 'Error de conexión',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sin conexión · Verifica tu internet',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          if (onReintentar != null) ...[
            const SizedBox(height: 12),
            BotonPrimario(
              label: 'Reintentar ahora',
              onPressed: onReintentar,
            ),
          ],
        ],
      ),
    );
  }
}