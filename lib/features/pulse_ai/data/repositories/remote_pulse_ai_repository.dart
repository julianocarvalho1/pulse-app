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
      ..writeln('- Use no máximo 4 parágrafos curtos.')
      ..writeln(
        '- Escreva como uma conversa natural, não como um relatório padronizado.',
      )
      ..writeln(
        '- Escolha apenas os 2 ou 3 aspectos mais relevantes do contexto.',
      )
      ..writeln(
        '- Interprete os dados em conjunto e evite repetir todos os números recebidos.',
      )
      ..writeln(
        '- Varie a construção das frases e evite respostas com o mesmo roteiro.',
      )
      ..writeln('- Não invente exercícios, cargas ou informações ausentes.')
      ..writeln('- Não faça diagnóstico nem prescrição médica.')
      ..writeln('- Não mencione o nome do modelo ou do provedor de IA.')
      ..writeln();

    switch (request.mode) {
      case PulseAiAssistantMode.explainWorkout:
      case PulseAiAssistantMode.suggestReplacement:
      case PulseAiAssistantMode.reviewRoutine:
        _writeRoutineContext(buffer, request, structuredResponse);
        break;
      case PulseAiAssistantMode.analyzeProgress:
        _writeProgressContext(buffer, request.progress!);
        break;
      case PulseAiAssistantMode.explainExercise:
        _writeExerciseContext(buffer, request.exercise!);
        break;
    }

    buffer.writeln(
      'Observação de privacidade: nome do usuário, foto, dados pessoais, observações livres e anotações de saúde não foram enviados.',
    );

    return buffer.toString();
  }

  void _writeRoutineContext(
    StringBuffer buffer,
    PulseAiRequest request,
    PulseAiResponse structuredResponse,
  ) {
    final routine = request.routine!;
    buffer
      ..writeln('Dados técnicos enviados pelo aplicativo:')
      ..writeln('Tipo de ficha: ${routine.typeLabel}')
      ..writeln('Quantidade de atividades: ${routine.totalActivities}');

    if (routine.exercises.isEmpty) {
      buffer.writeln('Exercícios: nenhum exercício cadastrado.');
    } else {
      buffer.writeln('Exercícios:');
      for (final indexed in routine.exercises.take(16).indexed) {
        buffer.writeln(_exerciseLine(indexed.$1 + 1, indexed.$2));
      }
      if (routine.exercises.length > 16) {
        buffer.writeln(
          '- Existem mais ${routine.exercises.length - 16} exercícios não listados para limitar o envio.',
        );
      }
    }

    if (routine.cardio.isNotEmpty) {
      buffer.writeln('Cardio planejado:');
      for (final cardio in routine.cardio.take(5)) {
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
  }

  void _writeProgressContext(
    StringBuffer buffer,
    PulseAiProgressSnapshot progress,
  ) {
    buffer
      ..writeln('Resumo numérico do progresso:')
      ..writeln('Período: ${progress.periodLabel}')
      ..writeln('Atividades registradas: ${progress.workouts}')
      ..writeln('Registros concluídos: ${progress.completedWorkouts}')
      ..writeln('Treinos incompletos: ${progress.incompleteWorkouts}')
      ..writeln('Dias ativos: ${progress.activeDays}')
      ..writeln(
        'Frequência semanal média: ${progress.weeklyFrequency.toStringAsFixed(2)}',
      )
      ..writeln('Duração total em segundos: ${progress.durationSeconds}')
      ..writeln('Séries registradas: ${progress.totalSets}')
      ..writeln('Repetições registradas: ${progress.totalReps}')
      ..writeln('Volume total: ${progress.totalVolume.toStringAsFixed(1)}')
      ..writeln('Sequência atual: ${progress.currentStreak}')
      ..writeln('Melhor sequência: ${progress.longestStreak}')
      ..writeln(
        'Sessões de musculação ou treino misto: ${progress.strengthSessions}',
      )
      ..writeln('Sessões somente de cardio: ${progress.cardioSessions}')
      ..writeln('Atividades livres: ${progress.freeActivitySessions}')
      ..writeln('Minutos de atividades livres: ${progress.freeActivityMinutes}')
      ..writeln(
        'Atividades que substituíram treino planejado: ${progress.substituteActivities}',
      )
      ..writeln(
        'Tipos de atividades livres: ${progress.freeActivityLabels.isEmpty ? 'não informados' : progress.freeActivityLabels.join(', ')}',
      );

    if (progress.workoutsChange != null ||
        progress.activeDaysChange != null ||
        progress.durationChange != null ||
        progress.volumeChange != null) {
      buffer
        ..writeln('Comparação percentual com o período anterior:')
        ..writeln('Atividades: ${progress.workoutsChange?.toStringAsFixed(1)}')
        ..writeln(
          'Dias ativos: ${progress.activeDaysChange?.toStringAsFixed(1)}',
        )
        ..writeln('Duração: ${progress.durationChange?.toStringAsFixed(1)}')
        ..writeln('Volume: ${progress.volumeChange?.toStringAsFixed(1)}');
    }

    buffer.writeln(
      'Diferencie aderência à ficha de consistência geral: atividades livres contam como dia ativo, mas não como ficha concluída. Analise tendências de consistência e registro. Não prescreva uma frequência ideal e não conclua que houve ganho de saúde, força ou massa muscular apenas com estes números.',
    );
  }

  void _writeExerciseContext(StringBuffer buffer, Exercise exercise) {
    buffer
      ..writeln('Exercício selecionado:')
      ..writeln('Nome: ${exercise.name}')
      ..writeln('Grupo muscular cadastrado: ${exercise.muscle}')
      ..writeln('Descrição: ${exercise.description}')
      ..writeln('Séries e repetições: ${exercise.reps}')
      ..writeln('Descanso: ${exercise.rest}');

    final sets = exercise.advancedPrescription.primaryPrescription?.sets;
    if (sets != null && sets.isNotEmpty) {
      buffer.writeln('Detalhes das séries:');
      for (final set in sets.take(6)) {
        buffer.writeln('- ${set.summary}');
      }
    }

    buffer.writeln(
      'Explique somente o que pode ser concluído a partir dos dados acima. Dê orientações gerais de execução segura, sem substituir supervisão profissional.',
    );
  }

  String _taskInstruction(PulseAiAssistantMode mode) => switch (mode) {
    PulseAiAssistantMode.explainWorkout =>
      'Explique a organização da ficha, a ordem dos exercícios e os termos técnicos presentes em linguagem simples.',
    PulseAiAssistantMode.suggestReplacement =>
      'Ajude a compreender as alternativas previamente filtradas pelo aplicativo, sem criar novas opções.',
    PulseAiAssistantMode.reviewRoutine =>
      'Faça uma revisão organizacional da ficha, apontando pontos positivos e pontos de atenção sem alterar o treino.',
    PulseAiAssistantMode.analyzeProgress =>
      'Converse com o usuário sobre o momento mais relevante do período. Relacione frequência, consistência, tipos de atividade e evolução registrada sem transformar a resposta em uma lista de métricas. Reconheça o que foi positivo, aponte uma observação útil e termine com uma orientação geral e realista, sem diagnóstico nem prescrição automática.',
    PulseAiAssistantMode.explainExercise =>
      'Explique o exercício selecionado, a prescrição cadastrada e os termos avançados em linguagem simples.',
  };

  String _onlineInsightTitle(PulseAiAssistantMode mode) => switch (mode) {
    PulseAiAssistantMode.explainWorkout => 'Leitura personalizada',
    PulseAiAssistantMode.suggestReplacement => 'Leitura das alternativas',
    PulseAiAssistantMode.reviewRoutine => 'Análise da ficha',
    PulseAiAssistantMode.analyzeProgress => 'Leitura do seu momento',
    PulseAiAssistantMode.explainExercise => 'Explicação personalizada',
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
