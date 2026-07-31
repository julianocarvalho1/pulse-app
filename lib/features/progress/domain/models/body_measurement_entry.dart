import 'package:flutter/foundation.dart';

enum BodyMeasurementType {
  weight,
  shoulders,
  chest,
  waist,
  hips,
  leftArm,
  rightArm,
  leftForearm,
  rightForearm,
  leftThigh,
  rightThigh,
  leftCalf,
  rightCalf;

  String get label {
    return switch (this) {
      BodyMeasurementType.weight => 'Peso',
      BodyMeasurementType.shoulders => 'Ombros',
      BodyMeasurementType.chest => 'Tórax',
      BodyMeasurementType.waist => 'Cintura',
      BodyMeasurementType.hips => 'Quadril',
      BodyMeasurementType.leftArm => 'Braço Esq.',
      BodyMeasurementType.rightArm => 'Braço Dir.',
      BodyMeasurementType.leftForearm => 'Antebraço Esq.',
      BodyMeasurementType.rightForearm => 'Antebraço Dir.',
      BodyMeasurementType.leftThigh => 'Coxa Esq.',
      BodyMeasurementType.rightThigh => 'Coxa Dir.',
      BodyMeasurementType.leftCalf => 'Panturrilha Esq.',
      BodyMeasurementType.rightCalf => 'Panturrilha Dir.',
    };
  }

  String get storageKey {
    return switch (this) {
      BodyMeasurementType.weight => 'weight_kg',
      BodyMeasurementType.shoulders => 'shoulders_cm',
      BodyMeasurementType.chest => 'chest_cm',
      BodyMeasurementType.waist => 'waist_cm',
      BodyMeasurementType.hips => 'hips_cm',
      BodyMeasurementType.leftArm => 'left_arm_cm',
      BodyMeasurementType.rightArm => 'right_arm_cm',
      BodyMeasurementType.leftForearm => 'left_forearm_cm',
      BodyMeasurementType.rightForearm => 'right_forearm_cm',
      BodyMeasurementType.leftThigh => 'left_thigh_cm',
      BodyMeasurementType.rightThigh => 'right_thigh_cm',
      BodyMeasurementType.leftCalf => 'left_calf_cm',
      BodyMeasurementType.rightCalf => 'right_calf_cm',
    };
  }

  bool get isWeight => this == BodyMeasurementType.weight;
}

@immutable
class BodyMeasurementEntry {
  const BodyMeasurementEntry({
    required this.id,
    required this.recordedAt,
    this.weightKg,
    this.shouldersCm,
    this.chestCm,
    this.waistCm,
    this.hipsCm,
    this.leftArmCm,
    this.rightArmCm,
    this.leftForearmCm,
    this.rightForearmCm,
    this.leftThighCm,
    this.rightThighCm,
    this.leftCalfCm,
    this.rightCalfCm,
  });

  final String id;
  final DateTime recordedAt;
  final double? weightKg;
  final double? shouldersCm;
  final double? chestCm;
  final double? waistCm;
  final double? hipsCm;
  final double? leftArmCm;
  final double? rightArmCm;
  final double? leftForearmCm;
  final double? rightForearmCm;
  final double? leftThighCm;
  final double? rightThighCm;
  final double? leftCalfCm;
  final double? rightCalfCm;

  bool get hasAnyValue {
    return BodyMeasurementType.values.any((type) => valueFor(type) != null);
  }

  bool get isWeightOnly {
    return weightKg != null &&
        BodyMeasurementType.values
            .where((type) => !type.isWeight)
            .every((type) => valueFor(type) == null);
  }

  bool get hasBodyMeasurements {
    return BodyMeasurementType.values
        .where((type) => !type.isWeight)
        .any((type) => valueFor(type) != null);
  }

