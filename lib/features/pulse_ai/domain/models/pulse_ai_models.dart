import 'package:flutter/foundation.dart';

import '../../../../models/exercise.dart';

enum PulseAiAssistantMode {
  explainWorkout,
  suggestReplacement,
  reviewRoutine,
  analyzeProgress,
  explainExercise;

  String get title => switch (this) {
    PulseAiAssistantMode.explainWorkout => 'Explicar meu treino',
    PulseAiAssistantMode.suggestReplacement => 'Sugerir substituição',
    PulseAiAssistantMode.reviewRoutine => 'Revisar minha ficha',
    PulseAiAssistantMode.analyzeProgress => 'Analisar meu progresso',
    PulseAiAssistantMode.explainExercise => 'Explicar exercício',
  };

  String get description => switch (this) {
    PulseAiAssistantMode.explainWorkout =>
      'Entenda a estrutura, a ordem e os termos usados nesta ficha.',
    PulseAiAssistantMode.suggestReplacement =>
      'Veja alternativas compatíveis com a biblioteca do PULSE.',
    PulseAiAssistantMode.reviewRoutine =>
      'Receba uma leitura geral da distribuição e da organização da ficha.',
    PulseAiAssistantMode.analyzeProgress =>
      'Entenda frequência, volume e consistência do período selecionado.',
    PulseAiAssistantMode.explainExercise =>
      'Entenda execução, prescrição, descanso e detalhes avançados.',
  };
}

enum PulseAiInsightTone { neutral, positive, attention }

@immutable
class PulseAiInsight {
  const PulseAiInsight({
    required this.title,
    required this.body,
    this.tone = PulseAiInsightTone.neutral,
  });

  final String title;
  final String body;
  final PulseAiInsightTone tone;
}

@immutable
class PulseAiExerciseAlternative {
  const PulseAiExerciseAlternative({
    required this.exerciseId,
    required this.name,
    required this.muscle,
    required this.reason,
  });

  final String exerciseId;
  final String name;
  final String muscle;
  final String reason;
}

@immutable
class PulseAiProgressSnapshot {
  const PulseAiProgressSnapshot({
    required this.periodLabel,
    required this.workouts,
    required this.completedWorkouts,
    required this.incompleteWorkouts,
    required this.activeDays,
    required this.durationSeconds,
    required this.totalSets,
    required this.totalReps,
    required this.totalVolume,
    required this.weeklyFrequency,
    required this.currentStreak,
    required this.longestStreak,
    this.workoutsChange,
    this.activeDaysChange,
    this.durationChange,
    this.volumeChange,
    this.strengthSessions = 0,
    this.cardioSessions = 0,
    this.freeActivitySessions = 0,
    this.substituteActivities = 0,
    this.freeActivityMinutes = 0,
    this.freeActivityLabels = const <String>[],
  });

  final String periodLabel;
  final int workouts;
  final int completedWorkouts;
  final int incompleteWorkouts;
  final int activeDays;
  final int durationSeconds;
  final int totalSets;
  final int totalReps;
  final double totalVolume;
  final double weeklyFrequency;
  final int currentStreak;
  final int longestStreak;
  final double? workoutsChange;
  final double? activeDaysChange;
  final double? durationChange;
  final double? volumeChange;
  final int strengthSessions;
  final int cardioSessions;
  final int freeActivitySessions;
  final int substituteActivities;
  final int freeActivityMinutes;
  final List<String> freeActivityLabels;

  bool get isEmpty => workouts == 0;
}

@immutable
class PulseAiRequest {
  const PulseAiRequest({
    required this.mode,
    this.routine,
    this.catalog = const <Exercise>[],
    this.selectedExerciseId,
    this.progress,
    this.exercise,
  }) : assert(
         (mode == PulseAiAssistantMode.analyzeProgress && progress != null) ||
             (mode == PulseAiAssistantMode.explainExercise &&
                 exercise != null) ||
             ((mode == PulseAiAssistantMode.explainWorkout ||
                     mode == PulseAiAssistantMode.suggestReplacement ||
                     mode == PulseAiAssistantMode.reviewRoutine) &&
                 routine != null),
         'O contexto necessário para a análise não foi informado.',
       );

  final PulseAiAssistantMode mode;
  final WorkoutRoutine? routine;
  final List<Exercise> catalog;
  final String? selectedExerciseId;
  final PulseAiProgressSnapshot? progress;
  final Exercise? exercise;
}

@immutable
class PulseAiResponse {
  const PulseAiResponse({
    required this.mode,
    required this.title,
    required this.summary,
    required this.insights,
    this.alternatives = const <PulseAiExerciseAlternative>[],
    this.selectedExerciseId,
    this.safetyNote =
        'Use estas informações como apoio. Em caso de dor, limitação ou condição de saúde, procure orientação profissional.',
    this.generatedLocally = true,
    this.providerModel,
    this.remoteResponseId,
    this.fallbackMessage,
  });

  final PulseAiAssistantMode mode;
  final String title;
  final String summary;
  final List<PulseAiInsight> insights;
  final List<PulseAiExerciseAlternative> alternatives;
  final String? selectedExerciseId;
  final String safetyNote;
  final bool generatedLocally;
  final String? providerModel;
  final String? remoteResponseId;
  final String? fallbackMessage;

  PulseAiResponse copyWith({
    PulseAiAssistantMode? mode,
    String? title,
    String? summary,
    List<PulseAiInsight>? insights,
    List<PulseAiExerciseAlternative>? alternatives,
    String? selectedExerciseId,
    bool clearSelectedExerciseId = false,
    String? safetyNote,
    bool? generatedLocally,
    String? providerModel,
    bool clearProviderModel = false,
    String? remoteResponseId,
    bool clearRemoteResponseId = false,
    String? fallbackMessage,
    bool clearFallbackMessage = false,
  }) {
    return PulseAiResponse(
      mode: mode ?? this.mode,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      insights: insights ?? this.insights,
      alternatives: alternatives ?? this.alternatives,
      selectedExerciseId: clearSelectedExerciseId
          ? null
          : (selectedExerciseId ?? this.selectedExerciseId),
      safetyNote: safetyNote ?? this.safetyNote,
      generatedLocally: generatedLocally ?? this.generatedLocally,
      providerModel: clearProviderModel
          ? null
          : (providerModel ?? this.providerModel),
      remoteResponseId: clearRemoteResponseId
          ? null
          : (remoteResponseId ?? this.remoteResponseId),
      fallbackMessage: clearFallbackMessage
          ? null
          : (fallbackMessage ?? this.fallbackMessage),
    );
  }

  bool get hasApplicableChange =>
      mode == PulseAiAssistantMode.suggestReplacement &&
      alternatives.isNotEmpty &&
      selectedExerciseId != null;
}
