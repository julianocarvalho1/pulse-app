import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppColors {
  static const Color background = Color(0xFF0F0F12);
  static const Color surface = Color(0xFF16161A);
  static const Color surfaceLight = Color(0xFF202025);
  static const Color border = Color(0xFF2A2A30);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFA0A0A5);
}

// Criamos a estrutura exata que a sua tela de perfil está procurando!
class AppPalette {
  final String name;
  final Color primary;
  const AppPalette(this.name, this.primary);
}

class ThemeProvider extends ChangeNotifier {
  // Cor padrão
  Color _primaryColor = const Color(0xFF00FF88);

  Color get primaryColor => _primaryColor;

  // Agora a lista fornece o "name" e o "primary" para o perfil não quebrar
  final List<AppPalette> palettes = const [
    AppPalette('Ciano', Color(0xFF00E5FF)),
    AppPalette('Verde Neon', Color(0xFF00E676)),
    AppPalette('Laranja', Color(0xFFFF3D00)),
    AppPalette('Amarelo', Color(0xFFFFEA00)),
    AppPalette('Vermelho', Color(0xFFFF1744)),
    AppPalette('Rosa', Color(0xFFF50057)),
    AppPalette('Roxo Cyber', Color(0xFFD500F9)),
    AppPalette('Azul Puro', Color(0xFF2979FF)),
  ];

  ThemeProvider() {
    _loadThemeColor();
  }

  ThemeData get currentTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter',

      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.dark,
        primary: _primaryColor,
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
    );
  }

  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_color', color.value);
  }

  // Função adaptada para ler a nova classe AppPalette
  void changePalette(int index) {
    if (index >= 0 && index < palettes.length) {
      setPrimaryColor(palettes[index].primary);
    }
  }

  Future<void> _loadThemeColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('theme_color');
    if (colorValue != null) {
      _primaryColor = Color(colorValue);
      notifyListeners();
    }
  }
}
