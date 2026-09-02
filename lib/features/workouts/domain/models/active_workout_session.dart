import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../../models/exercise.dart';
import 'advanced_workout_prescription.dart';
import 'cardio_log.dart';

@immutable
class ActiveWorkoutSet {
  const ActiveWorkoutSet({
    required this.setNumber,
    this.weightText = '',
    this.repsText = '',
    this.isCompleted = false,
    this.targetText = '',
    this.targetRir,
    this.cadence = '',
    this.technique = WorkoutTechnique.none,
    this.prescribedRestSeconds,
    this.prescriptionNotes = '',
  });

  final int setNumber;
  final String weightText;
  final String repsText;
  final bool isCompleted;
  final String targetText;
  final int? targetRir;
  final String cadence;
  final WorkoutTechnique technique;
  final int? prescribedRestSeconds;
  final String prescriptionNotes;

  ActiveWorkoutSet copyWith({
    int? setNumber,
    String? weightText,
    String? repsText,
    bool? isCompleted,
    String? targetText,
    int? targetRir,
    bool clearTargetRir = false,
    String? cadence,
    WorkoutTechnique? technique,
    int? prescribedRestSeconds,
    bool clearPrescribedRestSeconds = false,
    String? prescriptionNotes,
  }) {
    return ActiveWorkoutSet(
      setNumber: setNumber ?? this.setNumber,
      weightText: weightText ?? this.weightText,
      repsText: repsText ?? this.repsText,
      isCompleted: isCompleted ?? this.isCompleted,
      targetText: targetText ?? this.targetText,
      targetRir: clearTargetRir ? null : (targetRir ?? this.targetRir),
      cadence: cadence ?? this.cadence,
      technique: technique ?? this.technique,
      prescribedRestSeconds: clearPrescribedRestSeconds
          ? null
          : (prescribedRestSeconds ?? this.prescribedRestSeconds),
      prescriptionNotes: prescriptionNotes ?? this.prescriptionNotes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'setNumber': setNumber,
      'weightText': weightText,
      'repsText': repsText,
      'isCompleted': isCompleted,
      'targetText': targetText,
      if (targetRir != null) 'targetRir': targetRir,
      'cadence': cadence,
      'technique': technique.storageValue,
      if (prescribedRestSeconds != null)
        'prescribedRestSeconds': prescribedRestSeconds,
      'prescriptionNotes': prescriptionNotes,
    };
  }

  factory ActiveWorkoutSet.fromMap(Map<String, dynamic> map) {
    return ActiveWorkoutSet(
      setNumber: _readInt(map['setNumber'], 1),
      weightText: map['weightText']?.toString() ?? '',
      repsText: map['repsText']?.toString() ?? '',
      isCompleted: map['isCompleted'] == true || map['isCompleted'] == 1,
      targetText: map['targetText']?.toString() ?? '',
      targetRir: _readNullableInt(map['targetRir']),
      cadence: map['cadence']?.toString() ?? '',
      technique: WorkoutTechnique.fromStorage(map['technique']),
      prescribedRestSeconds: _readNullableInt(map['prescribedRestSeconds']),
      prescriptionNotes: map['prescriptionNotes']?.toString() ?? '',
    );
  }
}

@immutable
class ActiveWorkoutExercise {
  ActiveWorkoutExercise({
    required this.exercise,
    required List<ActiveWorkoutSet> sets,
    this.sessionNotes = '',
    this.isLoadComparable = true,
    this.perceivedRir,
  }) : sets = UnmodifiableListView<ActiveWorkoutSet>(
         List<ActiveWorkoutSet>.from(sets),
       );

  final Exercise exercise;
  final List<ActiveWorkoutSet> sets;
  final String sessionNotes;
  final bool isLoadComparable;
  final int? perceivedRir;

