import '../models/progress_period.dart';
import '../models/workout_progress_summary.dart';
import '../../../workouts/domain/models/workout_history_item.dart';
import '../../../workouts/domain/models/workout_session_status.dart';

class WorkoutAnalyticsService {
  const WorkoutAnalyticsService();

  WorkoutProgressSummary buildSummary({
    required List<WorkoutHistoryItem> history,
    required ProgressPeriod period,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final end = DateTime(
      reference.year,
      reference.month,
      reference.day,
      23,
      59,
      59,
      999,
    );
    final start = period.startDate(reference);

    final validHistory =
        history
            .where((item) => item.status != WorkoutSessionStatus.cancelled)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    final currentItems = validHistory.where((item) {
      if (item.date.isAfter(end)) {
        return false;
      }
      return start == null || !item.date.isBefore(start);
    }).toList();

    final currentStats = _buildStats(currentItems, start: start, end: end);

    WorkoutPeriodStats? previousStats;
    ProgressComparison? comparison;

    final dayCount = period.dayCount;
    if (start != null && dayCount != null) {
      final previousEnd = start.subtract(const Duration(milliseconds: 1));
      final previousEndDate = DateTime(
        previousEnd.year,
        previousEnd.month,
        previousEnd.day,
      );
      final previousStart = previousEndDate.subtract(
        Duration(days: dayCount - 1),
      );
      final previousItems = validHistory.where((item) {
        return !item.date.isBefore(previousStart) &&
            !item.date.isAfter(previousEnd);
      }).toList();

      previousStats = _buildStats(
        previousItems,
        start: previousStart,
        end: previousEnd,
      );
      comparison = ProgressComparison(
        workoutsChange: _percentageChange(
          currentStats.workouts.toDouble(),
          previousStats.workouts.toDouble(),
        ),
        activeDaysChange: _percentageChange(
          currentStats.activeDays.toDouble(),
          previousStats.activeDays.toDouble(),
        ),
        durationChange: _percentageChange(
          currentStats.durationSeconds.toDouble(),
          previousStats.durationSeconds.toDouble(),
        ),
        volumeChange: _percentageChange(
          currentStats.totalVolume,
          previousStats.totalVolume,
        ),
      );
    }

    final weeklyPoints = _buildWeeklyPoints(
      currentItems,
      start: start,
      end: end,
    );
    final records = _buildPersonalRecords(currentItems);
    final exerciseProgress = _buildExerciseProgress(currentItems);
    final trainingDays = validHistory
        .map((item) => _dateOnly(item.date))
        .toSet();

    return WorkoutProgressSummary(
      workouts: currentItems,
      current: currentStats,
      previous: previousStats,
      comparison: comparison,
      weeklyPoints: weeklyPoints,
      personalRecords: records,
      exerciseProgress: exerciseProgress,
      currentStreak: _currentStreak(trainingDays, reference),
      longestStreak: _longestStreak(trainingDays),
    );
  }

  Map<DateTime, WorkoutDaySummary> buildCalendar(
    List<WorkoutHistoryItem> history, {
    required int year,
    required int month,
  }) {
    final grouped = <DateTime, List<WorkoutHistoryItem>>{};

    for (final item in history) {
      if (item.status == WorkoutSessionStatus.cancelled ||
          item.date.year != year ||
          item.date.month != month) {
        continue;
      }

      final day = _dateOnly(item.date);
      grouped.putIfAbsent(day, () => <WorkoutHistoryItem>[]).add(item);
    }

    return grouped.map((date, items) {
      final sortedItems = List<WorkoutHistoryItem>.from(items)
        ..sort((a, b) => b.date.compareTo(a.date));
      final completed = sortedItems
          .where((item) => item.status == WorkoutSessionStatus.completed)
          .length;
      final incomplete = sortedItems
          .where((item) => item.status == WorkoutSessionStatus.incomplete)
          .length;

      return MapEntry(
        date,
        WorkoutDaySummary(
          date: date,
          items: sortedItems,
          completedCount: completed,
          incompleteCount: incomplete,
        ),
      );
    });
  }

  WorkoutPeriodStats _buildStats(
    List<WorkoutHistoryItem> items, {
    required DateTime? start,
    required DateTime end,
  }) {
    var durationSeconds = 0;
    var totalSets = 0;
    var totalReps = 0;
    var totalVolume = 0.0;
    var completed = 0;
    var incomplete = 0;
    final activeDays = <DateTime>{};

    for (final item in items) {
      durationSeconds += parseDurationSeconds(item.duration);
      totalSets += item.totalSets;
      totalVolume += item.totalVolume;
      activeDays.add(_dateOnly(item.date));

      if (item.status == WorkoutSessionStatus.completed) {
        completed++;
      } else if (item.status == WorkoutSessionStatus.incomplete) {
        incomplete++;
      }

      for (final exercise in item.exercises) {
        for (final set in exercise.sets) {
          totalReps += set.reps;
        }
      }
    }

    final effectiveStart =
        start ??
        (items.isEmpty
            ? end
            : _dateOnly(
                items
                    .map((item) => item.date)
                    .reduce((a, b) => a.isBefore(b) ? a : b),
              ));
    final periodDays = end.difference(effectiveStart).inDays + 1;
    final weeks = periodDays <= 0 ? 1.0 : periodDays / 7.0;

    return WorkoutPeriodStats(
      workouts: items.length,
      completedWorkouts: completed,
      incompleteWorkouts: incomplete,
      activeDays: activeDays.length,
      durationSeconds: durationSeconds,
      totalSets: totalSets,
      totalReps: totalReps,
      totalVolume: totalVolume,
      weeklyFrequency: activeDays.isEmpty ? 0 : activeDays.length / weeks,
    );
  }

  List<WeeklyProgressPoint> _buildWeeklyPoints(
    List<WorkoutHistoryItem> items, {
    required DateTime? start,
    required DateTime end,
  }) {
    if (items.isEmpty) {
      return const <WeeklyProgressPoint>[];
    }

    final firstDay = start == null
        ? _dateOnly(
            items
                .map((item) => item.date)
                .reduce((a, b) => a.isBefore(b) ? a : b),
          )
        : _dateOnly(start);
    final firstWeek = _startOfWeek(firstDay);
    final lastWeek = _startOfWeek(end);
    final points = <WeeklyProgressPoint>[];

    for (
      var cursor = firstWeek;
      !cursor.isAfter(lastWeek);
      cursor = cursor.add(const Duration(days: 7))
    ) {
      final weekEnd = cursor
          .add(const Duration(days: 7))
          .subtract(const Duration(milliseconds: 1));
      final weekItems = items.where((item) {
        return !item.date.isBefore(cursor) && !item.date.isAfter(weekEnd);
      });

      var volume = 0.0;
      var duration = 0;
      var workouts = 0;

      for (final item in weekItems) {
        workouts++;
        volume += item.totalVolume;
        duration += parseDurationSeconds(item.duration);
      }

      points.add(
        WeeklyProgressPoint(
          weekStart: cursor,
          workouts: workouts,
          volume: volume,
          durationSeconds: duration,
        ),
      );
    }

    return points;
  }

  List<PersonalRecord> _buildPersonalRecords(List<WorkoutHistoryItem> items) {
    final records = <String, PersonalRecord>{};

    for (final workout in items) {
      for (final exercise in workout.exercises) {
        final key = _exerciseKey(exercise.exerciseId, exercise.exerciseName);

        for (final set in exercise.sets) {
          if (set.weight <= 0) {
            continue;
          }

          final current = records[key];
          final isBetter =
              current == null ||
              set.weight > current.weight ||
              (set.weight == current.weight && set.reps > current.reps);

          if (isBetter) {
            records[key] = PersonalRecord(
              exerciseKey: key,
              exerciseName: exercise.exerciseName,
              weight: set.weight,
              reps: set.reps,
              date: workout.date,
            );
          }
        }
      }
    }

    final result = records.values.toList()
      ..sort((a, b) {
        final weightOrder = b.weight.compareTo(a.weight);
        if (weightOrder != 0) {
          return weightOrder;
        }
        return a.exerciseName.toLowerCase().compareTo(
          b.exerciseName.toLowerCase(),
        );
      });

    return result;
  }

  List<ExerciseProgressSummary> _buildExerciseProgress(
    List<WorkoutHistoryItem> items,
  ) {
    final grouped = <String, _MutableExerciseProgress>{};
    final chronological = List<WorkoutHistoryItem>.from(items)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final workout in chronological) {
      for (final exercise in workout.exercises) {
        final key = _exerciseKey(exercise.exerciseId, exercise.exerciseName);
        final maxWeight = exercise.sets.fold<double>(
          0,
          (value, set) => set.weight > value ? set.weight : value,
        );

        grouped
            .putIfAbsent(
              key,
              () => _MutableExerciseProgress(
                key: key,
                name: exercise.exerciseName,
              ),
            )
            .points
            .add(
              ExerciseProgressPoint(
                date: workout.date,
                maxWeight: maxWeight,
                totalVolume: exercise.totalVolume,
                totalReps: exercise.totalReps,
              ),
            );
      }
    }

    final result =
        grouped.values
            .map(
              (entry) => ExerciseProgressSummary(
                exerciseKey: entry.key,
                exerciseName: entry.name,
                points: List<ExerciseProgressPoint>.unmodifiable(entry.points),
              ),
            )
            .where((entry) => entry.points.isNotEmpty)
            .toList()
          ..sort(
            (a, b) => a.exerciseName.toLowerCase().compareTo(
              b.exerciseName.toLowerCase(),
            ),
          );

    return result;
  }

