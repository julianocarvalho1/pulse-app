import '../../../../models/exercise.dart';
import '../../domain/models/pulse_ai_models.dart';
import '../../domain/repositories/pulse_ai_repository.dart';
import 'local_pulse_ai_repository.dart';
import 'pulse_ai_remote_client.dart';

class RemotePulseAiRepository implements PulseAiRepository {
  const RemotePulseAiRepository({
    required this.client,
    this.localAnalyzer = const LocalPulseAiRepository(
      responseDelay: Duration.zero,
    ),
  });

  final PulseAiRemoteClient client;
  final LocalPulseAiRepository localAnalyzer;

  @override
  Future<PulseAiResponse> analyze(PulseAiRequest request) async {
    final structuredResponse = await localAnalyzer.analyze(request);

    if (request.mode == PulseAiAssistantMode.analyzeProgress) {
      return structuredResponse.copyWith(
        generatedLocally: true,
        fallbackMessage:
            'Para proteger suas métricas de atividade física, esta análise é feita no aparelho.',
        clearProviderModel: true,
        clearRemoteResponseId: true,
      );
    }

    if (request.mode == PulseAiAssistantMode.suggestReplacement &&
        structuredResponse.alternatives.isEmpty) {
      return structuredResponse;
    }

    final remoteAnswer = await client.ask(
      PulseAiRemoteRequest(
        mode: request.mode.name,
        context: _buildContext(request, structuredResponse),
      ),
    );
    final cleanedAnswer = _cleanAnswer(remoteAnswer.answer);

    final supportingInsights =
        request.mode == PulseAiAssistantMode.analyzeProgress
        ? const <PulseAiInsight>[]
        : structuredResponse.insights;

    return structuredResponse.copyWith(
      insights: <PulseAiInsight>[
        PulseAiInsight(
          title: _onlineInsightTitle(request.mode),
          body: cleanedAnswer,
          tone: PulseAiInsightTone.neutral,
        ),
        ...supportingInsights,
      ],
      generatedLocally: false,
      providerModel: remoteAnswer.model,
      remoteResponseId: remoteAnswer.responseId,
      clearFallbackMessage: true,
    );
  }

  Map<String, Object?> _buildContext(
    PulseAiRequest request,
    PulseAiResponse structuredResponse,
  ) {
    return switch (request.mode) {
      PulseAiAssistantMode.explainWorkout ||
      PulseAiAssistantMode.suggestReplacement ||
      PulseAiAssistantMode.reviewRoutine => _routineContext(
        request,
        structuredResponse,
      ),
      PulseAiAssistantMode.analyzeProgress => const <String, Object?>{},
      PulseAiAssistantMode.explainExercise => <String, Object?>{
        'exercise': _exerciseContext(request.exercise!),
      },
    };
  }

  Map<String, Object?> _routineContext(
    PulseAiRequest request,
    PulseAiResponse structuredResponse,
  ) {
    final routine = request.routine!;
    final context = <String, Object?>{
      'routineType': routine.typeLabel,
      'totalActivities': routine.totalActivities,
      'exercises': routine.exercises
          .take(16)
          .map(_exerciseContext)
          .toList(growable: false),
      'omittedExerciseCount': routine.exercises.length > 16
          ? routine.exercises.length - 16
          : 0,
      'cardio': routine.cardio
          .take(5)
          .map(
            (cardio) => <String, Object?>{
              'modality': cardio.modality.label,
              'durationMinutes': cardio.plannedDurationMinutes,
            },
          )
          .toList(growable: false),
    };

    if (request.mode == PulseAiAssistantMode.suggestReplacement) {
      final selected = _selectedExercise(request);
      context['selectedExercise'] = selected == null
          ? null
          : _exerciseContext(selected);
      context['allowedAlternatives'] = structuredResponse.alternatives
          .take(10)
          .map(
            (alternative) => <String, Object?>{
              'name': alternative.name,
              'muscle': alternative.muscle,
            },
          )
          .toList(growable: false);
    }

    return context;
  }

  Map<String, Object?> _exerciseContext(Exercise exercise) {
    final sets = exercise.advancedPrescription.primaryPrescription?.sets;
    return <String, Object?>{
      'name': exercise.name,
      'muscle': exercise.muscle,
      'description': exercise.description,
      'reps': exercise.reps,
      'rest': exercise.rest,
      'sets': sets?.take(6).map((set) => set.summary).toList(growable: false),
    };
  }

  String _onlineInsightTitle(PulseAiAssistantMode mode) => switch (mode) {
    PulseAiAssistantMode.explainWorkout => 'Leitura personalizada',
    PulseAiAssistantMode.suggestReplacement => 'Leitura das alternativas',
    PulseAiAssistantMode.reviewRoutine => 'Análise da ficha',
    PulseAiAssistantMode.analyzeProgress => 'Leitura do seu momento',
    PulseAiAssistantMode.explainExercise => 'Explicação personalizada',
  };

  Exercise? _selectedExercise(PulseAiRequest request) {
    for (final exercise in request.routine!.exercises) {
      if (exercise.id == request.selectedExerciseId) {
        return exercise;
      }
    }
    return null;
  }

  String _cleanAnswer(String value) {
    var cleaned = value
        .replaceAll('**', '')
        .replaceAll('__', '')
        .replaceAll('`', '')
        .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*[-*]\s+', multiLine: true), '• ')
        .trim();

    if (cleaned.length > 3600) {
      cleaned = '${cleaned.substring(0, 3597).trimRight()}…';
    }
    return cleaned;
  }
}
