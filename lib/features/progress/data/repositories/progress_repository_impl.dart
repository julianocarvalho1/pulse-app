import '../../../../core/database/pulse_database.dart';
import '../../domain/models/body_measurement_entry.dart';
import '../../domain/repositories/progress_repository.dart';
import '../services/progress_local_service.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl({
    PulseDatabase? database,
    ProgressLocalService? localService,
  }) : _localService =
           localService ?? ProgressLocalService(database ?? PulseDatabase());

  final ProgressLocalService _localService;

  @override
  Future<void> initialize() {
    return _localService.initialize();
  }

  @override
  Future<List<BodyMeasurementEntry>> loadMeasurements() {
    return _localService.loadMeasurements();
  }

  @override
  Future<void> saveMeasurement(BodyMeasurementEntry entry) {
    return _localService.saveMeasurement(entry);
  }

  @override
  Future<void> deleteMeasurement(String id) {
    return _localService.deleteMeasurement(id);
  }

  @override
  Future<void> clearMeasurements() {
    return _localService.clearMeasurements();
  }
}
