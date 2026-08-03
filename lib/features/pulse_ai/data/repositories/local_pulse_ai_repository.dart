import '../../../../models/exercise.dart';
import '../../domain/models/pulse_ai_models.dart';
import '../../domain/repositories/pulse_ai_repository.dart';

class LocalPulseAiRepository implements PulseAiRepository {
  const LocalPulseAiRepository({
    this.responseDelay = const Duration(milliseconds: 650),
  });

  final Duration responseDelay;

  @override
  Future<PulseAiResponse> analyze(PulseAiRequest request) async {
    if (responseDelay > Duration.zero) {
      await Future<void>.delayed(responseDelay);
    }

    return switch (request.mode) {
      PulseAiAssistantMode.explainWorkout => _explainWorkout(request),
      PulseAiAssistantMode.suggestReplacement => _suggestReplacement(request),
      PulseAiAssistantMode.reviewRoutine => _reviewRoutine(request),
      PulseAiAssistantMode.analyzeProgress => _analyzeProgress(request),
      PulseAiAssistantMode.explainExercise => _explainExercise(request),
    };
  }

  PulseAiResponse _explainWorkout(PulseAiRequest request) {
    final routine = request.routine!;
    final insights = <PulseAiInsight>[
      PulseAiInsight(
        title: 'Estrutura da ficha',
        body:
            '${routine.name} é uma ficha do tipo ${routine.typeLabel.toLowerCase()}, com ${routine.activitySummary}. O foco informado é “${routine.focus}”.',
        tone: PulseAiInsightTone.positive,
      ),
    ];

    if (routine.exercises.isNotEmpty) {
      final orderedNames = routine.exercises
          .take(4)
          .map((exercise) => exercise.name)
          .join(' → ');
      final suffix = routine.exercises.length > 4 ? ' → …' : '';
      insights.add(
        PulseAiInsight(
          title: 'Ordem da sessão',
          body:
              'A ficha começa com $orderedNames$suffix. Siga a ordem cadastrada para preservar a lógica definida na ficha.',
        ),
      );
    }

    final detailedExercises = routine.exercises
        .where((exercise) => exercise.advancedPrescription.hasSetDetails)
        .toList(growable: false);
    if (detailedExercises.isNotEmpty) {
      insights.add(
        PulseAiInsight(
          title: 'RIR, cadência e técnicas',
          body:
              '${detailedExercises.length} exercício${detailedExercises.length == 1 ? '' : 's'} possui${detailedExercises.length == 1 ? '' : 'em'} detalhes avançados. RIR indica quantas repetições ainda seriam possíveis; cadência descreve o ritmo do movimento.',
        ),
      );
    } else if (routine.exercises.isNotEmpty) {
      insights.add(
        const PulseAiInsight(
          title: 'Séries e descanso',
          body:
              'As séries, repetições e pausas aparecem em cada exercício. Registre carga e repetições durante a sessão para acompanhar sua evolução.',
        ),
      );
    }

    if (routine.cardio.isNotEmpty) {
      insights.add(
        PulseAiInsight(
          title: 'Cardio planejado',
          body:
              'Há ${routine.cardio.length} atividade${routine.cardio.length == 1 ? '' : 's'} de cardio cadastrada${routine.cardio.length == 1 ? '' : 's'}.',
        ),
      );
    }

    return PulseAiResponse(
      mode: request.mode,
      title: 'Entenda sua ficha',
      summary:
          'Uma leitura objetiva da estrutura atual, sem modificar nenhum exercício.',
      insights: insights,
    );
  }

  PulseAiResponse _suggestReplacement(PulseAiRequest request) {
    final routine = request.routine!;
    final selectedId = request.selectedExerciseId;
    Exercise? current;
    for (final exercise in routine.exercises) {
      if (exercise.id == selectedId) {
        current = exercise;
        break;
      }
    }

    if (current == null) {
      return PulseAiResponse(
        mode: request.mode,
        title: 'Escolha um exercício',
        summary:
            'Não foi possível identificar qual exercício deve ser substituído.',
        insights: const <PulseAiInsight>[
          PulseAiInsight(
            title: 'Nenhuma alteração realizada',
            body:
                'Volte e selecione um exercício da ficha para consultar alternativas.',
            tone: PulseAiInsightTone.attention,
          ),
        ],
      );
    }

    final alternatives = _compatibleAlternatives(
      current: current,
      catalog: request.catalog,
    );

    final insights = <PulseAiInsight>[
      PulseAiInsight(
        title: 'O que será preservado',
        body:
            'Ao aplicar uma alternativa, o PULSE mantém as séries, repetições, descanso, observações e prescrições avançadas de ${current.name}.',
        tone: PulseAiInsightTone.positive,
      ),
    ];

    if (alternatives.isEmpty) {
      insights.add(
        PulseAiInsight(
          title: 'Sem alternativa compatível',
          body:
              'A biblioteca atual não possui outro exercício cadastrado para ${current.muscle}. Nenhum exercício foi inventado ou adicionado.',
          tone: PulseAiInsightTone.attention,
        ),
      );
    }

    return PulseAiResponse(
      mode: request.mode,
      title: 'Alternativas para ${current.name}',
      summary: alternatives.isEmpty
          ? 'Não encontramos uma troca segura dentro da biblioteca atual.'
          : 'Selecione uma alternativa e revise a troca antes de aplicar.',
      insights: insights,
      alternatives: alternatives,
      selectedExerciseId: current.id,
    );
  }

