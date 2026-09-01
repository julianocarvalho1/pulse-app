import '../../../../models/exercise.dart';
import '../models/exercise_log.dart';
import '../models/exercise_progression_suggestion.dart';
import '../models/workout_history_item.dart';
import '../models/workout_set.dart';

class WorkoutProgressionService {
  const WorkoutProgressionService();

  ExerciseProgressionSuggestion buildSuggestion({
    required Exercise exercise,
    required List<WorkoutHistoryItem> history,
  }) {
    final previousLog = _findLatestComparableLog(exercise.id, history);
    if (previousLog == null || previousLog.sets.isEmpty) {
      return const ExerciseProgressionSuggestion.noHistory();
    }

    final previousSets = previousLog.sets.where((set) => set.reps > 0).toList();
    if (previousSets.isEmpty) {
      return const ExerciseProgressionSuggestion.noHistory();
    }

    final targets = _targetsFor(exercise, previousSets.length);
    final lastPerformance = _formatPerformance(previousSets);

    if (previousSets.length < targets.length) {
      return ExerciseProgressionSuggestion(
        lastPerformance: lastPerformance,
        nextTarget:
            'Complete as ${targets.length} séries previstas antes de avaliar uma progressão.',
        hasHistory: true,
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
        );
      }
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

      if (usesVariableRange && hasRecordedLoad) {
        final minimum = targets
            .map((target) => target.min)
            .reduce((current, value) => value < current ? value : current);
        return ExerciseProgressionSuggestion(
          lastPerformance: lastPerformance,
          nextTarget:
              'Faixa concluída. Se a execução esteve controlada e isso estiver previsto pelo seu personal, use o menor incremento de carga disponível e retorne a $minimum repetições — nunca ultrapasse o teto da ficha.',
          hasHistory: true,
        );
      }

      return ExerciseProgressionSuggestion(
        lastPerformance: lastPerformance,
        nextTarget:
            'Prescrição cumprida. Repita o alvo da ficha; só altere carga, variação ou dificuldade se isso estiver previsto pelo seu personal.',
        hasHistory: true,
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
      return weight.toStringAsFixed(0);
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
