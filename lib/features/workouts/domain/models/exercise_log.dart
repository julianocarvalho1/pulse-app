import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'workout_set.dart';

@immutable
class ExerciseLog {
  ExerciseLog({
    required this.exerciseId,
    required this.exerciseName,
    required List<ExerciseSet> sets,
  }) : sets = UnmodifiableListView<ExerciseSet>(List<ExerciseSet>.from(sets));

  final String exerciseId;
  final String exerciseName;
  final List<ExerciseSet> sets;

  int get totalReps {
    return sets.fold<int>(0, (total, set) => total + set.reps);
  }

  double get totalVolume {
    return sets.fold<double>(0, (total, set) => total + set.volume);
  }

  ExerciseLog copyWith({
    String? exerciseId,
    String? exerciseName,
    List<ExerciseSet>? sets,
  }) {
    return ExerciseLog(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      sets: sets ?? this.sets,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'sets': sets.map((set) => set.toMap()).toList(),
    };
  }

  factory ExerciseLog.fromMap(Map<String, dynamic> map) {
    final rawSets = map['sets'];

    return ExerciseLog(
      exerciseId: map['exerciseId']?.toString() ?? '',
      exerciseName: map['exerciseName']?.toString() ?? '',
      sets: rawSets is List
          ? rawSets
                .whereType<Map>()
                .map(
                  (set) => ExerciseSet.fromMap(Map<String, dynamic>.from(set)),
                )
                .toList()
          : const <ExerciseSet>[],
    );
  }
}