  PulseAiResponse _reviewRoutine(PulseAiRequest request) {
    final routine = request.routine!;
    final muscleCounts = <String, int>{};
    for (final exercise in routine.exercises) {
      final muscle = exercise.muscle.trim().isEmpty
          ? 'Não informado'
          : exercise.muscle.trim();
      muscleCounts[muscle] = (muscleCounts[muscle] ?? 0) + 1;
    }

    final distribution = muscleCounts.entries.toList(growable: false)
      ..sort((first, second) => second.value.compareTo(first.value));
    final distributionText = distribution.isEmpty
        ? 'A ficha não possui exercícios de musculação.'
        : distribution
              .take(5)
              .map(
                (entry) =>
                    '${entry.key}: ${entry.value} exercício${entry.value == 1 ? '' : 's'}',
              )
              .join(' • ');

    final detailedCount = routine.exercises
        .where((exercise) => exercise.advancedPrescription.hasSetDetails)
        .length;
    final alternativesCount = routine.exercises.fold<int>(
      0,
      (total, exercise) =>
          total + exercise.advancedPrescription.alternatives.length,
    );

    final insights = <PulseAiInsight>[
      PulseAiInsight(title: 'Distribuição muscular', body: distributionText),
      PulseAiInsight(
        title: 'Tamanho da sessão',
        body: _sessionSizeText(routine),
        tone: routine.totalActivities > 10
            ? PulseAiInsightTone.attention
            : PulseAiInsightTone.positive,
      ),
      PulseAiInsight(
        title: 'Nível de detalhamento',
        body:
            '$detailedCount exercício${detailedCount == 1 ? '' : 's'} possui${detailedCount == 1 ? '' : 'em'} séries detalhadas e há $alternativesCount alternativa${alternativesCount == 1 ? '' : 's'} cadastrada${alternativesCount == 1 ? '' : 's'}.',
      ),
    ];

    if (routine.exercises.isEmpty && routine.cardio.isEmpty) {
      insights.add(
        const PulseAiInsight(
          title: 'Ficha vazia',
          body: 'Inclua pelo menos uma atividade antes de iniciar esta ficha.',
          tone: PulseAiInsightTone.attention,
        ),
      );
    } else {
      insights.add(
        const PulseAiInsight(
          title: 'Você mantém o controle',
          body:
              'A análise apenas destaca características da ficha. Mudanças de volume, frequência ou intensidade continuam sob controle do usuário e do profissional responsável.',
        ),
      );
    }

    return PulseAiResponse(
      mode: request.mode,
      title: 'Revisão da ficha',
      summary:
          'Uma análise organizacional da ficha atual, sem diagnóstico e sem alterações automáticas.',
      insights: insights,
    );
  }

  PulseAiResponse _analyzeProgress(PulseAiRequest request) {
    final progress = request.progress!;
    if (progress.isEmpty) {
      return PulseAiResponse(
        mode: request.mode,
        title: 'Seu progresso',
        summary: 'Ainda não há dados suficientes no período selecionado.',
        insights: const <PulseAiInsight>[
          PulseAiInsight(
            title: 'Primeiro passo',
            body:
                'Conclua ou salve um treino para começar a acompanhar frequência, volume e consistência.',
            tone: PulseAiInsightTone.attention,
          ),
        ],
      );
    }

    final completionRate = progress.workouts == 0
        ? 0
        : (progress.completedWorkouts / progress.workouts) * 100;
    final insights = <PulseAiInsight>[
      PulseAiInsight(
        title: 'Consistência no período',
        body:
            '${progress.completedWorkouts} de ${progress.workouts} treinos foram concluídos, em ${progress.activeDays} dias ativos. A frequência média foi de ${progress.weeklyFrequency.toStringAsFixed(1)} dia${progress.weeklyFrequency == 1 ? '' : 's'} por semana.',
        tone: completionRate >= 75
            ? PulseAiInsightTone.positive
            : PulseAiInsightTone.neutral,
      ),
      PulseAiInsight(
        title: 'Volume registrado',
        body:
            'Foram registradas ${progress.totalSets} séries, ${progress.totalReps} repetições e ${_formatVolume(progress.totalVolume)} de volume total.',
      ),
    ];

    final trend = _progressTrend(progress);
    if (trend != null) {
      insights.add(trend);
    }

    if (progress.currentStreak > 0 || progress.longestStreak > 0) {
      insights.add(
        PulseAiInsight(
          title: 'Sequência de treinos',
          body:
              'Sequência atual: ${progress.currentStreak} dia${progress.currentStreak == 1 ? '' : 's'}. Melhor sequência registrada: ${progress.longestStreak}.',
          tone: progress.currentStreak > 0
              ? PulseAiInsightTone.positive
              : PulseAiInsightTone.neutral,
        ),
      );
    }

    return PulseAiResponse(
      mode: request.mode,
      title: 'Leitura do seu progresso',
      summary:
          'Resumo do período ${progress.periodLabel.toLowerCase()}, usando somente os dados registrados no PULSE.',
      insights: insights,
      safetyNote:
          'Os números ajudam a visualizar tendências, mas não substituem avaliação profissional nem consideram fatores de saúde que não foram registrados.',
    );
  }

