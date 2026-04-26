import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// BotónSecundario: background #FFFFFF · border 1.5dp #16AA3A
/// text: #16AA3A · Inter Medium 15sp
/// height: 52dp · radius: 12dp · full-width
class BotonSecundario extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const BotonSecundario({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: onPressed == null ? 'Botón deshabilitado: $label' : 'Botón: $label',
      button: true,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF16AA3A),
            disabledForegroundColor: Color(0xFF16AA3A).withValues(alpha: 0.4),
            side: BorderSide(
              color: onPressed == null
                  ? Color(0xFF16AA3A).withValues(alpha: 0.4)
                  : Color(0xFF16AA3A),
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF16AA3A)),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}