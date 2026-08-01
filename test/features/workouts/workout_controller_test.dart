import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse/features/workouts/data/catalogs/pre_made_workout_catalog.dart';
import 'package:pulse/features/workouts/data/services/workout_feedback_service.dart';
import 'package:pulse/features/workouts/domain/models/active_workout_session.dart';
import 'package:pulse/features/workouts/domain/models/exercise_log.dart';
import 'package:pulse/features/workouts/domain/models/workout_history_item.dart';
import 'package:pulse/features/workouts/domain/models/workout_set.dart';
import 'package:pulse/features/workouts/domain/repositories/workout_repository.dart';
import 'package:pulse/features/workouts/presentation/providers/workout_controller.dart';
import 'package:pulse/models/exercise.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const exercise = Exercise(
    id: 'exercise-1',
    name: 'Supino',
    muscle: 'Peito',
    description: 'Teste',
    reps: '3x 10',
    rest: '60 seg',
  );

  final routine = WorkoutRoutine(
    id: 'routine-1',
    name: 'Treino A',
    focus: 'Peito',
    groupName: 'ABC',
    exercises: const <Exercise>[exercise],
  );

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'settings_vibrate_after_rest': false,
    });
  });

  test('inicializa o estado de treino pelo Riverpod', () async {
    final repository = _FakeWorkoutRepository(
      routines: <WorkoutRoutine>[routine],
      activeProgramName: 'ABC',
    );
    final feedbackService = _FakeWorkoutFeedbackService();

    final container = ProviderContainer(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(repository),
        workoutFeedbackServiceProvider.overrideWithValue(feedbackService),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(workoutControllerProvider.notifier);
    await controller.initialization;

    final workoutState = container.read(workoutControllerProvider);

    expect(workoutState.isInitialized, isTrue);
    expect(workoutState.initializationError, isNull);
    expect(workoutState.myRoutines, hasLength(1));
    expect(workoutState.activeProgramName, 'ABC');
    expect(workoutState.nextRoutineToTrain?.id, routine.id);
    expect(workoutState.voiceAfterRest, isFalse);
    expect(feedbackService.configureCalls, 1);
  });

  test('inicia e persiste uma sessão sem depender de BuildContext', () async {
    final repository = _FakeWorkoutRepository(
      routines: <WorkoutRoutine>[routine],
    );
    final container = ProviderContainer(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(repository),
        workoutFeedbackServiceProvider.overrideWithValue(
          _FakeWorkoutFeedbackService(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(workoutControllerProvider.notifier);
    await controller.initialization;

    controller.startRoutine(routine);
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
      notes: 'Sessão de teste',
    );

    await Future<void>.delayed(Duration.zero);

    final activeState = container.read(workoutControllerProvider);

    expect(activeState.isWorkoutActive, isTrue);
    expect(activeState.activeRoutineName, routine.name);
    expect(controller.activeSession?.notes, 'Sessão de teste');
    expect(
      controller.activeSession?.exercises.first.sets.first.isCompleted,
      isTrue,
    );
    expect(
      controller.activeSession?.exercises.first.sets.first.weightText,
      '40',
    );
    expect(repository.savedActiveSession, isNotNull);

    await controller.cancelWorkout();

    final finishedState = container.read(workoutControllerProvider);

    expect(finishedState.isWorkoutActive, isFalse);
    expect(controller.activeSession, isNull);
    expect(repository.clearActiveSessionCalls, greaterThanOrEqualTo(1));
  });

  test('publica um novo estado imutável ao criar exercício', () async {
    final repository = _FakeWorkoutRepository();
    final container = ProviderContainer(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(repository),
        workoutFeedbackServiceProvider.overrideWithValue(
          _FakeWorkoutFeedbackService(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(workoutControllerProvider.notifier);
    await controller.initialization;

    final previousState = container.read(workoutControllerProvider);

    controller.createCustomExercise('Remada baixa', 'Costas');
    await Future<void>.delayed(Duration.zero);

    final nextState = container.read(workoutControllerProvider);

    expect(identical(previousState, nextState), isFalse);
    expect(nextState.customExercises, hasLength(1));
    expect(nextState.customExercises.single.name, 'Remada baixa');
    expect(repository.customExercises, hasLength(1));
  });

  test('não duplica um programa pronto já importado', () async {
    final repository = _FakeWorkoutRepository();
    final container = ProviderContainer(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(repository),
        workoutFeedbackServiceProvider.overrideWithValue(
          _FakeWorkoutFeedbackService(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(workoutControllerProvider.notifier);
    await controller.initialization;

    final program = controller.preMadePrograms.first;

    expect(controller.importProgram(program), isTrue);
    final firstImportCount = container
        .read(workoutControllerProvider)
        .myRoutines
        .length;

    expect(controller.isProgramImported(program), isTrue);
    expect(controller.importProgram(program), isFalse);
    expect(
      container.read(workoutControllerProvider).myRoutines.length,
      firstImportCount,
    );
  });

  test('reconhece importações antigas pelo identificador da ficha', () async {
    final program = buildPreMadeWorkoutPrograms().first;
    final legacyRoutines = program.routines
        .map(
          (item) => item.copyWith(
            id: '1700000000000_${item.id}',
            groupName: program.name,
          ),
        )
        .toList();
    final repository = _FakeWorkoutRepository(routines: legacyRoutines);
    final container = ProviderContainer(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(repository),
        workoutFeedbackServiceProvider.overrideWithValue(
          _FakeWorkoutFeedbackService(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(workoutControllerProvider.notifier);
    await controller.initialization;

    expect(controller.isProgramImported(program), isTrue);
    expect(controller.importProgram(program), isFalse);
    expect(
      container.read(workoutControllerProvider).myRoutines,
      hasLength(program.routines.length),
    );
  });

  test('atualiza imediatamente a ficha após remover um exercício', () async {
    const secondExercise = Exercise(
      id: 'exercise-2',
      name: 'Crucifixo',
      muscle: 'Peito',
      description: 'Teste',
      reps: '3x 12',
      rest: '45 seg',
    );

    final routineWithTwoExercises = routine.copyWith(
      exercises: const <Exercise>[exercise, secondExercise],
    );
    final repository = _FakeWorkoutRepository(
      routines: <WorkoutRoutine>[routineWithTwoExercises],
    );
    final container = ProviderContainer(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(repository),
        workoutFeedbackServiceProvider.overrideWithValue(
          _FakeWorkoutFeedbackService(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(workoutControllerProvider.notifier);
    await controller.initialization;

    controller.updateRoutine(
      routineWithTwoExercises.id,
      routineWithTwoExercises.name,
      routineWithTwoExercises.focus,
      routineWithTwoExercises.groupName,
      const <Exercise>[exercise],
    );

    final updatedRoutine = container
        .read(workoutControllerProvider)
        .myRoutines
        .single;

    expect(updatedRoutine.exercises, hasLength(1));
    expect(updatedRoutine.exercises.single.id, exercise.id);
  });

  test('normaliza identidades antigas sem perder fichas e histórico', () async {
    const legacyExercise = Exercise(
      id: 'ex_pm_1',
      name: 'Chest Press',
      muscle: 'Peito',
      description: 'Controle bem a descida.',
      reps: '4x 8-12',
      rest: '60 seg',
      customNote: 'Teste de migração',
    );
    final legacyRoutine = WorkoutRoutine(
      id: 'legacy-routine',
      name: 'Treino antigo',
      focus: 'Peito',
      exercises: const <Exercise>[legacyExercise],
    );
    final legacyHistory = WorkoutHistoryItem(
      id: 'legacy-history',
      routineName: legacyRoutine.name,
      date: DateTime(2026, 7, 31),
      duration: '30 min',
      exercises: <ExerciseLog>[
        ExerciseLog(
          exerciseId: 'ex_pm_1',
          exerciseName: 'Chest Press',
          sets: const <ExerciseSet>[ExerciseSet(reps: 10, weight: 40)],
        ),
      ],
    );
    final legacySession = ActiveWorkoutSession(
      id: 'active',
      routineName: legacyRoutine.name,
      startedAt: DateTime(2026, 7, 31),
      elapsedSeconds: 12,
      exercises: <ActiveWorkoutExercise>[
        ActiveWorkoutExercise(
          exercise: legacyExercise,
          sets: const <ActiveWorkoutSet>[
            ActiveWorkoutSet(setNumber: 1, repsText: '10'),
          ],
        ),
      ],
    );
    final repository =
        _FakeWorkoutRepository(routines: <WorkoutRoutine>[legacyRoutine])
          ..history = <WorkoutHistoryItem>[legacyHistory]
          ..activeSession = legacySession;
    final container = ProviderContainer(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(repository),
        workoutFeedbackServiceProvider.overrideWithValue(
          _FakeWorkoutFeedbackService(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(workoutControllerProvider.notifier).initialization;

    final migratedExercise = container
        .read(workoutControllerProvider)
        .myRoutines
        .single
        .exercises
        .single;
    final migratedLog = container
        .read(workoutHistoryControllerProvider)
        .items
        .single
        .exercises
        .single;
    final migratedSession = container
        .read(workoutSessionControllerProvider)
        .activeSession;

    expect(migratedExercise.id, 'p12');
    expect(migratedExercise.name, 'Supino Reto Articulado');
    expect(migratedExercise.reps, legacyExercise.reps);
    expect(migratedExercise.customNote, legacyExercise.customNote);
    expect(migratedLog.exerciseId, 'p12');
    expect(migratedLog.exerciseName, 'Supino Reto Articulado');
    expect(migratedSession?.exercises.single.exercise.id, 'p12');
    expect(repository.routines.single.exercises.single.id, 'p12');
    expect(repository.history.single.exercises.single.exerciseId, 'p12');
    expect(repository.activeSession?.exercises.single.exercise.id, 'p12');
  });

  test('migra duplicidade p13 em fichas histórico e sessão', () async {
    const duplicateExercise = Exercise(
      id: 'p13',
      name: 'Crucifixo na Máquina',
      muscle: 'Peito',
      description: 'Descrição preservada.',
      reps: '4x 12',
      rest: '75 seg',
      customNote: 'Nota preservada',
    );
    final duplicateRoutine = WorkoutRoutine(
      id: 'duplicate-routine',
      name: 'Treino duplicado',
      focus: 'Peito',
      exercises: const <Exercise>[duplicateExercise],
    );
    final duplicateHistory = WorkoutHistoryItem(
      id: 'duplicate-history',
      routineName: duplicateRoutine.name,
      date: DateTime(2026, 7, 31),
      duration: '20 min',
      exercises: <ExerciseLog>[
        ExerciseLog(
          exerciseId: 'p13',
          exerciseName: 'Crucifixo na Máquina',
          sets: const <ExerciseSet>[ExerciseSet(reps: 12, weight: 30)],
        ),
      ],
    );
    final duplicateSession = ActiveWorkoutSession(
      id: 'duplicate-active',
      routineName: duplicateRoutine.name,
      startedAt: DateTime(2026, 7, 31),
      elapsedSeconds: 0,
      exercises: <ActiveWorkoutExercise>[
        ActiveWorkoutExercise(
          exercise: duplicateExercise,
          sets: const <ActiveWorkoutSet>[
            ActiveWorkoutSet(setNumber: 1, weightText: '30', repsText: '12'),
          ],
        ),
      ],
    );
    final repository =
        _FakeWorkoutRepository(routines: <WorkoutRoutine>[duplicateRoutine])
          ..history = <WorkoutHistoryItem>[duplicateHistory]
          ..activeSession = duplicateSession;
    final container = ProviderContainer(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(repository),
        workoutFeedbackServiceProvider.overrideWithValue(
          _FakeWorkoutFeedbackService(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(workoutControllerProvider.notifier).initialization;

    final migratedRoutineExercise = container
        .read(workoutControllerProvider)
        .myRoutines
        .single
        .exercises
        .single;
    final migratedLog = container
        .read(workoutHistoryControllerProvider)
        .items
        .single
        .exercises
        .single;
    final migratedSessionExercise = container
        .read(workoutSessionControllerProvider)
        .activeSession
        ?.exercises
        .single
        .exercise;

    expect(migratedRoutineExercise.id, 'p9');
    expect(migratedRoutineExercise.name, 'Voador Peitoral na Máquina');
    expect(migratedRoutineExercise.reps, duplicateExercise.reps);
    expect(migratedRoutineExercise.rest, duplicateExercise.rest);
    expect(migratedRoutineExercise.customNote, duplicateExercise.customNote);
    expect(migratedLog.exerciseId, 'p9');
    expect(migratedLog.exerciseName, 'Voador Peitoral na Máquina');
    expect(migratedLog.sets.single.weight, 30);
    expect(migratedSessionExercise?.id, 'p9');
    expect(repository.routines.single.exercises.single.id, 'p9');
    expect(repository.history.single.exercises.single.exerciseId, 'p9');
    expect(repository.activeSession?.exercises.single.exercise.id, 'p9');
  });

  test('migra bi-set criado pelo construtor antigo', () async {
    const firstExercise = Exercise(
      id: 'exercise-biset-1',
      name: 'Supino reto',
      muscle: 'Peito',
      description: '',
      reps: '3x 10',
      rest: '0 seg',
    );
    const secondExercise = Exercise(
      id: 'exercise-biset-2',
      name: 'Remada baixa',
      muscle: 'Costas',
      description: '',
      reps: '3x 10 + BISET',
      rest: '60 seg',
    );

    final legacyRoutine = WorkoutRoutine(
      id: 'legacy-biset',
      name: 'Treino Bi-set',
      focus: 'Superiores',
      groupName: 'Teste',
      exercises: const <Exercise>[firstExercise, secondExercise],
    );
    final repository = _FakeWorkoutRepository(
      routines: <WorkoutRoutine>[legacyRoutine],
    );
    final container = ProviderContainer(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(repository),
        workoutFeedbackServiceProvider.overrideWithValue(
          _FakeWorkoutFeedbackService(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(workoutControllerProvider.notifier);
    await controller.initialization;

    final migratedRoutine = container
        .read(workoutControllerProvider)
        .myRoutines
        .single;

    expect(migratedRoutine.exercises.first.isSuperset, isTrue);
    expect(migratedRoutine.exercises.last.isSuperset, isFalse);
    expect(migratedRoutine.exercises.last.reps, '3x 10');
    expect(repository.routines.single.exercises.first.isSuperset, isTrue);
    expect(repository.routines.single.exercises.last.reps, '3x 10');
  });

  test(
    'mantém biblioteca, histórico e sessão em estados independentes',
    () async {
      final repository = _FakeWorkoutRepository(
        routines: <WorkoutRoutine>[routine],
      );
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(repository),
          workoutFeedbackServiceProvider.overrideWithValue(
            _FakeWorkoutFeedbackService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final facade = container.read(workoutControllerProvider.notifier);
      await facade.initialization;

      final libraryBefore = container.read(workoutLibraryControllerProvider);
      final historyBefore = container.read(workoutHistoryControllerProvider);

      container
          .read(workoutSessionControllerProvider.notifier)
          .startRoutine(routine);

      expect(
        identical(
          container.read(workoutLibraryControllerProvider),
          libraryBefore,
        ),
        isTrue,
      );
      expect(
        identical(
          container.read(workoutHistoryControllerProvider),
          historyBefore,
        ),
        isTrue,
      );
      expect(
        container.read(workoutSessionControllerProvider).isWorkoutActive,
        isTrue,
      );
    },
  );

  test('catálogo delega a importação somente para a biblioteca', () async {
    final repository = _FakeWorkoutRepository();
    final container = ProviderContainer(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(repository),
        workoutFeedbackServiceProvider.overrideWithValue(
          _FakeWorkoutFeedbackService(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(workoutControllerProvider.notifier).initialization;

    final historyBefore = container.read(workoutHistoryControllerProvider);
    final sessionBefore = container.read(workoutSessionControllerProvider);
    final program = container.read(workoutCatalogControllerProvider).first;

    final imported = container
        .read(workoutCatalogControllerProvider.notifier)
        .importProgram(program);

    expect(imported, isTrue);
    expect(
      container.read(workoutLibraryControllerProvider).routines,
      hasLength(program.routines.length),
    );
    expect(
      identical(
        container.read(workoutHistoryControllerProvider),
        historyBefore,
      ),
      isTrue,
    );
    expect(
      identical(
        container.read(workoutSessionControllerProvider),
        sessionBefore,
      ),
      isTrue,
    );
  });

  test('exclui todas as fichas de um programa de uma vez', () async {
    final secondProgramRoutine = routine.copyWith(
      id: 'routine-2',
      name: 'Treino B',
      groupName: 'Outro programa',
    );
    final secondRoutineSameProgram = routine.copyWith(
      id: 'routine-3',
      name: 'Treino C',
    );
    final repository = _FakeWorkoutRepository(
      routines: <WorkoutRoutine>[
        routine,
        secondRoutineSameProgram,
        secondProgramRoutine,
      ],
      activeProgramName: 'ABC',
    );
    final container = ProviderContainer(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(repository),
        workoutFeedbackServiceProvider.overrideWithValue(
          _FakeWorkoutFeedbackService(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(workoutControllerProvider.notifier);
    await controller.initialization;
    controller.deleteProgram('ABC');
    await Future<void>.delayed(Duration.zero);

    final state = container.read(workoutControllerProvider);
    expect(state.myRoutines, hasLength(1));
    expect(state.myRoutines.single.groupName, 'Outro programa');
    expect(state.activeProgramName, 'Outro programa');
    expect(repository.routines, hasLength(1));
  });

  test('mantém a duração do treino em um Notifier separado', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final durationController = container.read(workoutDurationProvider.notifier);

    expect(container.read(workoutDurationProvider), 0);

    durationController.setSeconds(15);
    durationController.increment();

    expect(container.read(workoutDurationProvider), 16);

    durationController.reset();

    expect(container.read(workoutDurationProvider), 0);
  });
}

class _FakeWorkoutFeedbackService implements WorkoutFeedbackService {
  int configureCalls = 0;

  @override
  Future<void> configure() async {
    configureCalls++;
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<void> playRestFinished({required bool enabled}) async {}
}

class _FakeWorkoutRepository implements WorkoutRepository {
  _FakeWorkoutRepository({
    this.routines = const <WorkoutRoutine>[],
    this.activeProgramName = '',
  });

  List<Exercise> customExercises = <Exercise>[];
  List<WorkoutRoutine> routines;
  List<WorkoutHistoryItem> history = <WorkoutHistoryItem>[];
  String activeProgramName;
  ActiveWorkoutSession? activeSession;

  ActiveWorkoutSession? savedActiveSession;
  int clearActiveSessionCalls = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<List<Exercise>> loadCustomExercises() async {
    return List<Exercise>.from(customExercises);
  }

  @override
  Future<List<WorkoutRoutine>> loadRoutines() async {
    return List<WorkoutRoutine>.from(routines);
  }

  @override
  Future<List<WorkoutHistoryItem>> loadHistory() async {
    return List<WorkoutHistoryItem>.from(history);
  }

  @override
  Future<String> loadActiveProgramName() async {
    return activeProgramName;
  }

  @override
  Future<ActiveWorkoutSession?> loadActiveSession() async {
    return activeSession;
  }

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
    savedActiveSession = session;
    activeSession = session;
  }

  @override
  Future<void> clearActiveSession() async {
    clearActiveSessionCalls++;
    activeSession = null;
    savedActiveSession = null;
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
