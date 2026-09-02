import 'package:flutter/foundation.dart';

@immutable
class ExerciseProgressionSuggestion {
  const ExerciseProgressionSuggestion({
    required this.lastPerformance,
    required this.nextTarget,
    required this.hasHistory,
    required this.source,
    required this.reason,
  });

  const ExerciseProgressionSuggestion.noHistory({
    this.source = 'Ficha atual • sem histórico comparável',
    this.reason =
        'Ainda não há uma execução comparável para calcular uma progressão.',
  }) : lastPerformance = 'Sem histórico',
       nextTarget = 'Use uma carga confortável e priorize a técnica.',
       hasHistory = false;

  final String lastPerformance;
  final String nextTarget;
  final bool hasHistory;
  final String source;
  final String reason;
}
