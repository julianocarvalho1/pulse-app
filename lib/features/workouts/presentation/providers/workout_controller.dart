import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../models/exercise.dart';
import '../../data/catalogs/pre_made_workout_catalog.dart';
import '../../data/mappers/legacy_workout_mapper.dart';
import '../../data/repositories/workout_repository_impl.dart';
import '../../data/services/workout_feedback_service.dart';
import '../../domain/models/active_workout_session.dart';
import '../../domain/models/exercise_log.dart';
import '../../domain/models/workout_history_item.dart';
import '../../domain/models/workout_session_status.dart';
import '../../domain/repositories/workout_repository.dart';
import '../state/workout_state.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => WorkoutRepositoryImpl(),
);

final workoutFeedbackServiceProvider = Provider<WorkoutFeedbackService>((ref) {
  final service = DeviceWorkoutFeedbackService();

  ref.onDispose(() {
    unawaited(service.dispose());
  });

  return service;
});

final workoutDurationProvider =
    NotifierProvider<WorkoutDurationController, int>(
      WorkoutDurationController.new,
    );

final workoutControllerProvider =
    NotifierProvider<WorkoutController, WorkoutState>(WorkoutController.new);

class WorkoutDurationController extends Notifier<int> {
  @override
  int build() => 0;

  void setSeconds(int seconds) {
    state = seconds < 0 ? 0 : seconds;
  }

  void increment() {
    state++;
  }

  void reset() {
    state = 0;
  }
}

class WorkoutController extends Notifier<WorkoutState> {
  late Future<void> _initializationFuture;
  bool _disposed = false;

  Timer? _globalTimer;
  Timer? _restTimer;
  ActiveWorkoutSession? _activeSessionSnapshot;

  WorkoutRepository get _repository => ref.read(workoutRepositoryProvider);

  WorkoutFeedbackService get _feedbackService =>
      ref.read(workoutFeedbackServiceProvider);

  Future<void> get initialization => _initializationFuture;

  bool get isResting => state.isResting;
  int get restSeconds => state.restSeconds;
  List<Exercise> get allExercises => state.allExercises;
  List<WorkoutRoutine> get myRoutines => state.myRoutines;
  List<WorkoutProgram> get preMadePrograms => state.preMadePrograms;
  List<WorkoutHistoryItem> get history => state.history;
  bool get isInitialized => state.isInitialized;
  Object? get initializationError => state.initializationError;
  bool get isWorkoutActive => state.isWorkoutActive;
  List<Exercise> get currentWorkoutExercises => state.currentWorkoutExercises;
  String get activeRoutineName => state.activeRoutineName;
  String get activeProgramName => state.activeProgramName;
  ActiveWorkoutSession? get activeSession =>
      _activeSessionSnapshot ?? state.activeSession;
  WorkoutRoutine? get nextRoutineToTrain => state.nextRoutineToTrain;

  @override
  WorkoutState build() {
    _disposed = false;

    ref.onDispose(() {
      _disposed = true;
      _globalTimer?.cancel();
      _restTimer?.cancel();
    });

    unawaited(_configureFeedback());
    _initializationFuture = Future<void>.microtask(_initialize);

    return WorkoutState.initial(preMadePrograms: buildPreMadeWorkoutPrograms());
  }

  Future<void> _configureFeedback() async {
    try {
      await _feedbackService.configure();
    } catch (error) {
      debugPrint('Não foi possível configurar os alertas do treino: $error');
    }
  }

  Future<void> _initialize() async {
    _globalTimer?.cancel();
    ref.read(workoutDurationProvider.notifier).reset();
    _activeSessionSnapshot = null;

    _setState(state.copyWith(isInitialized: false, initializationError: null));

    try {
      final preferences = await SharedPreferences.getInstance();
      final voiceAfterRest =
          preferences.getBool('settings_voice_after_rest') ??
          preferences.getBool('settings_vibrate_after_rest') ??
          true;

      await _repository.initialize();

      final customExercises = await _repository.loadCustomExercises();
      final routines = await _repository.loadRoutines();
      final history = await _repository.loadHistory();
      final activeProgramName = await _repository.loadActiveProgramName();
      final restoredSession = await _repository.loadActiveSession();

      if (_disposed) {
        return;
      }

      _activeSessionSnapshot = restoredSession;

      _setState(
        state.copyWith(
          customExercises: customExercises,
          myRoutines: routines,
          history: history,
          voiceAfterRest: voiceAfterRest,
          isWorkoutActive: restoredSession != null,
          currentWorkoutExercises:
              restoredSession?.exercises
                  .map((activeExercise) => activeExercise.exercise)
                  .toList() ??
              const <Exercise>[],
          activeRoutineName: restoredSession?.routineName ?? 'Treino do Dia',
          activeProgramName: activeProgramName,
          activeSession: restoredSession,
          initializationError: null,
        ),
      );

      if (restoredSession != null) {
        _startGlobalTimer(initialSeconds: restoredSession.elapsedSeconds);
      }
    } catch (error, stackTrace) {
      debugPrint('Erro ao inicializar os treinos: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!_disposed) {
        _setState(state.copyWith(initializationError: error));
      }
    } finally {
      if (!_disposed) {
        _setState(state.copyWith(isInitialized: true));
      }
    }
  }

