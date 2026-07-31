import 'package:flutter/foundation.dart';

import '../../../models/exercise.dart';

enum ExerciseModality { strength, cardio, mobility }

@immutable
class ExerciseDefinition {
  ExerciseDefinition({
    required this.id,
    required this.name,
    required this.primaryMuscle,
    required this.description,
    required this.mediaAssetId,
    this.modality = ExerciseModality.strength,
    List<String> aliases = const <String>[],
  }) : aliases = List<String>.unmodifiable(aliases);

  final String id;
  final String name;
  final String primaryMuscle;
  final String description;
  final String mediaAssetId;
  final ExerciseModality modality;
  final List<String> aliases;

  Exercise prescribe(ExercisePrescription prescription) {
    final descriptionOverride = prescription.descriptionOverride.trim();

    return Exercise(
      id: id,
      name: name,
      muscle: primaryMuscle,
      description: descriptionOverride.isEmpty
          ? description
          : descriptionOverride,
      reps: prescription.repsText,
      rest: prescription.restText,
      isSuperset: prescription.isSuperset,
      customNote: prescription.customNote,
    );
  }
}

@immutable
class ExercisePrescription {
  const ExercisePrescription({
    required this.repsText,
    required this.restText,
    this.descriptionOverride = '',
    this.isSuperset = false,
    this.customNote = '',
  });

  final String repsText;
  final String restText;
  final String descriptionOverride;
  final bool isSuperset;
  final String customNote;

  factory ExercisePrescription.fromExercise(Exercise exercise) {
    return ExercisePrescription(
      repsText: exercise.reps,
      restText: exercise.rest,
      descriptionOverride: exercise.description,
      isSuperset: exercise.isSuperset,
      customNote: exercise.customNote,
    );
  }
}
