import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'cardio_log.dart';
import 'exercise_log.dart';
import 'free_activity_log.dart';
import 'workout_session_status.dart';

@immutable
class WorkoutHistoryItem {
  WorkoutHistoryItem({
    required this.id,
    required this.routineName,
    required this.date,
    required this.duration,
    required List<ExerciseLog> exercises,
    List<CardioLog> cardio = const <CardioLog>[],
    List<FreeActivityLog> freeActivities = const <FreeActivityLog>[],
    this.notes = '',
    this.status = WorkoutSessionStatus.completed,
  }) : exercises = UnmodifiableListView<ExerciseLog>(
         List<ExerciseLog>.from(exercises),
       ),
       cardio = UnmodifiableListView<CardioLog>(List<CardioLog>.from(cardio)),
       freeActivities = UnmodifiableListView<FreeActivityLog>(
         List<FreeActivityLog>.from(freeActivities),
       );

  final String id;
  final String routineName;
  final DateTime date;
  final String duration;
  final List<ExerciseLog> exercises;
  final List<CardioLog> cardio;
  final List<FreeActivityLog> freeActivities;
  final String notes;
  final WorkoutSessionStatus status;

  int get totalExercises => exercises.length;

  int get totalCardioActivities => cardio.length;

  int get totalFreeActivities => freeActivities.length;

  int get totalActivities =>
      totalExercises + totalCardioActivities + totalFreeActivities;

  int get totalCardioMinutes {
    return cardio.fold<int>(
      0,
      (total, entry) => total + entry.actualDurationMinutes,
    );
  }

  double get totalCardioDistanceKm {
    return cardio.fold<double>(
      0,
      (total, entry) => total + (entry.distanceKm ?? 0),
    );
  }

  int get totalFreeActivityMinutes {
    return freeActivities.fold<int>(
      0,
      (total, entry) => total + entry.durationMinutes,
    );
  }

  bool get isFreeActivityOnly =>
      freeActivities.isNotEmpty && exercises.isEmpty && cardio.isEmpty;

  bool get isCardioOnly =>
      cardio.isNotEmpty && exercises.isEmpty && freeActivities.isEmpty;

  bool get isMixedSession =>
      (cardio.isNotEmpty || freeActivities.isNotEmpty) && exercises.isNotEmpty;

  bool get replacedPlannedWorkout =>
      freeActivities.any((entry) => entry.replacedPlannedWorkout);

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
    List<CardioLog>? cardio,
    List<FreeActivityLog>? freeActivities,
    String? notes,
    WorkoutSessionStatus? status,
  }) {
    return WorkoutHistoryItem(
      id: id ?? this.id,
      routineName: routineName ?? this.routineName,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      exercises: exercises ?? this.exercises,
      cardio: cardio ?? this.cardio,
      freeActivities: freeActivities ?? this.freeActivities,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'routineName': routineName,
      'date': date.toIso8601String(),
      'duration': duration,
      'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
      'cardio': cardio.map((entry) => entry.toMap()).toList(),
      'freeActivities': freeActivities.map((entry) => entry.toMap()).toList(),
      'notes': notes,
      'status': status.storageValue,
    };
  }

  factory WorkoutHistoryItem.fromMap(Map<String, dynamic> map) {
    final rawExercises = map['exercises'];
    final rawCardio = map['cardio'];
    final rawFreeActivities = map['freeActivities'];

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
      cardio: rawCardio is List
          ? rawCardio
                .whereType<Map>()
                .map(
                  (entry) =>
                      CardioLog.fromMap(Map<String, dynamic>.from(entry)),
                )
                .toList()
          : const <CardioLog>[],
      freeActivities: rawFreeActivities is List
          ? rawFreeActivities
                .whereType<Map>()
                .map(
                  (entry) =>
                      FreeActivityLog.fromMap(Map<String, dynamic>.from(entry)),
                )
                .toList()
          : const <FreeActivityLog>[],
      notes: map['notes']?.toString() ?? '',
      status: WorkoutSessionStatus.fromStorage(map['status']),
    );
  }
}
