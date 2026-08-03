import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/screens/how_to_use_screen.dart';
import 'package:pulse/theme/app_theme.dart';

void main() {
  testWidgets('guia rapido apresenta os principais fluxos do PULSE', (
    tester,
  ) async {
    final palette = pulsePalettes[1];
    AppColors.configure(Brightness.light, primaryColor: palette.lightPrimary);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildPulseLightTheme(palette.lightPrimary),
        home: const HowToUseScreen(),
      ),
    );

    expect(find.text('Como usar'), findsOneWidget);
    expect(find.text('1 de 7'), findsOneWidget);
    expect(find.text('Comece pela tela Hoje'), findsOneWidget);
    expect(find.text('Próximo'), findsOneWidget);

    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();

    expect(find.text('2 de 7'), findsOneWidget);
    expect(find.text('Crie, importe ou compartilhe fichas'), findsOneWidget);
    expect(find.text('Anterior'), findsOneWidget);
  });
}
