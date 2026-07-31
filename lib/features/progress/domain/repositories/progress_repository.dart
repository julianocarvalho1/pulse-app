import '../models/body_measurement_entry.dart';

abstract interface class ProgressRepository {
  Future<void> initialize();

  Future<List<BodyMeasurementEntry>> loadMeasurements();

  Future<void> saveMeasurement(BodyMeasurementEntry entry);

  Future<void> deleteMeasurement(String id);

  Future<void> clearMeasurements();
}
