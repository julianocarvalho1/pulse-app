import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/workouts/domain/models/active_workout_session.dart';
import 'package:pulse/features/workouts/domain/models/workout_session_progress.dart';
import 'package:pulse/features/workouts/presentation/providers/workout_controller.dart';
import 'package:pulse/features/workouts/presentation/state/workout_state.dart';
import 'package:pulse/models/exercise.dart';
import 'package:pulse/screens/workout_session_screen.dart';
import 'package:pulse/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    SessionStateCache.clear();
  });

  testWidgets('cronômetro total fica compacto dentro da barra superior', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final palette = pulsePalettes[1];
    AppColors.configure(Brightness.light, primaryColor: palette.lightPrimary);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutControllerProvider.overrideWith(_FakeWorkoutController.new),
          workoutDurationProvider.overrideWith(_FixedDurationController.new),
          workoutSessionProgressProvider.overrideWithValue(
            const WorkoutSessionProgress(
              completedSets: 0,
              totalSets: 3,
              completedExercises: 0,
              totalExercises: 1,
            ),
          ),
        ],
        child: MaterialApp(
          theme: buildPulseLightTheme(palette.lightPrimary),
          home: const WorkoutSessionScreen(),
        ),
      ),
    );

    await tester.pump();

    final timerFinder = find.text('02:05');
    expect(timerFinder, findsOneWidget);
    expect(
      find.ancestor(of: timerFinder, matching: find.byType(AppBar)),
      findsOneWidget,
    );
    expect(find.text('TEMPO TOTAL'), findsNothing);

    final timerText = tester.widget<Text>(timerFinder);
    expect(timerText.style?.fontSize, 14);
  });

  testWidgets('descanso oferece pausar, continuar e pular', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final palette = pulsePalettes[1];
    AppColors.configure(Brightness.light, primaryColor: palette.lightPrimary);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutControllerProvider.overrideWith(_RestingWorkoutController.new),
          workoutDurationProvider.overrideWith(_FixedDurationController.new),
          workoutSessionProgressProvider.overrideWithValue(
            const WorkoutSessionProgress(
              completedSets: 1,
              totalSets: 3,
              completedExercises: 0,
              totalExercises: 1,
            ),
          ),
        ],
        child: MaterialApp(
          theme: buildPulseLightTheme(palette.lightPrimary),
          home: const WorkoutSessionScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('restPauseResumeButton')), findsOneWidget);
    expect(find.byKey(const Key('skipRestButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('restPauseResumeButton')));
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    await tester.tap(find.byKey(const Key('restPauseResumeButton')));
    await tester.pump();
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

    await tester.tap(find.byKey(const Key('skipRestButton')));
    await tester.pump();
    expect(find.text('DESCANSO'), findsNothing);
  });
}

class _FixedDurationController extends WorkoutDurationController {
  @override
  int build() => 125;
}

class _FakeWorkoutController extends WorkoutController {
  static const _exercise = Exercise(
    id: 'p1',
    name: 'Supino Reto com Barra',
    muscle: 'Peito',
    description: 'Exercício de teste',
    reps: '3x 10',
    rest: '60 seg',
  );

  @override
  WorkoutState build() {
    return WorkoutState(
      customExercises: const <Exercise>[],
      myRoutines: const <WorkoutRoutine>[],
      history: const [],
      preMadePrograms: const <WorkoutProgram>[],
      isInitialized: true,
      voiceAfterRest: false,
      isWorkoutActive: true,
      currentWorkoutExercises: const <Exercise>[_exercise],
      activeRoutineName: 'Treino A',
      activeProgramName: '',
      activeSession: null,
      isResting: false,
      restSeconds: 0,
      isFinishing: false,
    );
  }

  @override
  ActiveWorkoutSession? get activeSession => null;

  @override
  void saveActiveSessionProgress({
    required Map<int, List<bool>> setsStatus,
    required Map<int, List<String>> weights,
    required Map<int, List<String>> reps,
    required String notes,
  }) {}
}

class _RestingWorkoutController extends _FakeWorkoutController {
  @override
  WorkoutState build() => super.build().copyWith(
    isResting: true,
    isRestPaused: false,
    restSeconds: 60,
  );

  @override
  void pauseRestTimer() {
    state = state.copyWith(isRestPaused: true);
  }

  @override
  void resumeRestTimer() {
    state = state.copyWith(isRestPaused: false);
  }

  @override
  void stopRestTimer() {
    state = state.copyWith(
      isResting: false,
      isRestPaused: false,
      restSeconds: 0,
    );
  }
}
