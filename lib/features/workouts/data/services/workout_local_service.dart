import 'package:sqflite/sqflite.dart';

import '../../../../core/database/pulse_database.dart';
import '../../../../models/exercise.dart';
import '../../domain/models/active_workout_session.dart';
import '../../domain/models/cardio_log.dart';
import '../../domain/models/exercise_log.dart';
import '../../domain/models/workout_history_item.dart';
import '../../domain/models/workout_session_status.dart';
import '../../domain/models/workout_set.dart';

class WorkoutLocalService {
  WorkoutLocalService(this._pulseDatabase);

  final PulseDatabase _pulseDatabase;

  Future<void> initialize() async {
    await _pulseDatabase.database;
  }

  Future<bool> hasWorkoutData() async {
    final db = await _pulseDatabase.database;

    final counts = await Future.wait<int>([
      _countRows(db, 'custom_exercises'),
      _countRows(db, 'routines'),
      _countRows(db, 'workout_history'),
    ]);

    return counts.any((count) => count > 0);
  }

  Future<List<Exercise>> loadCustomExercises() async {
    final db = await _pulseDatabase.database;
    final rows = await db.query(
      'custom_exercises',
      orderBy: 'created_at ASC, id ASC',
    );

    return rows.map(_exerciseFromRow).toList();
  }

