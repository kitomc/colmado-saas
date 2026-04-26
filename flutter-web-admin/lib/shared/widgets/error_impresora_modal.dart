import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'boton_primario.dart';
import 'boton_secundario.dart';

/// ErrorImpresoraModal:
/// showModalBottomSheet (no ruta nueva) con:
///   handle bar arriba
///   Icono impresora grande con badge rojo ❌
///   Título: "No se puede imprimir el pedido #XXXX"
///   Sección "Posibles causas":
///     • Impresora apagada
///     • Sin papel
///     • Fuera de alcance
///     • Error de conexión
///   BotónPrimario "Reintentar"
///   BotónSecundario "Ver ayuda"
class ErrorImpresoraModal extends StatelessWidget {
  final String ordenId;
  final VoidCallback? onReintentar;
  final VoidCallback? onVerAyuda;

  const ErrorImpresoraModal({
    super.key,
    required this.ordenId,
    this.onReintentar,
    this.onVerAyuda,
  });

  /// Muestra el modal. Llamar con:
  /// showModalBottomSheet(
  ///   context: context,
  ///   isScrollControlled: true,
  ///   backgroundColor: Colors.transparent,
  ///   builder: (context) => ErrorImpresoraModal(
  ///     ordenId: '#1250',
  ///     onReintentar: () => print('reintentar'),
  ///     onVerAyuda: () => print('ayuda'),
  ///   ),
  /// );
  static Future<void> show({
    required BuildContext context,
    required String ordenId,
    VoidCallback? onReintentar,
    VoidCallback? onVerAyuda,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ErrorImpresoraModal(
        ordenId: ordenId,
        onReintentar: onReintentar,
        onVerAyuda: onVerAyuda,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              // Icono impresora con badge rojo
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.print,
                      size: 40,
                      color: Color(0xFFEF4444),
                      semanticLabel: 'Error de impresora',
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Título
              Text(
                'No se puede imprimir el pedido $ordenId',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A2E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Posibles causas
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Posibles causas:',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCausaItem('Impresora apagada'),
                    _buildCausaItem('Sin papel'),
                    _buildCausaItem('Fuera de alcance'),
                    _buildCausaItem('Error de conexión'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Botones
              BotonPrimario(
                label: 'Reintentar',
                onPressed: () {
                  Navigator.pop(context);
                  onReintentar?.call();
                },
              ),
              const SizedBox(height: 12),
              BotonSecundario(
                label: 'Ver ayuda',
                onPressed: () {
                  Navigator.pop(context);
                  onVerAyuda?.call();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCausaItem(String causa) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.circle,
            size: 6,
            color: Color(0xFF687280),
          ),
          const SizedBox(width: 12),
          Text(
            causa,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF687280),
            ),
          ),
        ],
      ),
    );
  }
}