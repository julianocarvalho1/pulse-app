import '../../../../models/exercise.dart';
import '../models/exercise_log.dart';
import '../models/exercise_progression_suggestion.dart';
import '../models/workout_history_item.dart';
import '../models/workout_progression_mode.dart';
import '../models/workout_set.dart';

class WorkoutProgressionService {
  const WorkoutProgressionService();

  ExerciseProgressionSuggestion buildSuggestion({
    required Exercise exercise,
    required List<WorkoutHistoryItem> history,
    WorkoutProgressionMode mode = WorkoutProgressionMode.withinRange,
  }) {
    final previousLog = _findLatestComparableLog(exercise.id, history);
    final previousSets =
        previousLog?.sets
            .where((set) => set.kind == WorkoutSetKind.working && set.reps > 0)
            .toList(growable: false) ??
        const <ExerciseSet>[];
    final source = _buildSource(
      exercise: exercise,
      mode: mode,
      log: previousLog,
    );

    if (_isTimeBased(exercise)) {
      return ExerciseProgressionSuggestion(
        lastPerformance: previousSets.isEmpty
            ? 'Sem histórico'
            : _formatPerformance(previousSets),
        nextTarget:
            'Siga a duração prescrita (${exercise.reps.trim()}) sem convertê-la em repetições.',
        hasHistory: previousSets.isNotEmpty,
        source: source,
        reason:
            'Séries por tempo e isometrias seguem o tempo da ficha; segundos não são tratados como repetições.',
      );
    }

    if (previousLog == null || previousSets.isEmpty) {
      return ExerciseProgressionSuggestion.noHistory(source: source);
    }

    final targets = _targetsFor(exercise, previousSets.length);
    final lastPerformance = _formatPerformance(previousSets);

    if (mode == WorkoutProgressionMode.followPlan) {
      return ExerciseProgressionSuggestion(
        lastPerformance: lastPerformance,
        nextTarget: _followPlanTarget(targets),
        hasHistory: true,
        source: source,
        reason:
            'O modo Seguir a ficha não cria metas além do que foi prescrito.',
      );
    }

    if (previousSets.length < targets.length) {
      return ExerciseProgressionSuggestion(
        lastPerformance: lastPerformance,
        nextTarget:
            'Complete as ${targets.length} séries previstas antes de avaliar uma progressão.',
        hasHistory: true,
        source: source,
        reason:
            'O último registro possui menos séries concluídas do que a ficha atual.',
      );
    }

    for (var index = 0; index < targets.length; index++) {
      final set = previousSets[index];
      final target = targets[index];
      if (set.reps < target.min) {
        return ExerciseProgressionSuggestion(
          lastPerformance: lastPerformance,
          nextTarget:
              'A série ${index + 1} ficou abaixo de ${target.label}. Priorize atingir os alvos da ficha antes de progredir.',
          hasHistory: true,
          source: source,
          reason:
              'A progressão foi interrompida porque ao menos uma série ficou abaixo do mínimo prescrito.',
        );
      }
    }

    final effortHoldReason = _effortHoldReason(exercise, previousLog);
    if (effortHoldReason != null) {
      return ExerciseProgressionSuggestion(
        lastPerformance: lastPerformance,
        nextTarget:
            'Mantenha a prescrição atual e não aumente a dificuldade neste momento.',
        hasHistory: true,
        source: source,
        reason: effortHoldReason,
      );
    }

    final allSetsReachedTop = List<bool>.generate(
      targets.length,
      (index) => previousSets[index].reps >= targets[index].max,
    ).every((reached) => reached);

    if (allSetsReachedTop) {
      final usesVariableRange = targets.any(
        (target) => target.min != target.max,
      );
      final hasRecordedLoad = previousSets.any((set) => set.weight > 0);

      if (mode == WorkoutProgressionMode.repsThenLoad &&
          usesVariableRange &&
          hasRecordedLoad) {
        final minimum = targets
            .map((target) => target.min)
            .reduce((current, value) => value < current ? value : current);
        return ExerciseProgressionSuggestion(
          lastPerformance: lastPerformance,
          nextTarget:
              'Faixa concluída. Se a execução esteve controlada e isso estiver previsto pelo seu personal, use o menor incremento de carga disponível e retorne a $minimum repetições — nunca ultrapasse o teto da ficha.',
          hasHistory: true,
          source: source,
          reason:
              'Todas as séries alcançaram o topo da faixa; o aumento de carga é opcional e não tem valor fixo.',
        );
      }

      return ExerciseProgressionSuggestion(
        lastPerformance: lastPerformance,
        nextTarget:
            'Prescrição cumprida. Repita os alvos da ficha sem ultrapassar o limite cadastrado.',
        hasHistory: true,
        source: source,
        reason: mode == WorkoutProgressionMode.withinRange
            ? 'O modo Dentro da faixa não sugere aumento automático de carga.'
            : 'A ficha possui alvo fixo ou não há carga registrada para comparar.',
      );
    }

    final pendingTargets = <int>[];
    for (var index = 0; index < targets.length; index++) {
      if (previousSets[index].reps < targets[index].max) {
        pendingTargets.add(
          (previousSets[index].reps + 1).clamp(
            targets[index].min,
            targets[index].max,
          ),
        );
      }
    }
    final nextFloor = pendingTargets.reduce(
      (current, value) => value < current ? value : current,
    );
    final overallTop = targets
        .map((target) => target.max)
        .reduce((current, value) => value > current ? value : current);

    return ExerciseProgressionSuggestion(
      lastPerformance: lastPerformance,
      nextTarget:
          'Mantenha a carga e tente levar as séries abaixo do topo para pelo menos $nextFloor repetições, sem passar de $overallTop.',
      hasHistory: true,
      source: source,
      reason:
          'As séries ficaram dentro da faixa, mas nem todas alcançaram o limite superior.',
    );
  }

