import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/theme/app_theme.dart';

void main() {
  test('cada paleta possui variantes distintas para claro e escuro', () {
    for (final palette in pulsePalettes) {
      expect(palette.lightPrimary, isNot(palette.darkPrimary));
      expect(palette.matches(palette.storageValue), isTrue);
    }
  });

  test('preferencias antigas continuam resolvendo a paleta correta', () {
    for (final palette in pulsePalettes) {
      expect(pulsePaletteForValue(palette.darkPrimary.toARGB32()), palette);
      expect(pulsePaletteForValue(palette.lightPrimary.toARGB32()), palette);
    }
  });

  test('tema escuro usa grafite mais suave em vez de preto quase absoluto', () {
    final palette = pulsePalettes[1];
    final theme = buildPulseDarkTheme(palette.darkPrimary);

    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, const Color(0xFF17191D));
    expect(theme.cardTheme.color, const Color(0xFF202329));
  });

  test('tema claro usa cor moderada e texto branco nas acoes principais', () {
    final palette = pulsePalettes.first;
    final theme = buildPulseLightTheme(palette.lightPrimary);

    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, palette.lightPrimary);
    expect(theme.colorScheme.onPrimary, Colors.white);
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF2F5F7));
  });
}
