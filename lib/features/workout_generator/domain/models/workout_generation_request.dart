import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../workouts/domain/models/cardio_log.dart';

enum WorkoutGoal {
  hypertrophy,
  strength,
  weightLoss,
  conditioning;

  String get label {
    return switch (this) {
      WorkoutGoal.hypertrophy => 'Hipertrofia',
      WorkoutGoal.strength => 'Força',
      WorkoutGoal.weightLoss => 'Emagrecimento',
      WorkoutGoal.conditioning => 'Condicionamento',
    };
  }

  String get description {
    return switch (this) {
      WorkoutGoal.hypertrophy => 'Mais volume para ganho de massa muscular.',
      WorkoutGoal.strength =>
        'Prioriza movimentos básicos e descansos maiores.',
      WorkoutGoal.weightLoss =>
        'Combina treino de força e cardio de forma prática.',
      WorkoutGoal.conditioning => 'Foco em capacidade física e regularidade.',
    };
  }
}

enum TrainingLevel {
  beginner,
  intermediate,
  advanced;

  String get label {
    return switch (this) {
      TrainingLevel.beginner => 'Iniciante',
      TrainingLevel.intermediate => 'Intermediário',
      TrainingLevel.advanced => 'Avançado',
    };
  }
}

enum GeneratedPlanType {
  strength,
  cardio,
  mixed;

  String get label {
    return switch (this) {
      GeneratedPlanType.strength => 'Musculação',
      GeneratedPlanType.cardio => 'Cardio',
      GeneratedPlanType.mixed => 'Misto',
    };
  }

  String get description {
    return switch (this) {
      GeneratedPlanType.strength => 'Somente exercícios de musculação.',
      GeneratedPlanType.cardio => 'Somente sessões de cardio.',
      GeneratedPlanType.mixed => 'Musculação seguida de cardio.',
    };
  }
}

enum TrainingEnvironment {
  fullGym,
  machinesAndCables,
  freeWeights;

  String get label {
    return switch (this) {
      TrainingEnvironment.fullGym => 'Academia completa',
      TrainingEnvironment.machinesAndCables => 'Máquinas e cabos',
      TrainingEnvironment.freeWeights => 'Pesos livres',
    };
  }

  String get description {
    return switch (this) {
      TrainingEnvironment.fullGym => 'Máquinas, cabos, barras e halteres.',
      TrainingEnvironment.machinesAndCables => 'Prioriza aparelhos e polias.',
      TrainingEnvironment.freeWeights =>
        'Prioriza barras, halteres e peso corporal.',
    };
  }
}

@immutable
class WorkoutGenerationRequest {
  WorkoutGenerationRequest({
    required this.goal,
    required this.level,
    required this.planType,
    required this.daysPerWeek,
    required this.sessionDurationMinutes,
    required this.environment,
    this.cardioModality = CardioModality.treadmill,
    Set<String> priorityMuscles = const <String>{},
    Set<String> avoidedExerciseIds = const <String>{},
    this.hasUnassessedPainOrRestriction = false,
  }) : priorityMuscles = UnmodifiableSetView<String>(
         Set<String>.from(priorityMuscles),
       ),
       avoidedExerciseIds = UnmodifiableSetView<String>(
         Set<String>.from(avoidedExerciseIds),
       );

  final WorkoutGoal goal;
  final TrainingLevel level;
  final GeneratedPlanType planType;
  final int daysPerWeek;
  final int sessionDurationMinutes;
  final TrainingEnvironment environment;
  final CardioModality cardioModality;
  final Set<String> priorityMuscles;
  final Set<String> avoidedExerciseIds;
  final bool hasUnassessedPainOrRestriction;

  bool get includesStrength => planType != GeneratedPlanType.cardio;
  bool get includesCardio => planType != GeneratedPlanType.strength;

  WorkoutGenerationRequest copyWith({
    WorkoutGoal? goal,
    TrainingLevel? level,
    GeneratedPlanType? planType,
    int? daysPerWeek,
    int? sessionDurationMinutes,
    TrainingEnvironment? environment,
    CardioModality? cardioModality,
    Set<String>? priorityMuscles,
    Set<String>? avoidedExerciseIds,
    bool? hasUnassessedPainOrRestriction,
  }) {
    return WorkoutGenerationRequest(
      goal: goal ?? this.goal,
      level: level ?? this.level,
      planType: planType ?? this.planType,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      sessionDurationMinutes:
          sessionDurationMinutes ?? this.sessionDurationMinutes,
      environment: environment ?? this.environment,
      cardioModality: cardioModality ?? this.cardioModality,
      priorityMuscles: priorityMuscles ?? this.priorityMuscles,
      avoidedExerciseIds: avoidedExerciseIds ?? this.avoidedExerciseIds,
      hasUnassessedPainOrRestriction:
          hasUnassessedPainOrRestriction ?? this.hasUnassessedPainOrRestriction,
    );
  }
}
