import 'package:flutter/foundation.dart';

enum CardioModality {
  treadmill,
  stationaryBike,
  elliptical,
  stairClimber,
  rowing,
  walking,
  running,
  other;

  String get storageValue => name;

  String get label {
    return switch (this) {
      CardioModality.treadmill => 'Esteira',
      CardioModality.stationaryBike => 'Bicicleta',
      CardioModality.elliptical => 'Elíptico',
      CardioModality.stairClimber => 'Escada',
      CardioModality.rowing => 'Remo',
      CardioModality.walking => 'Caminhada',
      CardioModality.running => 'Corrida',
      CardioModality.other => 'Outro',
    };
  }

  static CardioModality fromStorage(Object? value) {
    final normalized = value?.toString().trim();
    return CardioModality.values.firstWhere(
      (item) => item.storageValue == normalized,
      orElse: () => CardioModality.other,
    );
  }
}

@immutable
class RoutineCardio {
  const RoutineCardio({
    required this.id,
    required this.modality,
    required this.plannedDurationMinutes,
    this.notes = '',
  });

  final String id;
  final CardioModality modality;
  final int plannedDurationMinutes;
  final String notes;

  RoutineCardio copyWith({
    String? id,
    CardioModality? modality,
    int? plannedDurationMinutes,
    String? notes,
  }) {
    return RoutineCardio(
      id: id ?? this.id,
      modality: modality ?? this.modality,
      plannedDurationMinutes:
          plannedDurationMinutes ?? this.plannedDurationMinutes,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'modality': modality.storageValue,
      'plannedDurationMinutes': plannedDurationMinutes,
      'notes': notes,
    };
  }

  factory RoutineCardio.fromMap(Map<String, dynamic> map) {
    return RoutineCardio(
      id: map['id']?.toString() ?? '',
      modality: CardioModality.fromStorage(map['modality']),
      plannedDurationMinutes:
          CardioLog._readInt(map['plannedDurationMinutes']) ?? 0,
      notes: map['notes']?.toString() ?? '',
    );
  }
}

@immutable
class CardioLog {
  const CardioLog({
    required this.modality,
    required this.actualDurationMinutes,
    this.plannedDurationMinutes = 0,
    this.distanceKm,
    this.averageSpeedKmh,
    this.inclinePercent,
    this.resistanceLevel,
    this.perceivedEffort,
    this.averageHeartRateBpm,
    this.notes = '',
  });

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

  bool get hasDistance => distanceKm != null && distanceKm! > 0;

  bool get hasOptionalMetrics {
    return hasDistance ||
        (averageSpeedKmh != null && averageSpeedKmh! > 0) ||
        inclinePercent != null ||
        resistanceLevel != null ||
        perceivedEffort != null ||
        averageHeartRateBpm != null;
  }

  CardioLog copyWith({
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
  }) {
    return CardioLog(
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
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
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
    };
  }

  factory CardioLog.fromMap(Map<String, dynamic> map) {
    return CardioLog(
      modality: CardioModality.fromStorage(map['modality']),
      plannedDurationMinutes: _readInt(map['plannedDurationMinutes']) ?? 0,
      actualDurationMinutes: _readInt(map['actualDurationMinutes']) ?? 0,
      distanceKm: _readDouble(map['distanceKm']),
      averageSpeedKmh: _readDouble(map['averageSpeedKmh']),
      inclinePercent: _readDouble(map['inclinePercent']),
      resistanceLevel: _readDouble(map['resistanceLevel']),
      perceivedEffort: _readInt(map['perceivedEffort']),
      averageHeartRateBpm: _readInt(map['averageHeartRateBpm']),
      notes: map['notes']?.toString() ?? '',
    );
  }

  static int? _readInt(Object? value) {
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

  static double? _readDouble(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString().replaceAll(',', '.'));
  }
}
