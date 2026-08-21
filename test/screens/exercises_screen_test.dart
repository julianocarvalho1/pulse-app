import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/workouts/presentation/providers/workout_controller.dart';
import 'package:pulse/features/workouts/presentation/state/workout_state.dart';
import 'package:pulse/models/exercise.dart';
import 'package:pulse/screens/exercises_screen.dart';
import 'package:pulse/theme/app_theme.dart';

void main() {
  testWidgets('cria exercício personalizado diretamente pela biblioteca', (
    tester,
  ) async {
    final palette = pulsePalettes.first;
    AppColors.configure(Brightness.light, primaryColor: palette.lightPrimary);
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutControllerProvider.overrideWith(_FakeWorkoutController.new),
        ],
        child: MaterialApp(
          theme: buildPulseLightTheme(palette.lightPrimary),
          home: const ExercisesScreen(),
        ),
      ),
    );

    expect(find.byKey(const Key('createCustomExerciseButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('createCustomExerciseButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('customExerciseNameField')),
      'Remada no aparelho azul',
    );
    await tester.tap(find.byKey(const Key('saveCustomExerciseButton')));
    await tester.pumpAndSettle();

    expect(find.text('Personalizados'), findsOneWidget);
    expect(find.text('Remada no aparelho azul'), findsOneWidget);
    expect(find.textContaining('foi salvo na sua biblioteca'), findsOneWidget);
  });
}

class _FakeWorkoutController extends WorkoutController {
  @override
  WorkoutState build() => WorkoutState.initial(
    preMadePrograms: const <WorkoutProgram>[],
  ).copyWith(isInitialized: true);

  @override
  Exercise createCustomExercise(
    String name,
    String muscle, {
    String description = 'Exercício personalizado.',
    String reps = '3x 10-12',
    String rest = '60 seg',
  }) {
    final exercise = Exercise(
      id: 'custom_test',
      name: name.trim(),
      muscle: muscle,
      description: description.trim().isEmpty
          ? 'Exercício personalizado.'
          : description.trim(),
      reps: reps,
      rest: rest,
    );
    state = state.copyWith(
      customExercises: <Exercise>[...state.customExercises, exercise],
    );
    return exercise;
  }
}
