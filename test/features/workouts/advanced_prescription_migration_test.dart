import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/database/pulse_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('migra banco da versão 4 preservando tabelas antigas', () async {
    sqfliteFfiInit();
    final tempDirectory = await Directory.systemTemp.createTemp(
      'pulse_advanced_migration_',
    );
    final databasePath = '${tempDirectory.path}/pulse.db';

    final legacyDatabase = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: (database, version) async {
          await database.execute('''
            CREATE TABLE custom_exercises (
              id TEXT PRIMARY KEY NOT NULL,
              name TEXT NOT NULL,
              muscle TEXT NOT NULL,
              description TEXT NOT NULL,
              reps TEXT NOT NULL,
              rest TEXT NOT NULL,
              is_superset INTEGER NOT NULL DEFAULT 0,
              custom_note TEXT NOT NULL DEFAULT '',
              created_at INTEGER NOT NULL
            )
          ''');
          await database.execute('''
            CREATE TABLE routine_exercises (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              routine_id TEXT NOT NULL,
              exercise_id TEXT NOT NULL,
              sort_order INTEGER NOT NULL,
              name TEXT NOT NULL,
              muscle TEXT NOT NULL,
              description TEXT NOT NULL,
              reps TEXT NOT NULL,
              rest TEXT NOT NULL,
              is_superset INTEGER NOT NULL DEFAULT 0,
              custom_note TEXT NOT NULL DEFAULT ''
            )
          ''');
          await database.execute('''
            CREATE TABLE active_session_exercises (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              session_id TEXT NOT NULL,
              exercise_id TEXT NOT NULL,
              sort_order INTEGER NOT NULL,
              name TEXT NOT NULL,
              muscle TEXT NOT NULL,
              description TEXT NOT NULL,
              reps TEXT NOT NULL,
              rest TEXT NOT NULL,
              is_superset INTEGER NOT NULL DEFAULT 0,
              custom_note TEXT NOT NULL DEFAULT ''
            )
          ''');
          await database.execute('''
            CREATE TABLE active_session_sets (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              session_exercise_id INTEGER NOT NULL,
              set_order INTEGER NOT NULL,
              weight_text TEXT NOT NULL DEFAULT '',
              reps_text TEXT NOT NULL DEFAULT '',
              is_completed INTEGER NOT NULL DEFAULT 0
            )
          ''');
        },
      ),
    );
    await legacyDatabase.insert('custom_exercises', <String, Object?>{
      'id': 'legacy',
      'name': 'Exercício antigo',
      'muscle': 'Outros',
      'description': '',
      'reps': '3x 10',
      'rest': '60 seg',
      'created_at': 1,
    });
    await legacyDatabase.close();

    final pulseDatabase = PulseDatabase(
      databaseFactoryOverride: databaseFactoryFfi,
      databasePathOverride: databasePath,
    );
    final migrated = await pulseDatabase.database;

    Future<Set<String>> columns(String table) async {
      final rows = await migrated.rawQuery('PRAGMA table_info($table)');
      return rows.map((row) => row['name']!.toString()).toSet();
    }

    expect(
      await columns('custom_exercises'),
      contains('advanced_prescription_json'),
    );
    expect(
      await columns('routine_exercises'),
      contains('advanced_prescription_json'),
    );
    expect(
      await columns('active_session_exercises'),
      contains('advanced_prescription_json'),
    );
    expect(
      await columns('active_session_sets'),
      containsAll(<String>[
        'target_text',
        'target_rir',
        'cadence',
        'technique',
        'prescribed_rest_seconds',
        'prescription_notes',
      ]),
    );
    final legacyRows = await migrated.query('custom_exercises');
    expect(legacyRows.single['name'], 'Exercício antigo');
    expect(legacyRows.single['advanced_prescription_json'], '');

    await pulseDatabase.close();
    await tempDirectory.delete(recursive: true);
  });

  test('migra banco da versão 6 adicionando estado do descanso', () async {
    sqfliteFfiInit();
    final tempDirectory = await Directory.systemTemp.createTemp(
      'pulse_rest_migration_',
    );
    final databasePath = '${tempDirectory.path}/pulse.db';

    final legacyDatabase = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 6,
        onCreate: (database, version) async {
          await database.execute('''
            CREATE TABLE active_session (
              id TEXT PRIMARY KEY NOT NULL,
              routine_name TEXT NOT NULL,
              started_at_ms INTEGER NOT NULL,
              elapsed_seconds INTEGER NOT NULL DEFAULT 0,
              notes TEXT NOT NULL DEFAULT ''
            )
          ''');
        },
      ),
    );
    await legacyDatabase.insert('active_session', <String, Object?>{
      'id': 'legacy-active',
      'routine_name': 'Treino antigo',
      'started_at_ms': 123,
      'elapsed_seconds': 45,
      'notes': 'preservar',
    });
    await legacyDatabase.close();

    final pulseDatabase = PulseDatabase(
      databaseFactoryOverride: databaseFactoryFfi,
      databasePathOverride: databasePath,
    );
    final migrated = await pulseDatabase.database;
    final columns = (await migrated.rawQuery(
      'PRAGMA table_info(active_session)',
    )).map((row) => row['name']!.toString()).toSet();

    expect(
      columns,
      containsAll(<String>['rest_seconds', 'rest_end_at_ms', 'is_rest_paused']),
    );
    final row = (await migrated.query('active_session')).single;
    expect(row['routine_name'], 'Treino antigo');
    expect(row['elapsed_seconds'], 45);
    expect(row['rest_seconds'], 0);
    expect(row['rest_end_at_ms'], isNull);
    expect(row['is_rest_paused'], 0);

    await pulseDatabase.close();
    await tempDirectory.delete(recursive: true);
  });
}
