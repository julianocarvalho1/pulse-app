import 'package:flutter/foundation.dart';

enum FreeActivityType {
  crossfit,
  functional,
  pilates,
  dance,
  mobility,
  sport,
  yoga,
  other;

  String get storageValue => name;

  String get label => switch (this) {
    FreeActivityType.crossfit => 'CrossFit',
    FreeActivityType.functional => 'Treino funcional',
    FreeActivityType.pilates => 'Pilates',
    FreeActivityType.dance => 'Dança ou zumba',
    FreeActivityType.mobility => 'Alongamento e mobilidade',
    FreeActivityType.sport => 'Esporte',
    FreeActivityType.yoga => 'Yoga',
    FreeActivityType.other => 'Outra atividade',
  };

  static FreeActivityType fromStorage(Object? value) {
    final normalized = value?.toString().trim();
    return FreeActivityType.values.firstWhere(
      (item) => item.storageValue == normalized,
      orElse: () => FreeActivityType.other,
    );
  }
}

enum FreeActivityIntensity {
  light,
  moderate,
  intense;

  String get storageValue => name;

  String get label => switch (this) {
    FreeActivityIntensity.light => 'Leve',
    FreeActivityIntensity.moderate => 'Moderada',
    FreeActivityIntensity.intense => 'Intensa',
  };

  static FreeActivityIntensity fromStorage(Object? value) {
    final normalized = value?.toString().trim();
    return FreeActivityIntensity.values.firstWhere(
      (item) => item.storageValue == normalized,
      orElse: () => FreeActivityIntensity.moderate,
    );
  }
}

@immutable
class FreeActivityLog {
  const FreeActivityLog({
    required this.type,
    required this.durationMinutes,
    required this.intensity,
    this.replacedPlannedWorkout = false,
    this.customName = '',
    this.notes = '',
  });

  final FreeActivityType type;
  final int durationMinutes;
  final FreeActivityIntensity intensity;
  final bool replacedPlannedWorkout;
  final String customName;
  final String notes;

  String get displayName {
    final normalized = customName.trim();
    if (normalized.isNotEmpty &&
        (type == FreeActivityType.other || type == FreeActivityType.sport)) {
      return normalized;
    }
    return type.label;
  }

  FreeActivityLog copyWith({
    FreeActivityType? type,
    int? durationMinutes,
    FreeActivityIntensity? intensity,
    bool? replacedPlannedWorkout,
    String? customName,
    String? notes,
  }) {
    return FreeActivityLog(
      type: type ?? this.type,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      intensity: intensity ?? this.intensity,
      replacedPlannedWorkout:
          replacedPlannedWorkout ?? this.replacedPlannedWorkout,
      customName: customName ?? this.customName,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type.storageValue,
      'durationMinutes': durationMinutes,
      'intensity': intensity.storageValue,
      'replacedPlannedWorkout': replacedPlannedWorkout,
      'customName': customName,
      'notes': notes,
    };
  }

  factory FreeActivityLog.fromMap(Map<String, dynamic> map) {
    return FreeActivityLog(
      type: FreeActivityType.fromStorage(map['type']),
      durationMinutes: _readInt(map['durationMinutes']),
      intensity: FreeActivityIntensity.fromStorage(map['intensity']),
      replacedPlannedWorkout: _readBool(map['replacedPlannedWorkout']),
      customName: map['customName']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
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

  static bool _readBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
}
