import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../settings/domain/pulse_settings.dart';

enum TrainingExperience { beginner, intermediate, advanced }

enum TrainingGoal {
  hypertrophy,
  strength,
  fatLoss,
  conditioning,
  generalHealth,
}

enum TrainingLocation { gym, home, both }

enum OnboardingNextStep { createRoutine, importProgram }

extension TrainingExperienceLabel on TrainingExperience {
  String get label => switch (this) {
    TrainingExperience.beginner => 'Começando agora',
    TrainingExperience.intermediate => 'Já treino há alguns meses',
    TrainingExperience.advanced => 'Treino há mais de 2 anos',
  };

  String get description => switch (this) {
    TrainingExperience.beginner => 'Quero uma experiência simples e guiada.',
    TrainingExperience.intermediate =>
      'Já conheço os principais exercícios e quero evoluir.',
    TrainingExperience.advanced =>
      'Tenho experiência e quero controlar melhor meus dados.',
  };
}

extension TrainingGoalLabel on TrainingGoal {
  String get label => switch (this) {
    TrainingGoal.hypertrophy => 'Ganhar massa muscular',
    TrainingGoal.strength => 'Aumentar força',
    TrainingGoal.fatLoss => 'Reduzir gordura corporal',
    TrainingGoal.conditioning => 'Melhorar condicionamento',
    TrainingGoal.generalHealth => 'Saúde e qualidade de vida',
  };
}

extension TrainingLocationLabel on TrainingLocation {
  String get label => switch (this) {
    TrainingLocation.gym => 'Academia',
    TrainingLocation.home => 'Casa',
    TrainingLocation.both => 'Academia e casa',
  };
}

extension OnboardingNextStepLabel on OnboardingNextStep {
  String get label => switch (this) {
    OnboardingNextStep.createRoutine => 'Montar minha própria ficha',
    OnboardingNextStep.importProgram => 'Importar um programa pronto',
  };

  String get description => switch (this) {
    OnboardingNextStep.createRoutine =>
      'Você poderá escolher exercícios, séries e descansos.',
    OnboardingNextStep.importProgram =>
      'Você poderá começar por um modelo e adaptar depois.',
  };
}

@immutable
class OnboardingProfile {
  OnboardingProfile({
    required this.name,
    required this.experience,
    required this.goal,
    required this.trainingDaysPerWeek,
    required this.sessionDurationMinutes,
    required this.location,
    required List<String> equipment,
    required List<String> avoidedExercises,
    required List<String> trainingPreferences,
    required this.measurementSystem,
    required this.nextStep,
    required this.isCompleted,
    required this.isPersonalized,
  }) : equipment = UnmodifiableListView<String>(List<String>.from(equipment)),
       avoidedExercises = UnmodifiableListView<String>(
         List<String>.from(avoidedExercises),
       ),
       trainingPreferences = UnmodifiableListView<String>(
         List<String>.from(trainingPreferences),
       );

  factory OnboardingProfile.defaults() {
    return OnboardingProfile(
      name: '',
      experience: TrainingExperience.intermediate,
      goal: TrainingGoal.hypertrophy,
      trainingDaysPerWeek: 4,
      sessionDurationMinutes: 60,
      location: TrainingLocation.gym,
      equipment: const <String>[],
      avoidedExercises: const <String>[],
      trainingPreferences: const <String>[],
      measurementSystem: MeasurementSystem.metric,
      nextStep: OnboardingNextStep.createRoutine,
      isCompleted: false,
      isPersonalized: false,
    );
  }

  final String name;
  final TrainingExperience experience;
  final TrainingGoal goal;
  final int trainingDaysPerWeek;
  final int sessionDurationMinutes;
  final TrainingLocation location;
  final List<String> equipment;
  final List<String> avoidedExercises;
  final List<String> trainingPreferences;
  final MeasurementSystem measurementSystem;
  final OnboardingNextStep nextStep;
  final bool isCompleted;
  final bool isPersonalized;

  String get displayName {
    final normalized = name.trim();
    return normalized.isEmpty ? 'Atleta' : normalized;
  }

  OnboardingProfile normalized() {
    return copyWith(
      name: displayName,
      trainingDaysPerWeek: trainingDaysPerWeek.clamp(2, 7).toInt(),
      sessionDurationMinutes: sessionDurationMinutes.clamp(20, 180).toInt(),
      equipment: _normalizeValues(equipment),
      avoidedExercises: _normalizeValues(avoidedExercises),
      trainingPreferences: _normalizeValues(trainingPreferences),
    );
  }

  OnboardingProfile copyWith({
    String? name,
    TrainingExperience? experience,
    TrainingGoal? goal,
    int? trainingDaysPerWeek,
    int? sessionDurationMinutes,
    TrainingLocation? location,
    List<String>? equipment,
    List<String>? avoidedExercises,
    List<String>? trainingPreferences,
    MeasurementSystem? measurementSystem,
    OnboardingNextStep? nextStep,
    bool? isCompleted,
    bool? isPersonalized,
  }) {
    return OnboardingProfile(
      name: name ?? this.name,
      experience: experience ?? this.experience,
      goal: goal ?? this.goal,
      trainingDaysPerWeek: trainingDaysPerWeek ?? this.trainingDaysPerWeek,
      sessionDurationMinutes:
          sessionDurationMinutes ?? this.sessionDurationMinutes,
      location: location ?? this.location,
      equipment: equipment ?? this.equipment,
      avoidedExercises: avoidedExercises ?? this.avoidedExercises,
      trainingPreferences: trainingPreferences ?? this.trainingPreferences,
      measurementSystem: measurementSystem ?? this.measurementSystem,
      nextStep: nextStep ?? this.nextStep,
      isCompleted: isCompleted ?? this.isCompleted,
      isPersonalized: isPersonalized ?? this.isPersonalized,
    );
  }

  static List<String> _normalizeValues(List<String> values) {
    final normalized = <String>[];
    final seen = <String>{};

    for (final value in values) {
      final trimmed = value.trim();
      final key = trimmed.toLowerCase();

      if (trimmed.isEmpty || seen.contains(key)) {
        continue;
      }

      seen.add(key);
      normalized.add(trimmed);
    }

    return normalized;
  }
}

@immutable
class OnboardingState {
  const OnboardingState({
    required this.profile,
    required this.hasCompletionDecision,
  });

  final OnboardingProfile profile;
  final bool hasCompletionDecision;

  OnboardingState copyWith({
    OnboardingProfile? profile,
    bool? hasCompletionDecision,
  }) {
    return OnboardingState(
      profile: profile ?? this.profile,
      hasCompletionDecision:
          hasCompletionDecision ?? this.hasCompletionDecision,
    );
  }
}
