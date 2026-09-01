import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'workout_set.dart';

@immutable
class ExerciseLog {
  ExerciseLog({
    required this.exerciseId,
    required this.exerciseName,
    required List<ExerciseSet> sets,
    this.notes = '',
    this.isLoadComparable = true,
  }) : sets = UnmodifiableListView<ExerciseSet>(List<ExerciseSet>.from(sets));

  final String exerciseId;
  final String exerciseName;
  final List<ExerciseSet> sets;
  final String notes;
  final bool isLoadComparable;

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
    String? notes,
    bool? isLoadComparable,
  }) {
    return ExerciseLog(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
      isLoadComparable: isLoadComparable ?? this.isLoadComparable,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'sets': sets.map((set) => set.toMap()).toList(),
      'notes': notes,
      'isLoadComparable': isLoadComparable,
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
      notes: map['notes']?.toString() ?? '',
      isLoadComparable:
          map['isLoadComparable'] == null ||
          map['isLoadComparable'] == true ||
          map['isLoadComparable'] == 1,
    );
  }
}