  Future<void> reload() {
    _globalTimer?.cancel();
    _initializationFuture = _initialize();
    return _initializationFuture;
  }

  void setActiveProgram(String programName) {
    _setState(state.copyWith(activeProgramName: programName));

    _persist(
      () => _repository.saveActiveProgramName(programName),
      'salvar programa ativo',
    );
  }

  void startRestTimer(String restString) {
    if (restString.trim().isEmpty) {
      return;
    }

    final seconds = LegacyWorkoutMapper.parseRestSeconds(restString);

    if (seconds <= 0) {
      return;
    }

    _restTimer?.cancel();
    _setState(state.copyWith(isResting: true, restSeconds: seconds));

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }

      if (state.restSeconds > 0) {
        _setState(state.copyWith(restSeconds: state.restSeconds - 1));
        return;
      }

      stopRestTimer();
      unawaited(_playAlarm());
    });
  }

  void stopRestTimer() {
    _restTimer?.cancel();

    if (!state.isResting && state.restSeconds == 0) {
      return;
    }

    _setState(state.copyWith(isResting: false, restSeconds: 0));
  }

  Future<void> _playAlarm() async {
    await _feedbackService.playRestFinished(enabled: state.voiceAfterRest);
  }

  void setVoiceAfterRest(bool enabled) {
    if (state.voiceAfterRest == enabled) {
      return;
    }

    _setState(state.copyWith(voiceAfterRest: enabled));
  }

  void createCustomExercise(String name, String muscle) {
    final exercise = Exercise(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      muscle: muscle,
      description: 'Exercicio personalizado.',
      reps: '3x 10-12',
      rest: '60 seg',
    );

    final updatedExercises = <Exercise>[...state.customExercises, exercise];

    _setState(state.copyWith(customExercises: updatedExercises));

    _persist(
      () => _repository.saveCustomExercises(updatedExercises),
      'salvar exercício personalizado',
    );
  }

  void createRoutine(
    String name,
    String focus,
    String groupName,
    List<Exercise> exercises,
  ) {
    final uniqueId =
        '${DateTime.now().millisecondsSinceEpoch}_${name.hashCode}_${exercises.length}';

    final routine = WorkoutRoutine(
      id: uniqueId,
      name: name,
      focus: focus,
      groupName: groupName,
      exercises: exercises,
    );

    final updatedRoutines = <WorkoutRoutine>[...state.myRoutines, routine];

    var activeProgramName = state.activeProgramName;

    if (activeProgramName.isEmpty && groupName.isNotEmpty) {
      activeProgramName = groupName;

      _persist(
        () => _repository.saveActiveProgramName(activeProgramName),
        'salvar programa ativo',
      );
    }

    _setState(
      state.copyWith(
        myRoutines: updatedRoutines,
        activeProgramName: activeProgramName,
      ),
    );

    _persist(() => _repository.saveRoutines(updatedRoutines), 'salvar fichas');
  }

  void updateRoutine(
    String id,
    String newName,
    String newFocus,
    String newGroupName,
    List<Exercise> newExercises,
  ) {
    final index = state.myRoutines.indexWhere((routine) => routine.id == id);

    if (index < 0) {
      return;
    }

    final updatedRoutines = List<WorkoutRoutine>.from(state.myRoutines);
    updatedRoutines[index] = updatedRoutines[index].copyWith(
      name: newName,
      focus: newFocus,
      groupName: newGroupName,
      exercises: newExercises,
    );

    _setState(state.copyWith(myRoutines: updatedRoutines));

    _persist(() => _repository.saveRoutines(updatedRoutines), 'salvar fichas');
  }

  void deleteRoutine(String id) {
    final updatedRoutines = state.myRoutines
        .where((routine) => routine.id != id)
        .toList();

    if (updatedRoutines.length == state.myRoutines.length) {
      return;
    }

    _setState(state.copyWith(myRoutines: updatedRoutines));

    _persist(() => _repository.saveRoutines(updatedRoutines), 'salvar fichas');
  }

  void importProgram(WorkoutProgram program) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final importedRoutines = <WorkoutRoutine>[];

    for (var index = 0; index < program.routines.length; index++) {
      final routine = program.routines[index];

      importedRoutines.add(
        WorkoutRoutine(
          id: '${timestamp + index}_${routine.id}',
          name: routine.name,
          focus: routine.focus,
          groupName: program.name,
          exercises: List<Exercise>.from(routine.exercises),
        ),
      );
    }

    final updatedRoutines = <WorkoutRoutine>[
      ...state.myRoutines,
      ...importedRoutines,
    ];

    _setState(
      state.copyWith(
        myRoutines: updatedRoutines,
        activeProgramName: program.name,
      ),
    );

    _persist(
      () => _repository.saveRoutines(updatedRoutines),
      'salvar programa importado',
    );

    _persist(
      () => _repository.saveActiveProgramName(program.name),
      'salvar programa ativo',
    );
  }

  void importRoutine(WorkoutRoutine routine) {
    final importedRoutine = WorkoutRoutine(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: routine.name,
      focus: routine.focus,
      groupName: '',
      exercises: List<Exercise>.from(routine.exercises),
    );

    final updatedRoutines = <WorkoutRoutine>[
      ...state.myRoutines,
      importedRoutine,
    ];

    _setState(state.copyWith(myRoutines: updatedRoutines));

    _persist(
      () => _repository.saveRoutines(updatedRoutines),
      'salvar ficha importada',
    );
  }

  void _saveToHistory(
    String routineName,
    String duration,
    List<ExerciseLog> exercises,
    String notes, {
    required WorkoutSessionStatus status,
  }) {
    final item = WorkoutHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      routineName: routineName.isEmpty ? 'Treino Avulso' : routineName,
      date: DateTime.now(),
      duration: duration,
      exercises: exercises,
      notes: notes,
      status: status,
    );

    final updatedHistory = <WorkoutHistoryItem>[item, ...state.history];

    _setState(state.copyWith(history: updatedHistory));

    _persist(() => _repository.saveHistory(updatedHistory), 'salvar histórico');
  }

  void deleteHistoryItem(String id) {
    final updatedHistory = state.history
        .where((item) => item.id != id)
        .toList();

    if (updatedHistory.length == state.history.length) {
      return;
    }

    _setState(state.copyWith(history: updatedHistory));

    _persist(
      () => _repository.saveHistory(updatedHistory),
      'excluir item do histórico',
    );
  }

  void startWorkout() {
    _beginWorkout(routineName: 'Treino Livre', exercises: const <Exercise>[]);
  }

  void startRoutine(WorkoutRoutine routine) {
    _beginWorkout(routineName: routine.name, exercises: routine.exercises);
  }

  void _beginWorkout({
    required String routineName,
    required List<Exercise> exercises,
  }) {
    final workoutExercises = List<Exercise>.from(exercises);
    final session = ActiveWorkoutSession(
      id: 'active',
      routineName: routineName,
      startedAt: DateTime.now(),
      elapsedSeconds: 0,
      exercises: _buildActiveExercises(workoutExercises),
    );

    _activeSessionSnapshot = session;

    _setState(
      state.copyWith(
        isWorkoutActive: true,
        activeRoutineName: routineName,
        currentWorkoutExercises: workoutExercises,
        activeSession: session,
      ),
    );

    _startGlobalTimer();
    _persistActiveSession();
  }

  void _startGlobalTimer({int initialSeconds = 0}) {
    final durationController = ref.read(workoutDurationProvider.notifier);
    durationController.setSeconds(initialSeconds);

    _globalTimer?.cancel();

    _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }

      durationController.increment();

      final elapsedSeconds = ref.read(workoutDurationProvider);
      if (elapsedSeconds % 10 != 0) {
        return;
      }

      final session = _activeSessionSnapshot ?? state.activeSession;
      if (session == null) {
        return;
      }

      _activeSessionSnapshot = session.copyWith(elapsedSeconds: elapsedSeconds);

      _persistActiveSession();
    });
  }

  void addExerciseToWorkout(Exercise exercise) {
    final updatedExercises = <Exercise>[
      ...state.currentWorkoutExercises,
      exercise,
    ];

    final session = _activeSessionSnapshot ?? state.activeSession;
    final updatedSession = session?.copyWith(
      exercises: <ActiveWorkoutExercise>[
        ...session.exercises,
        _buildActiveExercise(exercise),
      ],
    );

    _activeSessionSnapshot = updatedSession;

    _setState(
      state.copyWith(
        currentWorkoutExercises: updatedExercises,
        activeSession: updatedSession,
      ),
    );

    _persistActiveSession();
  }

  void saveActiveSessionProgress({
    required Map<int, List<bool>> setsStatus,
    required Map<int, List<String>> weights,
    required Map<int, List<String>> reps,
    required String notes,
  }) {
    final session = _activeSessionSnapshot ?? state.activeSession;

    if (session == null) {
      return;
    }

    final updatedExercises = <ActiveWorkoutExercise>[];

    for (
      var exerciseIndex = 0;
      exerciseIndex < state.currentWorkoutExercises.length;
      exerciseIndex++
    ) {
      final exercise = state.currentWorkoutExercises[exerciseIndex];
      final completedValues = setsStatus[exerciseIndex] ?? const <bool>[];
      final weightValues = weights[exerciseIndex] ?? const <String>[];
      final repsValues = reps[exerciseIndex] ?? const <String>[];

      final expectedCount = <int>[
        completedValues.length,
        weightValues.length,
        repsValues.length,
        LegacyWorkoutMapper.parseExerciseConfig(
          reps: exercise.reps,
          rest: exercise.rest,
        ).seriesCount,
      ].reduce((a, b) => a > b ? a : b);

      final activeSets = List<ActiveWorkoutSet>.generate(
        expectedCount,
        (setIndex) => ActiveWorkoutSet(
          setNumber: setIndex + 1,
          weightText: setIndex < weightValues.length
              ? weightValues[setIndex]
              : '',
          repsText: setIndex < repsValues.length ? repsValues[setIndex] : '',
          isCompleted: setIndex < completedValues.length
              ? completedValues[setIndex]
              : false,
        ),
      );

      updatedExercises.add(
        ActiveWorkoutExercise(exercise: exercise, sets: activeSets),
      );
    }

    _activeSessionSnapshot = session.copyWith(
      elapsedSeconds: ref.read(workoutDurationProvider),
      notes: notes,
      exercises: updatedExercises,
    );

    _persistActiveSession();
  }

  void finishWorkout(
    String duration, {
    required bool isIncomplete,
    required List<ExerciseLog> logs,
    String notes = '',
  }) {
    if (logs.isNotEmpty) {
      _saveToHistory(
        state.activeRoutineName,
        duration,
        logs,
        notes,
        status: isIncomplete
            ? WorkoutSessionStatus.incomplete
            : WorkoutSessionStatus.completed,
      );
    }

    _endActiveWorkout();
  }

  void cancelWorkout() {
    _endActiveWorkout();
  }

  void _endActiveWorkout() {
    _globalTimer?.cancel();
    _restTimer?.cancel();
    _activeSessionSnapshot = null;
    ref.read(workoutDurationProvider.notifier).reset();

    _setState(
      state.copyWith(
        isWorkoutActive: false,
        currentWorkoutExercises: const <Exercise>[],
        activeSession: null,
        isResting: false,
        restSeconds: 0,
      ),
    );

    _persist(_repository.clearActiveSession, 'limpar sessão ativa');
  }

  Future<void> factoryReset() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.clear();
    await _repository.clearAll();

    _globalTimer?.cancel();
    _restTimer?.cancel();
    _activeSessionSnapshot = null;
    ref.read(workoutDurationProvider.notifier).reset();

    _setState(
      WorkoutState.initial(
        preMadePrograms: state.preMadePrograms,
      ).copyWith(isInitialized: true),
    );
  }

  List<ActiveWorkoutExercise> _buildActiveExercises(List<Exercise> exercises) {
    return exercises.map(_buildActiveExercise).toList();
  }

  ActiveWorkoutExercise _buildActiveExercise(Exercise exercise) {
    final config = LegacyWorkoutMapper.parseExerciseConfig(
      reps: exercise.reps,
      rest: exercise.rest,
    );

    return ActiveWorkoutExercise(
      exercise: exercise,
      sets: List<ActiveWorkoutSet>.generate(
        config.seriesCount,
        (index) => ActiveWorkoutSet(setNumber: index + 1),
      ),
    );
  }

  void _persistActiveSession() {
    final session = _activeSessionSnapshot ?? state.activeSession;

    if (session == null) {
      return;
    }

    _persist(
      () => _repository.saveActiveSession(session),
      'salvar sessão ativa',
    );
  }

  void _persist(Future<void> Function() operation, String label) {
    unawaited(
      (() async {
        try {
          await operation();
        } catch (error, stackTrace) {
          debugPrint('Erro ao $label: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      })(),
    );
  }

  void _setState(WorkoutState next) {
    if (_disposed) {
      return;
    }

    state = next;
  }
}
