import 'package:flutter/foundation.dart';

enum WorkoutSetKind {
  warmUp,
  working;

  String get storageValue => name;

  String get label => switch (this) {
    WorkoutSetKind.warmUp => 'Aquecimento',
    WorkoutSetKind.working => 'Trabalho',
  };

  static WorkoutSetKind fromStorage(Object? value) {
    return WorkoutSetKind.values.firstWhere(
      (item) => item.storageValue == value?.toString(),
      orElse: () => WorkoutSetKind.working,
    );
  }
}

enum WorkoutSetTargetType {
  repetitions,
  duration;

  String get storageValue => name;

  static WorkoutSetTargetType fromStorage(Object? value) {
    return WorkoutSetTargetType.values.firstWhere(
      (item) => item.storageValue == value?.toString(),
      orElse: () => WorkoutSetTargetType.repetitions,
    );
  }
}

@immutable
class WorkoutSetTarget {
  const WorkoutSetTarget({required this.type, this.plannedDurationSeconds = 0});

  final WorkoutSetTargetType type;
  final int plannedDurationSeconds;

  bool get isTimed => type == WorkoutSetTargetType.duration;

  static WorkoutSetTarget fromText(String raw) {
    final normalized = raw
        .toLowerCase()
        .replaceAll('×', 'x')
        .replaceAll(',', '.')
        .trim();
    final target = normalized.contains('x')
        ? normalized.split('x').skip(1).join('x').trim()
        : normalized;
    final clockMatch = RegExp(r'\b(\d{1,2}):(\d{2})\b').firstMatch(target);
    final containsDurationUnit = RegExp(
      r'\b(seg(?:undo)?s?|sec(?:ond)?s?|min(?:uto)?s?)\b|\d\s*s\b',
    ).hasMatch(target);

    if (!containsDurationUnit && clockMatch == null) {
      return const WorkoutSetTarget(type: WorkoutSetTargetType.repetitions);
    }

    if (clockMatch != null) {
      final minutes = int.tryParse(clockMatch.group(1)!) ?? 0;
      final seconds = int.tryParse(clockMatch.group(2)!) ?? 0;
      return WorkoutSetTarget(
        type: WorkoutSetTargetType.duration,
        plannedDurationSeconds: minutes * 60 + seconds,
      );
    }

    final valueMatch = RegExp(r'\d+(?:\.\d+)?').firstMatch(target);
    final value = double.tryParse(valueMatch?.group(0) ?? '') ?? 0;
    final isMinutes = RegExp(r'\bmin(?:uto)?s?\b').hasMatch(target);

    return WorkoutSetTarget(
      type: WorkoutSetTargetType.duration,
      plannedDurationSeconds: (value * (isMinutes ? 60 : 1)).round(),
    );
  }
}

@immutable
class ExerciseSet {
  const ExerciseSet({
    required this.reps,
    required this.weight,
    this.kind = WorkoutSetKind.working,
    this.targetType = WorkoutSetTargetType.repetitions,
    this.plannedDurationSeconds = 0,
    this.actualDurationSeconds = 0,
  });

  final int reps;
  final double weight;
  final WorkoutSetKind kind;
  final WorkoutSetTargetType targetType;
  final int plannedDurationSeconds;
  final int actualDurationSeconds;

  bool get isTimed => targetType == WorkoutSetTargetType.duration;

  bool get isWarmUp => kind == WorkoutSetKind.warmUp;

  double get volume => isTimed || isWarmUp ? 0 : reps * weight;

  ExerciseSet copyWith({
    int? reps,
    double? weight,
    WorkoutSetKind? kind,
    WorkoutSetTargetType? targetType,
    int? plannedDurationSeconds,
    int? actualDurationSeconds,
  }) {
    return ExerciseSet(
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      kind: kind ?? this.kind,
      targetType: targetType ?? this.targetType,
      plannedDurationSeconds:
          plannedDurationSeconds ?? this.plannedDurationSeconds,
      actualDurationSeconds:
          actualDurationSeconds ?? this.actualDurationSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reps': reps,
      'weight': weight,
      if (kind != WorkoutSetKind.working) 'kind': kind.storageValue,
      'targetType': targetType.storageValue,
      'plannedDurationSeconds': plannedDurationSeconds,
      'actualDurationSeconds': actualDurationSeconds,
    };
  }

  factory ExerciseSet.fromMap(Map<String, dynamic> map) {
    return ExerciseSet(
      reps: _readInt(map['reps']),
      weight: _readDouble(map['weight']),
      kind: WorkoutSetKind.fromStorage(map['kind']),
      targetType: WorkoutSetTargetType.fromStorage(map['targetType']),
      plannedDurationSeconds: _readInt(map['plannedDurationSeconds']),
      actualDurationSeconds: _readInt(map['actualDurationSeconds']),
    );
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse((value?.toString() ?? '').replaceAll(',', '.')) ?? 0;
  }
}