  ExerciseLog? _findLatestComparableLog(
    String exerciseId,
    List<WorkoutHistoryItem> history,
  ) {
    for (final workout in history) {
      for (final exercise in workout.exercises) {
        if (exercise.exerciseId == exerciseId &&
            exercise.sets.isNotEmpty &&
            exercise.isLoadComparable) {
          return exercise;
        }
      }
    }
    return null;
  }

  String _buildSource({
    required Exercise exercise,
    required WorkoutProgressionMode mode,
    required ExerciseLog? log,
  }) {
    final parts = <String>[
      'ficha ${exercise.reps.trim()}',
      log == null ? 'sem histórico comparável' : 'último treino local',
      'modo ${mode.label}',
    ];
    if (log?.perceivedRir != null) {
      parts.add('RIR ${log!.perceivedRir} informado');
    }
    return parts.join(' • ');
  }

  String? _effortHoldReason(Exercise exercise, ExerciseLog log) {
    final perceivedRir = log.perceivedRir;
    if (perceivedRir == null) {
      return null;
    }

    final prescribedRir = _lastPrescribedRir(exercise);
    if (prescribedRir != null && perceivedRir < prescribedRir) {
      return 'O RIR percebido ($perceivedRir) ficou abaixo do RIR $prescribedRir da ficha. O esforço serve apenas como sinal auxiliar para não antecipar a progressão.';
    }
    if (prescribedRir == null && perceivedRir == 0) {
      return 'O RIR 0 informado indica que não sobraram repetições com boa execução; por segurança, a sugestão não aumenta a dificuldade.';
    }
    return null;
  }

  int? _lastPrescribedRir(Exercise exercise) {
    final sets = exercise.advancedPrescription.primaryPrescription?.sets;
    if (sets == null || sets.isEmpty) {
      return null;
    }
    for (final set in sets.reversed) {
      if (set.targetRir != null) {
        return set.targetRir;
      }
    }
    return null;
  }

