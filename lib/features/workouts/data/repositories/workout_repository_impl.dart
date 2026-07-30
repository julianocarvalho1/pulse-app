import '../../../../core/database/pulse_database.dart';
import '../../../../models/exercise.dart';
import '../../domain/models/active_workout_session.dart';
import '../../domain/models/exercise_log.dart';
import '../../domain/models/workout_history_item.dart';
import '../../domain/models/workout_session_status.dart';
import '../../domain/repositories/workout_repository.dart';
import '../services/workout_legacy_migration_service.dart';
import '../services/workout_local_service.dart';

class WorkoutRepositoryImpl implements WorkoutRepository {
  factory WorkoutRepositoryImpl({
    PulseDatabase? database,
    WorkoutLocalService? localService,
    WorkoutLegacyMigrationService? migrationService,
  }) {
    final resolvedLocalService =
        localService ?? WorkoutLocalService(database ?? PulseDatabase());

    return WorkoutRepositoryImpl._(resolvedLocalService, migrationService);
  }

  WorkoutRepositoryImpl._(this._localService, this._migrationService);

  final WorkoutLocalService _localService;
  final WorkoutLegacyMigrationService? _migrationService;

  WorkoutLegacyMigrationService get _migration =>
      _migrationService ??
      WorkoutLegacyMigrationService(localService: _localService);

  @override
  Future<void> initialize() async {
    await _localService.initialize();
    await _migration.migrateIfNeeded();
  }

  @override
  Future<List<Exercise>> loadCustomExercises() {
    return _localService.loadCustomExercises();
  }

  @override
  Future<List<WorkoutRoutine>> loadRoutines() {
    return _localService.loadRoutines();
  }

  @override
  Future<List<WorkoutHistoryItem>> loadHistory() {
    return _localService.loadHistory();
  }

  @override
  Future<String> loadActiveProgramName() {
    return _localService.loadActiveProgramName();
  }

  @override
  Future<void> saveCustomExercises(List<Exercise> exercises) {
    return _localService.saveCustomExercises(exercises);
  }

  @override
  Future<void> saveRoutines(List<WorkoutRoutine> routines) {
    return _localService.saveRoutines(routines);
  }

  @override
  Future<void> saveHistory(List<WorkoutHistoryItem> history) {
    return _localService.saveHistory(history);
  }

  @override
  Future<void> saveActiveProgramName(String programName) {
    return _localService.saveActiveProgramName(programName);
  }

  @override
  Future<void> saveCompletedWorkout({
    required String routineName,
    required String duration,
    required List<ExerciseLog> exercises,
    required String notes,
    required bool isIncomplete,
  }) {
    return _localService.insertHistoryItem(
      WorkoutHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        routineName: routineName.isEmpty ? 'Treino Avulso' : routineName,
        date: DateTime.now(),
        duration: duration,
        exercises: exercises,
        notes: notes,
        status: isIncomplete
            ? WorkoutSessionStatus.incomplete
            : WorkoutSessionStatus.completed,
      ),
    );
  }

  @override
  Future<ActiveWorkoutSession?> loadActiveSession() {
    return _localService.loadActiveSession();
  }

  @override
  Future<void> saveActiveSession(ActiveWorkoutSession session) {
    return _localService.saveActiveSession(session);
  }

  @override
  Future<void> clearActiveSession() {
    return _localService.clearActiveSession();
  }

  @override
  Future<void> clearAll() {
    return _localService.clearWorkoutData();
  }
}