  ActiveWorkoutExercise copyWith({
    Exercise? exercise,
    List<ActiveWorkoutSet>? sets,
    String? sessionNotes,
    bool? isLoadComparable,
    int? perceivedRir,
    bool clearPerceivedRir = false,
  }) {
    return ActiveWorkoutExercise(
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
      sessionNotes: sessionNotes ?? this.sessionNotes,
      isLoadComparable: isLoadComparable ?? this.isLoadComparable,
      perceivedRir: clearPerceivedRir
          ? null
          : (perceivedRir ?? this.perceivedRir),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exercise': exercise.toMap(),
      'sets': sets.map((set) => set.toMap()).toList(),
      'sessionNotes': sessionNotes,
      'isLoadComparable': isLoadComparable,
      if (perceivedRir != null) 'perceivedRir': perceivedRir,
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
      sessionNotes: map['sessionNotes']?.toString() ?? '',
      isLoadComparable:
          map['isLoadComparable'] == null ||
          map['isLoadComparable'] == true ||
          map['isLoadComparable'] == 1,
      perceivedRir: _readNullableInt(map['perceivedRir']),
    );
  }
}

@immutable
class ActiveCardioEntry {
  const ActiveCardioEntry({
    required this.id,
    required this.modality,
    required this.plannedDurationMinutes,
    this.actualDurationMinutes = 0,
    this.distanceKm,
    this.averageSpeedKmh,
    this.inclinePercent,
    this.resistanceLevel,
    this.perceivedEffort,
    this.averageHeartRateBpm,
    this.notes = '',
    this.isCompleted = false,
  });

  factory ActiveCardioEntry.fromRoutine(RoutineCardio cardio) {
    return ActiveCardioEntry(
      id: cardio.id,
      modality: cardio.modality,
      plannedDurationMinutes: cardio.plannedDurationMinutes,
      notes: cardio.notes,
    );
  }

  final String id;
  final CardioModality modality;
  final int plannedDurationMinutes;
  final int actualDurationMinutes;
  final double? distanceKm;
  final double? averageSpeedKmh;
  final double? inclinePercent;
  final double? resistanceLevel;
  final int? perceivedEffort;
  final int? averageHeartRateBpm;
  final String notes;
  final bool isCompleted;

  CardioLog toLog() {
    return CardioLog(
      modality: modality,
      plannedDurationMinutes: plannedDurationMinutes,
      actualDurationMinutes: actualDurationMinutes,
      distanceKm: distanceKm,
      averageSpeedKmh: averageSpeedKmh,
      inclinePercent: inclinePercent,
      resistanceLevel: resistanceLevel,
      perceivedEffort: perceivedEffort,
      averageHeartRateBpm: averageHeartRateBpm,
      notes: notes,
    );
  }

  ActiveCardioEntry copyWith({
    String? id,
    CardioModality? modality,
    int? plannedDurationMinutes,
    int? actualDurationMinutes,
    double? distanceKm,
    bool clearDistance = false,
    double? averageSpeedKmh,
    bool clearAverageSpeed = false,
    double? inclinePercent,
    bool clearIncline = false,
    double? resistanceLevel,
    bool clearResistance = false,
    int? perceivedEffort,
    bool clearPerceivedEffort = false,
    int? averageHeartRateBpm,
    bool clearAverageHeartRate = false,
    String? notes,
    bool? isCompleted,
  }) {
    return ActiveCardioEntry(
      id: id ?? this.id,
      modality: modality ?? this.modality,
      plannedDurationMinutes:
          plannedDurationMinutes ?? this.plannedDurationMinutes,
      actualDurationMinutes:
          actualDurationMinutes ?? this.actualDurationMinutes,
      distanceKm: clearDistance ? null : distanceKm ?? this.distanceKm,
      averageSpeedKmh: clearAverageSpeed
          ? null
          : averageSpeedKmh ?? this.averageSpeedKmh,
      inclinePercent: clearIncline
          ? null
          : inclinePercent ?? this.inclinePercent,
      resistanceLevel: clearResistance
          ? null
          : resistanceLevel ?? this.resistanceLevel,
      perceivedEffort: clearPerceivedEffort
          ? null
          : perceivedEffort ?? this.perceivedEffort,
      averageHeartRateBpm: clearAverageHeartRate
          ? null
          : averageHeartRateBpm ?? this.averageHeartRateBpm,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'modality': modality.storageValue,
      'plannedDurationMinutes': plannedDurationMinutes,
      'actualDurationMinutes': actualDurationMinutes,
      'distanceKm': distanceKm,
      'averageSpeedKmh': averageSpeedKmh,
      'inclinePercent': inclinePercent,
      'resistanceLevel': resistanceLevel,
      'perceivedEffort': perceivedEffort,
      'averageHeartRateBpm': averageHeartRateBpm,
      'notes': notes,
      'isCompleted': isCompleted,
    };
  }

