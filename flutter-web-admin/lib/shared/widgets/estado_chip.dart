import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// EstadoChip widget
/// - "lista_para_imprimir" → ● amarillo · bg #FEF3C7 · text #D97706 · "En cola"
/// - "imprimiendo" → ● azul ANIMADO (pulse) · bg #DBEAFE · text #2563EB · "Imprimiendo"
/// - "impresa" → ● verde · bg #DCFCE7 · text #16AA3A · "Impreso"
/// - "entregada" → ● verde · bg #DCFCE7 · text #16AA3A · "Entregado"
/// - "cancelada" → ● gris · bg #F1F5F9 · text #687280 · "Cancelado"
/// - "conectado" → ● verde · bg #DCFCE7 · text #16AA3A · "Conectado"
/// - "error" → ● rojo · bg #FEE2E2 · text #EF4444 · "Error"
/// - "inactivo" → ● gris · bg #F1F5F9 · text #687280 · "Inactivo"
class EstadoChip extends StatefulWidget {
  final String estado;

  const EstadoChip({super.key, required this.estado});

  @override
  State<EstadoChip> createState() => _EstadoChipState();
}

class _EstadoChipState extends State<EstadoChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.estado == 'imprimiendo') {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(EstadoChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.estado == 'imprimiendo' && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (widget.estado != 'imprimiendo' && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(widget.estado);
    final isAnimating = widget.estado == 'imprimiendo';

    return Semantics(
      label: 'Estado: ${config.label}',
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return AnimatedOpacity(
            opacity: isAnimating ? _animation.value : 1.0,
            duration: Duration.zero,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: config.bgColor,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: config.dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    config.label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: config.textColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  _ChipConfig _getConfig(String estado) {
    switch (estado) {
      case 'lista_para_imprimir':
        return _ChipConfig(
          bgColor: const Color(0xFFFEF3C7),
          textColor: const Color(0xFFD97706),
          dotColor: const Color(0xFFD97706),
          label: 'En cola',
        );
      case 'imprimiendo':
        return _ChipConfig(
          bgColor: const Color(0xFFDBEAFE),
          textColor: const Color(0xFF2563EB),
          dotColor: const Color(0xFF2563EB),
          label: 'Imprimiendo',
        );
      case 'impresa':
        return _ChipConfig(
          bgColor: const Color(0xFFDCFCE7),
          textColor: const Color(0xFF16AA3A),
          dotColor: const Color(0xFF16AA3A),
          label: 'Impreso',
        );
      case 'entregada':
        return _ChipConfig(
          bgColor: const Color(0xFFDCFCE7),
          textColor: const Color(0xFF16AA3A),
          dotColor: const Color(0xFF16AA3A),
          label: 'Entregado',
        );
      case 'cancelada':
        return _ChipConfig(
          bgColor: const Color(0xFFF1F5F9),
          textColor: const Color(0xFF687280),
          dotColor: const Color(0xFF687280),
          label: 'Cancelado',
        );
      case 'conectado':
        return _ChipConfig(
          bgColor: const Color(0xFFDCFCE7),
          textColor: const Color(0xFF16AA3A),
          dotColor: const Color(0xFF16AA3A),
          label: 'Conectado',
        );
      case 'error':
        return _ChipConfig(
          bgColor: const Color(0xFFFEE2E2),
          textColor: const Color(0xFFEF4444),
          dotColor: const Color(0xFFEF4444),
          label: 'Error',
        );
      case 'inactivo':
        return _ChipConfig(
          bgColor: const Color(0xFFF1F5F9),
          textColor: const Color(0xFF687280),
          dotColor: const Color(0xFF687280),
          label: 'Inactivo',
        );
      case 'confirmada':
        return _ChipConfig(
          bgColor: const Color(0xFFDCFCE7),
          textColor: const Color(0xFF16AA3A),
          dotColor: const Color(0xFF16AA3A),
          label: 'Confirmado',
        );
      default:
        return _ChipConfig(
          bgColor: const Color(0xFFF1F5F9),
          textColor: const Color(0xFF687280),
          dotColor: const Color(0xFF687280),
          label: estado,
        );
    }
  }
}

class _ChipConfig {
  final Color bgColor;
  final Color textColor;
  final Color dotColor;
  final String label;

  _ChipConfig({
    required this.bgColor,
    required this.textColor,
    required this.dotColor,
    required this.label,
  });
}