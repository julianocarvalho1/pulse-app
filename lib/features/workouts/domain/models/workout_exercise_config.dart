import 'package:flutter/foundation.dart';

@immutable
class WorkoutExerciseConfig {
  const WorkoutExerciseConfig({
    required this.seriesCount,
    required this.minimumReps,
    required this.maximumReps,
    required this.minimumRestSeconds,
    required this.maximumRestSeconds,
    required this.originalRepsText,
    required this.originalRestText,
  });

  final int seriesCount;
  final int minimumReps;
  final int maximumReps;
  final int minimumRestSeconds;
  final int maximumRestSeconds;
  final String originalRepsText;
  final String originalRestText;

  int get recommendedRestSeconds {
    if (minimumRestSeconds == maximumRestSeconds) {
      return minimumRestSeconds;
    }

    final midpoint = (minimumRestSeconds + maximumRestSeconds) / 2;

    return (midpoint / 5).round() * 5;
  }

  bool get hasRestRange {
    return minimumRestSeconds != maximumRestSeconds;
  }

  WorkoutExerciseConfig copyWith({
    int? seriesCount,
    int? minimumReps,
    int? maximumReps,
    int? minimumRestSeconds,
    int? maximumRestSeconds,
    String? originalRepsText,
    String? originalRestText,
  }) {
    return WorkoutExerciseConfig(
      seriesCount: seriesCount ?? this.seriesCount,
      minimumReps: minimumReps ?? this.minimumReps,
      maximumReps: maximumReps ?? this.maximumReps,
      minimumRestSeconds: minimumRestSeconds ?? this.minimumRestSeconds,
      maximumRestSeconds: maximumRestSeconds ?? this.maximumRestSeconds,
      originalRepsText: originalRepsText ?? this.originalRepsText,
      originalRestText: originalRestText ?? this.originalRestText,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'seriesCount': seriesCount,
      'minimumReps': minimumReps,
      'maximumReps': maximumReps,
      'minimumRestSeconds': minimumRestSeconds,
      'maximumRestSeconds': maximumRestSeconds,
      'originalRepsText': originalRepsText,
      'originalRestText': originalRestText,
    };
  }

  factory WorkoutExerciseConfig.fromMap(Map<String, dynamic> map) {
    return WorkoutExerciseConfig(
      seriesCount: _readInt(map['seriesCount'], 3),
      minimumReps: _readInt(map['minimumReps'], 10),
      maximumReps: _readInt(map['maximumReps'], 12),
      minimumRestSeconds: _readInt(map['minimumRestSeconds'], 60),
      maximumRestSeconds: _readInt(map['maximumRestSeconds'], 60),
      originalRepsText: map['originalRepsText']?.toString() ?? '',
      originalRestText: map['originalRestText']?.toString() ?? '',
    );
  }

  static int _readInt(Object? value, int fallback) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
