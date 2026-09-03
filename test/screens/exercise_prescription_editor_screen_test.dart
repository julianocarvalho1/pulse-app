import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/models/exercise.dart';
import 'package:pulse/screens/exercise_prescription_editor_screen.dart';
import 'package:pulse/theme/app_theme.dart';

void main() {
  testWidgets('permite trocar o alvo da série de repetições para tempo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final palette = pulsePalettes.first;
    AppColors.configure(Brightness.light, primaryColor: palette.lightPrimary);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildPulseLightTheme(palette.lightPrimary),
        home: const ExercisePrescriptionEditorScreen(
          exercise: Exercise(
            id: 'test',
            name: 'Exercício teste',
            muscle: 'Abdômen',
            description: '',
            reps: '1x 10',
            rest: '60 seg',
          ),
          availableExercises: <Exercise>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('10').first);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('set-target-type-selector')), findsOneWidget);
    expect(find.byKey(const Key('set-kind-selector')), findsOneWidget);
    await tester.tap(find.text('Aquecimento'));
    await tester.pump();
    await tester.tap(find.text('Tempo'));
    await tester.pump();
    expect(find.text('30 seg'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('30 seg'), findsWidgets);
    expect(find.textContaining('Aquecimento'), findsWidgets);
  });
}
