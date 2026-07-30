import '../../../../models/exercise.dart';
import '../models/exercise_log.dart';
import '../models/workout_history_item.dart';

abstract interface class WorkoutRepository {
  Future<List<Exercise>> loadCustomExercises();

  Future<List<WorkoutRoutine>> loadRoutines();

  Future<List<WorkoutHistoryItem>> loadHistory();

  Future<String> loadActiveProgramName();

  Future<void> saveCustomExercises(List<Exercise> exercises);

  Future<void> saveRoutines(List<WorkoutRoutine> routines);

  Future<void> saveHistory(List<WorkoutHistoryItem> history);

  Future<void> saveActiveProgramName(String programName);

  Future<void> saveCompletedWorkout({
    required String routineName,
    required String duration,
    required List<ExerciseLog> exercises,
    required String notes,
    required bool isIncomplete,
  });

  Future<void> clearAll();
}
