import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/database/pulse_database.dart';
import 'package:pulse/features/backup/data/pulse_backup_service.dart';
import 'package:pulse/features/backup/domain/pulse_backup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PulseDatabase database;
  late PulseBackupService service;

  setUp(() async {
    sqfliteFfiInit();
    SharedPreferences.setMockInitialValues(<String, Object>{});

    database = PulseDatabase(
      databaseFactoryOverride: databaseFactoryFfi,
      databasePathOverride: inMemoryDatabasePath,
    );
    service = PulseBackupService(database: database);
    await database.database;
  });

  tearDown(() async {
    await database.close();
  });

  test('exporta, resume e restaura banco e preferências', () async {
    final db = await database.database;
    final preferences = await SharedPreferences.getInstance();

    await db.insert('routines', <String, Object>{
      'id': 'routine-a',
      'name': 'Treino A',
      'focus': 'Peito',
      'group_name': 'Hipertrofia',
      'sort_order': 0,
    });
    await db.insert('custom_exercises', <String, Object>{
      'id': 'custom-advanced',
      'name': 'Exercício avançado',
      'muscle': 'Peito',
      'description': '',
      'reps': '3x 10',
      'rest': '60 seg',
      'is_superset': 0,
      'custom_note': '',
      'advanced_prescription_json': jsonEncode(<String, Object>{
        'activeWeek': 1,
        'weeks': <Object>[
          <String, Object>{
            'weekNumber': 1,
            'sets': <Object>[
              <String, Object>{'setNumber': 1, 'target': '8–10 reps'},
            ],
          },
        ],
        'alternatives': <Object>[],
      }),
      'created_at': 1,
    });
    await db.insert('workout_history', <String, Object>{
      'id': 'history-a',
      'routine_name': 'Treino A',
      'date_ms': DateTime(2026, 7, 31).millisecondsSinceEpoch,
      'duration': '40:00',
      'notes': '',
      'status': 'completed',
    });
    await db.insert('workout_history_exercises', <String, Object>{
      'history_id': 'history-a',
      'exercise_id': 'supino',
      'exercise_name': 'Supino',
      'sort_order': 0,
      'notes': 'Máquina diferente.',
      'is_load_comparable': 0,
    });
    await db.insert('body_measurements', <String, Object?>{
      'id': 'weight-a',
      'recorded_at_ms': DateTime(2026, 7, 31).millisecondsSinceEpoch,
      'weight_kg': 78.5,
    });
    await db.insert('workout_history_cardio', <String, Object?>{
      'history_id': 'history-a',
      'sort_order': 0,
      'modality': 'treadmill',
      'planned_duration_minutes': 30,
      'actual_duration_minutes': 28,
      'distance_km': 4.2,
      'notes': '',
    });
    await db.insert('workout_history_free_activities', <String, Object?>{
      'history_id': 'history-a',
      'sort_order': 0,
      'activity_type': 'crossfit',
      'duration_minutes': 50,
      'intensity': 'intense',
      'replaced_planned_workout': 1,
      'custom_name': '',
      'notes': 'Aula externa.',
    });
    final restEndsAt = DateTime(2026, 7, 31, 20, 1);
    await db.insert('active_session', <String, Object?>{
      'id': 'active-a',
      'routine_name': 'Treino A',
      'started_at_ms': DateTime(2026, 7, 31, 20).millisecondsSinceEpoch,
      'elapsed_seconds': 45,
      'notes': '',
      'rest_seconds': 42,
      'rest_end_at_ms': restEndsAt.millisecondsSinceEpoch,
      'is_rest_paused': 0,
    });
    await db.insert('active_session_exercises', <String, Object>{
      'session_id': 'active-a',
      'exercise_id': 'supino',
      'sort_order': 0,
      'name': 'Supino',
      'muscle': 'Peito',
      'description': '',
      'reps': '3x 8-12',
      'rest': '90 seg',
      'is_superset': 0,
      'custom_note': '',
      'advanced_prescription_json': '',
      'session_notes': 'Ombro cansado.',
      'is_load_comparable': 0,
    });

    await preferences.setString('user_name', 'Juliano');
    await preferences.setString('settings_theme_mode', 'light');
    await preferences.setBool('app_lock_enabled', true);

    final bytes = await service.exportBytes();
    final preview = service.inspectBytes(bytes);

    expect(preview.routineCount, 1);
    expect(preview.workoutCount, 1);
    expect(preview.measurementCount, 1);

    await db.delete('workout_history');
    await db.delete('routines');
    await db.delete('custom_exercises');
    await db.delete('body_measurements');
    await db.delete('active_session');
    await preferences.clear();

    await service.importBytes(bytes);

    expect(await db.query('routines'), hasLength(1));
    final restoredCustom = await db.query('custom_exercises');
    expect(restoredCustom, hasLength(1));
    expect(
      restoredCustom.single['advanced_prescription_json']?.toString(),
      contains('8–10 reps'),
    );
    expect(await db.query('workout_history'), hasLength(1));
    final restoredHistoryExercise = (await db.query(
      'workout_history_exercises',
    )).single;
    expect(restoredHistoryExercise['notes'], 'Máquina diferente.');
    expect(restoredHistoryExercise['is_load_comparable'], 0);
    expect(await db.query('workout_history_cardio'), hasLength(1));
    final restoredActivities = await db.query(
      'workout_history_free_activities',
    );
    expect(restoredActivities, hasLength(1));
    expect(restoredActivities.single['activity_type'], 'crossfit');
    expect(restoredActivities.single['replaced_planned_workout'], 1);
    expect(await db.query('body_measurements'), hasLength(1));
    final restoredActiveSession = (await db.query('active_session')).single;
    expect(restoredActiveSession['rest_seconds'], 42);
    expect(
      restoredActiveSession['rest_end_at_ms'],
      restEndsAt.millisecondsSinceEpoch,
    );
    expect(restoredActiveSession['is_rest_paused'], 0);
    final restoredActiveExercise = (await db.query(
      'active_session_exercises',
    )).single;
    expect(restoredActiveExercise['session_notes'], 'Ombro cansado.');
    expect(restoredActiveExercise['is_load_comparable'], 0);
    expect(preferences.getString('user_name'), 'Juliano');
    expect(preferences.getString('settings_theme_mode'), 'light');
    expect(preferences.getBool('app_lock_enabled'), isFalse);
  });

  test('não exporta a preferência de proteção local', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('app_lock_enabled', true);
    await preferences.setString('user_name', 'Atleta');
    await preferences.setString(
      'user_profile_photo_path',
      '/data/user/0/pulse/profile/foto.jpg',
    );

    final bytes = await service.exportBytes();
    final decoded = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    final exportedPreferences = decoded['preferences'] as Map<String, dynamic>;

    expect(exportedPreferences['user_name'], 'Atleta');
    expect(exportedPreferences.containsKey('app_lock_enabled'), isFalse);
    expect(exportedPreferences.containsKey('user_profile_photo_path'), isFalse);
  });

  test('rejeita arquivo que não pertence ao PULSE', () {
    final bytes = Uint8List.fromList(
      utf8.encode(
        jsonEncode(<String, Object>{'format': 'outro_app', 'schemaVersion': 1}),
      ),
    );

    expect(
      () => service.inspectBytes(bytes),
      throwsA(isA<PulseBackupException>()),
    );
  });

  test('aceita backup anterior sem a tabela de cardio', () async {
    final bytes = await service.exportBytes();
    final decoded = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    final tables = decoded['tables'] as Map<String, dynamic>;
    tables.remove('workout_history_cardio');

    final legacyBytes = Uint8List.fromList(utf8.encode(jsonEncode(decoded)));

    expect(() => service.inspectBytes(legacyBytes), returnsNormally);
    await service.importBytes(legacyBytes);

    final db = await database.database;
    expect(await db.query('workout_history_cardio'), isEmpty);
  });

  test('aceita backup anterior sem a tabela de atividades livres', () async {
    final bytes = await service.exportBytes();
    final decoded = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    final tables = decoded['tables'] as Map<String, dynamic>;
    tables.remove('workout_history_free_activities');

    final legacyBytes = Uint8List.fromList(utf8.encode(jsonEncode(decoded)));

    expect(() => service.inspectBytes(legacyBytes), returnsNormally);
    await service.importBytes(legacyBytes);

    final db = await database.database;
    expect(await db.query('workout_history_free_activities'), isEmpty);
  });

  test(
    'aceita backup anterior aos campos de anotações por exercício',
    () async {
      final db = await database.database;
      await db.insert('workout_history', <String, Object>{
        'id': 'legacy-history',
        'routine_name': 'Treino A',
        'date_ms': 1,
        'duration': '20:00',
        'notes': '',
        'status': 'completed',
      });
      await db.insert('workout_history_exercises', <String, Object>{
        'history_id': 'legacy-history',
        'exercise_id': 'supino',
        'exercise_name': 'Supino',
        'sort_order': 0,
      });
      await db.insert('active_session', <String, Object>{
        'id': 'legacy-active',
        'routine_name': 'Treino A',
        'started_at_ms': 1,
        'elapsed_seconds': 10,
        'notes': '',
        'rest_seconds': 0,
        'is_rest_paused': 0,
      });
      await db.insert('active_session_exercises', <String, Object>{
        'session_id': 'legacy-active',
        'exercise_id': 'supino',
        'sort_order': 0,
        'name': 'Supino',
        'muscle': 'Peito',
        'description': '',
        'reps': '3x 8-12',
        'rest': '90 seg',
      });

      final decoded =
          jsonDecode(utf8.decode(await service.exportBytes()))
              as Map<String, dynamic>;
      final tables = decoded['tables'] as Map<String, dynamic>;
      final historyRows = tables['workout_history_exercises'] as List<dynamic>;
      final activeRows = tables['active_session_exercises'] as List<dynamic>;
      for (final row in historyRows.cast<Map<String, dynamic>>()) {
        row.remove('notes');
        row.remove('is_load_comparable');
      }
      for (final row in activeRows.cast<Map<String, dynamic>>()) {
        row.remove('session_notes');
        row.remove('is_load_comparable');
      }

      await service.importBytes(
        Uint8List.fromList(utf8.encode(jsonEncode(decoded))),
      );

      final restoredHistory = (await db.query(
        'workout_history_exercises',
      )).single;
      expect(restoredHistory['notes'], '');
      expect(restoredHistory['is_load_comparable'], 1);
      final restoredActive = (await db.query(
        'active_session_exercises',
      )).single;
      expect(restoredActive['session_notes'], '');
      expect(restoredActive['is_load_comparable'], 1);
    },
  );
}
