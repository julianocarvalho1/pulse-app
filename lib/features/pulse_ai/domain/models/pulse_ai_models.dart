import 'package:flutter/foundation.dart';

import '../../../../models/exercise.dart';

enum PulseAiAssistantMode {
  explainWorkout,
  suggestReplacement,
  reviewRoutine;

  String get title => switch (this) {
    PulseAiAssistantMode.explainWorkout => 'Explicar meu treino',
    PulseAiAssistantMode.suggestReplacement => 'Sugerir substituição',
    PulseAiAssistantMode.reviewRoutine => 'Revisar minha ficha',
  };

  String get description => switch (this) {
    PulseAiAssistantMode.explainWorkout =>
      'Entenda a estrutura, a ordem e os termos usados nesta ficha.',
    PulseAiAssistantMode.suggestReplacement =>
      'Veja alternativas compatíveis com a biblioteca do PULSE.',
    PulseAiAssistantMode.reviewRoutine =>
      'Receba uma leitura geral da distribuição e da organização da ficha.',
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
class PulseAiRequest {
  const PulseAiRequest({
    required this.mode,
    required this.routine,
    required this.catalog,
    this.selectedExerciseId,
  });

  final PulseAiAssistantMode mode;
  final WorkoutRoutine routine;
  final List<Exercise> catalog;
  final String? selectedExerciseId;
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
