import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/database/pulse_database.dart';
import 'package:pulse/features/workouts/data/services/workout_local_service.dart';
import 'package:pulse/features/workouts/domain/models/active_workout_session.dart';
import 'package:pulse/features/workouts/domain/models/cardio_log.dart';
import 'package:pulse/features/workouts/domain/models/exercise_log.dart';
import 'package:pulse/features/workouts/domain/models/workout_history_item.dart';
import 'package:pulse/features/workouts/domain/models/workout_set.dart';
import 'package:pulse/models/exercise.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late PulseDatabase database;
  late WorkoutLocalService service;

  setUp(() async {
    sqfliteFfiInit();

    database = PulseDatabase(
      databaseFactoryOverride: databaseFactoryFfi,
      databasePathOverride: inMemoryDatabasePath,
    );

    service = WorkoutLocalService(database);
    await service.initialize();
  });

  tearDown(() async {
    await database.close();
  });

  test('persists routines, history and active session', () async {
    const exercise = Exercise(
      id: 'p1',
      name: 'Supino reto',
      muscle: 'Peito',
      description: 'Controle a descida.',
      reps: '3x 8-10',
      rest: '90 seg',
    );

    final routine = WorkoutRoutine(
      id: 'routine-a',
      name: 'Treino A',
      focus: 'Peito',
      groupName: 'Hipertrofia',
      exercises: const [exercise],
      cardio: const <RoutineCardio>[
        RoutineCardio(
          id: 'routine-cardio-1',
          modality: CardioModality.treadmill,
          plannedDurationMinutes: 20,
          notes: 'Após a musculação.',
        ),
      ],
    );

    await service.saveRoutines([routine]);

    final loadedRoutines = await service.loadRoutines();

    expect(loadedRoutines, hasLength(1));
    expect(loadedRoutines.single.exercises.single.id, 'p1');
    expect(loadedRoutines.single.cardio, hasLength(1));
    expect(
      loadedRoutines.single.cardio.single.modality,
      CardioModality.treadmill,
    );
    expect(loadedRoutines.single.cardio.single.plannedDurationMinutes, 20);

    final historyItem = WorkoutHistoryItem(
      id: 'history-1',
      routineName: 'Treino A',
      date: DateTime(2026, 7, 29),
      duration: '42:00',
      exercises: [
        ExerciseLog(
          exerciseId: 'p1',
          exerciseName: 'Supino reto',
          sets: const [ExerciseSet(reps: 10, weight: 20)],
        ),
      ],
    );

    await service.saveHistory([historyItem]);

    final loadedHistory = await service.loadHistory();

    expect(loadedHistory.single.totalVolume, 200);
    expect(loadedHistory.single.exercises.single.sets.single.reps, 10);

    final activeSession = ActiveWorkoutSession(
      id: 'active',
      routineName: 'Treino A',
      startedAt: DateTime(2026, 7, 29, 21),
      elapsedSeconds: 80,
      exercises: [
        ActiveWorkoutExercise(
          exercise: exercise,
          sets: const [
            ActiveWorkoutSet(
              setNumber: 1,
              weightText: '20',
              repsText: '10',
              isCompleted: true,
            ),
          ],
        ),
      ],
      cardio: const <ActiveCardioEntry>[
        ActiveCardioEntry(
          id: 'routine-cardio-1',
          modality: CardioModality.treadmill,
          plannedDurationMinutes: 20,
          actualDurationMinutes: 18,
          distanceKm: 2.5,
          isCompleted: true,
        ),
      ],
    );

    await service.saveActiveSession(activeSession);

    final restoredSession = await service.loadActiveSession();

    expect(restoredSession, isNotNull);
    expect(restoredSession!.elapsedSeconds, 80);
    expect(restoredSession.exercises.single.sets.single.isCompleted, isTrue);
    expect(restoredSession.cardio, hasLength(1));
    expect(restoredSession.cardio.single.actualDurationMinutes, 18);
    expect(restoredSession.cardio.single.distanceKm, 2.5);
    expect(restoredSession.cardio.single.isCompleted, isTrue);
  });

  test('finaliza histórico e remove sessão ativa na mesma transação', () async {
    const exercise = Exercise(
      id: 'p1',
      name: 'Supino reto',
      muscle: 'Peito',
      description: '',
      reps: '1x 10',
      rest: '60 seg',
    );

    final activeSession = ActiveWorkoutSession(
      id: 'active',
      routineName: 'Treino A',
      startedAt: DateTime(2026, 7, 30, 10),
      elapsedSeconds: 45,
      exercises: <ActiveWorkoutExercise>[
        ActiveWorkoutExercise(
          exercise: exercise,
          sets: const <ActiveWorkoutSet>[
            ActiveWorkoutSet(
              setNumber: 1,
              weightText: '20',
              repsText: '10',
              isCompleted: true,
            ),
          ],
        ),
      ],
    );

    final historyItem = WorkoutHistoryItem(
      id: 'history-finalized',
      routineName: 'Treino A',
      date: DateTime(2026, 7, 30, 10, 1),
      duration: '00:45',
      exercises: <ExerciseLog>[
        ExerciseLog(
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          sets: const <ExerciseSet>[ExerciseSet(reps: 10, weight: 20)],
        ),
      ],
    );

    await service.saveActiveSession(activeSession);
    await service.finalizeWorkout(historyItem);

    expect(await service.loadActiveSession(), isNull);
    final history = await service.loadHistory();
    expect(history.single.id, historyItem.id);
  });

  test('persiste cardio integrado ao histórico', () async {
    final historyItem = WorkoutHistoryItem(
      id: 'cardio-history-1',
      routineName: 'Cardio • Esteira',
      date: DateTime(2026, 7, 31, 13, 30),
      duration: '35:00',
      exercises: const <ExerciseLog>[],
      cardio: const <CardioLog>[
        CardioLog(
          modality: CardioModality.treadmill,
          plannedDurationMinutes: 40,
          actualDurationMinutes: 35,
          distanceKm: 4.8,
          averageSpeedKmh: 8.2,
          inclinePercent: 2,
          perceivedEffort: 7,
          averageHeartRateBpm: 145,
          notes: 'Ritmo moderado.',
        ),
      ],
    );

    await service.saveHistory(<WorkoutHistoryItem>[historyItem]);

    final loadedHistory = await service.loadHistory();
    final loaded = loadedHistory.single;

    expect(loaded.isCardioOnly, isTrue);
    expect(loaded.totalCardioMinutes, 35);
    expect(loaded.totalCardioDistanceKm, 4.8);
    expect(loaded.cardio.single.modality, CardioModality.treadmill);
    expect(loaded.cardio.single.averageHeartRateBpm, 145);
    expect(loaded.cardio.single.notes, 'Ritmo moderado.');
  });
}
