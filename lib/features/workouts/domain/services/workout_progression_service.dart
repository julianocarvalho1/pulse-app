import '../../../../models/exercise.dart';
import '../models/exercise_progression_suggestion.dart';
import '../models/workout_history_item.dart';
import '../models/workout_set.dart';

class WorkoutProgressionService {
  const WorkoutProgressionService();

  ExerciseProgressionSuggestion buildSuggestion({
    required Exercise exercise,
    required List<WorkoutHistoryItem> history,
  }) {
    final previousSets = _findLatestSets(exercise.id, history);

    if (previousSets == null || previousSets.isEmpty) {
      return const ExerciseProgressionSuggestion.noHistory();
    }

    final bestSet = previousSets.reduce(_strongerSet);
    final range = _parseRepRange(exercise.reps);
    final lastPerformance = _formatSet(bestSet);

    if (bestSet.weight <= 0) {
      final targetReps = bestSet.reps <= 0 ? range.min : bestSet.reps + 1;
      return ExerciseProgressionSuggestion(
        lastPerformance: lastPerformance,
        nextTarget: 'Tente $targetReps repetições com execução controlada.',
        hasHistory: true,
      );
    }

    final allSetsReachedTop = previousSets.every(
      (set) => set.reps >= range.max && set.weight >= bestSet.weight,
    );

    if (allSetsReachedTop) {
      final nextWeight = bestSet.weight + 2.5;
      return ExerciseProgressionSuggestion(
        lastPerformance: lastPerformance,
        nextTarget:
            'Teste ${_formatWeight(nextWeight)} kg e volte para ${range.min} repetições.',
        hasHistory: true,
      );
    }

    final nextReps = (bestSet.reps + 1).clamp(range.min, range.max);
    return ExerciseProgressionSuggestion(
      lastPerformance: lastPerformance,
      nextTarget:
          'Mantenha ${_formatWeight(bestSet.weight)} kg e tente $nextReps repetições.',
      hasHistory: true,
    );
  }

  List<ExerciseSet>? _findLatestSets(
    String exerciseId,
    List<WorkoutHistoryItem> history,
  ) {
    for (final workout in history) {
      for (final exercise in workout.exercises) {
        if (exercise.exerciseId == exerciseId && exercise.sets.isNotEmpty) {
          return exercise.sets;
        }
      }
    }

    return null;
  }

  ExerciseSet _strongerSet(ExerciseSet first, ExerciseSet second) {
    if (second.weight > first.weight) {
      return second;
    }

    if (second.weight == first.weight && second.reps > first.reps) {
      return second;
    }

    return first;
  }

  _RepRange _parseRepRange(String raw) {
    final target = raw.toLowerCase().contains('x')
        ? raw.toLowerCase().split('x').last
        : raw.toLowerCase();
    final values = RegExp(
      r'\d+',
    ).allMatches(target).map((match) => int.parse(match.group(0)!)).toList();

    if (values.isEmpty) {
      return const _RepRange(8, 12);
    }

    if (values.length == 1) {
      return _RepRange(values.first, values.first);
    }

    // Prescrições por série também podem ser descendentes, por exemplo
    // "15-12-10". `int.clamp` exige que o limite mínimo não seja maior que o
    // máximo, então normalize todos os alvos encontrados antes de sugerir a
    // progressão.
    return _RepRange(
      values.reduce((current, value) => value < current ? value : current),
      values.reduce((current, value) => value > current ? value : current),
    );
  }

  String _formatSet(ExerciseSet set) {
    if (set.weight <= 0) {
      return '${set.reps} repetições';
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
}
