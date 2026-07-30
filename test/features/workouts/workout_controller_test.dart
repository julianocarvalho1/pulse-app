import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse/features/workouts/data/services/workout_feedback_service.dart';
import 'package:pulse/features/workouts/domain/models/active_workout_session.dart';
import 'package:pulse/features/workouts/domain/models/exercise_log.dart';
import 'package:pulse/features/workouts/domain/models/workout_history_item.dart';
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

    final controller = container.read(workoutControllerProvider);
    await controller.initialization;

    expect(controller.isInitialized, isTrue);
    expect(controller.initializationError, isNull);
    expect(controller.myRoutines, hasLength(1));
    expect(controller.activeProgramName, 'ABC');
    expect(controller.nextRoutineToTrain?.id, routine.id);
    expect(controller.state.vibrateAfterRest, isFalse);
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

    final controller = container.read(workoutControllerProvider);
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

    expect(controller.isWorkoutActive, isTrue);
    expect(controller.activeRoutineName, routine.name);
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

    controller.cancelWorkout();
    await Future<void>.delayed(Duration.zero);

    expect(controller.isWorkoutActive, isFalse);
    expect(controller.activeSession, isNull);
    expect(repository.clearActiveSessionCalls, greaterThanOrEqualTo(1));
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
  Future<void> playRestFinished({required bool vibrate}) async {}
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
