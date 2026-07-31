import '../../../workouts/domain/models/workout_history_item.dart';

class WorkoutPeriodStats {
  const WorkoutPeriodStats({
    required this.workouts,
    required this.completedWorkouts,
    required this.incompleteWorkouts,
    required this.activeDays,
    required this.durationSeconds,
    required this.totalSets,
    required this.totalReps,
    required this.totalVolume,
    required this.weeklyFrequency,
  });

  final int workouts;
  final int completedWorkouts;
  final int incompleteWorkouts;
  final int activeDays;
  final int durationSeconds;
  final int totalSets;
  final int totalReps;
  final double totalVolume;
  final double weeklyFrequency;

  bool get isEmpty => workouts == 0;
}

class ProgressComparison {
  const ProgressComparison({
    required this.workoutsChange,
    required this.activeDaysChange,
    required this.durationChange,
    required this.volumeChange,
  });

  final double? workoutsChange;
  final double? activeDaysChange;
  final double? durationChange;
  final double? volumeChange;
}

class WeeklyProgressPoint {
  const WeeklyProgressPoint({
    required this.weekStart,
    required this.workouts,
    required this.volume,
    required this.durationSeconds,
  });

  final DateTime weekStart;
  final int workouts;
  final double volume;
  final int durationSeconds;
}

class PersonalRecord {
  const PersonalRecord({
    required this.exerciseKey,
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.date,
  });

  final String exerciseKey;
  final String exerciseName;
  final double weight;
  final int reps;
  final DateTime date;
}

class ExerciseProgressPoint {
  const ExerciseProgressPoint({
    required this.date,
    required this.maxWeight,
    required this.totalVolume,
    required this.totalReps,
  });

  final DateTime date;
  final double maxWeight;
  final double totalVolume;
  final int totalReps;
}

class ExerciseProgressSummary {
  const ExerciseProgressSummary({
    required this.exerciseKey,
    required this.exerciseName,
    required this.points,
  });

  final String exerciseKey;
  final String exerciseName;
  final List<ExerciseProgressPoint> points;

  double get latestWeight => points.isEmpty ? 0 : points.last.maxWeight;

  double get previousWeight {
    return points.length < 2 ? 0 : points[points.length - 2].maxWeight;
  }

  double get latestVolume => points.isEmpty ? 0 : points.last.totalVolume;

  double? get weightChange {
    if (points.length < 2) {
      return null;
    }
    final previous = previousWeight;
    if (previous <= 0) {
      return latestWeight > 0 ? null : 0;
    }
    return ((latestWeight - previous) / previous) * 100;
  }
}

class WorkoutDaySummary {
  const WorkoutDaySummary({
    required this.date,
    required this.items,
    required this.completedCount,
    required this.incompleteCount,
  });

  final DateTime date;
  final List<WorkoutHistoryItem> items;
  final int completedCount;
  final int incompleteCount;

  int get total => completedCount + incompleteCount;
  bool get hasCompleted => completedCount > 0;
  bool get hasIncomplete => incompleteCount > 0;
}

class WorkoutProgressSummary {
  const WorkoutProgressSummary({
    required this.workouts,
    required this.current,
    required this.previous,
    required this.comparison,
    required this.weeklyPoints,
    required this.personalRecords,
    required this.exerciseProgress,
    required this.currentStreak,
    required this.longestStreak,
  });

  final List<WorkoutHistoryItem> workouts;
  final WorkoutPeriodStats current;
  final WorkoutPeriodStats? previous;
  final ProgressComparison? comparison;
  final List<WeeklyProgressPoint> weeklyPoints;
  final List<PersonalRecord> personalRecords;
  final List<ExerciseProgressSummary> exerciseProgress;
  final int currentStreak;
  final int longestStreak;
}
