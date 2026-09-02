import 'package:flutter/foundation.dart';

import '../../workouts/domain/models/workout_progression_mode.dart';

enum MeasurementSystem { metric, imperial }

enum PulseThemeMode { system, light, dark }

@immutable
class UserProfile {
  const UserProfile({
    required this.name,
    required this.weightKg,
    required this.heightCm,
    required this.age,
    this.photoPath = '',
  });

  final String name;
  final double weightKg;
  final double heightCm;
  final int age;
  final String photoPath;

  String get displayName {
    final normalizedName = name.trim();
    return normalizedName.isEmpty ? 'Atleta' : normalizedName;
  }

  UserProfile copyWith({
    String? name,
    double? weightKg,
    double? heightCm,
    int? age,
    String? photoPath,
    bool clearPhotoPath = false,
  }) {
    return UserProfile(
      name: name ?? this.name,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      age: age ?? this.age,
      photoPath: clearPhotoPath ? '' : photoPath ?? this.photoPath,
    );
  }
}

@immutable
class PulseSettings {
  const PulseSettings({
    required this.themeColorValue,
    required this.themeMode,
    required this.voiceAfterRest,
    required this.inactivityReminder,
    required this.measurementSystem,
    required this.workoutProgressionMode,
    required this.profile,
  });

  final int themeColorValue;
  final PulseThemeMode themeMode;
  final bool voiceAfterRest;
  final bool inactivityReminder;
  final MeasurementSystem measurementSystem;
  final WorkoutProgressionMode workoutProgressionMode;
  final UserProfile profile;

  factory PulseSettings.defaults() {
    return const PulseSettings(
      themeColorValue: 0xFF00E676,
      themeMode: PulseThemeMode.dark,
      voiceAfterRest: true,
      inactivityReminder: true,
      measurementSystem: MeasurementSystem.metric,
      workoutProgressionMode: WorkoutProgressionMode.withinRange,
      profile: UserProfile(name: 'Atleta', weightKg: 0, heightCm: 0, age: 0),
    );
  }

  PulseSettings copyWith({
    int? themeColorValue,
    PulseThemeMode? themeMode,
    bool? voiceAfterRest,
    bool? inactivityReminder,
    MeasurementSystem? measurementSystem,
    WorkoutProgressionMode? workoutProgressionMode,
    UserProfile? profile,
  }) {
    return PulseSettings(
      themeColorValue: themeColorValue ?? this.themeColorValue,
      themeMode: themeMode ?? this.themeMode,
      voiceAfterRest: voiceAfterRest ?? this.voiceAfterRest,
      inactivityReminder: inactivityReminder ?? this.inactivityReminder,
      measurementSystem: measurementSystem ?? this.measurementSystem,
      workoutProgressionMode:
          workoutProgressionMode ?? this.workoutProgressionMode,
      profile: profile ?? this.profile,
    );
  }
}