  int _currentStreak(Set<DateTime> trainingDays, DateTime now) {
    if (trainingDays.isEmpty) {
      return 0;
    }

    var cursor = _dateOnly(now);
    if (!trainingDays.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var streak = 0;
    while (trainingDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _longestStreak(Set<DateTime> trainingDays) {
    if (trainingDays.isEmpty) {
      return 0;
    }

    final sorted = trainingDays.toList()..sort();
    var longest = 1;
    var current = 1;

    for (var index = 1; index < sorted.length; index++) {
      final difference = sorted[index].difference(sorted[index - 1]).inDays;
      if (difference == 1) {
        current++;
        if (current > longest) {
          longest = current;
        }
      } else if (difference > 1) {
        current = 1;
      }
    }

    return longest;
  }

  int parseDurationSeconds(String duration) {
    final parts = duration
        .trim()
        .split(':')
        .map((part) => int.tryParse(part.trim()) ?? 0)
        .toList();

    return switch (parts.length) {
      3 => parts[0] * 3600 + parts[1] * 60 + parts[2],
      2 => parts[0] * 60 + parts[1],
      1 => parts[0],
      _ => 0,
    };
  }

  double? _percentageChange(double current, double previous) {
    if (previous == 0) {
      if (current == 0) {
        return 0;
      }
      return null;
    }
    return ((current - previous) / previous) * 100;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _startOfWeek(DateTime date) {
    final day = _dateOnly(date);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  String _exerciseKey(String id, String name) {
    final normalizedId = id.trim();
    if (normalizedId.isNotEmpty) {
      return normalizedId;
    }

    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}

class _MutableExerciseProgress {
  _MutableExerciseProgress({required this.key, required this.name});

  final String key;
  final String name;
  final List<ExerciseProgressPoint> points = <ExerciseProgressPoint>[];
}
