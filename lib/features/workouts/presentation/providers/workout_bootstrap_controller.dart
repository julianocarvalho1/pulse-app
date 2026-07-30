import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../models/exercise.dart';
import '../../domain/models/active_workout_session.dart';
import '../../domain/repositories/workout_repository.dart';
import 'workout_dependencies.dart';
import 'workout_history_controller.dart';
import 'workout_library_controller.dart';
import 'workout_session_controller.dart';

final workoutBootstrapControllerProvider =
    AsyncNotifierProvider<WorkoutBootstrapController, void>(
      WorkoutBootstrapController.new,
    );

class WorkoutBootstrapController extends AsyncNotifier<void> {
  static final RegExp _legacyBisetMarker = RegExp(
    r'\s*\+\s*BISET',
    caseSensitive: false,
  );

  WorkoutRepository get _repository => ref.read(workoutRepositoryProvider);

  @override
  Future<void> build() => _load();

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> factoryReset() async {
    final preferences = await SharedPreferences.getInstance();
    await ref
        .read(workoutSessionControllerProvider.notifier)
        .prepareForFactoryReset();
    await preferences.clear();
    await _repository.clearAll();

    ref.read(workoutLibraryControllerProvider.notifier).reset();
    ref.read(workoutHistoryControllerProvider.notifier).reset();
    state = const AsyncData<void>(null);
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final voiceAfterRest =
        preferences.getBool('settings_voice_after_rest') ??
        preferences.getBool('settings_vibrate_after_rest') ??
        true;

    await _repository.initialize();

    final customExercises = await _repository.loadCustomExercises();
    final loadedRoutines = await _repository.loadRoutines();
    final history = await _repository.loadHistory();
    final activeProgramName = await _repository.loadActiveProgramName();
    final loadedSession = await _repository.loadActiveSession();

    final hasLegacyRoutineBiset = _routinesContainLegacyBiset(loadedRoutines);
    final routines = hasLegacyRoutineBiset
        ? _normalizeLegacyBisetRoutines(loadedRoutines)
        : loadedRoutines;

    final hasLegacySessionBiset = _sessionContainsLegacyBiset(loadedSession);
    final restoredSession = hasLegacySessionBiset
        ? _normalizeLegacyBisetSession(loadedSession!)
        : loadedSession;

    if (hasLegacyRoutineBiset) {
      await _repository.saveRoutines(routines);
    }

    if (hasLegacySessionBiset && restoredSession != null) {
      await _repository.saveActiveSession(restoredSession);
    }

    ref
        .read(workoutLibraryControllerProvider.notifier)
        .hydrate(
          customExercises: customExercises,
          routines: routines,
          activeProgramName: activeProgramName,
        );
    ref.read(workoutHistoryControllerProvider.notifier).hydrate(history);
    ref
        .read(workoutSessionControllerProvider.notifier)
        .hydrate(restoredSession, voiceAfterRest: voiceAfterRest);
  }

  bool _routinesContainLegacyBiset(List<WorkoutRoutine> routines) {
    return routines.any(
      (routine) => routine.exercises.any(
        (exercise) => _legacyBisetMarker.hasMatch(exercise.reps),
      ),
    );
  }

  List<WorkoutRoutine> _normalizeLegacyBisetRoutines(
    List<WorkoutRoutine> routines,
  ) {
    return routines
        .map(
          (routine) => routine.copyWith(
            exercises: _normalizeLegacyBisetExercises(routine.exercises),
          ),
        )
        .toList();
  }

  List<Exercise> _normalizeLegacyBisetExercises(List<Exercise> exercises) {
    final normalized = List<Exercise>.from(exercises);

    for (var index = 0; index < normalized.length; index++) {
      final exercise = normalized[index];

      if (!_legacyBisetMarker.hasMatch(exercise.reps)) {
        continue;
      }

      normalized[index] = exercise.copyWith(
        reps: exercise.reps.replaceAll(_legacyBisetMarker, '').trim(),
      );

      if (index > 0) {
        normalized[index - 1] = normalized[index - 1].copyWith(
          isSuperset: true,
        );
      } else if (normalized.length > 1) {
        normalized[index] = normalized[index].copyWith(isSuperset: true);
      }
    }

    if (normalized.isNotEmpty && normalized.last.isSuperset) {
      normalized[normalized.length - 1] = normalized.last.copyWith(
        isSuperset: false,
      );
    }

    return normalized;
  }

  bool _sessionContainsLegacyBiset(ActiveWorkoutSession? session) {
    return session?.exercises.any(
          (item) => _legacyBisetMarker.hasMatch(item.exercise.reps),
        ) ??
        false;
  }

  ActiveWorkoutSession _normalizeLegacyBisetSession(
    ActiveWorkoutSession session,
  ) {
    final exercises = List<ActiveWorkoutExercise>.from(session.exercises);
    final normalizedModels = _normalizeLegacyBisetExercises(
      exercises.map((item) => item.exercise).toList(),
    );

    return session.copyWith(
      exercises: List<ActiveWorkoutExercise>.generate(
        exercises.length,
        (index) => exercises[index].copyWith(exercise: normalizedModels[index]),
      ),
    );
  }
}
