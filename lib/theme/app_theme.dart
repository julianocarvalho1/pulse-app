import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0F0F12);
  static const Color surface = Color(0xFF16161A);
  static const Color surfaceLight = Color(0xFF202025);
  static const Color border = Color(0xFF2A2A30);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFA0A0A5);
}

class AppPalette {
  const AppPalette(this.name, this.primary);

  final String name;
  final Color primary;
}

const List<AppPalette> pulsePalettes = [
  AppPalette('Ciano', Color(0xFF00E5FF)),
  AppPalette('Verde Neon', Color(0xFF00E676)),
  AppPalette('Laranja', Color(0xFFFF3D00)),
  AppPalette('Amarelo', Color(0xFFFFEA00)),
  AppPalette('Vermelho', Color(0xFFFF1744)),
  AppPalette('Rosa', Color(0xFFF50057)),
  AppPalette('Roxo Cyber', Color(0xFFD500F9)),
  AppPalette('Azul Puro', Color(0xFF2979FF)),
];

ThemeData buildPulseTheme(Color primaryColor) {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Inter',
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor,
      surface: AppColors.surface,
      onPrimary: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
    ),
  );
}
