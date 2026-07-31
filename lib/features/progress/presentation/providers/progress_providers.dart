import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../workouts/presentation/providers/workout_selectors.dart';
import '../../domain/models/progress_period.dart';
import '../../domain/models/workout_progress_summary.dart';
import '../../domain/services/workout_analytics_service.dart';

final workoutAnalyticsServiceProvider = Provider<WorkoutAnalyticsService>(
  (ref) => const WorkoutAnalyticsService(),
);

final workoutProgressSummaryProvider =
    Provider.family<WorkoutProgressSummary, ProgressPeriod>((ref, period) {
      final history = ref.watch(workoutHistoryItemsProvider);
      final service = ref.watch(workoutAnalyticsServiceProvider);

      return service.buildSummary(history: history, period: period);
    });

final workoutCalendarProvider =
    Provider.family<Map<DateTime, WorkoutDaySummary>, DateTime>((ref, month) {
      final history = ref.watch(workoutHistoryItemsProvider);
      final service = ref.watch(workoutAnalyticsServiceProvider);

      return service.buildCalendar(
        history,
        year: month.year,
        month: month.month,
      );
    });
