import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/exercise.dart';
import '../../data/mappers/legacy_workout_mapper.dart';
import '../../data/services/workout_feedback_service.dart';
import '../../domain/models/active_workout_session.dart';
import '../../domain/models/exercise_log.dart';
import '../../domain/models/workout_session_status.dart';
import '../../domain/repositories/workout_repository.dart';
import '../state/workout_session_state.dart';
import 'workout_dependencies.dart';
import 'workout_history_controller.dart';

final workoutDurationProvider =
    NotifierProvider<WorkoutDurationController, int>(
      WorkoutDurationController.new,
    );

final workoutSessionControllerProvider =
    NotifierProvider<WorkoutSessionController, WorkoutSessionState>(
      WorkoutSessionController.new,
    );

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

class WorkoutSessionController extends Notifier<WorkoutSessionState> {
  bool _disposed = false;
  Timer? _globalTimer;
  Timer? _restTimer;
  ActiveWorkoutSession? _activeSessionSnapshot;

  WorkoutRepository get _repository => ref.read(workoutRepositoryProvider);

  WorkoutFeedbackService get _feedbackService =>
      ref.read(workoutFeedbackServiceProvider);

  ActiveWorkoutSession? get activeSession =>
      _activeSessionSnapshot ?? state.activeSession;

  @override
  WorkoutSessionState build() {
    _disposed = false;

    ref.onDispose(() {
      _disposed = true;
      _globalTimer?.cancel();
      _restTimer?.cancel();
    });

    unawaited(_configureFeedback());
    return WorkoutSessionState.initial();
  }

  Future<void> _configureFeedback() async {
    try {
      await _feedbackService.configure();
    } catch (error) {
      debugPrint('Não foi possível configurar os alertas do treino: $error');
    }
  }

  void hydrate(ActiveWorkoutSession? session, {required bool voiceAfterRest}) {
    _globalTimer?.cancel();
    _restTimer?.cancel();
    ref.read(workoutDurationProvider.notifier).reset();
    _activeSessionSnapshot = session;

    state = WorkoutSessionState(
      voiceAfterRest: voiceAfterRest,
      isWorkoutActive: session != null,
      exercises:
          session?.exercises.map((item) => item.exercise).toList() ??
          const <Exercise>[],
      routineName: session?.routineName ?? 'Treino do Dia',
      activeSession: session,
      isResting: false,
      restSeconds: 0,
    );

    if (session != null) {
      _startGlobalTimer(initialSeconds: session.elapsedSeconds);
    }
  }

  void reset() {
    _globalTimer?.cancel();
    _restTimer?.cancel();
    _activeSessionSnapshot = null;
    ref.read(workoutDurationProvider.notifier).reset();
    state = WorkoutSessionState.initial();
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
    state = state.copyWith(isResting: true, restSeconds: seconds);

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }

      if (state.restSeconds > 0) {
        state = state.copyWith(restSeconds: state.restSeconds - 1);
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

    state = state.copyWith(isResting: false, restSeconds: 0);
  }

  Future<void> _playAlarm() {
    return _feedbackService.playRestFinished(enabled: state.voiceAfterRest);
  }

  void setVoiceAfterRest(bool enabled) {
    if (state.voiceAfterRest == enabled) {
      return;
    }

    state = state.copyWith(voiceAfterRest: enabled);
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
    state = state.copyWith(
      isWorkoutActive: true,
      routineName: routineName,
      exercises: workoutExercises,
      activeSession: session,
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

      final session = activeSession;
      if (session == null) {
        return;
      }

      _activeSessionSnapshot = session.copyWith(elapsedSeconds: elapsedSeconds);
      _persistActiveSession();
    });
  }

  void addExerciseToWorkout(Exercise exercise) {
    final updatedExercises = <Exercise>[...state.exercises, exercise];
    final session = activeSession;
    final updatedSession = session?.copyWith(
      exercises: <ActiveWorkoutExercise>[
        ...session.exercises,
        _buildActiveExercise(exercise),
      ],
    );

    _activeSessionSnapshot = updatedSession;
    state = state.copyWith(
      exercises: updatedExercises,
      activeSession: updatedSession,
    );
    _persistActiveSession();
  }

  void saveActiveSessionProgress({
    required Map<int, List<bool>> setsStatus,
    required Map<int, List<String>> weights,
    required Map<int, List<String>> reps,
    required String notes,
  }) {
    final session = activeSession;

    if (session == null) {
      return;
    }

    final updatedExercises = <ActiveWorkoutExercise>[];

    for (
      var exerciseIndex = 0;
      exerciseIndex < state.exercises.length;
      exerciseIndex++
    ) {
      final exercise = state.exercises[exerciseIndex];
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
    state = state.copyWith(activeSession: _activeSessionSnapshot);
    _persistActiveSession();
  }

  void finishWorkout(
    String duration, {
    required bool isIncomplete,
    required List<ExerciseLog> logs,
    String notes = '',
  }) {
    if (logs.isNotEmpty) {
      ref
          .read(workoutHistoryControllerProvider.notifier)
          .addWorkout(
            routineName: state.routineName,
            duration: duration,
            exercises: logs,
            notes: notes,
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

    state = state.copyWith(
      isWorkoutActive: false,
      exercises: const <Exercise>[],
      activeSession: null,
      isResting: false,
      restSeconds: 0,
    );

    _persist(_repository.clearActiveSession, 'limpar sessão ativa');
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
    final session = activeSession;

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
}
