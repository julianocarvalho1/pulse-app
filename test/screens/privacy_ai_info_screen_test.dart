import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/screens/privacy_ai_info_screen.dart';
import 'package:pulse/theme/app_theme.dart';

void main() {
  testWidgets('tela de privacidade explica dados locais e assistencia online', (
    tester,
  ) async {
    final palette = pulsePalettes[1];
    AppColors.configure(Brightness.light, primaryColor: palette.lightPrimary);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildPulseLightTheme(palette.lightPrimary),
        home: const PrivacyAiInfoScreen(),
      ),
    );

    expect(find.text('Privacidade e assistência'), findsOneWidget);
    expect(find.text('Dados armazenados no aparelho'), findsOneWidget);
    expect(find.text('Como o Assistente PULSE funciona'), findsOneWidget);
    expect(find.text('Resposta local de reserva'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Suporte ou relatar resposta'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Suporte ou relatar resposta'), findsOneWidget);
    expect(find.text('Contato: pulse.appp@gmail.com'), findsOneWidget);
  });
}
