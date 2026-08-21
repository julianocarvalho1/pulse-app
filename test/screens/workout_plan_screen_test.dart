import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/workouts/presentation/providers/workout_controller.dart';
import 'package:pulse/features/workouts/presentation/state/workout_state.dart';
import 'package:pulse/models/exercise.dart';
import 'package:pulse/screens/workout_plan_screen.dart';
import 'package:pulse/theme/app_theme.dart';

void main() {
  testWidgets('ficha só é excluída depois da confirmação', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final palette = pulsePalettes.first;
    AppColors.configure(Brightness.light, primaryColor: palette.lightPrimary);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutControllerProvider.overrideWith(_FakeWorkoutController.new),
        ],
        child: MaterialApp(
          theme: buildPulseLightTheme(palette.lightPrimary),
          home: const WorkoutPlanScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final routines = find.byKey(const Key('routine-test'));
    final routine = routines.hitTestable().first;

    await tester.drag(routine, const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.text('Excluir esta ficha?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(routines, findsWidgets);

    await tester.drag(routine, const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDeleteRoutineButton')));
    await tester.pumpAndSettle();

    expect(routines, findsNothing);
    expect(find.text('Ficha temporária foi apagada.'), findsOneWidget);
  });
}

class _FakeWorkoutController extends WorkoutController {
  @override
  WorkoutState build() =>
      WorkoutState.initial(preMadePrograms: const <WorkoutProgram>[]).copyWith(
        isInitialized: true,
        myRoutines: <WorkoutRoutine>[
          WorkoutRoutine(
            id: 'routine-test',
            name: 'Ficha temporária',
            focus: 'Teste',
            exercises: const <Exercise>[],
          ),
        ],
      );

  @override
  void deleteRoutine(String id) {
    state = state.copyWith(
      myRoutines: state.myRoutines.where((item) => item.id != id).toList(),
    );
  }
}
