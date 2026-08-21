import 'package:flutter/foundation.dart';

@immutable
class ExerciseProgressionSuggestion {
  const ExerciseProgressionSuggestion({
    required this.lastPerformance,
    required this.nextTarget,
    required this.hasHistory,
  });

  const ExerciseProgressionSuggestion.noHistory()
    : lastPerformance = 'Sem histórico',
      nextTarget = 'Use uma carga confortável e priorize a técnica.',
      hasHistory = false;

  final String lastPerformance;
  final String nextTarget;
  final bool hasHistory;
}
