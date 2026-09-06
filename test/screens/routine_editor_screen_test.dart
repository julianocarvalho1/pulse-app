import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/models/exercise.dart';
import 'package:pulse/screens/routine_editor_screen.dart';

void main() {
  testWidgets('oferece cardio e preserva musculação ao mudar o tipo', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: RoutineEditorScreen(
            routine: WorkoutRoutine(
              id: 'test',
              name: 'Ficha teste',
              focus: 'Peito',
              exercises: const [
                Exercise(
                  id: 'bench',
                  name: 'Supino teste',
                  muscle: 'Peito',
                  description: '',
                  reps: '3x 10',
                  rest: '60 seg',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('ADICIONAR CARDIO'), findsNothing);
    await tester.ensureVisible(find.text('Cardio'));
    await tester.tap(find.text('Cardio'));
    await tester.pumpAndSettle();
    expect(find.text('Remover musculação?'), findsNothing);
    await tester.tap(
      find.byKey(const Key('cardio-template-editable_intervals')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('save-cardio-plan')));
    await tester.tap(find.byKey(const Key('save-cardio-plan')));
    await tester.pumpAndSettle();
    expect(find.text('Esteira'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Supino teste'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Supino teste'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
