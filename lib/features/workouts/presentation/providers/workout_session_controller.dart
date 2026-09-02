import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/exercise.dart';
import '../../data/mappers/legacy_workout_mapper.dart';
import '../../data/services/workout_feedback_service.dart';
import '../../domain/models/active_workout_session.dart';
import '../../domain/models/cardio_log.dart';
import '../../domain/models/exercise_log.dart';
import '../../domain/models/workout_session_progress.dart';
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

final workoutSessionProgressProvider = Provider<WorkoutSessionProgress>((ref) {
  final session = ref.watch(
    workoutSessionControllerProvider.select((state) => state.activeSession),
  );
  return WorkoutSessionProgress.fromSession(session);
});

enum RestStartOutcome {
  started,
  skippedForSuperset,
  waitingForSupersetPair,
  unavailable,
}

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
  DateTime? _restEndsAt;
  ActiveWorkoutSession? _activeSessionSnapshot;
  Future<void> _persistenceQueue = Future<void>.value();

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
    _restEndsAt = null;
    ref.read(workoutDurationProvider.notifier).reset();

    var restoredRestSeconds = 0;
    var restoredRestPaused = false;
    var restoredResting = false;
    var normalizedSession = session;

    if (session != null && session.isRestPaused && session.restSeconds > 0) {
      restoredRestSeconds = session.restSeconds;
      restoredRestPaused = true;
      restoredResting = true;
    } else if (session?.restEndsAt != null) {
      final remaining = _remainingRestSeconds(session!.restEndsAt!);
      if (remaining > 0) {
        restoredRestSeconds = remaining;
        restoredResting = true;
        _restEndsAt = session.restEndsAt;
      } else {
        normalizedSession = session.copyWith(
          restSeconds: 0,
          clearRestEndsAt: true,
          isRestPaused: false,
        );
      }
    }

    _activeSessionSnapshot = normalizedSession;

    state = WorkoutSessionState(
      voiceAfterRest: voiceAfterRest,
      isWorkoutActive: normalizedSession != null,
      exercises:
          normalizedSession?.exercises.map((item) => item.exercise).toList() ??
          const <Exercise>[],
      routineName: normalizedSession?.routineName ?? 'Treino do Dia',
      activeSession: normalizedSession,
      isResting: restoredResting,
      isRestPaused: restoredRestPaused,
      restSeconds: restoredRestSeconds,
      isFinishing: false,
    );

    if (normalizedSession != null) {
      _startGlobalTimer(initialSeconds: normalizedSession.elapsedSeconds);
      if (restoredResting && !restoredRestPaused) {
        _startRestCountdown();
      }
      if (!identical(normalizedSession, session)) {
        unawaited(_persistActiveSession());
      }
    }
  }

  void reset() {
    final voiceAfterRest = state.voiceAfterRest;
    _globalTimer?.cancel();
    _restTimer?.cancel();
    _restEndsAt = null;
    _activeSessionSnapshot = null;
    ref.read(workoutDurationProvider.notifier).reset();
    state = WorkoutSessionState.initial(voiceAfterRest: voiceAfterRest);
  }

  Future<void> prepareForFactoryReset() async {
    _globalTimer?.cancel();
    _restTimer?.cancel();
    _restEndsAt = null;
    await _persistenceQueue;
    _activeSessionSnapshot = null;
    ref.read(workoutDurationProvider.notifier).reset();
    state = WorkoutSessionState.initial();
  }

  void startRestTimer(String restString) {
    final seconds = LegacyWorkoutMapper.parseRestSeconds(restString);
    _startRestWithSeconds(seconds);
  }

  RestStartOutcome startRestAfterSet(int exerciseIndex, {int? setIndex}) {
    if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) {
      return RestStartOutcome.unavailable;
    }

    final session = activeSession;

    bool isPairSetCompleted(int pairedExerciseIndex) {
      return session != null &&
          setIndex != null &&
          pairedExerciseIndex >= 0 &&
          pairedExerciseIndex < session.exercises.length &&
          setIndex < session.exercises[pairedExerciseIndex].sets.length &&
          session.exercises[pairedExerciseIndex].sets[setIndex].isCompleted;
    }

    final exercise = state.exercises[exerciseIndex];
    final startsSuperset =
        exercise.isSuperset && exerciseIndex < state.exercises.length - 1;
    final continuesSuperset =
        exerciseIndex > 0 && state.exercises[exerciseIndex - 1].isSuperset;

    var restText = exercise.rest;
    var prescribedRestSeconds =
        session != null &&
            setIndex != null &&
            exerciseIndex < session.exercises.length &&
            setIndex < session.exercises[exerciseIndex].sets.length
        ? session.exercises[exerciseIndex].sets[setIndex].prescribedRestSeconds
        : null;

    if (startsSuperset) {
      final nextExerciseIndex = exerciseIndex + 1;

      if (!isPairSetCompleted(nextExerciseIndex)) {
        stopRestTimer();
        return RestStartOutcome.skippedForSuperset;
      }

      final nextExerciseRest = state.exercises[nextExerciseIndex].rest;
      if (nextExerciseRest.trim().isNotEmpty) {
        restText = nextExerciseRest;
      }
      prescribedRestSeconds =
          session != null &&
              setIndex != null &&
              nextExerciseIndex < session.exercises.length &&
              setIndex < session.exercises[nextExerciseIndex].sets.length
          ? session
                .exercises[nextExerciseIndex]
                .sets[setIndex]
                .prescribedRestSeconds
          : prescribedRestSeconds;
    } else if (continuesSuperset) {
      final previousExerciseIndex = exerciseIndex - 1;

      if (!isPairSetCompleted(previousExerciseIndex)) {
        stopRestTimer();
        return RestStartOutcome.waitingForSupersetPair;
      }

      if (restText.trim().isEmpty) {
        restText = state.exercises[previousExerciseIndex].rest;
      }
    }

    final seconds = prescribedRestSeconds != null && prescribedRestSeconds > 0
        ? prescribedRestSeconds
        : LegacyWorkoutMapper.parseRestSeconds(restText);
    if (seconds <= 0) {
      return RestStartOutcome.unavailable;
    }

    _startRestWithSeconds(seconds);
    return RestStartOutcome.started;
  }

  void _startRestWithSeconds(int seconds) {
    if (seconds <= 0) {
      return;
    }

    _restTimer?.cancel();
    _restEndsAt = DateTime.now().add(Duration(seconds: seconds));
    state = state.copyWith(
      isResting: true,
      isRestPaused: false,
      restSeconds: seconds,
    );
    _persistRestState(
      restSeconds: seconds,
      restEndsAt: _restEndsAt,
      isRestPaused: false,
    );

    _startRestCountdown();
  }

  void _startRestCountdown() {
    _restTimer?.cancel();

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }

      final restEndsAt = _restEndsAt;
      final remaining = restEndsAt == null
          ? state.restSeconds - 1
          : _remainingRestSeconds(restEndsAt);

      if (remaining <= 0) {
        stopRestTimer();
        unawaited(_playAlarm());
        return;
      }

      if (remaining != state.restSeconds) {
        state = state.copyWith(restSeconds: remaining);
      }
    });
  }

  void pauseRestTimer() {
    if (!state.isResting || state.isRestPaused) {
      return;
    }

    _restTimer?.cancel();
    final remaining = _restEndsAt == null
        ? state.restSeconds
        : _remainingRestSeconds(_restEndsAt!);
    _restEndsAt = null;

    if (remaining <= 0) {
      stopRestTimer();
      unawaited(_playAlarm());
      return;
    }

    state = state.copyWith(isRestPaused: true, restSeconds: remaining);
    _persistRestState(
      restSeconds: remaining,
      restEndsAt: null,
      isRestPaused: true,
    );
  }

  void resumeRestTimer() {
    if (!state.isResting || !state.isRestPaused || state.restSeconds <= 0) {
      return;
    }

    _restEndsAt = DateTime.now().add(Duration(seconds: state.restSeconds));
    state = state.copyWith(isRestPaused: false);
    _persistRestState(
      restSeconds: state.restSeconds,
      restEndsAt: _restEndsAt,
      isRestPaused: false,
    );
    _startRestCountdown();
  }

  void addRestSeconds(int seconds) {
    if (!state.isResting || seconds == 0) {
      return;
    }

    final currentValue = state.isRestPaused || _restEndsAt == null
        ? state.restSeconds
        : _remainingRestSeconds(_restEndsAt!);
    final nextValue = (currentValue + seconds).clamp(1, 3600).toInt();
    if (!state.isRestPaused) {
      _restEndsAt = DateTime.now().add(Duration(seconds: nextValue));
    }
    state = state.copyWith(restSeconds: nextValue);
    _persistRestState(
      restSeconds: nextValue,
      restEndsAt: _restEndsAt,
      isRestPaused: state.isRestPaused,
    );
  }

  void stopRestTimer() {
    _restTimer?.cancel();
    _restEndsAt = null;

    if (!state.isResting && state.restSeconds == 0) {
      return;
    }

    state = state.copyWith(
      isResting: false,
      isRestPaused: false,
      restSeconds: 0,
    );
    _persistRestState(restSeconds: 0, restEndsAt: null, isRestPaused: false);
  }

  int _remainingRestSeconds(DateTime restEndsAt) {
    final milliseconds = restEndsAt.difference(DateTime.now()).inMilliseconds;
    if (milliseconds <= 0) {
      return 0;
    }
    return (milliseconds + 999) ~/ 1000;
  }

  void _persistRestState({
    required int restSeconds,
    required DateTime? restEndsAt,
    required bool isRestPaused,
  }) {
    final session = activeSession;
    if (session == null) {
      return;
    }

    _activeSessionSnapshot = session.copyWith(
      elapsedSeconds: ref.read(workoutDurationProvider),
      restSeconds: restSeconds,
      restEndsAt: restEndsAt,
      clearRestEndsAt: restEndsAt == null,
      isRestPaused: isRestPaused,
    );
    state = state.copyWith(activeSession: _activeSessionSnapshot);
    unawaited(_persistActiveSession());
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

  bool startWorkout({bool replaceActive = false}) {
    return _beginWorkout(
      routineName: 'Treino Livre',
      exercises: const <Exercise>[],
      cardio: const <RoutineCardio>[],
      replaceActive: replaceActive,
    );
  }

  bool startRoutine(WorkoutRoutine routine, {bool replaceActive = false}) {
    return _beginWorkout(
      routineName: routine.name,
      exercises: routine.exercises,
      cardio: routine.cardio,
      replaceActive: replaceActive,
    );
  }

  bool _beginWorkout({
    required String routineName,
    required List<Exercise> exercises,
    required List<RoutineCardio> cardio,
    required bool replaceActive,
  }) {
    if (state.isWorkoutActive && !replaceActive) {
      return false;
    }

    _globalTimer?.cancel();
    _restTimer?.cancel();
    _restEndsAt = null;

    final now = DateTime.now();
    final workoutExercises = List<Exercise>.from(exercises);
    final session = ActiveWorkoutSession(
      id: 'session-${now.millisecondsSinceEpoch}',
      routineName: routineName,
      startedAt: now,
      elapsedSeconds: 0,
      exercises: _buildActiveExercises(workoutExercises),
      cardio: cardio.map(ActiveCardioEntry.fromRoutine).toList(growable: false),
    );

    _activeSessionSnapshot = session;
    state = state.copyWith(
      isWorkoutActive: true,
      routineName: routineName,
      exercises: workoutExercises,
      activeSession: session,
      isResting: false,
      restSeconds: 0,
      isFinishing: false,
    );

    _startGlobalTimer();
    unawaited(_persistActiveSession());
    return true;
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
      state = state.copyWith(activeSession: _activeSessionSnapshot);
      unawaited(_persistActiveSession());
    });
  }

  void replaceExerciseInActiveWorkout(int index, Exercise replacement) {
    final session = activeSession;
    if (session == null ||
        index < 0 ||
        index >= state.exercises.length ||
        index >= session.exercises.length) {
      return;
    }

    final updatedExercises = List<Exercise>.from(state.exercises);
    updatedExercises[index] = replacement;
    final updatedSessionExercises = List<ActiveWorkoutExercise>.from(
      session.exercises,
    );
    updatedSessionExercises[index] = updatedSessionExercises[index].copyWith(
      exercise: replacement,
    );

    _activeSessionSnapshot = session.copyWith(
      elapsedSeconds: ref.read(workoutDurationProvider),
      exercises: updatedSessionExercises,
    );
    state = state.copyWith(
      exercises: updatedExercises,
      activeSession: _activeSessionSnapshot,
    );
    unawaited(_persistActiveSession());
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
    unawaited(_persistActiveSession());
  }

  void updateActiveCardio(ActiveCardioEntry entry) {
    final session = activeSession;

    if (session == null) {
      return;
    }

    final index = session.cardio.indexWhere((item) => item.id == entry.id);
    if (index < 0) {
      return;
    }

    final updatedCardio = List<ActiveCardioEntry>.from(session.cardio);
    updatedCardio[index] = entry;
    _activeSessionSnapshot = session.copyWith(
      elapsedSeconds: ref.read(workoutDurationProvider),
      cardio: updatedCardio,
    );
    state = state.copyWith(activeSession: _activeSessionSnapshot);
    unawaited(_persistActiveSession());
  }

  void updateExerciseSessionDetails(
    int exerciseIndex, {
    required String notes,
    required bool isLoadComparable,
    required int? perceivedRir,
  }) {
    final session = activeSession;
    if (session == null ||
        exerciseIndex < 0 ||
        exerciseIndex >= session.exercises.length) {
      return;
    }

    final updatedExercises = List<ActiveWorkoutExercise>.from(
      session.exercises,
    );
    updatedExercises[exerciseIndex] = updatedExercises[exerciseIndex].copyWith(
      sessionNotes: notes.trim(),
      isLoadComparable: isLoadComparable,
      perceivedRir: perceivedRir,
      clearPerceivedRir: perceivedRir == null,
    );

    _activeSessionSnapshot = session.copyWith(
      elapsedSeconds: ref.read(workoutDurationProvider),
      exercises: updatedExercises,
    );
    state = state.copyWith(activeSession: _activeSessionSnapshot);
    unawaited(_persistActiveSession());
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

      final prescribedSets = _prescribedSetsForExercise(exercise);
      final restoredExercise = session.exercises.length > exerciseIndex
          ? session.exercises[exerciseIndex]
          : null;
      final restoredSets = restoredExercise?.sets ?? const <ActiveWorkoutSet>[];
      final expectedCount = <int>[
        completedValues.length,
        weightValues.length,
        repsValues.length,
        restoredSets.length,
        prescribedSets.length,
      ].reduce((a, b) => a > b ? a : b);

      final activeSets = List<ActiveWorkoutSet>.generate(expectedCount, (
        setIndex,
      ) {
        final prescription = setIndex < restoredSets.length
            ? restoredSets[setIndex]
            : setIndex < prescribedSets.length
            ? prescribedSets[setIndex]
            : ActiveWorkoutSet(setNumber: setIndex + 1);
        return prescription.copyWith(
          setNumber: setIndex + 1,
          weightText: setIndex < weightValues.length
              ? weightValues[setIndex]
              : prescription.weightText,
          repsText: setIndex < repsValues.length
              ? repsValues[setIndex]
              : prescription.repsText,
          isCompleted: setIndex < completedValues.length
              ? completedValues[setIndex]
              : prescription.isCompleted,
        );
      });

      updatedExercises.add(
        ActiveWorkoutExercise(
          exercise: exercise,
          sets: activeSets,
          sessionNotes: restoredExercise?.sessionNotes ?? '',
          isLoadComparable: restoredExercise?.isLoadComparable ?? true,
          perceivedRir: restoredExercise?.perceivedRir,
        ),
      );
    }

    _activeSessionSnapshot = session.copyWith(
      elapsedSeconds: ref.read(workoutDurationProvider),
      notes: notes,
      exercises: updatedExercises,
    );
    state = state.copyWith(activeSession: _activeSessionSnapshot);
    unawaited(_persistActiveSession());
  }

  Future<bool> finishWorkout(
    String duration, {
    required bool isIncomplete,
    required List<ExerciseLog> logs,
    List<CardioLog> cardio = const <CardioLog>[],
    String notes = '',
  }) async {
    final session = activeSession;

    if (session == null ||
        state.isFinishing ||
        (logs.isEmpty && cardio.isEmpty)) {
      return false;
    }

    state = state.copyWith(isFinishing: true);
    final progress = WorkoutSessionProgress.fromSession(session);
    final strengthComplete = session.exercises.isEmpty || progress.isComplete;
    final cardioComplete =
        session.cardio.isEmpty ||
        session.cardio.every((entry) => entry.isCompleted);
    final effectiveIncomplete =
        isIncomplete || !strengthComplete || !cardioComplete;

    try {
      await ref
          .read(workoutHistoryControllerProvider.notifier)
          .addWorkout(
            id: session.startedAt.millisecondsSinceEpoch.toString(),
            routineName: state.routineName,
            duration: duration,
            exercises: logs,
            cardio: cardio,
            notes: notes,
            status: effectiveIncomplete
                ? WorkoutSessionStatus.incomplete
                : WorkoutSessionStatus.completed,
          );

      await _endActiveWorkout();
      return true;
    } catch (error, stackTrace) {
      debugPrint('Erro ao finalizar treino: $error');
      debugPrintStack(stackTrace: stackTrace);
      state = state.copyWith(isFinishing: false);
      return false;
    }
  }

  Future<void> cancelWorkout() {
    return _endActiveWorkout();
  }

  Future<void> _endActiveWorkout() async {
    final voiceAfterRest = state.voiceAfterRest;
    final repository = _repository;

    _globalTimer?.cancel();
    _restTimer?.cancel();
    _restEndsAt = null;
    _activeSessionSnapshot = null;
    ref.read(workoutDurationProvider.notifier).reset();

    await _persistenceQueue;

    if (_disposed) {
      return;
    }

    await repository.clearActiveSession();

    if (_disposed) {
      return;
    }

    state = WorkoutSessionState.initial(voiceAfterRest: voiceAfterRest);
  }

  List<ActiveWorkoutExercise> _buildActiveExercises(List<Exercise> exercises) {
    return exercises.map(_buildActiveExercise).toList();
  }

  ActiveWorkoutExercise _buildActiveExercise(Exercise exercise) {
    return ActiveWorkoutExercise(
      exercise: exercise,
      sets: _prescribedSetsForExercise(exercise),
    );
  }

  List<ActiveWorkoutSet> _prescribedSetsForExercise(Exercise exercise) {
    final advancedWeek = exercise.advancedPrescription.primaryPrescription;
    if (advancedWeek != null && advancedWeek.sets.isNotEmpty) {
      return <ActiveWorkoutSet>[
        for (var index = 0; index < advancedWeek.sets.length; index++)
          ActiveWorkoutSet(
            setNumber: index + 1,
            targetText: advancedWeek.sets[index].target,
            targetRir: advancedWeek.sets[index].targetRir,
            cadence: advancedWeek.sets[index].cadence,
            technique: advancedWeek.sets[index].technique,
            prescribedRestSeconds: advancedWeek.sets[index].restSeconds,
            prescriptionNotes: advancedWeek.sets[index].notes,
          ),
      ];
    }

    final config = LegacyWorkoutMapper.parseExerciseConfig(
      reps: exercise.reps,
      rest: exercise.rest,
    );
    return List<ActiveWorkoutSet>.generate(
      config.seriesCount,
      (index) => ActiveWorkoutSet(setNumber: index + 1),
    );
  }

  Future<void> _persistActiveSession() {
    final session = activeSession;

    if (session == null) {
      return Future<void>.value();
    }

    final repository = _repository;

    _persistenceQueue = _persistenceQueue.then((_) async {
      if (_disposed) {
        return;
      }

      try {
        await repository.saveActiveSession(session);
      } catch (error, stackTrace) {
        debugPrint('Erro ao salvar sessão ativa: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    });

    return _persistenceQueue;
  }
}
