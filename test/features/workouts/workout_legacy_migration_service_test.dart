import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/database/pulse_database.dart';
import 'package:pulse/features/workouts/data/services/workout_legacy_migration_service.dart';
import 'package:pulse/features/workouts/data/services/workout_local_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late PulseDatabase database;
  late WorkoutLocalService localService;

  setUp(() async {
    sqfliteFfiInit();

    SharedPreferences.setMockInitialValues({
      'active_program': 'Programa antigo',
      'custom_exercises': jsonEncode([
        {
          'id': 'custom-1',
          'name': 'Exercício antigo',
          'muscle': 'Peito',
          'description': 'Migrado',
          'reps': '3x 10',
          'rest': '60 seg',
          'isSuperset': false,
          'customNote': '',
        },
      ]),
      'my_routines': jsonEncode([
        {
          'id': 'routine-1',
          'name': 'Treino antigo',
          'focus': 'Hipertrofia',
          'groupName': 'Programa antigo',
          'exercises': [],
        },
      ]),
      'workout_history': jsonEncode([]),
    });

    database = PulseDatabase(
      databaseFactoryOverride: databaseFactoryFfi,
      databasePathOverride: inMemoryDatabasePath,
    );

    localService = WorkoutLocalService(database);
    await localService.initialize();
  });

  tearDown(() async {
    await database.close();
  });

  test('moves legacy SharedPreferences workout data to SQLite', () async {
    final migration = WorkoutLegacyMigrationService(localService: localService);

    await migration.migrateIfNeeded();

    final exercises = await localService.loadCustomExercises();
    final routines = await localService.loadRoutines();
    final activeProgram = await localService.loadActiveProgramName();
    final preferences = await SharedPreferences.getInstance();

    expect(exercises.single.name, 'Exercício antigo');
    expect(routines.single.name, 'Treino antigo');
    expect(activeProgram, 'Programa antigo');
    expect(
      preferences.getBool('workout_sqlite_migration_v1_completed'),
      isTrue,
    );
    expect(preferences.containsKey('my_routines'), isFalse);
  });
}
