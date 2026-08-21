import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/onboarding/domain/onboarding_profile.dart';
import 'package:pulse/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:pulse/theme/app_theme.dart';

void main() {
  Future<void> pumpOnboarding(
    WidgetTester tester, {
    required bool isEditing,
  }) async {
    final palette = pulsePalettes[1];
    AppColors.configure(Brightness.light, primaryColor: palette.lightPrimary);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildPulseLightTheme(palette.lightPrimary),
          home: OnboardingScreen(
            initialProfile: OnboardingProfile.defaults(),
            isEditing: isEditing,
          ),
        ),
      ),
    );
  }

  testWidgets('novo onboarding começa em uma jornada de três etapas', (
    tester,
  ) async {
    await pumpOnboarding(tester, isEditing: false);

    expect(find.text('CONFIGURE SEU PULSE'), findsOneWidget);
    expect(find.text('Etapa 1 de 3'), findsOneWidget);
    expect(find.text('Seu ponto de partida'), findsOneWidget);
    expect(find.text('CONTINUAR'), findsOneWidget);
  });

  testWidgets('edição percorre ambiente e preferências em três etapas', (
    tester,
  ) async {
    await pumpOnboarding(tester, isEditing: true);

    await tester.enterText(find.byType(TextField).first, 'Atleta teste');
    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();

    expect(find.text('Etapa 2 de 3'), findsOneWidget);
    expect(find.text('Onde você treina?'), findsOneWidget);

    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();

    expect(find.text('Etapa 3 de 3'), findsOneWidget);
    expect(find.text('Preferências e cuidados'), findsOneWidget);
    expect(find.text('SALVAR'), findsOneWidget);
  });
}
