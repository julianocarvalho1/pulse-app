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
    await db.insert('workout_history_cardio', <String, Object?>{
      'history_id': 'history-a',
      'sort_order': 0,
      'modality': 'treadmill',
      'planned_duration_minutes': 30,
      'actual_duration_minutes': 28,
      'distance_km': 4.2,
      'notes': '',
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
    expect(await db.query('workout_history_cardio'), hasLength(1));
    expect(await db.query('body_measurements'), hasLength(1));
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
}