  double? valueFor(BodyMeasurementType type) {
    return switch (type) {
      BodyMeasurementType.weight => weightKg,
      BodyMeasurementType.shoulders => shouldersCm,
      BodyMeasurementType.chest => chestCm,
      BodyMeasurementType.waist => waistCm,
      BodyMeasurementType.hips => hipsCm,
      BodyMeasurementType.leftArm => leftArmCm,
      BodyMeasurementType.rightArm => rightArmCm,
      BodyMeasurementType.leftForearm => leftForearmCm,
      BodyMeasurementType.rightForearm => rightForearmCm,
      BodyMeasurementType.leftThigh => leftThighCm,
      BodyMeasurementType.rightThigh => rightThighCm,
      BodyMeasurementType.leftCalf => leftCalfCm,
      BodyMeasurementType.rightCalf => rightCalfCm,
    };
  }

  BodyMeasurementEntry copyWith({
    String? id,
    DateTime? recordedAt,
    double? weightKg,
    double? shouldersCm,
    double? chestCm,
    double? waistCm,
    double? hipsCm,
    double? leftArmCm,
    double? rightArmCm,
    double? leftForearmCm,
    double? rightForearmCm,
    double? leftThighCm,
    double? rightThighCm,
    double? leftCalfCm,
    double? rightCalfCm,
  }) {
    return BodyMeasurementEntry(
      id: id ?? this.id,
      recordedAt: recordedAt ?? this.recordedAt,
      weightKg: weightKg ?? this.weightKg,
      shouldersCm: shouldersCm ?? this.shouldersCm,
      chestCm: chestCm ?? this.chestCm,
      waistCm: waistCm ?? this.waistCm,
      hipsCm: hipsCm ?? this.hipsCm,
      leftArmCm: leftArmCm ?? this.leftArmCm,
      rightArmCm: rightArmCm ?? this.rightArmCm,
      leftForearmCm: leftForearmCm ?? this.leftForearmCm,
      rightForearmCm: rightForearmCm ?? this.rightForearmCm,
      leftThighCm: leftThighCm ?? this.leftThighCm,
      rightThighCm: rightThighCm ?? this.rightThighCm,
      leftCalfCm: leftCalfCm ?? this.leftCalfCm,
      rightCalfCm: rightCalfCm ?? this.rightCalfCm,
    );
  }

  Map<String, Object?> toDatabaseMap() {
    return {
      'id': id,
      'recorded_at_ms': recordedAt.millisecondsSinceEpoch,
      'weight_kg': weightKg,
      'shoulders_cm': shouldersCm,
      'chest_cm': chestCm,
      'waist_cm': waistCm,
      'hips_cm': hipsCm,
      'left_arm_cm': leftArmCm,
      'right_arm_cm': rightArmCm,
      'left_forearm_cm': leftForearmCm,
      'right_forearm_cm': rightForearmCm,
      'left_thigh_cm': leftThighCm,
      'right_thigh_cm': rightThighCm,
      'left_calf_cm': leftCalfCm,
      'right_calf_cm': rightCalfCm,
    };
  }

  factory BodyMeasurementEntry.fromDatabaseMap(Map<String, Object?> map) {
    return BodyMeasurementEntry(
      id: map['id']?.toString() ?? '',
      recordedAt: DateTime.fromMillisecondsSinceEpoch(
        _readInt(map['recorded_at_ms']),
      ),
      weightKg: _readNullableDouble(map['weight_kg']),
      shouldersCm: _readNullableDouble(map['shoulders_cm']),
      chestCm: _readNullableDouble(map['chest_cm']),
      waistCm: _readNullableDouble(map['waist_cm']),
      hipsCm: _readNullableDouble(map['hips_cm']),
      leftArmCm: _readNullableDouble(map['left_arm_cm']),
      rightArmCm: _readNullableDouble(map['right_arm_cm']),
      leftForearmCm: _readNullableDouble(map['left_forearm_cm']),
      rightForearmCm: _readNullableDouble(map['right_forearm_cm']),
      leftThighCm: _readNullableDouble(map['left_thigh_cm']),
      rightThighCm: _readNullableDouble(map['right_thigh_cm']),
      leftCalfCm: _readNullableDouble(map['left_calf_cm']),
      rightCalfCm: _readNullableDouble(map['right_calf_cm']),
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

  static double? _readNullableDouble(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      final parsed = value.toDouble();
      return parsed > 0 ? parsed : null;
    }

    final parsed = double.tryParse(value.toString().replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }
}
