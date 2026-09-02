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
    expect(find.text('Anotações'), findsOneWidget);

    final timerText = tester.widget<Text>(timerFinder);
    expect(timerText.style?.fontSize, 14);

    final progressionDetails = find.byKey(
      const Key('progression-details-p1-0'),
    );
    await tester.ensureVisible(progressionDetails);
    await tester.tap(progressionDetails);
    await tester.pumpAndSettle();
    expect(find.text('Como foi calculado'), findsOneWidget);
    expect(find.text('Base utilizada'), findsOneWidget);
    expect(find.text('Motivo'), findsOneWidget);
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

  testWidgets('fecha editor de anotações sem descartar controller em uso', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
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

    await tester.tap(find.byKey(const Key('exercise-notes-p1-0')));
    await tester.pumpAndSettle();
    expect(find.text('Anotação deste exercício'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Anotação deste exercício'), findsNothing);
  });

  testWidgets('não conclui série vazia e mantém carga opcional', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
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

    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    expect(SessionStateCache.setsStatus[0]!.first, isFalse);
    expect(
      find.text(
        'Informe as repetições realizadas antes de concluir a série. A carga é opcional.',
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField).at(1), '10');
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    expect(SessionStateCache.weights[0]!.first, isEmpty);
    expect(SessionStateCache.setsStatus[0]!.first, isTrue);
  });

  testWidgets('atalho de anotação marca carga e salva RIR opcional', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    _NotesWorkoutController.resetCapturedValues();

    final palette = pulsePalettes[1];
    AppColors.configure(Brightness.light, primaryColor: palette.lightPrimary);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutControllerProvider.overrideWith(_NotesWorkoutController.new),
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

    await tester.tap(find.byKey(const Key('exercise-notes-p1-0')));
    await tester.pumpAndSettle();
    final shortcut = find.byKey(const Key('shortcut-different-machine'));
    await tester.ensureVisible(shortcut);
    await tester.tap(shortcut);
    await tester.pump();

    final rirField = find.byKey(const Key('perceived-rir-field'));
    await tester.ensureVisible(rirField);
    await tester.tap(rirField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('RIR 2').last);
    await tester.pumpAndSettle();

    final save = find.text('Salvar');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(_NotesWorkoutController.savedNotes, 'Usei outra máquina.');
    expect(_NotesWorkoutController.savedIsLoadComparable, isFalse);
    expect(_NotesWorkoutController.savedPerceivedRir, 2);
    expect(tester.takeException(), isNull);
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

class _NotesWorkoutController extends _FakeWorkoutController {
  static String? savedNotes;
  static bool? savedIsLoadComparable;
  static int? savedPerceivedRir;

  static void resetCapturedValues() {
    savedNotes = null;
    savedIsLoadComparable = null;
    savedPerceivedRir = null;
  }

  @override
  WorkoutState build() {
    final base = super.build();
    return base.copyWith(
      activeSession: ActiveWorkoutSession(
        id: 'active-notes',
        routineName: 'Treino A',
        startedAt: DateTime(2026, 9, 1),
        elapsedSeconds: 0,
        exercises: <ActiveWorkoutExercise>[
          ActiveWorkoutExercise(
            exercise: _FakeWorkoutController._exercise,
            sets: const <ActiveWorkoutSet>[
              ActiveWorkoutSet(setNumber: 1),
              ActiveWorkoutSet(setNumber: 2),
              ActiveWorkoutSet(setNumber: 3),
            ],
          ),
        ],
      ),
    );
  }

  @override
  ActiveWorkoutSession? get activeSession => state.activeSession;

  @override
  void updateExerciseSessionDetails(
    int exerciseIndex, {
    required String notes,
    required bool isLoadComparable,
    required int? perceivedRir,
  }) {
    savedNotes = notes;
    savedIsLoadComparable = isLoadComparable;
    savedPerceivedRir = perceivedRir;
  }
}
