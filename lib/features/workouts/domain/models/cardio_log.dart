import 'dart:convert';

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

enum CardioPurpose {
  warmUp,
  postWorkout,
  standalone;

  String get storageValue => name;

  String get label => switch (this) {
    CardioPurpose.warmUp => 'Aquecimento',
    CardioPurpose.postWorkout => 'Após o treino',
    CardioPurpose.standalone => 'Sessão separada',
  };

  static CardioPurpose fromStorage(Object? value) {
    final normalized = value?.toString().trim();
    return CardioPurpose.values.firstWhere(
      (item) => item.storageValue == normalized,
      orElse: () => CardioPurpose.postWorkout,
    );
  }
}

enum CardioFormat {
  continuous,
  intervals;

  String get storageValue => name;

  String get label => switch (this) {
    CardioFormat.continuous => 'Contínuo',
    CardioFormat.intervals => 'Intervalado',
  };

  static CardioFormat fromStorage(Object? value) {
    final normalized = value?.toString().trim();
    return CardioFormat.values.firstWhere(
      (item) => item.storageValue == normalized,
      orElse: () => CardioFormat.continuous,
    );
  }
}

enum CardioIntensity {
  selfSelected,
  light,
  moderate,
  vigorous;

  String get storageValue => name;

  String get label => switch (this) {
    CardioIntensity.selfSelected => 'Livre / definida na ficha',
    CardioIntensity.light => 'Leve',
    CardioIntensity.moderate => 'Moderada',
    CardioIntensity.vigorous => 'Vigorosa',
  };

  String get talkTestDescription => switch (this) {
    CardioIntensity.selfSelected =>
      'Use a intensidade indicada pelo seu profissional ou ajuste ao seu nível.',
    CardioIntensity.light =>
      'Respiração confortável; normalmente dá para cantar.',
    CardioIntensity.moderate =>
      'Dá para conversar, mas cantar já fica difícil.',
    CardioIntensity.vigorous =>
      'Só dá para dizer poucas palavras antes de respirar.',
  };

  static CardioIntensity fromStorage(Object? value) {
    final normalized = value?.toString().trim();
    return CardioIntensity.values.firstWhere(
      (item) => item.storageValue == normalized,
      orElse: () => CardioIntensity.selfSelected,
    );
  }
}

@immutable
class CardioIntervalPlan {
  const CardioIntervalPlan({
    this.warmUpMinutes = 5,
    this.effortSeconds = 30,
    this.recoverySeconds = 60,
    this.cycles = 6,
    this.coolDownMinutes = 5,
  });

  final int warmUpMinutes;
  final int effortSeconds;
  final int recoverySeconds;
  final int cycles;
  final int coolDownMinutes;

  int get totalDurationSeconds =>
      ((warmUpMinutes + coolDownMinutes) * 60) +
      ((effortSeconds + recoverySeconds) * cycles);

  int get totalDurationMinutes => (totalDurationSeconds / 60).ceil();

  Map<String, dynamic> toMap() => <String, dynamic>{
    'warmUpMinutes': warmUpMinutes,
    'effortSeconds': effortSeconds,
    'recoverySeconds': recoverySeconds,
    'cycles': cycles,
    'coolDownMinutes': coolDownMinutes,
  };

  factory CardioIntervalPlan.fromMap(Map<String, dynamic> map) {
    return CardioIntervalPlan(
      warmUpMinutes: CardioLog._readInt(map['warmUpMinutes']) ?? 0,
      effortSeconds: CardioLog._readInt(map['effortSeconds']) ?? 0,
      recoverySeconds: CardioLog._readInt(map['recoverySeconds']) ?? 0,
      cycles: CardioLog._readInt(map['cycles']) ?? 0,
      coolDownMinutes: CardioLog._readInt(map['coolDownMinutes']) ?? 0,
    );
  }
}

@immutable
class CardioPlan {
  const CardioPlan({
    this.purpose = CardioPurpose.postWorkout,
    this.format = CardioFormat.continuous,
    this.intensity = CardioIntensity.selfSelected,
    this.plannedDistanceKm,
    this.plannedSpeedKmh,
    this.plannedInclinePercent,
    this.plannedResistanceLevel,
    this.intervals,
  });

  final CardioPurpose purpose;
  final CardioFormat format;
  final CardioIntensity intensity;
  final double? plannedDistanceKm;
  final double? plannedSpeedKmh;
  final double? plannedInclinePercent;
  final double? plannedResistanceLevel;
  final CardioIntervalPlan? intervals;

  bool get isInterval => format == CardioFormat.intervals;

