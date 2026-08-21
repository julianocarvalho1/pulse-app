import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/progress/domain/models/body_measurement_entry.dart';
import 'package:pulse/features/progress/domain/repositories/progress_repository.dart';
import 'package:pulse/features/progress/presentation/providers/progress_controller.dart';
import 'package:pulse/features/settings/data/settings_local_service.dart';
import 'package:pulse/features/settings/domain/pulse_settings.dart';
import 'package:pulse/features/settings/presentation/providers/settings_controller.dart';

void main() {
  test('mantém pesagens e avaliações como registros independentes', () async {
    final repository = _MemoryProgressRepository();
    final settingsService = _MemorySettingsLocalService(
      PulseSettings.defaults().copyWith(
        profile: const UserProfile(
          name: 'Atleta',
          weightKg: 80,
          heightCm: 175,
          age: 30,
        ),
      ),
    );
    final container = ProviderContainer(
      overrides: [
        progressRepositoryProvider.overrideWithValue(repository),
        settingsLocalServiceProvider.overrideWithValue(settingsService),
      ],
    );
    addTearDown(container.dispose);

    final initial = await container.read(
      bodyMeasurementsControllerProvider.future,
    );

    expect(initial, hasLength(1));
    expect(initial.single.weightKg, 80);

    final controller = container.read(
      bodyMeasurementsControllerProvider.notifier,
    );
    final now = DateTime.now();

    await controller.save(
      BodyMeasurementEntry(id: 'new-weight', recordedAt: now, weightKg: 79),
    );

    var measurements = container
        .read(bodyMeasurementsControllerProvider)
        .requireValue;
    expect(measurements, hasLength(2));
    expect(measurements.first.weightKg, 79);
    expect(
      container.read(settingsControllerProvider).requireValue.profile.weightKg,
      79,
    );

    await controller.save(
      BodyMeasurementEntry(
        id: 'full-assessment',
        recordedAt: now.add(const Duration(minutes: 5)),
        waistCm: 88,
      ),
    );

    measurements = container
        .read(bodyMeasurementsControllerProvider)
        .requireValue;
    expect(measurements, hasLength(3));
    expect(measurements.first.weightKg, isNull);
    expect(measurements.first.waistCm, 88);
    expect(measurements[1].weightKg, 79);
    expect(measurements[1].waistCm, isNull);
    expect(
      container.read(settingsControllerProvider).requireValue.profile.weightKg,
      79,
    );
  });
}

class _MemoryProgressRepository implements ProgressRepository {
  final List<BodyMeasurementEntry> _items = <BodyMeasurementEntry>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<List<BodyMeasurementEntry>> loadMeasurements() async {
    return <BodyMeasurementEntry>[..._items]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
  }

  @override
  Future<void> saveMeasurement(BodyMeasurementEntry entry) async {
    _items
      ..removeWhere((item) => item.id == entry.id)
      ..add(entry);
  }

  @override
  Future<void> deleteMeasurement(String id) async {
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> clearMeasurements() async {
    _items.clear();
  }
}

class _MemorySettingsLocalService extends SettingsLocalService {
  _MemorySettingsLocalService(this.value);

  PulseSettings value;

  @override
  Future<PulseSettings> load() async => value;

  @override
  Future<void> save(PulseSettings settings) async {
    value = settings;
  }

  @override
  Future<void> clearAll() async {
    value = PulseSettings.defaults();
  }
}
