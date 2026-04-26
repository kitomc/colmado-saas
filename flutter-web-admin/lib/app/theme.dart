import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens para COLMARIA Web Admin
class ColmariaColors {
  // Primary
  static const Color primary = Color(0xFF16AA3A);
  static const Color primaryDark = Color(0xFF0F5132);

  // Background & Surface
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);

  // Semantic
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF5960B);
  static const Color info = Color(0xFF3B82F6);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textMuted = Color(0xFF687280);

  // Divider
  static const Color divider = Color(0xFFE5E7EB);

  // Chips de estado de orden
  static const Color chipYellowBg = Color(0xFFFEF3C7);
  static const Color chipYellowTx = Color(0xFFD97706);
  static const Color chipBlueBg = Color(0xFFDBEAFE);
  static const Color chipBlueTx = Color(0xFF2563EB);
  static const Color chipGreenBg = Color(0xFFDCFCE7);
  static const Color chipGreenTx = Color(0xFF16AA3A);
  static const Color chipGrayBg = Color(0xFFF1F5F9);
  static const Color chipGrayTx = Color(0xFF687280);
}

/// Tema de la app
class ColmariaTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: ColmariaColors.primary,
        onPrimary: Colors.white,
        secondary: ColmariaColors.primaryDark,
        secondaryContainer: ColmariaColors.primaryDark,
        surface: ColmariaColors.surface,
        onSurface: ColmariaColors.textPrimary,
        error: ColmariaColors.error,
      ),
      scaffoldBackgroundColor: ColmariaColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: ColmariaColors.surface,
        foregroundColor: ColmariaColors.textPrimary,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: ColmariaColors.textPrimary,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: ColmariaColors.textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: ColmariaColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: ColmariaColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: ColmariaColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: ColmariaColors.textMuted,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: ColmariaColors.textMuted,
          letterSpacing: 0.5,
        ),
        labelSmall: GoogleFonts.jetBrainsMono(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: ColmariaColors.textMuted,
        ),
      ),
      cardTheme: CardThemeData(
        color: ColmariaColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: ColmariaColors.divider),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColmariaColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ColmariaColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ColmariaColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ColmariaColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ColmariaColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColmariaColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColmariaColors.primary,
          side: BorderSide(color: ColmariaColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: ColmariaColors.divider,
        thickness: 1,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: ColmariaColors.primary,
        unselectedLabelColor: ColmariaColors.textMuted,
        indicatorColor: ColmariaColors.primary,
      ),
    );
  }
}

/// Widget helper que retorna el chip de estado según el estado de la orden
Widget estadoChip(String estado) {
  Color bgColor;
  Color textColor;
  String label;

  switch (estado) {
    case 'confirmada':
      bgColor = ColmariaColors.chipGreenBg;
      textColor = ColmariaColors.chipGreenTx;
      label = 'Confirmada';
    case 'lista_para_imprimir':
      bgColor = ColmariaColors.chipYellowBg;
      textColor = ColmariaColors.chipYellowTx;
      label = 'En cola';
    case 'imprimiendo':
      bgColor = ColmariaColors.chipBlueBg;
      textColor = ColmariaColors.chipBlueTx;
      label = 'Imprimiendo';
    case 'impresa':
    case 'entregada':
      bgColor = ColmariaColors.chipGreenBg;
      textColor = ColmariaColors.chipGreenTx;
      label = estado == 'entregada' ? 'Entregada' : 'Impresa';
    case 'cancelada':
      bgColor = ColmariaColors.chipGrayBg;
      textColor = ColmariaColors.chipGrayTx;
      label = 'Cancelada';
    default:
      bgColor = ColmariaColors.chipGrayBg;
      textColor = ColmariaColors.chipGrayTx;
      label = estado;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: textColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}