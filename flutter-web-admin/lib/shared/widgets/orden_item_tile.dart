import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../shared/utils/formatters.dart';
import 'estado_chip.dart';

/// OrdenItemTile widget:
/// height: 72dp
/// Layout Row:
///   Izquierda: Column[ "#1250" (mono bold 14sp) | "Cliente de WhatsApp" (muted 12sp) ]
///   Derecha:   Column[ hora relativa (muted 12sp) | monto "RD$ 250.00" (bold 14sp) | chip estado ]
/// Divider: 1dp · color #E5E7EB · startIndent: 16dp
/// InkWell ripple: color #16AA3A · opacity 8%
class OrdenItemTile extends StatelessWidget {
  final String ordenId;
  final String clienteTelefono;
  final int timestamp;
  final double monto;
  final String estado;
  final VoidCallback? onTap;

  const OrdenItemTile({
    super.key,
    required this.ordenId,
    required this.clienteTelefono,
    required this.timestamp,
    required this.monto,
    required this.estado,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pedido ${ordenId} de ${clienteTelefono}, monto ${formatRD(monto)}, estado ${estado}. Toca para ver detalles',
      button: onTap != null,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            splashColor: const Color(0xFF16AA3A).withValues(alpha: 0.08),
            highlightColor: const Color(0xFF16AA3A).withValues(alpha: 0.08),
            child: Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Izquierda: ID y cliente
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ordenId,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatTelefono(clienteTelefono),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF687280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Derecha: hora, monto, estado
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatFechaRelativa(timestamp),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF687280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatRD(monto),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  EstadoChip(estado: estado),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: const Color(0xFF687280),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Divider
          Container(
            margin: const EdgeInsets.only(left: 16),
            height: 1,
            color: const Color(0xFFE5E7EB),
          ),
        ],
      ),
    );
  }
}