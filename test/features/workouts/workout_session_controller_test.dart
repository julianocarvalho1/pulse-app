import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/workouts/data/services/workout_feedback_service.dart';
import 'package:pulse/features/workouts/domain/models/active_workout_session.dart';
import 'package:pulse/features/workouts/domain/models/advanced_workout_prescription.dart';
import 'package:pulse/features/workouts/domain/models/cardio_log.dart';
import 'package:pulse/features/workouts/domain/models/exercise_log.dart';
import 'package:pulse/features/workouts/domain/models/workout_history_item.dart';
import 'package:pulse/features/workouts/domain/models/workout_set.dart';
import 'package:pulse/features/workouts/domain/repositories/workout_repository.dart';
import 'package:pulse/features/workouts/presentation/providers/workout_controller.dart';
import 'package:pulse/models/exercise.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const firstExercise = Exercise(
    id: 'exercise-1',
    name: 'Supino',
    muscle: 'Peito',
    description: '',
    reps: '3x 8-10',
    rest: '60 seg',
    isSuperset: true,
  );

  const secondExercise = Exercise(
    id: 'exercise-2',
    name: 'Remada',
    muscle: 'Costas',
    description: '',
    reps: '3x 8-10',
    rest: '75 seg',
  );

  final routineA = WorkoutRoutine(
    id: 'routine-a',
    name: 'Treino A',
    focus: 'Superiores',
    exercises: const <Exercise>[firstExercise, secondExercise],
  );

  final routineB = WorkoutRoutine(
    id: 'routine-b',
    name: 'Treino B',
    focus: 'Superiores',
    exercises: const <Exercise>[secondExercise],
  );

  final routineWithCardio = WorkoutRoutine(
    id: 'routine-cardio',
    name: 'Treino com cardio',
    focus: 'Condicionamento',
    exercises: const <Exercise>[secondExercise],
    cardio: const <RoutineCardio>[
      RoutineCardio(
        id: 'cardio-1',
        modality: CardioModality.stationaryBike,
        plannedDurationMinutes: 20,
      ),
    ],
  );

  final timedRoutine = WorkoutRoutine(
    id: 'routine-timed',
    name: 'Core por tempo',
    focus: 'Core',
    exercises: const <Exercise>[
      Exercise(
        id: 'plank',
        name: 'Prancha',
        muscle: 'Abdômen',
        description: '',
        reps: '2x 30 seg',
        rest: '45 seg',
      ),
    ],
  );

  final routineWithWarmUp = WorkoutRoutine(
    id: 'routine-warm-up',
    name: 'Treino com aquecimento',
    focus: 'Peito',
    exercises: const <Exercise>[
      Exercise(
        id: 'supino-warm-up',
        name: 'Supino',
        muscle: 'Peito',
        description: '',
        reps: '2x 8-10',
        rest: '60 seg',
        advancedPrescription: AdvancedExercisePrescription(
          weeks: <WorkoutWeekPrescription>[
            WorkoutWeekPrescription(
              weekNumber: 1,
              sets: <WorkoutSetPrescription>[
                WorkoutSetPrescription(
                  setNumber: 1,
                  kind: WorkoutSetKind.warmUp,
                  target: '12 reps',
                  restSeconds: 30,
                ),
                WorkoutSetPrescription(
                  setNumber: 2,
                  target: '8-10 reps',
                  restSeconds: 90,
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'settings_voice_after_rest': false,
    });
  });

  test('não substitui sessão ativa sem confirmação explícita', () async {
    final repository = _SessionFakeRepository(
      routines: <WorkoutRoutine>[routineA, routineB],
    );
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    final controller = container.read(workoutControllerProvider.notifier);
    await controller.initialization;

    expect(controller.startRoutine(routineA), isTrue);
    final originalStartedAt = controller.activeSession!.startedAt;

    expect(controller.startRoutine(routineB), isFalse);
    expect(controller.activeRoutineName, routineA.name);
    expect(controller.activeSession!.startedAt, originalStartedAt);

    expect(controller.startRoutine(routineB, replaceActive: true), isTrue);
    expect(controller.activeRoutineName, routineB.name);
  });

  test('inicia, pausa, continua e conclui uma série por tempo', () async {
    final repository = _SessionFakeRepository(
      routines: <WorkoutRoutine>[timedRoutine],
    );
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    final controller = container.read(workoutControllerProvider.notifier);
    await controller.initialization;
    expect(controller.startRoutine(timedRoutine), isTrue);

    var timedSet = controller.activeSession!.exercises.single.sets.first;
    expect(timedSet.targetType, WorkoutSetTargetType.duration);
    expect(timedSet.plannedDurationSeconds, 30);

    expect(controller.startTimedSet(0, 0), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(controller.pauseTimedSet(0, 0), isTrue);

    timedSet = controller.activeSession!.exercises.single.sets.first;
    expect(timedSet.durationStartedAt, isNull);
    expect(timedSet.actualDurationSeconds, greaterThanOrEqualTo(1));

    expect(controller.startTimedSet(0, 0), isTrue);
    expect(controller.completeTimedSet(0, 0), isTrue);
    timedSet = controller.activeSession!.exercises.single.sets.first;
    expect(timedSet.isCompleted, isTrue);
    expect(timedSet.durationStartedAt, isNull);

    expect(controller.reopenTimedSet(0, 0), isTrue);
    expect(
      controller.activeSession!.exercises.single.sets.first.isCompleted,
      isFalse,
    );
  });

  test('preserva aquecimento e usa o descanso próprio de cada série', () async {
    final repository = _SessionFakeRepository(
      routines: <WorkoutRoutine>[routineWithWarmUp],
    );
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    final controller = container.read(workoutControllerProvider.notifier);
    await controller.initialization;
    expect(controller.startRoutine(routineWithWarmUp), isTrue);

    final sets = controller.activeSession!.exercises.single.sets;
    expect(sets.first.kind, WorkoutSetKind.warmUp);
    expect(sets.last.kind, WorkoutSetKind.working);

    expect(
      controller.startRestAfterSet(0, setIndex: 0),
      RestStartOutcome.started,
    );
    expect(container.read(workoutControllerProvider).restSeconds, 30);
    controller.stopRestTimer();

    expect(
      controller.startRestAfterSet(0, setIndex: 1),
      RestStartOutcome.started,
    );
    expect(container.read(workoutControllerProvider).restSeconds, 90);
  });

  test('não inicia descanso entre as duas partes do bi-set', () async {
    final repository = _SessionFakeRepository(
      routines: <WorkoutRoutine>[routineA],
    );
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    final controller = container.read(workoutControllerProvider.notifier);
    await controller.initialization;
    controller.startRoutine(routineA);

    expect(
      controller.startRestAfterSet(0, setIndex: 0),
      RestStartOutcome.skippedForSuperset,
    );
    expect(container.read(workoutControllerProvider).isResting, isFalse);

    expect(
      controller.startRestAfterSet(1, setIndex: 0),
      RestStartOutcome.waitingForSupersetPair,
    );

    controller.saveActiveSessionProgress(
      setsStatus: <int, List<bool>>{
        0: <bool>[true, false, false],
        1: <bool>[true, false, false],
      },
      weights: <int, List<String>>{
        0: <String>['40', '', ''],
        1: <String>['40', '', ''],
      },
      reps: <int, List<String>>{
        0: <String>['10', '', ''],
        1: <String>['10', '', ''],
      },
      notes: '',
    );

    expect(
      controller.startRestAfterSet(1, setIndex: 0),
      RestStartOutcome.started,
    );
    expect(container.read(workoutControllerProvider).isResting, isTrue);
    expect(container.read(workoutControllerProvider).restSeconds, 75);
  });

  test(
    'inicia descanso quando o bi-set é concluído na ordem inversa',
    () async {
      final repository = _SessionFakeRepository(
        routines: <WorkoutRoutine>[routineA],
      );
      final container = _buildContainer(repository);
      addTearDown(container.dispose);

      final controller = container.read(workoutControllerProvider.notifier);
      await controller.initialization;
      controller.startRoutine(routineA);

      controller.saveActiveSessionProgress(
        setsStatus: <int, List<bool>>{
          0: <bool>[false, false, false],
          1: <bool>[true, false, false],
        },
        weights: <int, List<String>>{
          0: <String>['', '', ''],
          1: <String>['40', '', ''],
        },
        reps: <int, List<String>>{
          0: <String>['', '', ''],
          1: <String>['10', '', ''],
        },
        notes: '',
      );

      expect(
        controller.startRestAfterSet(1, setIndex: 0),
        RestStartOutcome.waitingForSupersetPair,
      );
      expect(container.read(workoutControllerProvider).isResting, isFalse);

      controller.saveActiveSessionProgress(
        setsStatus: <int, List<bool>>{
          0: <bool>[true, false, false],
          1: <bool>[true, false, false],
        },
        weights: <int, List<String>>{
          0: <String>['40', '', ''],
          1: <String>['40', '', ''],
        },
        reps: <int, List<String>>{
          0: <String>['10', '', ''],
          1: <String>['10', '', ''],
        },
        notes: '',
      );

      expect(
        controller.startRestAfterSet(0, setIndex: 0),
        RestStartOutcome.started,
      );
      expect(container.read(workoutControllerProvider).isResting, isTrue);
      expect(container.read(workoutControllerProvider).restSeconds, 75);
    },
  );

  test('pausa, continua e pula o descanso preservando o tempo', () async {
    final repository = _SessionFakeRepository(
      routines: <WorkoutRoutine>[routineB],
    );
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    final controller = container.read(workoutControllerProvider.notifier);
    await controller.initialization;
    controller.startRoutine(routineB);
    controller.startRestTimer('60 seg');
    await Future<void>.delayed(Duration.zero);

    expect(container.read(workoutControllerProvider).isResting, isTrue);
    expect(container.read(workoutControllerProvider).isRestPaused, isFalse);
    expect(container.read(workoutControllerProvider).restSeconds, 60);
    expect(repository.activeSession?.restEndsAt, isNotNull);
    expect(repository.activeSession?.isRestPaused, isFalse);

    controller.pauseRestTimer();
    await Future<void>.delayed(Duration.zero);
    expect(container.read(workoutControllerProvider).isRestPaused, isTrue);
    expect(container.read(workoutControllerProvider).restSeconds, 60);
    expect(repository.activeSession?.restEndsAt, isNull);
    expect(repository.activeSession?.isRestPaused, isTrue);

    controller.addRestSeconds(15);
    expect(container.read(workoutControllerProvider).restSeconds, 75);

    controller.resumeRestTimer();
    expect(container.read(workoutControllerProvider).isRestPaused, isFalse);
    expect(container.read(workoutControllerProvider).isResting, isTrue);

    controller.stopRestTimer();
    expect(container.read(workoutControllerProvider).isResting, isFalse);
    expect(container.read(workoutControllerProvider).isRestPaused, isFalse);
    expect(container.read(workoutControllerProvider).restSeconds, 0);
  });

  test('restaura descanso em andamento após recriar o processo', () async {
    final restEndsAt = DateTime.now().add(const Duration(seconds: 60));
    final repository =
        _SessionFakeRepository(routines: <WorkoutRoutine>[routineB])
          ..activeSession = ActiveWorkoutSession(
            id: 'active-rest',
            routineName: routineB.name,
            startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
            elapsedSeconds: 300,
            exercises: <ActiveWorkoutExercise>[
              ActiveWorkoutExercise(
                exercise: secondExercise,
                sets: const <ActiveWorkoutSet>[
                  ActiveWorkoutSet(setNumber: 1, isCompleted: true),
                ],
              ),
            ],
            restSeconds: 60,
            restEndsAt: restEndsAt,
          );
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    final controller = container.read(workoutControllerProvider.notifier);
    await controller.initialization;

    final restored = container.read(workoutControllerProvider);
    expect(restored.isResting, isTrue);
    expect(restored.isRestPaused, isFalse);
    expect(restored.restSeconds, inInclusiveRange(59, 60));
  });

  test('restaura descanso pausado com os segundos preservados', () async {
    final repository =
        _SessionFakeRepository(routines: <WorkoutRoutine>[routineB])
          ..activeSession = ActiveWorkoutSession(
            id: 'paused-rest',
            routineName: routineB.name,
            startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
            elapsedSeconds: 300,
            exercises: <ActiveWorkoutExercise>[
              ActiveWorkoutExercise(
                exercise: secondExercise,
                sets: const <ActiveWorkoutSet>[
                  ActiveWorkoutSet(setNumber: 1, isCompleted: true),
                ],
              ),
            ],
            restSeconds: 47,
            isRestPaused: true,
          );
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    final controller = container.read(workoutControllerProvider.notifier);
    await controller.initialization;

    final restored = container.read(workoutControllerProvider);
    expect(restored.isResting, isTrue);
    expect(restored.isRestPaused, isTrue);
    expect(restored.restSeconds, 47);
  });

  test('não encerra treino sem nenhuma série concluída', () async {
    final repository = _SessionFakeRepository(
      routines: <WorkoutRoutine>[routineB],
    );
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    final controller = container.read(workoutControllerProvider.notifier);
    await controller.initialization;
    controller.startRoutine(routineB);

    final saved = await controller.finishWorkout(
      '10:00',
      isIncomplete: true,
      logs: const <ExerciseLog>[],
    );

    expect(saved, isFalse);
    expect(container.read(workoutControllerProvider).isWorkoutActive, isTrue);
    expect(repository.history, isEmpty);
  });

  test('salva uma única entrada e limpa a sessão ao finalizar', () async {
    final repository = _SessionFakeRepository(
      routines: <WorkoutRoutine>[routineB],
    );
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    final controller = container.read(workoutControllerProvider.notifier);
    await controller.initialization;
    controller.startRoutine(routineB);
    controller.saveActiveSessionProgress(
      setsStatus: <int, List<bool>>{
        0: <bool>[true, true, true],
      },
      weights: <int, List<String>>{
        0: <String>['40', '40', '40'],
      },
      reps: <int, List<String>>{
        0: <String>['10', '10', '10'],
      },
      notes: '',
    );

    final saved = await controller.finishWorkout(
      '10:00',
      isIncomplete: false,
      logs: <ExerciseLog>[
        ExerciseLog(
          exerciseId: secondExercise.id,
          exerciseName: secondExercise.name,
          sets: const <ExerciseSet>[
            ExerciseSet(reps: 10, weight: 40),
            ExerciseSet(reps: 10, weight: 40),
            ExerciseSet(reps: 10, weight: 40),
          ],
        ),
      ],
    );

    expect(saved, isTrue);
    expect(container.read(workoutControllerProvider).isWorkoutActive, isFalse);
    expect(repository.history, hasLength(1));
    expect(repository.history.single.isIncomplete, isFalse);
    expect(repository.clearActiveSessionCalls, 1);
  });

  test(
    'saves next routine choice while preserving incomplete status',
    () async {
      final repository = _SessionFakeRepository(routines: [routineB]);
      final container = _buildContainer(repository);
      addTearDown(container.dispose);
      final controller = container.read(workoutControllerProvider.notifier);
      await controller.initialization;
      controller.startRoutine(routineB);
      final saved = await controller.finishWorkout(
        '05:00',
        isIncomplete: true,
        nextRoutineId: 'next-routine',
        logs: [
          ExerciseLog(
            exerciseId: secondExercise.id,
            exerciseName: secondExercise.name,
            sets: const [ExerciseSet(reps: 10, weight: 40)],
          ),
        ],
      );
      expect(saved, isTrue);
      expect(repository.history.single.nextRoutineId, 'next-routine');
      expect(repository.history.single.isIncomplete, isTrue);
      expect(
        container.read(workoutControllerProvider).isWorkoutActive,
        isFalse,
      );
    },
  );

  test('mantém anotações do exercício ao salvar séries da sessão', () async {
    final repository = _SessionFakeRepository(
      routines: <WorkoutRoutine>[routineB],
    );
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    final controller = container.read(workoutControllerProvider.notifier);
    await controller.initialization;
    controller.startRoutine(routineB);

    controller.updateExerciseSessionDetails(
      0,
      notes: 'Usei outra máquina hoje.',
      isLoadComparable: false,
      perceivedRir: 2,
    );
    controller.saveActiveSessionProgress(
      setsStatus: <int, List<bool>>{
        0: <bool>[true, false, false],
      },
      weights: <int, List<String>>{
        0: <String>['40', '', ''],
      },
      reps: <int, List<String>>{
        0: <String>['10', '', ''],
      },
      notes: '',
    );

    final activeExercise = controller.activeSession!.exercises.single;
    expect(activeExercise.sessionNotes, 'Usei outra máquina hoje.');
    expect(activeExercise.isLoadComparable, isFalse);
    expect(activeExercise.perceivedRir, 2);
    expect(activeExercise.sets.first.isCompleted, isTrue);
  });

  test('inicia, persiste e salva cardio planejado dentro da sessão', () async {
    final repository = _SessionFakeRepository(
      routines: <WorkoutRoutine>[routineWithCardio],
    );
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    final controller = container.read(workoutControllerProvider.notifier);
    await controller.initialization;
    expect(controller.startRoutine(routineWithCardio), isTrue);

    final initialCardio = controller.activeSession!.cardio.single;
    expect(initialCardio.modality, CardioModality.stationaryBike);
    expect(initialCardio.plannedDurationMinutes, 20);
    expect(initialCardio.isCompleted, isFalse);

    controller.saveActiveSessionProgress(
      setsStatus: <int, List<bool>>{
        0: <bool>[true, true, true],
      },
      weights: <int, List<String>>{
        0: <String>['40', '40', '40'],
      },
      reps: <int, List<String>>{
        0: <String>['10', '10', '10'],
      },
      notes: '',
    );
    controller.updateActiveCardio(
      initialCardio.copyWith(
        actualDurationMinutes: 18,
        distanceKm: 6.2,
        isCompleted: true,
      ),
    );

    final saved = await controller.finishWorkout(
      '35:00',
      isIncomplete: false,
      logs: <ExerciseLog>[
        ExerciseLog(
          exerciseId: secondExercise.id,
          exerciseName: secondExercise.name,
          sets: const <ExerciseSet>[
            ExerciseSet(reps: 10, weight: 40),
            ExerciseSet(reps: 10, weight: 40),
            ExerciseSet(reps: 10, weight: 40),
          ],
        ),
      ],
      cardio: <CardioLog>[controller.activeSession!.cardio.single.toLog()],
    );

    expect(saved, isTrue);
    expect(repository.history, hasLength(1));
    expect(repository.history.single.cardio, hasLength(1));
    expect(repository.history.single.cardio.single.actualDurationMinutes, 18);
    expect(repository.history.single.cardio.single.distanceKm, 6.2);
    expect(repository.history.single.isIncomplete, isFalse);
  });

  test('permite finalizar sessão composta somente por cardio', () async {
    final cardioOnlyRoutine = WorkoutRoutine(
      id: 'cardio-only',
      name: 'Cardio leve',
      focus: 'Condicionamento',
      exercises: const <Exercise>[],
      cardio: const <RoutineCardio>[
        RoutineCardio(
          id: 'walk-1',
          modality: CardioModality.walking,
          plannedDurationMinutes: 30,
        ),
      ],
    );
    final repository = _SessionFakeRepository(
      routines: <WorkoutRoutine>[cardioOnlyRoutine],
    );
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    final controller = container.read(workoutControllerProvider.notifier);
    await controller.initialization;
    controller.startRoutine(cardioOnlyRoutine);
    final entry = controller.activeSession!.cardio.single.copyWith(
      actualDurationMinutes: 25,
      isCompleted: true,
    );
    controller.updateActiveCardio(entry);

    final saved = await controller.finishWorkout(
      '25:00',
      isIncomplete: false,
      logs: const <ExerciseLog>[],
      cardio: <CardioLog>[entry.toLog()],
    );

    expect(saved, isTrue);
    expect(repository.history.single.isCardioOnly, isTrue);
    expect(repository.history.single.isIncomplete, isFalse);
  });
}

ProviderContainer _buildContainer(_SessionFakeRepository repository) {
  return ProviderContainer(
    overrides: [
      workoutRepositoryProvider.overrideWithValue(repository),
      workoutFeedbackServiceProvider.overrideWithValue(
        _SessionFakeFeedbackService(),
      ),
    ],
  );
}

class _SessionFakeFeedbackService implements WorkoutFeedbackService {
  @override
  Future<void> configure() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<void> playRestFinished({required bool enabled}) async {}
}

class _SessionFakeRepository implements WorkoutRepository {
  _SessionFakeRepository({this.routines = const <WorkoutRoutine>[]});

  List<Exercise> customExercises = <Exercise>[];
  List<WorkoutRoutine> routines;
  List<WorkoutHistoryItem> history = <WorkoutHistoryItem>[];
  String activeProgramName = '';
  ActiveWorkoutSession? activeSession;
  int clearActiveSessionCalls = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<List<Exercise>> loadCustomExercises() async =>
      List<Exercise>.from(customExercises);

  @override
  Future<List<WorkoutRoutine>> loadRoutines() async =>
      List<WorkoutRoutine>.from(routines);

  @override
  Future<List<WorkoutHistoryItem>> loadHistory() async =>
      List<WorkoutHistoryItem>.from(history);

  @override
  Future<String> loadActiveProgramName() async => activeProgramName;

  @override
  Future<ActiveWorkoutSession?> loadActiveSession() async => activeSession;

  @override
  Future<void> saveCustomExercises(List<Exercise> exercises) async {
    customExercises = List<Exercise>.from(exercises);
  }

  @override
  Future<void> saveRoutines(List<WorkoutRoutine> routines) async {
    this.routines = List<WorkoutRoutine>.from(routines);
  }

  @override
  Future<void> saveHistory(List<WorkoutHistoryItem> history) async {
    this.history = List<WorkoutHistoryItem>.from(history);
  }

  @override
  Future<void> saveActiveProgramName(String programName) async {
    activeProgramName = programName;
  }

  @override
  Future<void> saveCompletedWorkout({
    required String routineName,
    required String duration,
    required List<ExerciseLog> exercises,
    required String notes,
    required bool isIncomplete,
  }) async {}

  @override
  Future<void> finalizeWorkout(WorkoutHistoryItem item) async {
    final existingIndex = history.indexWhere(
      (historyItem) => historyItem.id == item.id,
    );

    if (existingIndex >= 0) {
      history[existingIndex] = item;
    } else {
      history.add(item);
    }

    activeSession = null;
  }

  @override
  Future<void> saveActiveSession(ActiveWorkoutSession session) async {
    activeSession = session;
  }

  @override
  Future<void> clearActiveSession() async {
    clearActiveSessionCalls++;
    activeSession = null;
  }

  @override
  Future<void> clearAll() async {
    customExercises = <Exercise>[];
    routines = <WorkoutRoutine>[];
    history = <WorkoutHistoryItem>[];
    activeProgramName = '';
    activeSession = null;
  }
}
