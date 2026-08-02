import '../../../../models/exercise.dart';
import '../models/advanced_workout_prescription.dart';

class RoutineWeekChange {
  const RoutineWeekChange({
    required this.exerciseName,
    required this.fromWeek,
    required this.toWeek,
    required this.fromSummary,
    required this.toSummary,
    required this.usesFallbackWeek,
  });

  final String exerciseName;
  final int fromWeek;
  final int toWeek;
  final String fromSummary;
  final String toSummary;
  final bool usesFallbackWeek;
}

class RoutineWeekProgressionService {
  const RoutineWeekProgressionService();

  List<int> availableWeeks(List<Exercise> exercises) {
    final weeks = <int>{};
    for (final exercise in exercises) {
      for (final week in exercise.advancedPrescription.weeks) {
        weeks.add(week.weekNumber);
      }
    }
    final ordered = weeks.toList()..sort();
    return ordered;
  }

  int activeWeek(List<Exercise> exercises) {
    final counts = <int, int>{};
    for (final exercise in exercises) {
      if (exercise.advancedPrescription.weeks.isEmpty) {
        continue;
      }
      final resolved = resolveWeek(
        exercise.advancedPrescription,
        exercise.advancedPrescription.activeWeek,
      );
      if (resolved == null) {
        continue;
      }
      counts.update(
        resolved.weekNumber,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    if (counts.isEmpty) {
      return 1;
    }
    final ordered = counts.entries.toList()
      ..sort((a, b) {
        final countComparison = b.value.compareTo(a.value);
        return countComparison != 0 ? countComparison : b.key.compareTo(a.key);
      });
    return ordered.first.key;
  }

  WorkoutWeekPrescription? resolveWeek(
    AdvancedExercisePrescription prescription,
    int requestedWeek,
  ) {
    if (prescription.weeks.isEmpty) {
      return null;
    }
    final ordered = List<WorkoutWeekPrescription>.from(prescription.weeks)
      ..sort((a, b) => a.weekNumber.compareTo(b.weekNumber));
    for (final week in ordered) {
      if (week.weekNumber == requestedWeek) {
        return week;
      }
    }

    WorkoutWeekPrescription? previous;
    for (final week in ordered) {
      if (week.weekNumber > requestedWeek) {
        break;
      }
      previous = week;
    }
    return previous ?? ordered.first;
  }

  List<Exercise> applyWeek(List<Exercise> exercises, int requestedWeek) {
    return <Exercise>[
      for (final exercise in exercises)
        if (exercise.advancedPrescription.weeks.isEmpty)
          exercise
        else
          exercise.copyWith(
            advancedPrescription: exercise.advancedPrescription.copyWith(
              activeWeek:
                  resolveWeek(
                    exercise.advancedPrescription,
                    requestedWeek,
                  )?.weekNumber ??
                  exercise.advancedPrescription.activeWeek,
            ),
          ),
    ];
  }

  List<RoutineWeekChange> describeChanges(
    List<Exercise> exercises,
    int requestedWeek,
  ) {
    final changes = <RoutineWeekChange>[];
    for (final exercise in exercises) {
      final prescription = exercise.advancedPrescription;
      if (prescription.weeks.isEmpty) {
        continue;
      }
      final from = resolveWeek(prescription, prescription.activeWeek);
      final to = resolveWeek(prescription, requestedWeek);
      if (from == null || to == null) {
        continue;
      }
      changes.add(
        RoutineWeekChange(
          exerciseName: exercise.name,
          fromWeek: from.weekNumber,
          toWeek: to.weekNumber,
          fromSummary: _weekSummary(from),
          toSummary: _weekSummary(to),
          usesFallbackWeek: to.weekNumber != requestedWeek,
        ),
      );
    }
    return changes;
  }

  String _weekSummary(WorkoutWeekPrescription week) {
    if (week.sets.isEmpty) {
      return 'sem séries detalhadas';
    }
    final targets = week.sets
        .map((set) => set.target.trim())
        .where((target) => target.isNotEmpty)
        .toList(growable: false);
    final targetSummary = targets.isEmpty
        ? ''
        : targets.toSet().length == 1
        ? ' • ${targets.first}'
        : ' • ${targets.join(' / ')}';
    return '${week.sets.length} série${week.sets.length == 1 ? '' : 's'}$targetSummary';
  }
}
