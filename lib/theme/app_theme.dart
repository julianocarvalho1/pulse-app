import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _PulseColorSet {
  const _PulseColorSet({
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  final Color background;
  final Color surface;
  final Color surfaceLight;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
}

/// Cores semânticas usadas pelas telas legadas do PULSE.
///
/// O projeto ainda possui componentes que consultam [AppColors] diretamente.
/// Esta ponte mantém esses componentes sincronizados com o tema claro/escuro
/// enquanto a migração para `ColorScheme` acontece de forma gradual.
class AppColors {
  AppColors._();

  /// Grafite escuro, sem usar preto quase absoluto. Mantém contraste e
  /// reduz a sensação de tela excessivamente fechada durante o treino.
  static const _PulseColorSet _dark = _PulseColorSet(
    background: Color(0xFF17191D),
    surface: Color(0xFF202329),
    surfaceLight: Color(0xFF2A2E35),
    border: Color(0xFF3A4049),
    textPrimary: Color(0xFFF5F7FA),
    textSecondary: Color(0xFFB8C0CB),
    textMuted: Color(0xFF8C96A3),
  );

  /// Neutros frios e menos contrastados para evitar o aspecto estourado no
  /// tema claro. O texto principal continua acessível, mas deixa de ser preto.
  static const _PulseColorSet _light = _PulseColorSet(
    background: Color(0xFFF2F5F7),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFE9EEF2),
    border: Color(0xFFD6DEE5),
    textPrimary: Color(0xFF26323F),
    textSecondary: Color(0xFF687483),
    textMuted: Color(0xFF8A95A3),
  );

  static _PulseColorSet _current = _dark;
  static Color _primary = const Color(0xFF00E676);
  static Color _onPrimary = Colors.black;
  static Color _primarySoft = const Color(0xFF173A29);
  static Color _primaryBorder = const Color(0xFF245D3D);

  static void configure(Brightness brightness, {required Color primaryColor}) {
    _current = brightness == Brightness.light ? _light : _dark;
    _primary = primaryColor;
    _onPrimary = _foregroundFor(primaryColor, brightness);
    _primarySoft = Color.alphaBlend(
      primaryColor.withValues(
        alpha: brightness == Brightness.light ? 0.11 : 0.16,
      ),
      _current.surface,
    );
    _primaryBorder = Color.alphaBlend(
      primaryColor.withValues(
        alpha: brightness == Brightness.light ? 0.30 : 0.38,
      ),
      _current.border,
    );
  }

  static Color _foregroundFor(Color color, Brightness brightness) {
    if (brightness == Brightness.light) {
      return Colors.white;
    }

    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  static Color get background => _current.background;
  static Color get surface => _current.surface;
  static Color get surfaceLight => _current.surfaceLight;
  static Color get border => _current.border;
  static Color get textPrimary => _current.textPrimary;
  static Color get textSecondary => _current.textSecondary;
  static Color get textMuted => _current.textMuted;
  static Color get primary => _primary;
  static Color get onPrimary => _onPrimary;
  static Color get primarySoft => _primarySoft;
  static Color get primaryBorder => _primaryBorder;

  static Color get success =>
      _current == _light ? const Color(0xFF12805C) : const Color(0xFF35D39A);
  static Color get warning =>
      _current == _light ? const Color(0xFFB45309) : const Color(0xFFFFB454);
  static Color get danger =>
      _current == _light ? const Color(0xFFC2414B) : const Color(0xFFFF6675);
  static Color get info =>
      _current == _light ? const Color(0xFF2563B8) : const Color(0xFF66A8FF);
}

class AppPalette {
  const AppPalette(
    this.name, {
    required this.darkPrimary,
    required this.lightPrimary,
  });

  final String name;
  final Color darkPrimary;
  final Color lightPrimary;

  /// O valor neon continua sendo salvo para preservar as preferências antigas.
  Color get storageColor => darkPrimary;

  int get storageValue => storageColor.toARGB32();

  Color colorFor(Brightness brightness) {
    return brightness == Brightness.light ? lightPrimary : darkPrimary;
  }

  bool matches(int value) {
    return value == darkPrimary.toARGB32() || value == lightPrimary.toARGB32();
  }
}

const List<AppPalette> pulsePalettes = [
  AppPalette(
    'Ciano',
    darkPrimary: Color(0xFF00E5FF),
    lightPrimary: Color(0xFF087F99),
  ),
  AppPalette(
    'Verde',
    darkPrimary: Color(0xFF00E676),
    lightPrimary: Color(0xFF087A57),
  ),
  AppPalette(
    'Laranja',
    darkPrimary: Color(0xFFFF3D00),
    lightPrimary: Color(0xFFC34D12),
  ),
  AppPalette(
    'Dourado',
    darkPrimary: Color(0xFFFFEA00),
    lightPrimary: Color(0xFF8A6508),
  ),
  AppPalette(
    'Vermelho',
    darkPrimary: Color(0xFFFF1744),
    lightPrimary: Color(0xFFB93646),
  ),
  AppPalette(
    'Rosa',
    darkPrimary: Color(0xFFF50057),
    lightPrimary: Color(0xFFA83266),
  ),
  AppPalette(
    'Roxo',
    darkPrimary: Color(0xFFD500F9),
    lightPrimary: Color(0xFF7046B8),
  ),
  AppPalette(
    'Azul',
    darkPrimary: Color(0xFF2979FF),
    lightPrimary: Color(0xFF3567B7),
  ),
];

AppPalette pulsePaletteForValue(int value) {
  return pulsePalettes.firstWhere(
    (palette) => palette.matches(value),
    orElse: () => pulsePalettes[1],
  );
}

ThemeData buildPulseLightTheme(Color primaryColor) {
  return _buildPulseTheme(
    primaryColor: primaryColor,
    brightness: Brightness.light,
  );
}

ThemeData buildPulseDarkTheme(Color primaryColor) {
  return _buildPulseTheme(
    primaryColor: primaryColor,
    brightness: Brightness.dark,
  );
}

ThemeData _buildPulseTheme({
  required Color primaryColor,
  required Brightness brightness,
}) {
  final isDark = brightness == Brightness.dark;
  final colors = isDark ? AppColors._dark : AppColors._light;
  final onPrimary = isDark
      ? (ThemeData.estimateBrightnessForColor(primaryColor) == Brightness.dark
            ? Colors.white
            : Colors.black)
      : Colors.white;
  final primaryContainer = Color.alphaBlend(
    primaryColor.withValues(alpha: isDark ? 0.16 : 0.11),
    colors.surface,
  );
  final primaryContainerBorder = Color.alphaBlend(
    primaryColor.withValues(alpha: isDark ? 0.36 : 0.28),
    colors.border,
  );

  final colorScheme = ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: brightness,
    primary: primaryColor,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: primaryColor,
    surface: colors.surface,
    onSurface: colors.textPrimary,
    surfaceContainerHighest: colors.surfaceLight,
    onSurfaceVariant: colors.textSecondary,
    outline: colors.border,
    outlineVariant: colors.border,
    error: isDark ? const Color(0xFFFF6675) : const Color(0xFFC2414B),
  );

  final baseTheme = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'Inter',
    colorScheme: colorScheme,
  );

  final textTheme = baseTheme.textTheme
      .apply(bodyColor: colors.textPrimary, displayColor: colors.textPrimary)
      .copyWith(
        headlineLarge: baseTheme.textTheme.headlineLarge?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: baseTheme.textTheme.headlineMedium?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: baseTheme.textTheme.headlineSmall?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: baseTheme.textTheme.titleLarge?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: baseTheme.textTheme.titleMedium?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: baseTheme.textTheme.titleSmall?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
          color: colors.textPrimary,
          height: 1.35,
        ),
        bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
          color: colors.textPrimary,
          height: 1.35,
        ),
        bodySmall: baseTheme.textTheme.bodySmall?.copyWith(
          color: colors.textSecondary,
          height: 1.3,
        ),
        labelLarge: baseTheme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        labelMedium: baseTheme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      );

  final primaryButtonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  );

  return baseTheme.copyWith(
    scaffoldBackgroundColor: colors.background,
    textTheme: textTheme,
    dividerColor: colors.border,
    disabledColor: colors.textMuted.withValues(alpha: 0.55),
    iconTheme: IconThemeData(color: colors.textSecondary),
    appBarTheme: AppBarTheme(
      backgroundColor: colors.background,
      foregroundColor: colors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: colors.textPrimary),
      actionsIconTheme: IconThemeData(color: colors.textSecondary),
      titleTextStyle: TextStyle(
        color: colors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      elevation: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: colors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: TextStyle(color: colors.textSecondary, height: 1.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surface,
      modalBackgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: colors.border,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      labelStyle: TextStyle(color: colors.textSecondary),
      hintStyle: TextStyle(color: colors.textMuted),
      prefixIconColor: colors.textSecondary,
      suffixIconColor: colors.textSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primaryColor, width: 1.6),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: colors.textSecondary,
      textColor: colors.textPrimary,
      titleTextStyle: TextStyle(
        color: colors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      subtitleTextStyle: TextStyle(
        color: colors.textSecondary,
        fontSize: 12,
        height: 1.35,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: onPrimary,
        disabledBackgroundColor: colors.surfaceLight,
        disabledForegroundColor: colors.textMuted,
        minimumSize: const Size(0, 48),
        elevation: 0,
        shape: primaryButtonShape,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: onPrimary,
        disabledBackgroundColor: colors.surfaceLight,
        disabledForegroundColor: colors.textMuted,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: primaryButtonShape,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryContainerBorder),
        shape: primaryButtonShape,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: onPrimary,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return colors.surface;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return onPrimary;
          }
          return colors.textSecondary;
        }),
        side: WidgetStatePropertyAll(BorderSide(color: colors.border)),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colors.surface,
      selectedItemColor: primaryColor,
      unselectedItemColor: colors.textMuted,
      selectedLabelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colors.surface,
      indicatorColor: primaryContainer,
      elevation: 0,
      height: 68,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: primaryColor, size: 24);
        }
        return IconThemeData(color: colors.textMuted, size: 23);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            color: primaryColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          );
        }
        return TextStyle(
          color: colors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        );
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark ? colors.surfaceLight : const Color(0xFF2E3742),
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return onPrimary;
        }
        return colors.textMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return colors.surfaceLight;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return colors.border;
      }),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: primaryColor),
  );
}

SystemUiOverlayStyle pulseSystemUiOverlayStyle(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarColor: AppColors.surface,
    systemNavigationBarDividerColor: AppColors.border,
    systemNavigationBarIconBrightness: isDark
        ? Brightness.light
        : Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );
}
