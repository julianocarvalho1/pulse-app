import 'package:sqflite/sqflite.dart';

import '../../../../core/database/pulse_database.dart';
import '../../domain/models/body_measurement_entry.dart';

class ProgressLocalService {
  ProgressLocalService(this._database);

  final PulseDatabase _database;

  Future<void> initialize() async {
    await _database.database;
  }

  Future<List<BodyMeasurementEntry>> loadMeasurements() async {
    final db = await _database.database;
    final rows = await db.query(
      'body_measurements',
      orderBy: 'recorded_at_ms DESC, id DESC',
    );

    return rows.map(BodyMeasurementEntry.fromDatabaseMap).toList();
  }

  Future<void> saveMeasurement(BodyMeasurementEntry entry) async {
    final db = await _database.database;
    await db.insert(
      'body_measurements',
      entry.toDatabaseMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteMeasurement(String id) async {
    final db = await _database.database;
    await db.delete(
      'body_measurements',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> clearMeasurements() async {
    final db = await _database.database;
    await db.delete('body_measurements');
  }
}
