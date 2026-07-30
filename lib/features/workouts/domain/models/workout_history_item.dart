import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'exercise_log.dart';
import 'workout_session_status.dart';

@immutable
class WorkoutHistoryItem {
  WorkoutHistoryItem({
    required this.id,
    required this.routineName,
    required this.date,
    required this.duration,
    required List<ExerciseLog> exercises,
    this.notes = '',
    this.status = WorkoutSessionStatus.completed,
  }) : exercises = UnmodifiableListView<ExerciseLog>(
         List<ExerciseLog>.from(exercises),
       );

  final String id;
  final String routineName;
  final DateTime date;
  final String duration;
  final List<ExerciseLog> exercises;
  final String notes;
  final WorkoutSessionStatus status;

  int get totalExercises => exercises.length;

  int get totalSets {
    return exercises.fold<int>(
      0,
      (total, exercise) => total + exercise.sets.length,
    );
  }

  double get totalVolume {
    return exercises.fold<double>(
      0,
      (total, exercise) => total + exercise.totalVolume,
    );
  }

  bool get isIncomplete {
    return status == WorkoutSessionStatus.incomplete;
  }

  WorkoutHistoryItem copyWith({
    String? id,
    String? routineName,
    DateTime? date,
    String? duration,
    List<ExerciseLog>? exercises,
    String? notes,
    WorkoutSessionStatus? status,
  }) {
    return WorkoutHistoryItem(
      id: id ?? this.id,
      routineName: routineName ?? this.routineName,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routineName': routineName,
      'date': date.toIso8601String(),
      'duration': duration,
      'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
      'notes': notes,
      'status': status.storageValue,
    };
  }

  factory WorkoutHistoryItem.fromMap(Map<String, dynamic> map) {
    final rawExercises = map['exercises'];

    return WorkoutHistoryItem(
      id: map['id']?.toString() ?? '',
      routineName: map['routineName']?.toString() ?? '',
      date:
          DateTime.tryParse(map['date']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      duration: map['duration']?.toString() ?? '',
      exercises: rawExercises is List
          ? rawExercises
                .whereType<Map>()
                .map(
                  (exercise) =>
                      ExerciseLog.fromMap(Map<String, dynamic>.from(exercise)),
                )
                .toList()
          : const <ExerciseLog>[],
      notes: map['notes']?.toString() ?? '',
      status: WorkoutSessionStatus.fromStorage(map['status']),
    );
  }
}
