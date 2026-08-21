import 'package:flutter/foundation.dart';

import 'active_workout_session.dart';

@immutable
class WorkoutSessionProgress {
  const WorkoutSessionProgress({
    required this.completedSets,
    required this.totalSets,
    required this.completedExercises,
    required this.totalExercises,
  });

  factory WorkoutSessionProgress.empty() {
    return const WorkoutSessionProgress(
      completedSets: 0,
      totalSets: 0,
      completedExercises: 0,
      totalExercises: 0,
    );
  }

  factory WorkoutSessionProgress.fromSession(ActiveWorkoutSession? session) {
    if (session == null) {
      return WorkoutSessionProgress.empty();
    }

    var completedSets = 0;
    var totalSets = 0;
    var completedExercises = 0;

    for (final exercise in session.exercises) {
      totalSets += exercise.sets.length;
      final exerciseCompletedSets = exercise.sets
          .where((set) => set.isCompleted)
          .length;
      completedSets += exerciseCompletedSets;

      if (exercise.sets.isNotEmpty &&
          exerciseCompletedSets == exercise.sets.length) {
        completedExercises++;
      }
    }

    return WorkoutSessionProgress(
      completedSets: completedSets,
      totalSets: totalSets,
      completedExercises: completedExercises,
      totalExercises: session.exercises.length,
    );
  }

  final int completedSets;
  final int totalSets;
  final int completedExercises;
  final int totalExercises;

  int get remainingSets =>
      (totalSets - completedSets).clamp(0, totalSets).toInt();

  double get fraction {
    if (totalSets == 0) {
      return 0;
    }

    return (completedSets / totalSets).clamp(0, 1).toDouble();
  }

  int get percentage => (fraction * 100).round();

  bool get hasProgress => completedSets > 0;

  bool get isComplete => totalSets > 0 && completedSets == totalSets;
}
