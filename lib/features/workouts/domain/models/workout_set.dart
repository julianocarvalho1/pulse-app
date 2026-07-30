import 'package:flutter/foundation.dart';

@immutable
class ExerciseSet {
  const ExerciseSet({required this.reps, required this.weight});

  final int reps;
  final double weight;

  double get volume => reps * weight;

  ExerciseSet copyWith({int? reps, double? weight}) {
    return ExerciseSet(reps: reps ?? this.reps, weight: weight ?? this.weight);
  }

  Map<String, dynamic> toMap() {
    return {'reps': reps, 'weight': weight};
  }

  factory ExerciseSet.fromMap(Map<String, dynamic> map) {
    return ExerciseSet(
      reps: _readInt(map['reps']),
      weight: _readDouble(map['weight']),
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
