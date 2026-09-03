import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/progress/domain/models/progress_period.dart';
import 'package:pulse/features/progress/domain/services/workout_analytics_service.dart';
import 'package:pulse/features/workouts/domain/models/exercise_log.dart';
import 'package:pulse/features/workouts/domain/models/free_activity_log.dart';
import 'package:pulse/features/workouts/domain/models/workout_history_item.dart';
import 'package:pulse/features/workouts/domain/models/workout_session_status.dart';
import 'package:pulse/features/workouts/domain/models/workout_set.dart';

void main() {
  const service = WorkoutAnalyticsService();

  test('calcula métricas reais e separa completos de incompletos', () {
    final history = <WorkoutHistoryItem>[
      _workout(
        id: 'complete',
        date: DateTime(2026, 7, 29, 10),
        duration: '01:10:30',
        status: WorkoutSessionStatus.completed,
        sets: const <ExerciseSet>[
          ExerciseSet(reps: 10, weight: 20),
          ExerciseSet(reps: 8, weight: 25),
        ],
      ),
      _workout(
        id: 'incomplete',
        date: DateTime(2026, 7, 25, 10),
        duration: '20:00',
        status: WorkoutSessionStatus.incomplete,
        sets: const <ExerciseSet>[ExerciseSet(reps: 5, weight: 10)],
      ),
      _workout(
        id: 'cancelled',
        date: DateTime(2026, 7, 24, 10),
        duration: '10:00',
        status: WorkoutSessionStatus.cancelled,
        sets: const <ExerciseSet>[ExerciseSet(reps: 100, weight: 100)],
      ),
    ];

    final summary = service.buildSummary(
      history: history,
      period: ProgressPeriod.fourWeeks,
      now: DateTime(2026, 7, 30),
    );

    expect(summary.current.workouts, 2);
    expect(summary.current.completedWorkouts, 1);
    expect(summary.current.incompleteWorkouts, 1);
    expect(summary.current.activeDays, 2);
    expect(summary.current.durationSeconds, 5430);
    expect(summary.current.totalSets, 3);
    expect(summary.current.totalReps, 23);
    expect(summary.current.totalVolume, 450);
  });

  test('calcula comparação com período anterior equivalente', () {
    final history = <WorkoutHistoryItem>[
      _workout(
        id: 'current-1',
        date: DateTime(2026, 7, 29),
        sets: const <ExerciseSet>[ExerciseSet(reps: 10, weight: 20)],
      ),
      _workout(
        id: 'current-2',
        date: DateTime(2026, 7, 20),
        sets: const <ExerciseSet>[ExerciseSet(reps: 10, weight: 20)],
      ),
      _workout(
        id: 'previous',
        date: DateTime(2026, 6, 20),
        sets: const <ExerciseSet>[ExerciseSet(reps: 10, weight: 20)],
      ),
    ];

    final summary = service.buildSummary(
      history: history,
      period: ProgressPeriod.fourWeeks,
      now: DateTime(2026, 7, 30),
    );

    expect(summary.previous, isNotNull);
    expect(summary.previous!.workouts, 1);
    expect(summary.comparison!.workoutsChange, 100);
    expect(summary.comparison!.volumeChange, 100);
  });

  test('gera recorde, evolução e calendário por status', () {
    final history = <WorkoutHistoryItem>[
      _workout(
        id: 'first',
        date: DateTime(2026, 7, 28),
        sets: const <ExerciseSet>[ExerciseSet(reps: 10, weight: 20)],
      ),
      _workout(
        id: 'second',
        date: DateTime(2026, 7, 29),
        sets: const <ExerciseSet>[ExerciseSet(reps: 8, weight: 30)],
      ),
      _workout(
        id: 'third',
        date: DateTime(2026, 7, 30),
        status: WorkoutSessionStatus.incomplete,
        sets: const <ExerciseSet>[ExerciseSet(reps: 9, weight: 30)],
      ),
    ];

    final summary = service.buildSummary(
      history: history,
      period: ProgressPeriod.fourWeeks,
      now: DateTime(2026, 7, 30),
    );
    final calendar = service.buildCalendar(history, year: 2026, month: 7);

    expect(summary.personalRecords.single.weight, 30);
    expect(summary.personalRecords.single.reps, 9);
    expect(summary.exerciseProgress.single.points, hasLength(3));
    expect(summary.exerciseProgress.single.latestWeight, 30);
    expect(summary.currentStreak, 3);
    expect(summary.longestStreak, 3);
    expect(calendar[DateTime(2026, 7, 30)]!.hasIncomplete, isTrue);
    expect(calendar[DateTime(2026, 7, 29)]!.hasCompleted, isTrue);
  });

  test('mantém recordes pessoais de todo o histórico fora do filtro', () {
    final history = <WorkoutHistoryItem>[
      _workout(
        id: 'recorde-antigo',
        date: DateTime(2026, 5, 1),
        sets: const <ExerciseSet>[ExerciseSet(reps: 6, weight: 80)],
      ),
      _workout(
        id: 'treino-recente',
        date: DateTime(2026, 7, 29),
        sets: const <ExerciseSet>[ExerciseSet(reps: 10, weight: 50)],
      ),
    ];

    final summary = service.buildSummary(
      history: history,
      period: ProgressPeriod.fourWeeks,
      now: DateTime(2026, 7, 30),
    );

    expect(summary.current.workouts, 1);
    expect(summary.exerciseProgress.single.points, hasLength(1));
    expect(summary.personalRecords.single.weight, 80);
    expect(summary.personalRecords.single.date, DateTime(2026, 5, 1));
  });

  test('mantém aquecimento no histórico sem inflar métricas e recordes', () {
    final history = <WorkoutHistoryItem>[
      _workout(
        id: 'warm-up',
        date: DateTime(2026, 7, 29),
        sets: const <ExerciseSet>[
          ExerciseSet(reps: 20, weight: 100, kind: WorkoutSetKind.warmUp),
          ExerciseSet(reps: 8, weight: 40),
        ],
      ),
    ];

    final summary = service.buildSummary(
      history: history,
      period: ProgressPeriod.fourWeeks,
      now: DateTime(2026, 7, 30),
    );

    expect(history.single.totalWarmUpSets, 1);
    expect(summary.current.totalSets, 1);
    expect(summary.current.totalReps, 8);
    expect(summary.current.totalVolume, 320);
    expect(summary.personalRecords.single.weight, 40);
    expect(summary.exerciseProgress.single.latestWeight, 40);
  });

  test('interpreta durações HH:MM:SS e MM:SS', () {
    expect(service.parseDurationSeconds('01:02:03'), 3723);
    expect(service.parseDurationSeconds('42:15'), 2535);
    expect(service.parseDurationSeconds('90'), 90);
  });

  test('atividade livre conta como dia ativo sem concluir uma ficha', () {
    final freeActivity = WorkoutHistoryItem(
      id: 'crossfit',
      routineName: 'Atividade • CrossFit',
      date: DateTime(2026, 7, 30, 19),
      duration: '60:00',
      exercises: const <ExerciseLog>[],
      freeActivities: const <FreeActivityLog>[
        FreeActivityLog(
          type: FreeActivityType.crossfit,
          durationMinutes: 60,
          intensity: FreeActivityIntensity.intense,
          replacedPlannedWorkout: true,
        ),
      ],
    );
    final strength = _workout(
      id: 'strength',
      date: DateTime(2026, 7, 29, 10),
      sets: const <ExerciseSet>[ExerciseSet(reps: 10, weight: 20)],
    );

    final summary = service.buildSummary(
      history: <WorkoutHistoryItem>[freeActivity, strength],
      period: ProgressPeriod.fourWeeks,
      now: DateTime(2026, 7, 30, 22),
    );
    final calendar = service.buildCalendar(
      <WorkoutHistoryItem>[freeActivity, strength],
      year: 2026,
      month: 7,
    );
    final freeDay = calendar[DateTime(2026, 7, 30)]!;

    expect(summary.current.workouts, 2);
    expect(summary.current.activeDays, 2);
    expect(summary.current.strengthSessions, 1);
    expect(summary.current.freeActivitySessions, 1);
    expect(summary.current.substituteActivities, 1);
    expect(summary.current.freeActivityMinutes, 60);
    expect(summary.current.totalSets, 1);
    expect(summary.current.totalVolume, 200);
    expect(freeDay.total, 1);
    expect(freeDay.hasFreeActivity, isTrue);
    expect(freeDay.hasCompleted, isFalse);
    expect(freeDay.hasIncomplete, isFalse);
  });
}

WorkoutHistoryItem _workout({
  required String id,
  required DateTime date,
  String duration = '30:00',
  WorkoutSessionStatus status = WorkoutSessionStatus.completed,
  required List<ExerciseSet> sets,
}) {
  return WorkoutHistoryItem(
    id: id,
    routineName: 'Treino A',
    date: date,
    duration: duration,
    status: status,
    exercises: <ExerciseLog>[
      ExerciseLog(
        exerciseId: 'supino',
        exerciseName: 'Supino reto',
        sets: sets,
      ),
    ],
  );
}
