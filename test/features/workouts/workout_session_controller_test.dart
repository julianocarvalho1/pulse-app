import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