  PulseAiResponse _explainExercise(PulseAiRequest request) {
    final exercise = request.exercise!;
    final insights = <PulseAiInsight>[
      PulseAiInsight(
        title: 'O que este exercício trabalha',
        body:
            '${exercise.name} está cadastrado para ${exercise.muscle.toLowerCase()}. ${exercise.description}',
        tone: PulseAiInsightTone.positive,
      ),
      PulseAiInsight(
        title: 'Prescrição atual',
        body:
            'A ficha indica ${exercise.reps}, com descanso de ${exercise.rest} entre as séries.',
      ),
    ];

    final sets = exercise.advancedPrescription.primaryPrescription?.sets;
    if (sets != null && sets.isNotEmpty) {
      final details = sets.take(4).map((set) => set.summary).join(' • ');
      insights.add(PulseAiInsight(title: 'Detalhes das séries', body: details));
    } else {
      insights.add(
        const PulseAiInsight(
          title: 'Durante a execução',
          body:
              'Priorize movimento controlado e amplitude confortável. Interrompa a série em caso de dor aguda, tontura ou mal-estar.',
        ),
      );
    }

    return PulseAiResponse(
      mode: request.mode,
      title: exercise.name,
      summary:
          'Uma explicação rápida da prescrição cadastrada para este exercício.',
      insights: insights,
    );
  }

  PulseAiInsight? _progressTrend(PulseAiProgressSnapshot progress) {
    final volumeChange = progress.volumeChange;
    final workoutsChange = progress.workoutsChange;
    if (volumeChange == null && workoutsChange == null) {
      return null;
    }

    final parts = <String>[];
    if (workoutsChange != null) {
      parts.add('treinos ${_formatChange(workoutsChange)}');
    }
    if (volumeChange != null) {
      parts.add('volume ${_formatChange(volumeChange)}');
    }

    final positive = (volumeChange ?? 0) > 0 || (workoutsChange ?? 0) > 0;
    return PulseAiInsight(
      title: 'Comparação com o período anterior',
      body: 'Na comparação disponível: ${parts.join(' e ')}.',
      tone: positive
          ? PulseAiInsightTone.positive
          : PulseAiInsightTone.attention,
    );
  }

  List<PulseAiExerciseAlternative> _compatibleAlternatives({
    required Exercise current,
    required List<Exercise> catalog,
  }) {
    final normalizedMuscle = _normalize(current.muscle);
    if (normalizedMuscle.isEmpty) {
      return const <PulseAiExerciseAlternative>[];
    }
    final byId = <String, Exercise>{};
    for (final exercise in catalog) {
      final isSameExercise =
          exercise.id == current.id ||
          _normalize(exercise.name) == _normalize(current.name);
      final sameMuscle = _normalize(exercise.muscle) == normalizedMuscle;
      if (!isSameExercise && sameMuscle && exercise.id.trim().isNotEmpty) {
        byId.putIfAbsent(exercise.id, () => exercise);
      }
    }

    final sorted = byId.values.toList(growable: false)
      ..sort((first, second) => first.name.compareTo(second.name));

    return sorted
        .take(4)
        .map(
          (exercise) => PulseAiExerciseAlternative(
            exerciseId: exercise.id,
            name: exercise.name,
            muscle: exercise.muscle,
            reason:
                'Trabalha ${exercise.muscle.toLowerCase()} e já faz parte da biblioteca do PULSE.',
          ),
        )
        .toList(growable: false);
  }

  String _sessionSizeText(WorkoutRoutine routine) {
    final total = routine.totalActivities;
    if (total == 0) {
      return 'Não há atividades cadastradas para estimar a organização da sessão.';
    }
    if (total <= 5) {
      return 'A ficha tem $total atividades e apresenta uma estrutura enxuta.';
    }
    if (total <= 9) {
      return 'A ficha tem $total atividades e apresenta uma estrutura intermediária.';
    }
    return 'A ficha tem $total atividades. Vale conferir se a duração planejada continua confortável para o usuário.';
  }

  String _formatVolume(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)} mil kg';
    }
    return '${value.toStringAsFixed(0)} kg';
  }

  String _formatChange(double value) {
    final signal = value > 0 ? '+' : '';
    return '$signal${value.toStringAsFixed(0)}%';
  }

  String _normalize(String value) => value.trim().toLowerCase();
}
