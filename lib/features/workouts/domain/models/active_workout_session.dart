import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../../models/exercise.dart';

@immutable
class ActiveWorkoutSet {
  const ActiveWorkoutSet({
    required this.setNumber,
    this.weightText = '',
    this.repsText = '',
    this.isCompleted = false,
  });

  final int setNumber;
  final String weightText;
  final String repsText;
  final bool isCompleted;

  ActiveWorkoutSet copyWith({
    int? setNumber,
    String? weightText,
    String? repsText,
    bool? isCompleted,
  }) {
    return ActiveWorkoutSet(
      setNumber: setNumber ?? this.setNumber,
      weightText: weightText ?? this.weightText,
      repsText: repsText ?? this.repsText,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'setNumber': setNumber,
      'weightText': weightText,
      'repsText': repsText,
      'isCompleted': isCompleted,
    };
  }

  factory ActiveWorkoutSet.fromMap(Map<String, dynamic> map) {
    return ActiveWorkoutSet(
      setNumber: _readInt(map['setNumber'], 1),
      weightText: map['weightText']?.toString() ?? '',
      repsText: map['repsText']?.toString() ?? '',
      isCompleted: map['isCompleted'] == true || map['isCompleted'] == 1,
    );
  }
}

@immutable
class ActiveWorkoutExercise {
  ActiveWorkoutExercise({
    required this.exercise,
    required List<ActiveWorkoutSet> sets,
  }) : sets = UnmodifiableListView<ActiveWorkoutSet>(
         List<ActiveWorkoutSet>.from(sets),
       );

  final Exercise exercise;
  final List<ActiveWorkoutSet> sets;

  ActiveWorkoutExercise copyWith({
    Exercise? exercise,
    List<ActiveWorkoutSet>? sets,
  }) {
    return ActiveWorkoutExercise(
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exercise': exercise.toMap(),
      'sets': sets.map((set) => set.toMap()).toList(),
    };
  }

  factory ActiveWorkoutExercise.fromMap(Map<String, dynamic> map) {
    final rawExercise = map['exercise'];
    final rawSets = map['sets'];

    return ActiveWorkoutExercise(
      exercise: rawExercise is Map
          ? Exercise.fromMap(Map<String, dynamic>.from(rawExercise))
          : const Exercise(
              id: '',
              name: '',
              muscle: '',
              description: '',
              reps: '3x 10-12',
              rest: '60 seg',
            ),
      sets: rawSets is List
          ? rawSets
                .whereType<Map>()
                .map(
                  (set) =>
                      ActiveWorkoutSet.fromMap(Map<String, dynamic>.from(set)),
                )
                .toList()
          : const <ActiveWorkoutSet>[],
    );
  }
}

@immutable
class ActiveWorkoutSession {
  ActiveWorkoutSession({
    required this.id,
    required this.routineName,
    required this.startedAt,
    required this.elapsedSeconds,
    required List<ActiveWorkoutExercise> exercises,
    this.notes = '',
  }) : exercises = UnmodifiableListView<ActiveWorkoutExercise>(
         List<ActiveWorkoutExercise>.from(exercises),
       );

  final String id;
  final String routineName;
  final DateTime startedAt;
  final int elapsedSeconds;
  final List<ActiveWorkoutExercise> exercises;
  final String notes;

  ActiveWorkoutSession copyWith({
    String? id,
    String? routineName,
    DateTime? startedAt,
    int? elapsedSeconds,
    List<ActiveWorkoutExercise>? exercises,
    String? notes,
  }) {
    return ActiveWorkoutSession(
      id: id ?? this.id,
      routineName: routineName ?? this.routineName,
      startedAt: startedAt ?? this.startedAt,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routineName': routineName,
      'startedAt': startedAt.toIso8601String(),
      'elapsedSeconds': elapsedSeconds,
      'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
      'notes': notes,
    };
  }

  factory ActiveWorkoutSession.fromMap(Map<String, dynamic> map) {
    final rawExercises = map['exercises'];

    return ActiveWorkoutSession(
      id: map['id']?.toString() ?? 'active',
      routineName: map['routineName']?.toString() ?? 'Treino do Dia',
      startedAt:
          DateTime.tryParse(map['startedAt']?.toString() ?? '') ??
          DateTime.now(),
      elapsedSeconds: _readInt(map['elapsedSeconds'], 0),
      exercises: rawExercises is List
          ? rawExercises
                .whereType<Map>()
                .map(
                  (exercise) => ActiveWorkoutExercise.fromMap(
                    Map<String, dynamic>.from(exercise),
                  ),
                )
                .toList()
          : const <ActiveWorkoutExercise>[],
      notes: map['notes']?.toString() ?? '',
    );
  }
}

int _readInt(Object? value, int fallback) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
