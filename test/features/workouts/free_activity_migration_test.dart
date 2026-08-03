import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/database/pulse_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test(
    'migra banco da versão 5 criando atividades livres sem perder histórico',
    () async {
      sqfliteFfiInit();
      final tempDirectory = await Directory.systemTemp.createTemp(
        'pulse_free_activity_migration_',
      );
      final databasePath = '${tempDirectory.path}/pulse.db';

      final legacyDatabase = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 5,
          onCreate: (database, version) async {
            await database.execute('''
            CREATE TABLE workout_history (
              id TEXT PRIMARY KEY NOT NULL,
              routine_name TEXT NOT NULL,
              date_ms INTEGER NOT NULL,
              duration TEXT NOT NULL,
              notes TEXT NOT NULL DEFAULT '',
              status TEXT NOT NULL
            )
          ''');
          },
        ),
      );
      await legacyDatabase.insert('workout_history', <String, Object?>{
        'id': 'legacy-history',
        'routine_name': 'Treino antigo',
        'date_ms': DateTime(2026, 8, 1).millisecondsSinceEpoch,
        'duration': '40:00',
        'notes': '',
        'status': 'completed',
      });
      await legacyDatabase.close();

      final pulseDatabase = PulseDatabase(
        databaseFactoryOverride: databaseFactoryFfi,
        databasePathOverride: databasePath,
      );
      final migrated = await pulseDatabase.database;

      final tables = await migrated.rawQuery(
        "SELECT name FROM sqlite_master "
        "WHERE type = 'table' AND name = 'workout_history_free_activities'",
      );
      final legacyRows = await migrated.query('workout_history');

      expect(tables, isNotEmpty);
      expect(legacyRows, hasLength(1));
      expect(legacyRows.single['routine_name'], 'Treino antigo');

      await pulseDatabase.close();
      await tempDirectory.delete(recursive: true);
    },
  );
}
