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

    if (request.mode == PulseAiAssistantMode.suggestReplacement &&
        structuredResponse.alternatives.isEmpty) {
      return structuredResponse;
    }

    final remoteAnswer = await client.ask(
      _buildPrompt(request, structuredResponse),
    );
    final cleanedAnswer = _cleanAnswer(remoteAnswer.answer);

    return structuredResponse.copyWith(
      insights: <PulseAiInsight>[
        PulseAiInsight(
          title: _onlineInsightTitle(request.mode),
          body: cleanedAnswer,
          tone: PulseAiInsightTone.neutral,
        ),
        ...structuredResponse.insights,
      ],
      generatedLocally: false,
      providerModel: remoteAnswer.model,
      clearFallbackMessage: true,
    );
  }

  String _buildPrompt(
    PulseAiRequest request,
    PulseAiResponse structuredResponse,
  ) {
    final buffer = StringBuffer()
      ..writeln('Tarefa: ${_taskInstruction(request.mode)}')
      ..writeln()
      ..writeln('Regras específicas desta solicitação:')
      ..writeln('- Responda sem Markdown e sem títulos com símbolos.')
      ..writeln('- Use no máximo 5 parágrafos curtos.')
      ..writeln('- Não invente exercícios, cargas ou informações ausentes.')
      ..writeln('- Não faça diagnóstico nem prescrição médica.')
      ..writeln()
      ..writeln('Dados técnicos enviados pelo aplicativo:')
      ..writeln('Tipo de ficha: ${request.routine.typeLabel}')
      ..writeln('Quantidade de atividades: ${request.routine.totalActivities}');

    if (request.routine.exercises.isEmpty) {
      buffer.writeln('Exercícios: nenhum exercício cadastrado.');
    } else {
      buffer.writeln('Exercícios:');
      for (final indexed in request.routine.exercises.take(16).indexed) {
        final exercise = indexed.$2;
        buffer.writeln(_exerciseLine(indexed.$1 + 1, exercise));
      }
      if (request.routine.exercises.length > 16) {
        buffer.writeln(
          '- Existem mais ${request.routine.exercises.length - 16} exercícios não listados para limitar o envio.',
        );
      }
    }

    if (request.routine.cardio.isNotEmpty) {
      buffer.writeln('Cardio planejado:');
      for (final cardio in request.routine.cardio.take(5)) {
        buffer.writeln(
          '- ${cardio.modality.label}: ${cardio.plannedDurationMinutes} minutos',
        );
      }
    }

    if (request.mode == PulseAiAssistantMode.suggestReplacement) {
      final selected = _selectedExercise(request);
      buffer
        ..writeln()
        ..writeln(
          'Exercício que o usuário selecionou: ${selected?.name ?? 'não identificado'}.',
        )
        ..writeln('Alternativas permitidas pela biblioteca do PULSE:');
      for (final alternative in structuredResponse.alternatives) {
        buffer.writeln('- ${alternative.name} (${alternative.muscle})');
      }
      buffer.writeln(
        'Explique brevemente por que as opções permitidas podem cumprir função semelhante. Não cite nenhuma alternativa fora dessa lista.',
      );
    }

    buffer.writeln(
      'Observação de privacidade: nome do usuário, foto, dados pessoais, observações livres e anotações de saúde não foram enviados.',
    );

    return buffer.toString();
  }

  String _taskInstruction(PulseAiAssistantMode mode) => switch (mode) {
    PulseAiAssistantMode.explainWorkout =>
      'Explique a organização da ficha, a ordem dos exercícios e os termos técnicos presentes em linguagem simples.',
    PulseAiAssistantMode.suggestReplacement =>
      'Ajude a compreender as alternativas previamente filtradas pelo aplicativo, sem criar novas opções.',
    PulseAiAssistantMode.reviewRoutine =>
      'Faça uma revisão organizacional da ficha, apontando pontos positivos e pontos de atenção sem alterar o treino.',
  };

  String _onlineInsightTitle(PulseAiAssistantMode mode) => switch (mode) {
    PulseAiAssistantMode.explainWorkout => 'Explicação com IA',
    PulseAiAssistantMode.suggestReplacement => 'Leitura das alternativas',
    PulseAiAssistantMode.reviewRoutine => 'Revisão com IA',
  };

  String _exerciseLine(int index, Exercise exercise) {
    final parts = <String>[
      '$index. ${exercise.name}',
      'grupo: ${exercise.muscle}',
      'prescrição: ${exercise.reps}',
      'descanso: ${exercise.rest}',
    ];

    final sets = exercise.advancedPrescription.primaryPrescription?.sets;
    if (sets != null && sets.isNotEmpty) {
      final summaries = sets.take(5).map((set) => set.summary).join(' | ');
      parts.add('detalhes das séries: $summaries');
    }

    return '- ${parts.join(' • ')}';
  }

  Exercise? _selectedExercise(PulseAiRequest request) {
    for (final exercise in request.routine.exercises) {
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
