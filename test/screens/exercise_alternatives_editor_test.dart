import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/models/exercise.dart';
import 'package:pulse/screens/exercise_prescription_editor_screen.dart';

void main() {
  testWidgets('filtra músculo e fecha busca ativa sem erro', (tester) async {
    const current = Exercise(
      id: 'bench',
      name: 'Supino',
      muscle: 'Peito',
      description: '',
      reps: '1x 10',
      rest: '60 seg',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ExercisePrescriptionEditorScreen(
          exercise: current,
          availableExercises: [
            current,
            current.copyWith(
              id: 'machine',
              name: 'Supino máquina',
              muscle: 'Peitoral',
            ),
            current.copyWith(
              id: 'squat',
              name: 'Agachamento',
              muscle: 'Pernas',
            ),
          ],
        ),
      ),
    );
    await tester.scrollUntilVisible(find.text('Escolher'), 250);
    await tester.tap(find.text('Escolher'));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(CheckboxListTile, 'Supino máquina'),
      findsOneWidget,
    );
    expect(find.widgetWithText(CheckboxListTile, 'Agachamento'), findsNothing);
    await tester.enterText(find.byType(TextField), 'Supino');
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Supino máquina'));
    await tester.pump();
    await tester.tap(find.text('Confirmar alternativas'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(InputChip, 'Supino máquina'), findsOneWidget);
    await tester.tap(find.text('Escolher'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'teste');
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
