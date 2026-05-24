import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// ===============================
/// COLORS
/// ===============================
class AppColors {
  static const Color bg = Color(0xFF0B1018);
  static const Color bgSoft = Color(0xFF0F1622);
  static const Color panel = Color(0xFF131C2B);
  static const Color panel2 = Color(0xFF172234);
  static const Color line = Color(0xFF223149);

  static const Color accent = Color(0xFF2E75B6);
  static const Color accentBright = Color(0xFF4F9FE0);

  static const Color text = Color(0xFFE8EDF5);
  static const Color textDim = Color(0xFF9AA9BF);
  static const Color textFaint = Color(0xFF637186);

  static const Color green = Color(0xFF4CAF7D);
  static const Color red = Color(0xFFE06C5B);
  static const Color amber = Color(0xFFE0B44F);
}

/// ===============================
/// THEME
/// ===============================
class AppTheme {
  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
    ).copyWith(
      surface: AppColors.panel,
      error: AppColors.red,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      primaryColor: AppColors.accent,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',

      /// APP BAR
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgSoft,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),

      /// CARDS
      cardTheme: CardThemeData(
        color: AppColors.panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: AppColors.line),
        ),
      ),

      /// INPUTS
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        hintStyle: const TextStyle(color: AppColors.textFaint),
        labelStyle: const TextStyle(color: AppColors.textDim),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.accent,
            width: 1.6,
          ),
        ),
      ),

      /// BUTTONS
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

/// ===============================
/// FORMATTERS
/// ===============================
final _euroFormat = NumberFormat.currency(
  locale: 'es_ES',
  symbol: '€',
);

String formatEuro(double value) {
  return _euroFormat.format(value);
}