  Future<void> saveCustomExercises(List<Exercise> exercises) async {
    final db = await _pulseDatabase.database;

    await db.transaction((transaction) async {
      await transaction.delete('custom_exercises');

      final batch = transaction.batch();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      for (var index = 0; index < exercises.length; index++) {
        batch.insert(
          'custom_exercises',
          _exerciseToRow(exercises[index], createdAt: timestamp + index),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
    });
  }

  Future<List<WorkoutRoutine>> loadRoutines() async {
    final db = await _pulseDatabase.database;
    final routineRows = await db.query('routines', orderBy: 'sort_order ASC');

    final routines = <WorkoutRoutine>[];

    for (final routineRow in routineRows) {
      final exerciseRows = await db.query(
        'routine_exercises',
        where: 'routine_id = ?',
        whereArgs: [routineRow['id']],
        orderBy: 'sort_order ASC',
      );

      final cardioRows = await db.query(
        'routine_cardio',
        where: 'routine_id = ?',
        whereArgs: <Object?>[routineRow['id']],
        orderBy: 'sort_order ASC',
      );

      routines.add(
        WorkoutRoutine(
          id: routineRow['id']?.toString() ?? '',
          name: routineRow['name']?.toString() ?? '',
          focus: routineRow['focus']?.toString() ?? '',
          groupName: routineRow['group_name']?.toString() ?? '',
          exercises: exerciseRows.map(_exerciseFromRow).toList(),
          cardio: cardioRows
              .map(
                (row) => RoutineCardio(
                  id: row['cardio_id']?.toString() ?? '',
                  modality: CardioModality.fromStorage(row['modality']),
                  plannedDurationMinutes: _readInt(
                    row['planned_duration_minutes'],
                  ),
                  notes: row['notes']?.toString() ?? '',
                ),
              )
              .toList(growable: false),
        ),
      );
    }

    return routines;
  }

  Future<void> saveRoutines(List<WorkoutRoutine> routines) async {
    final db = await _pulseDatabase.database;

    await db.transaction((transaction) async {
      await transaction.delete('routines');

      for (
        var routineIndex = 0;
        routineIndex < routines.length;
        routineIndex++
      ) {
        final routine = routines[routineIndex];

        await transaction.insert('routines', {
          'id': routine.id,
          'name': routine.name,
          'focus': routine.focus,
          'group_name': routine.groupName,
          'sort_order': routineIndex,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        final batch = transaction.batch();

        for (
          var exerciseIndex = 0;
          exerciseIndex < routine.exercises.length;
          exerciseIndex++
        ) {
          batch.insert('routine_exercises', {
            'routine_id': routine.id,
            'exercise_id': routine.exercises[exerciseIndex].id,
            'sort_order': exerciseIndex,
            ..._exerciseToRow(
              routine.exercises[exerciseIndex],
              includeId: false,
            ),
          });
        }

        await batch.commit(noResult: true);

        if (routine.cardio.isNotEmpty) {
          final cardioBatch = transaction.batch();
          for (
            var cardioIndex = 0;
            cardioIndex < routine.cardio.length;
            cardioIndex++
          ) {
            final entry = routine.cardio[cardioIndex];
            cardioBatch.insert('routine_cardio', <String, Object?>{
              'routine_id': routine.id,
              'cardio_id': entry.id,
              'sort_order': cardioIndex,
              'modality': entry.modality.storageValue,
              'planned_duration_minutes': entry.plannedDurationMinutes,
              'notes': entry.notes,
            });
          }
          await cardioBatch.commit(noResult: true);
        }
      }
    });
  }

  Future<List<WorkoutHistoryItem>> loadHistory() async {
    final db = await _pulseDatabase.database;
    final historyRows = await db.query(
      'workout_history',
      orderBy: 'date_ms DESC',
    );

    final history = <WorkoutHistoryItem>[];

    for (final historyRow in historyRows) {
      final historyId = historyRow['id']?.toString() ?? '';

      final exerciseRows = await db.query(
        'workout_history_exercises',
        where: 'history_id = ?',
        whereArgs: [historyId],
        orderBy: 'sort_order ASC',
      );

      final exerciseLogs = <ExerciseLog>[];

      for (final exerciseRow in exerciseRows) {
        final logId = exerciseRow['id'];

        final setRows = await db.query(
          'workout_history_sets',
          where: 'history_exercise_id = ?',
          whereArgs: [logId],
          orderBy: 'set_order ASC',
        );

        exerciseLogs.add(
          ExerciseLog(
            exerciseId: exerciseRow['exercise_id']?.toString() ?? '',
            exerciseName: exerciseRow['exercise_name']?.toString() ?? '',
            sets: setRows
                .map(
                  (setRow) => ExerciseSet(
                    reps: _readInt(setRow['reps']),
                    weight: _readDouble(setRow['weight']),
                  ),
                )
                .toList(),
          ),
        );
      }

      final cardioRows = await db.query(
        'workout_history_cardio',
        where: 'history_id = ?',
        whereArgs: <Object?>[historyId],
        orderBy: 'sort_order ASC',
      );

      final cardioLogs = cardioRows
          .map(
            (row) => CardioLog(
              modality: CardioModality.fromStorage(row['modality']),
              plannedDurationMinutes: _readInt(row['planned_duration_minutes']),
              actualDurationMinutes: _readInt(row['actual_duration_minutes']),
              distanceKm: _readNullableDouble(row['distance_km']),
              averageSpeedKmh: _readNullableDouble(row['average_speed_kmh']),
              inclinePercent: _readNullableDouble(row['incline_percent']),
              resistanceLevel: _readNullableDouble(row['resistance_level']),
              perceivedEffort: _readNullableInt(row['perceived_effort']),
              averageHeartRateBpm: _readNullableInt(
                row['average_heart_rate_bpm'],
              ),
              notes: row['notes']?.toString() ?? '',
            ),
          )
          .toList(growable: false);

      history.add(
        WorkoutHistoryItem(
          id: historyId,
          routineName: historyRow['routine_name']?.toString() ?? '',
          date: DateTime.fromMillisecondsSinceEpoch(
            _readInt(historyRow['date_ms']),
          ),
          duration: historyRow['duration']?.toString() ?? '',
          exercises: exerciseLogs,
          cardio: cardioLogs,
          notes: historyRow['notes']?.toString() ?? '',
          status: WorkoutSessionStatus.fromStorage(historyRow['status']),
        ),
      );
    }

    return history;
  }

  Future<void> saveHistory(List<WorkoutHistoryItem> history) async {
    final db = await _pulseDatabase.database;

    await db.transaction((transaction) async {
      await transaction.delete('workout_history');

      for (final item in history) {
        await _insertHistoryItem(transaction, item);
      }
    });
  }

  Future<void> insertHistoryItem(WorkoutHistoryItem item) async {
    final db = await _pulseDatabase.database;

    await db.transaction((transaction) async {
      await _insertHistoryItem(transaction, item);
    });
  }

  Future<void> finalizeWorkout(WorkoutHistoryItem item) async {
    final db = await _pulseDatabase.database;

    await db.transaction((transaction) async {
      await _insertHistoryItem(transaction, item);
      await transaction.delete('active_session');
    });
  }

  Future<String> loadActiveProgramName() async {
    final db = await _pulseDatabase.database;
    final rows = await db.query(
      'app_metadata',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['active_program'],
      limit: 1,
    );

    if (rows.isEmpty) {
      return '';
    }

    return rows.first['value']?.toString() ?? '';
  }

  Future<void> saveActiveProgramName(String programName) async {
    final db = await _pulseDatabase.database;

    await db.insert('app_metadata', {
      'key': 'active_program',
      'value': programName,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<ActiveWorkoutSession?> loadActiveSession() async {
    final db = await _pulseDatabase.database;
    final sessionRows = await db.query('active_session', limit: 1);

    if (sessionRows.isEmpty) {
      return null;
    }

    final sessionRow = sessionRows.first;
    final sessionId = sessionRow['id']?.toString() ?? 'active';

    final exerciseRows = await db.query(
      'active_session_exercises',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'sort_order ASC',
    );

    final activeExercises = <ActiveWorkoutExercise>[];

    for (final exerciseRow in exerciseRows) {
      final activeExerciseId = exerciseRow['id'];

      final setRows = await db.query(
        'active_session_sets',
        where: 'session_exercise_id = ?',
        whereArgs: [activeExerciseId],
        orderBy: 'set_order ASC',
      );

      activeExercises.add(
        ActiveWorkoutExercise(
          exercise: _exerciseFromRow(exerciseRow),
          sets: setRows
              .map(
                (setRow) => ActiveWorkoutSet(
                  setNumber: _readInt(setRow['set_order']) + 1,
                  weightText: setRow['weight_text']?.toString() ?? '',
                  repsText: setRow['reps_text']?.toString() ?? '',
                  isCompleted: _readInt(setRow['is_completed']) == 1,
                ),
              )
              .toList(),
        ),
      );
    }

    final cardioRows = await db.query(
      'active_session_cardio',
      where: 'session_id = ?',
      whereArgs: <Object?>[sessionId],
      orderBy: 'sort_order ASC',
    );

    return ActiveWorkoutSession(
      id: sessionId,
      routineName: sessionRow['routine_name']?.toString() ?? 'Treino do Dia',
      startedAt: DateTime.fromMillisecondsSinceEpoch(
        _readInt(sessionRow['started_at_ms']),
      ),
      elapsedSeconds: _readInt(sessionRow['elapsed_seconds']),
      exercises: activeExercises,
      cardio: cardioRows
          .map(
            (row) => ActiveCardioEntry(
              id: row['cardio_id']?.toString() ?? '',
              modality: CardioModality.fromStorage(row['modality']),
              plannedDurationMinutes: _readInt(row['planned_duration_minutes']),
              actualDurationMinutes: _readInt(row['actual_duration_minutes']),
              distanceKm: _readNullableDouble(row['distance_km']),
              averageSpeedKmh: _readNullableDouble(row['average_speed_kmh']),
              inclinePercent: _readNullableDouble(row['incline_percent']),
              resistanceLevel: _readNullableDouble(row['resistance_level']),
              perceivedEffort: _readNullableInt(row['perceived_effort']),
              averageHeartRateBpm: _readNullableInt(
                row['average_heart_rate_bpm'],
              ),
              notes: row['notes']?.toString() ?? '',
              isCompleted: _readInt(row['is_completed']) == 1,
            ),
          )
          .toList(growable: false),
      notes: sessionRow['notes']?.toString() ?? '',
    );
  }

  Future<void> saveActiveSession(ActiveWorkoutSession session) async {
    final db = await _pulseDatabase.database;

    await db.transaction((transaction) async {
      await transaction.delete('active_session');

      await transaction.insert('active_session', {
        'id': session.id,
        'routine_name': session.routineName,
        'started_at_ms': session.startedAt.millisecondsSinceEpoch,
        'elapsed_seconds': session.elapsedSeconds,
        'notes': session.notes,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      for (
        var exerciseIndex = 0;
        exerciseIndex < session.exercises.length;
        exerciseIndex++
      ) {
        final activeExercise = session.exercises[exerciseIndex];

        final sessionExerciseId = await transaction
            .insert('active_session_exercises', {
              'session_id': session.id,
              'exercise_id': activeExercise.exercise.id,
              'sort_order': exerciseIndex,
              ..._exerciseToRow(activeExercise.exercise, includeId: false),
            });

        final batch = transaction.batch();

        for (
          var setIndex = 0;
          setIndex < activeExercise.sets.length;
          setIndex++
        ) {
          final set = activeExercise.sets[setIndex];

          batch.insert('active_session_sets', {
            'session_exercise_id': sessionExerciseId,
            'set_order': setIndex,
            'weight_text': set.weightText,
            'reps_text': set.repsText,
            'is_completed': set.isCompleted ? 1 : 0,
          });
        }

        await batch.commit(noResult: true);
      }

      if (session.cardio.isNotEmpty) {
        final cardioBatch = transaction.batch();
        for (
          var cardioIndex = 0;
          cardioIndex < session.cardio.length;
          cardioIndex++
        ) {
          final entry = session.cardio[cardioIndex];
          cardioBatch.insert('active_session_cardio', <String, Object?>{
            'session_id': session.id,
            'cardio_id': entry.id,
            'sort_order': cardioIndex,
            'modality': entry.modality.storageValue,
            'planned_duration_minutes': entry.plannedDurationMinutes,
            'actual_duration_minutes': entry.actualDurationMinutes,
            'distance_km': entry.distanceKm,
            'average_speed_kmh': entry.averageSpeedKmh,
            'incline_percent': entry.inclinePercent,
            'resistance_level': entry.resistanceLevel,
            'perceived_effort': entry.perceivedEffort,
            'average_heart_rate_bpm': entry.averageHeartRateBpm,
            'notes': entry.notes,
            'is_completed': entry.isCompleted ? 1 : 0,
          });
        }
        await cardioBatch.commit(noResult: true);
      }
    });
  }

  Future<void> clearActiveSession() async {
    final db = await _pulseDatabase.database;
    await db.delete('active_session');
  }

  Future<void> clearWorkoutData() async {
    final db = await _pulseDatabase.database;

    await db.transaction((transaction) async {
      await transaction.delete('active_session');
      await transaction.delete('workout_history');
      await transaction.delete('routines');
      await transaction.delete('custom_exercises');
      await transaction.delete('body_measurements');
      await transaction.delete(
        'app_metadata',
        where: 'key = ?',
        whereArgs: ['active_program'],
      );
    });
  }

  Future<void> _insertHistoryItem(
    DatabaseExecutor executor,
    WorkoutHistoryItem item,
  ) async {
    await executor.insert('workout_history', {
      'id': item.id,
      'routine_name': item.routineName,
      'date_ms': item.date.millisecondsSinceEpoch,
      'duration': item.duration,
      'notes': item.notes,
      'status': item.status.storageValue,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    for (
      var exerciseIndex = 0;
      exerciseIndex < item.exercises.length;
      exerciseIndex++
    ) {
      final exercise = item.exercises[exerciseIndex];

      final exerciseLogId = await executor.insert('workout_history_exercises', {
        'history_id': item.id,
        'exercise_id': exercise.exerciseId,
        'exercise_name': exercise.exerciseName,
        'sort_order': exerciseIndex,
      });

      final batch = executor.batch();

      for (var setIndex = 0; setIndex < exercise.sets.length; setIndex++) {
        final set = exercise.sets[setIndex];

        batch.insert('workout_history_sets', {
          'history_exercise_id': exerciseLogId,
          'set_order': setIndex,
          'reps': set.reps,
          'weight': set.weight,
        });
      }

      await batch.commit(noResult: true);
    }

    if (item.cardio.isNotEmpty) {
      final cardioBatch = executor.batch();
      for (
        var cardioIndex = 0;
        cardioIndex < item.cardio.length;
        cardioIndex++
      ) {
        final entry = item.cardio[cardioIndex];
        cardioBatch.insert('workout_history_cardio', <String, Object?>{
          'history_id': item.id,
          'sort_order': cardioIndex,
          'modality': entry.modality.storageValue,
          'planned_duration_minutes': entry.plannedDurationMinutes,
          'actual_duration_minutes': entry.actualDurationMinutes,
          'distance_km': entry.distanceKm,
          'average_speed_kmh': entry.averageSpeedKmh,
          'incline_percent': entry.inclinePercent,
          'resistance_level': entry.resistanceLevel,
          'perceived_effort': entry.perceivedEffort,
          'average_heart_rate_bpm': entry.averageHeartRateBpm,
          'notes': entry.notes,
        });
      }
      await cardioBatch.commit(noResult: true);
    }
  }

  Map<String, Object?> _exerciseToRow(
    Exercise exercise, {
    bool includeId = true,
    int? createdAt,
  }) {
    return {
      if (includeId) 'id': exercise.id,
      'name': exercise.name,
      'muscle': exercise.muscle,
      'description': exercise.description,
      'reps': exercise.reps,
      'rest': exercise.rest,
      'is_superset': exercise.isSuperset ? 1 : 0,
      'custom_note': exercise.customNote,
      'created_at': ?createdAt,
    };
  }

  Exercise _exerciseFromRow(Map<String, Object?> row) {
    return Exercise(
      id: row['exercise_id']?.toString() ?? row['id']?.toString() ?? '',
      name: row['name']?.toString() ?? '',
      muscle: row['muscle']?.toString() ?? '',
      description: row['description']?.toString() ?? '',
      reps: row['reps']?.toString() ?? '3x 10-12',
      rest: row['rest']?.toString() ?? '60 seg',
      isSuperset: _readInt(row['is_superset']) == 1,
      customNote: row['custom_note']?.toString() ?? '',
    );
  }

  Future<int> _countRows(Database db, String table) async {
    final result = await db.rawQuery('SELECT COUNT(*) AS count FROM $table');

    return _readInt(result.first['count']);
  }

  int _readInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse((value?.toString() ?? '').replaceAll(',', '.')) ?? 0;
  }

  int? _readNullableInt(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }

  double? _readNullableDouble(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString().replaceAll(',', '.'));
  }
}
