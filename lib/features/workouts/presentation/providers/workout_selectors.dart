import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/exercise.dart';
import '../../../settings/domain/pulse_settings.dart';
import '../../../settings/presentation/providers/settings_controller.dart';
import '../../domain/models/active_workout_session.dart';
import '../../domain/models/exercise_progression_suggestion.dart';
import '../../domain/services/workout_progression_service.dart';
import '../../domain/models/workout_history_item.dart';
import 'workout_history_controller.dart';
import 'workout_library_controller.dart';
import 'workout_session_controller.dart';

final workoutRoutinesProvider = Provider<List<WorkoutRoutine>>(
  (ref) => ref.watch(workoutLibraryControllerProvider).routines,
);

final workoutAllExercisesProvider = Provider<List<Exercise>>(
  (ref) => ref.watch(workoutLibraryControllerProvider).allExercises,
);

final workoutHistoryItemsProvider = Provider<List<WorkoutHistoryItem>>(
  (ref) => ref.watch(workoutHistoryControllerProvider).items,
);

final activeWorkoutSessionProvider = Provider<ActiveWorkoutSession?>(
  (ref) => ref.watch(workoutSessionControllerProvider).activeSession,
);

final nextRoutineToTrainProvider = Provider<WorkoutRoutine?>((ref) {
  final library = ref.watch(workoutLibraryControllerProvider);
  final history = ref.watch(workoutHistoryControllerProvider).items;

  if (library.activeProgramName.isEmpty) {
    return null;
  }

  final routines =
      library.routines
          .where((routine) => routine.groupName == library.activeProgramName)
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  if (routines.isEmpty) {
    return null;
  }

  WorkoutHistoryItem? lastProgramWorkout;
  for (final item in history) {
    if (routines.any((routine) => routine.name == item.routineName)) {
      lastProgramWorkout = item;
      break;
    }
  }

  if (lastProgramWorkout == null) {
    return routines.first;
  }

  final lastIndex = routines.indexWhere(
    (routine) => routine.name == lastProgramWorkout!.routineName,
  );

  if (lastIndex < 0) {
    return routines.first;
  }

  return routines[(lastIndex + 1) % routines.length];
});

final exerciseProgressionProvider =
    Provider.family<ExerciseProgressionSuggestion, Exercise>((ref, exercise) {
      final history = ref.watch(workoutHistoryControllerProvider).items;
      final settingsAsync = ref.watch(settingsControllerProvider);
      final progressionMode = switch (settingsAsync) {
        AsyncData<PulseSettings>(:final value) => value.workoutProgressionMode,
        _ => PulseSettings.defaults().workoutProgressionMode,
      };
      return const WorkoutProgressionService().buildSuggestion(
        exercise: exercise,
        history: history,
        mode: progressionMode,
      );
    });
