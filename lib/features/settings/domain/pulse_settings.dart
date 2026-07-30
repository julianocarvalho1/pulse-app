import 'package:flutter/foundation.dart';

enum MeasurementSystem { metric, imperial }

@immutable
class UserProfile {
  const UserProfile({
    required this.name,
    required this.weightKg,
    required this.heightCm,
    required this.age,
  });

  final String name;
  final double weightKg;
  final double heightCm;
  final int age;

  String get displayName {
    final normalizedName = name.trim();
    return normalizedName.isEmpty ? 'Atleta' : normalizedName;
  }

  UserProfile copyWith({
    String? name,
    double? weightKg,
    double? heightCm,
    int? age,
  }) {
    return UserProfile(
      name: name ?? this.name,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      age: age ?? this.age,
    );
  }
}

@immutable
class PulseSettings {
  const PulseSettings({
    required this.themeColorValue,
    required this.vibrateAfterRest,
    required this.inactivityReminder,
    required this.measurementSystem,
    required this.profile,
  });

  final int themeColorValue;
  final bool vibrateAfterRest;
  final bool inactivityReminder;
  final MeasurementSystem measurementSystem;
  final UserProfile profile;

  factory PulseSettings.defaults() {
    return const PulseSettings(
      themeColorValue: 0xFF00E676,
      vibrateAfterRest: true,
      inactivityReminder: true,
      measurementSystem: MeasurementSystem.metric,
      profile: UserProfile(name: 'Atleta', weightKg: 0, heightCm: 0, age: 0),
    );
  }

  PulseSettings copyWith({
    int? themeColorValue,
    bool? vibrateAfterRest,
    bool? inactivityReminder,
    MeasurementSystem? measurementSystem,
    UserProfile? profile,
  }) {
    return PulseSettings(
      themeColorValue: themeColorValue ?? this.themeColorValue,
      vibrateAfterRest: vibrateAfterRest ?? this.vibrateAfterRest,
      inactivityReminder: inactivityReminder ?? this.inactivityReminder,
      measurementSystem: measurementSystem ?? this.measurementSystem,
      profile: profile ?? this.profile,
    );
  }
}
