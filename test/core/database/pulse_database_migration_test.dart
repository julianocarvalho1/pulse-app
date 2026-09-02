import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/database/pulse_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('migra da versão 9 preservando séries já registradas', () async {
    sqfliteFfiInit();
    final directory = await Directory.systemTemp.createTemp(
      'pulse-db-v9-migration-',
    );
    final databasePath = '${directory.path}${Platform.pathSeparator}pulse.db';
    addTearDown(() async {
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
    });

    final legacyDatabase = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 9,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE workout_history_sets (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              history_exercise_id INTEGER NOT NULL,
              set_order INTEGER NOT NULL,
              reps INTEGER NOT NULL,
              weight REAL NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE active_session_sets (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              session_exercise_id INTEGER NOT NULL,
              set_order INTEGER NOT NULL,
              weight_text TEXT NOT NULL DEFAULT '',
              reps_text TEXT NOT NULL DEFAULT '',
              is_completed INTEGER NOT NULL DEFAULT 0,
              target_text TEXT NOT NULL DEFAULT '',
              target_rir INTEGER,
              cadence TEXT NOT NULL DEFAULT '',
              technique TEXT NOT NULL DEFAULT 'none',
              prescribed_rest_seconds INTEGER,
              prescription_notes TEXT NOT NULL DEFAULT ''
            )
          ''');
        },
      ),
    );
    await legacyDatabase.insert('workout_history_sets', <String, Object>{
      'history_exercise_id': 1,
      'set_order': 0,
      'reps': 12,
      'weight': 20,
    });
    await legacyDatabase.insert('active_session_sets', <String, Object>{
      'session_exercise_id': 1,
      'set_order': 0,
      'weight_text': '20',
      'reps_text': '10',
      'is_completed': 1,
      'target_text': '8-12 reps',
      'cadence': '',
      'technique': 'none',
      'prescription_notes': '',
    });
    await legacyDatabase.close();

    final pulseDatabase = PulseDatabase(
      databaseFactoryOverride: databaseFactoryFfi,
      databasePathOverride: databasePath,
    );
    addTearDown(pulseDatabase.close);
    final migrated = await pulseDatabase.database;

    final historyRow = (await migrated.query('workout_history_sets')).single;
    expect(historyRow['reps'], 12);
    expect(historyRow['weight'], 20.0);
    expect(historyRow['target_type'], 'repetitions');
    expect(historyRow['planned_duration_seconds'], 0);
    expect(historyRow['actual_duration_seconds'], 0);

    final activeRow = (await migrated.query('active_session_sets')).single;
    expect(activeRow['reps_text'], '10');
    expect(activeRow['is_completed'], 1);
    expect(activeRow['target_type'], 'repetitions');
    expect(activeRow['planned_duration_seconds'], 0);
    expect(activeRow['actual_duration_seconds'], 0);
    expect(activeRow['duration_started_at_ms'], isNull);
  });
}