  bool _isTimeBased(Exercise exercise) {
    final advancedSets =
        exercise.advancedPrescription.primaryPrescription?.sets ?? const [];
    final targets = <String>[
      exercise.reps,
      ...advancedSets.map((set) => set.target),
    ].join(' ');
    return RegExp(
      r'\b\d+\s*(?:s|seg|segs|segundo|segundos|min|minuto|minutos)\b',
      caseSensitive: false,
    ).hasMatch(targets);
  }

  String _followPlanTarget(List<_RepRange> targets) {
    final first = targets.first;
    final allEqual = targets.every(
      (target) => target.min == first.min && target.max == first.max,
    );
    if (allEqual) {
      return 'Repita ${targets.length} séries de ${first.label}, conforme a ficha.';
    }
    return 'Repita os alvos individuais cadastrados em cada série, sem acrescentar repetições.';
  }

  List<_RepRange> _targetsFor(Exercise exercise, int completedSetCount) {
    final advancedSets =
        exercise.advancedPrescription.primaryPrescription?.sets ?? const [];
    if (advancedSets.isNotEmpty) {
      final fallback = _parseRepRange(exercise.reps);
      return advancedSets
          .map((set) => _tryParseRepRange(set.target) ?? fallback)
          .toList(growable: false);
    }

    final raw = exercise.reps.trim().toLowerCase();
    final values = _numbers(raw);
    if (!raw.contains('x') &&
        values.length >= 3 &&
        values.length == completedSetCount) {
      return values.map((value) => _RepRange(value, value)).toList();
    }

    final range = _parseRepRange(raw);
    final prescribedSetCount = _parseSetCount(raw) ?? completedSetCount;
    return List<_RepRange>.filled(prescribedSetCount, range);
  }

  int? _parseSetCount(String raw) {
    if (!raw.contains('x')) {
      return null;
    }
    final value = int.tryParse(raw.split('x').first.trim());
    return value != null && value > 0 ? value : null;
  }

  _RepRange _parseRepRange(String raw) {
    return _tryParseRepRange(raw) ?? const _RepRange(8, 12);
  }

  _RepRange? _tryParseRepRange(String raw) {
    final target = raw.toLowerCase().contains('x')
        ? raw.toLowerCase().split('x').last
        : raw.toLowerCase();
    final values = _numbers(target);

    if (values.isEmpty) {
      return null;
    }
    if (values.length == 1) {
      return _RepRange(values.first, values.first);
    }
    return _RepRange(
      values.reduce((current, value) => value < current ? value : current),
      values.reduce((current, value) => value > current ? value : current),
    );
  }

  List<int> _numbers(String raw) {
    return RegExp(
      r'\d+',
    ).allMatches(raw).map((match) => int.parse(match.group(0)!)).toList();
  }

  String _formatPerformance(List<ExerciseSet> sets) {
    final sameWeight = sets.every((set) => set.weight == sets.first.weight);
    final reps = sets.map((set) => set.reps).join(' / ');
    if (sameWeight) {
      if (sets.first.weight <= 0) {
        return '$reps repetições';
      }
      return '${_formatWeight(sets.first.weight)} kg: $reps reps';
    }
    return sets.map(_formatSet).join(' • ');
  }

  String _formatSet(ExerciseSet set) {
    if (set.weight <= 0) {
      return '${set.reps} reps';
    }
    return '${_formatWeight(set.weight)} kg × ${set.reps}';
  }

  String _formatWeight(double weight) {
    if (weight == weight.roundToDouble()) {
      return weight.toInt().toString();
    }
    return weight.toStringAsFixed(1).replaceAll('.', ',');
  }
}

class _RepRange {
  const _RepRange(this.min, this.max);

  final int min;
  final int max;

  String get label => min == max ? '$min repetições' : '$min–$max repetições';
}