  CardioPlan copyWith({
    CardioPurpose? purpose,
    CardioFormat? format,
    CardioIntensity? intensity,
    double? plannedDistanceKm,
    bool clearPlannedDistance = false,
    double? plannedSpeedKmh,
    bool clearPlannedSpeed = false,
    double? plannedInclinePercent,
    bool clearPlannedIncline = false,
    double? plannedResistanceLevel,
    bool clearPlannedResistance = false,
    CardioIntervalPlan? intervals,
    bool clearIntervals = false,
  }) {
    return CardioPlan(
      purpose: purpose ?? this.purpose,
      format: format ?? this.format,
      intensity: intensity ?? this.intensity,
      plannedDistanceKm: clearPlannedDistance
          ? null
          : plannedDistanceKm ?? this.plannedDistanceKm,
      plannedSpeedKmh: clearPlannedSpeed
          ? null
          : plannedSpeedKmh ?? this.plannedSpeedKmh,
      plannedInclinePercent: clearPlannedIncline
          ? null
          : plannedInclinePercent ?? this.plannedInclinePercent,
      plannedResistanceLevel: clearPlannedResistance
          ? null
          : plannedResistanceLevel ?? this.plannedResistanceLevel,
      intervals: clearIntervals ? null : intervals ?? this.intervals,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'purpose': purpose.storageValue,
    'format': format.storageValue,
    'intensity': intensity.storageValue,
    'plannedDistanceKm': plannedDistanceKm,
    'plannedSpeedKmh': plannedSpeedKmh,
    'plannedInclinePercent': plannedInclinePercent,
    'plannedResistanceLevel': plannedResistanceLevel,
    if (intervals != null) 'intervals': intervals!.toMap(),
  };

  String toJson() => jsonEncode(toMap());

  factory CardioPlan.fromMap(Map<String, dynamic> map) {
    final rawIntervals = map['intervals'];
    return CardioPlan(
      purpose: CardioPurpose.fromStorage(map['purpose']),
      format: CardioFormat.fromStorage(map['format']),
      intensity: CardioIntensity.fromStorage(map['intensity']),
      plannedDistanceKm: CardioLog._readDouble(map['plannedDistanceKm']),
      plannedSpeedKmh: CardioLog._readDouble(map['plannedSpeedKmh']),
      plannedInclinePercent: CardioLog._readDouble(
        map['plannedInclinePercent'],
      ),
      plannedResistanceLevel: CardioLog._readDouble(
        map['plannedResistanceLevel'],
      ),
      intervals: rawIntervals is Map
          ? CardioIntervalPlan.fromMap(Map<String, dynamic>.from(rawIntervals))
          : null,
    );
  }

  factory CardioPlan.fromJson(Object? value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) {
      return const CardioPlan();
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        return CardioPlan.fromMap(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      // Backups e bancos antigos podem não possuir um plano estruturado.
    }
    return const CardioPlan();
  }
}

@immutable
class RoutineCardio {
  const RoutineCardio({
    required this.id,
    required this.modality,
    required this.plannedDurationMinutes,
    this.plan = const CardioPlan(),
    this.notes = '',
  });

  final String id;
  final CardioModality modality;
  final int plannedDurationMinutes;
  final CardioPlan plan;
  final String notes;

  RoutineCardio copyWith({
    String? id,
    CardioModality? modality,
    int? plannedDurationMinutes,
    CardioPlan? plan,
    String? notes,
  }) {
    return RoutineCardio(
      id: id ?? this.id,
      modality: modality ?? this.modality,
      plannedDurationMinutes:
          plannedDurationMinutes ?? this.plannedDurationMinutes,
      plan: plan ?? this.plan,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'modality': modality.storageValue,
      'plannedDurationMinutes': plannedDurationMinutes,
      'plan': plan.toMap(),
      'notes': notes,
    };
  }

  factory RoutineCardio.fromMap(Map<String, dynamic> map) {
    return RoutineCardio(
      id: map['id']?.toString() ?? '',
      modality: CardioModality.fromStorage(map['modality']),
      plannedDurationMinutes:
          CardioLog._readInt(map['plannedDurationMinutes']) ?? 0,
      plan: map['plan'] is Map
          ? CardioPlan.fromMap(Map<String, dynamic>.from(map['plan'] as Map))
          : const CardioPlan(),
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
    this.plan = const CardioPlan(),
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
  final CardioPlan plan;
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
    CardioPlan? plan,
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
      plan: plan ?? this.plan,
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
      'plan': plan.toMap(),
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
      plan: map['plan'] is Map
          ? CardioPlan.fromMap(Map<String, dynamic>.from(map['plan'] as Map))
          : const CardioPlan(),
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
