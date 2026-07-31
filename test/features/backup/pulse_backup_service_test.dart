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
    await db.insert('workout_history', <String, Object>{
      'id': 'history-a',
      'routine_name': 'Treino A',
      'date_ms': DateTime(2026, 7, 31).millisecondsSinceEpoch,
      'duration': '40:00',
      'notes': '',
      'status': 'completed',
    });
    await db.insert('body_measurements', <String, Object?>{
      'id': 'weight-a',
      'recorded_at_ms': DateTime(2026, 7, 31).millisecondsSinceEpoch,
      'weight_kg': 78.5,
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
    await db.delete('body_measurements');
    await preferences.clear();

    await service.importBytes(bytes);

    expect(await db.query('routines'), hasLength(1));
    expect(await db.query('workout_history'), hasLength(1));
    expect(await db.query('body_measurements'), hasLength(1));
    expect(preferences.getString('user_name'), 'Juliano');
    expect(preferences.getString('settings_theme_mode'), 'light');
    expect(preferences.getBool('app_lock_enabled'), isFalse);
  });

  test('não exporta a preferência de proteção local', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('app_lock_enabled', true);
    await preferences.setString('user_name', 'Atleta');

    final bytes = await service.exportBytes();
    final decoded = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    final exportedPreferences = decoded['preferences'] as Map<String, dynamic>;

    expect(exportedPreferences['user_name'], 'Atleta');
    expect(exportedPreferences.containsKey('app_lock_enabled'), isFalse);
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
}
