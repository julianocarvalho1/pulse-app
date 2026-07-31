import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/progress_repository_impl.dart';
import '../../domain/models/body_measurement_entry.dart';
import '../../domain/repositories/progress_repository.dart';

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepositoryImpl(),
);

final bodyMeasurementsControllerProvider =
    AsyncNotifierProvider<
      BodyMeasurementsController,
      List<BodyMeasurementEntry>
    >(BodyMeasurementsController.new);

class BodyMeasurementsController
    extends AsyncNotifier<List<BodyMeasurementEntry>> {
  ProgressRepository get _repository => ref.read(progressRepositoryProvider);

  @override
  Future<List<BodyMeasurementEntry>> build() async {
    await _repository.initialize();
    return _repository.loadMeasurements();
  }

  Future<void> save(BodyMeasurementEntry entry) async {
    final previous = _currentItems;
    final next = <BodyMeasurementEntry>[
      entry,
      ...previous.where((item) => item.id != entry.id),
    ]..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    state = AsyncData<List<BodyMeasurementEntry>>(next);

    try {
      await _repository.saveMeasurement(entry);
    } catch (error, stackTrace) {
      state = AsyncError<List<BodyMeasurementEntry>>(error, stackTrace);
      state = AsyncData<List<BodyMeasurementEntry>>(previous);
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    final previous = _currentItems;
    state = AsyncData<List<BodyMeasurementEntry>>(
      previous.where((item) => item.id != id).toList(),
    );

    try {
      await _repository.deleteMeasurement(id);
    } catch (error, stackTrace) {
      state = AsyncError<List<BodyMeasurementEntry>>(error, stackTrace);
      state = AsyncData<List<BodyMeasurementEntry>>(previous);
      rethrow;
    }
  }

  Future<void> clearAll() async {
    await _repository.initialize();
    await _repository.clearMeasurements();
    state = const AsyncData<List<BodyMeasurementEntry>>(
      <BodyMeasurementEntry>[],
    );
  }

  Future<void> reload() async {
    state = const AsyncLoading<List<BodyMeasurementEntry>>();
    state = await AsyncValue.guard(() async {
      await _repository.initialize();
      return _repository.loadMeasurements();
    });
  }

  List<BodyMeasurementEntry> get _currentItems {
    return switch (state) {
      AsyncData<List<BodyMeasurementEntry>>(:final value) => value,
      _ => const <BodyMeasurementEntry>[],
    };
  }
}
