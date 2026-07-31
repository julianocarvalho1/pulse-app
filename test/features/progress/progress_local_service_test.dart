import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/database/pulse_database.dart';
import 'package:pulse/features/progress/data/services/progress_local_service.dart';
import 'package:pulse/features/progress/domain/models/body_measurement_entry.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late PulseDatabase database;
  late ProgressLocalService service;

  setUp(() async {
    sqfliteFfiInit();

    database = PulseDatabase(
      databaseFactoryOverride: databaseFactoryFfi,
      databasePathOverride: inMemoryDatabasePath,
    );
    service = ProgressLocalService(database);
    await service.initialize();
  });

  tearDown(() async {
    await database.close();
  });

  test('persiste, ordena e remove avaliações corporais', () async {
    final older = BodyMeasurementEntry(
      id: 'older',
      recordedAt: DateTime(2026, 6, 1),
      weightKg: 82,
      waistCm: 90,
    );
    final newer = BodyMeasurementEntry(
      id: 'newer',
      recordedAt: DateTime(2026, 7, 1),
      weightKg: 80,
      waistCm: 87,
    );

    await service.saveMeasurement(older);
    await service.saveMeasurement(newer);

    final loaded = await service.loadMeasurements();

    expect(loaded, hasLength(2));
    expect(loaded.first.id, 'newer');
    expect(loaded.first.weightKg, 80);
    expect(loaded.first.waistCm, 87);

    await service.deleteMeasurement('newer');

    final afterDelete = await service.loadMeasurements();
    expect(afterDelete.single.id, 'older');

    await service.clearMeasurements();
    expect(await service.loadMeasurements(), isEmpty);
  });

  test('migra banco versão 1 criando a tabela de medidas', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'pulse_progress_migration_',
    );
    final databasePath = '${tempDirectory.path}/pulse_v1.db';

    final oldDatabase = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute("""
            CREATE TABLE app_metadata (
              key TEXT PRIMARY KEY NOT NULL,
              value TEXT NOT NULL
            )
          """);
        },
      ),
    );
    await oldDatabase.close();

    final migratedDatabase = PulseDatabase(
      databaseFactoryOverride: databaseFactoryFfi,
      databasePathOverride: databasePath,
    );

    final db = await migratedDatabase.database;
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master "
      "WHERE type = 'table' AND name = 'body_measurements'",
    );

    expect(tables, isNotEmpty);

    await migratedDatabase.close();
    await tempDirectory.delete(recursive: true);
  });
}
