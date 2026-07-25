import 'package:flutter/material.dart';

// ============================================================
//  CORES FIXAS (Restauradas para não quebrar o resto do app!)
// ============================================================
class AppColors {
  // Cores de Fundo Padrão (Usadas pelas telas antigas)
  static const Color background = Color(0xFF0A0E0A);
  static const Color surface = Color(0xFF151A16);
  static const Color surfaceLight = Color(0xFF1D241E);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8A928B);
  static const Color border = Color(0xFF283028);

  // Cores de Destaque
  static const Color neon = Color(0xFFC5F92E);
  static const Color orange = Color(0xFFFF5A1F);
  static const Color cyan = Color(0xFF00E5FF);
  static const Color purple = Color(0xFFB026FF);
}

// ============================================================
//  ESTRUTURA DA PALETA COMPLETA
// ============================================================
class AppThemePalette {
  final String name;
  final Color primary;
  final Color background;
  final Color surface;

  AppThemePalette({
    required this.name,
    required this.primary,
    required this.background,
    required this.surface
  });
}

// ============================================================
//  GERENCIADOR DE TEMA DINÂMICO
// ============================================================
class ThemeProvider extends ChangeNotifier {
  // As 5 Paletas perfeitamente harmonizadas para o Dark Mode
  static final List<AppThemePalette> availablePalettes = [
    AppThemePalette(
      name: 'Neon Matrix',
      primary: AppColors.neon,
      background: const Color(0xFF0A0E0A), // Fundo preto esverdeado
      surface: const Color(0xFF151A16),    // Card cinza esverdeado
    ),
    AppThemePalette(
      name: 'Chama',
      primary: AppColors.orange,
      background: const Color(0xFF140A08), // Fundo preto avermelhado
      surface: const Color(0xFF1F1210),    // Card marrom escuro
    ),
    AppThemePalette(
      name: 'Oceano',
      primary: AppColors.cyan,
      background: const Color(0xFF040A14), // Fundo azul marinho profundo
      surface: const Color(0xFF0B1421),    // Card azul escuro
    ),
    AppThemePalette(
      name: 'Ametista',
      primary: AppColors.purple,
      background: const Color(0xFF0D0612), // Fundo roxo muito escuro
      surface: const Color(0xFF16101F),    // Card violeta escuro
    ),
    AppThemePalette(
      name: 'Ouro Negro',
      primary: const Color(0xFFFFD700),
      background: const Color(0xFF121212), // Fundo grafite neutro
      surface: const Color(0xFF1E1E1E),    // Card cinza clássico
    ),
  ];

  int _currentPaletteIndex = 0;

  AppThemePalette get currentPalette => availablePalettes[_currentPaletteIndex];
  Color get primaryColor => currentPalette.primary;
  List<AppThemePalette> get palettes => availablePalettes;

  ThemeData get currentTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: currentPalette.background,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.dark(
        primary: currentPalette.primary,
        surface: currentPalette.surface,
        onPrimary: Colors.black,
      ),
      highlightColor: Colors.transparent,
      splashColor: currentPalette.primary.withValues(alpha: 0.08),
    );
  }

  void changePalette(int index) {
    _currentPaletteIndex = index;
    notifyListeners();
  }
}