  factory ActiveCardioEntry.fromMap(Map<String, dynamic> map) {
    return ActiveCardioEntry(
      id: map['id']?.toString() ?? '',
      modality: CardioModality.fromStorage(map['modality']),
      plannedDurationMinutes: _readInt(map['plannedDurationMinutes'], 0),
      actualDurationMinutes: _readInt(map['actualDurationMinutes'], 0),
      distanceKm: _readNullableDouble(map['distanceKm']),
      averageSpeedKmh: _readNullableDouble(map['averageSpeedKmh']),
      inclinePercent: _readNullableDouble(map['inclinePercent']),
      resistanceLevel: _readNullableDouble(map['resistanceLevel']),
      perceivedEffort: _readNullableInt(map['perceivedEffort']),
      averageHeartRateBpm: _readNullableInt(map['averageHeartRateBpm']),
      notes: map['notes']?.toString() ?? '',
      isCompleted: map['isCompleted'] == true || map['isCompleted'] == 1,
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
    List<ActiveCardioEntry> cardio = const <ActiveCardioEntry>[],
    this.notes = '',
    this.restSeconds = 0,
    this.restEndsAt,
    this.isRestPaused = false,
  }) : exercises = UnmodifiableListView<ActiveWorkoutExercise>(
         List<ActiveWorkoutExercise>.from(exercises),
       ),
       cardio = UnmodifiableListView<ActiveCardioEntry>(
         List<ActiveCardioEntry>.from(cardio),
       );

  final String id;
  final String routineName;
  final DateTime startedAt;
  final int elapsedSeconds;
  final List<ActiveWorkoutExercise> exercises;
  final List<ActiveCardioEntry> cardio;
  final String notes;
  final int restSeconds;
  final DateTime? restEndsAt;
  final bool isRestPaused;

  ActiveWorkoutSession copyWith({
    String? id,
    String? routineName,
    DateTime? startedAt,
    int? elapsedSeconds,
    List<ActiveWorkoutExercise>? exercises,
    List<ActiveCardioEntry>? cardio,
    String? notes,
    int? restSeconds,
    DateTime? restEndsAt,
    bool clearRestEndsAt = false,
    bool? isRestPaused,
  }) {
    return ActiveWorkoutSession(
      id: id ?? this.id,
      routineName: routineName ?? this.routineName,
      startedAt: startedAt ?? this.startedAt,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      exercises: exercises ?? this.exercises,
      cardio: cardio ?? this.cardio,
      notes: notes ?? this.notes,
      restSeconds: restSeconds ?? this.restSeconds,
      restEndsAt: clearRestEndsAt ? null : (restEndsAt ?? this.restEndsAt),
      isRestPaused: isRestPaused ?? this.isRestPaused,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routineName': routineName,
      'startedAt': startedAt.toIso8601String(),
      'elapsedSeconds': elapsedSeconds,
      'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
      'cardio': cardio.map((entry) => entry.toMap()).toList(),
      'notes': notes,
      'restSeconds': restSeconds,
      'restEndsAt': restEndsAt?.toIso8601String(),
      'isRestPaused': isRestPaused,
    };
  }

  factory ActiveWorkoutSession.fromMap(Map<String, dynamic> map) {
    final rawExercises = map['exercises'];
    final rawCardio = map['cardio'];

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
      cardio: rawCardio is List
          ? rawCardio
                .whereType<Map>()
                .map(
                  (entry) => ActiveCardioEntry.fromMap(
                    Map<String, dynamic>.from(entry),
                  ),
                )
                .toList()
          : const <ActiveCardioEntry>[],
      notes: map['notes']?.toString() ?? '',
      restSeconds: _readInt(map['restSeconds'], 0),
      restEndsAt: DateTime.tryParse(map['restEndsAt']?.toString() ?? ''),
      isRestPaused: map['isRestPaused'] == true || map['isRestPaused'] == 1,
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

int? _readNullableInt(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
}

double? _readNullableDouble(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString().replaceAll(',', '.'));
}
