class PulseBackupPreview {
  const PulseBackupPreview({
    required this.createdAt,
    required this.routineCount,
    required this.workoutCount,
    required this.measurementCount,
    required this.customExerciseCount,
  });

  final DateTime createdAt;
  final int routineCount;
  final int workoutCount;
  final int measurementCount;
  final int customExerciseCount;
}

class PulseBackupException implements Exception {
  const PulseBackupException(this.message);

  final String message;

  @override
  String toString() => message;
}
