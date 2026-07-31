import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../../models/exercise.dart';
import 'workout_generation_request.dart';

enum WorkoutValidationSeverity { warning, error }

@immutable
class WorkoutValidationIssue {
  const WorkoutValidationIssue({
    required this.code,
    required this.message,
    required this.severity,
  });

  final String code;
  final String message;
  final WorkoutValidationSeverity severity;
}

@immutable
class WorkoutValidationResult {
  WorkoutValidationResult({List<WorkoutValidationIssue> issues = const []})
    : issues = UnmodifiableListView<WorkoutValidationIssue>(
        List<WorkoutValidationIssue>.from(issues),
      );

  final List<WorkoutValidationIssue> issues;

  bool get isValid => issues.every(
    (issue) => issue.severity != WorkoutValidationSeverity.error,
  );

  List<WorkoutValidationIssue> get errors => issues
      .where((issue) => issue.severity == WorkoutValidationSeverity.error)
      .toList(growable: false);

  List<WorkoutValidationIssue> get warnings => issues
      .where((issue) => issue.severity == WorkoutValidationSeverity.warning)
      .toList(growable: false);
}

@immutable
class GeneratedWorkoutPlan {
  const GeneratedWorkoutPlan({
    required this.request,
    required this.program,
    required this.validation,
    required this.explanation,
  });

  final WorkoutGenerationRequest request;
  final WorkoutProgram program;
  final WorkoutValidationResult validation;
  final String explanation;
}

class WorkoutGenerationException implements Exception {
  const WorkoutGenerationException(this.message);

  final String message;

  @override
  String toString() => message;
}
