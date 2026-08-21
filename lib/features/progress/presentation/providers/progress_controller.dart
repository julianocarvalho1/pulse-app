import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/presentation/providers/settings_controller.dart';
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
    final loaded = await _repository.loadMeasurements();
    final settings = await ref.read(settingsControllerProvider.future);

    final seeded = await _seedProfileWeightWhenNeeded(
      loaded,
      settings.profile.weightKg,
    );
    await _syncProfileWithLatestWeight(seeded);

    return _sorted(seeded);
  }

  Future<void> save(BodyMeasurementEntry entry) async {
    final previous = await _itemsReady();
    final next = <BodyMeasurementEntry>[
      entry,
      ...previous.where((item) => item.id != entry.id),
    ];

    state = AsyncData<List<BodyMeasurementEntry>>(_sorted(next));

    try {
      await _repository.saveMeasurement(entry);
    } catch (error, stackTrace) {
      state = AsyncError<List<BodyMeasurementEntry>>(error, stackTrace);
      state = AsyncData<List<BodyMeasurementEntry>>(previous);
      rethrow;
    }

    await _syncProfileWithLatestWeight(next);
  }

  Future<void> ensureWeightBaseline(double weightKg) async {
    if (weightKg <= 0) {
      return;
    }

    final items = await _itemsReady();
    final alreadyHasWeight = items.any((item) => item.weightKg != null);
    if (alreadyHasWeight) {
      return;
    }

    await save(
      BodyMeasurementEntry(
        id: 'profile_weight_${DateTime.now().microsecondsSinceEpoch}',
        recordedAt: DateTime.now(),
        weightKg: weightKg,
      ),
    );
  }

  Future<void> delete(String id) async {
    final previous = await _itemsReady();
    final next = previous.where((item) => item.id != id).toList();
    state = AsyncData<List<BodyMeasurementEntry>>(next);

    try {
      await _repository.deleteMeasurement(id);
    } catch (error, stackTrace) {
      state = AsyncError<List<BodyMeasurementEntry>>(error, stackTrace);
      state = AsyncData<List<BodyMeasurementEntry>>(previous);
      rethrow;
    }

    await _syncProfileWithLatestWeight(next);
  }

  Future<void> clearAll() async {
    await _repository.initialize();
    await _repository.clearMeasurements();
    state = const AsyncData<List<BodyMeasurementEntry>>(
      <BodyMeasurementEntry>[],
    );
    await _syncProfileWithLatestWeight(const <BodyMeasurementEntry>[]);
  }

  Future<void> reload() async {
    state = const AsyncLoading<List<BodyMeasurementEntry>>();
    state = await AsyncValue.guard(() async {
      await _repository.initialize();
      final loaded = await _repository.loadMeasurements();
      final settings = await ref.read(settingsControllerProvider.future);
      final seeded = await _seedProfileWeightWhenNeeded(
        loaded,
        settings.profile.weightKg,
      );
      await _syncProfileWithLatestWeight(seeded);
      return _sorted(seeded);
    });
  }

  Future<List<BodyMeasurementEntry>> _seedProfileWeightWhenNeeded(
    List<BodyMeasurementEntry> items,
    double profileWeightKg,
  ) async {
    if (profileWeightKg <= 0 || items.any((item) => item.weightKg != null)) {
      return items;
    }

    final baseline = BodyMeasurementEntry(
      id: 'profile_weight_${DateTime.now().microsecondsSinceEpoch}',
      recordedAt: DateTime.now(),
      weightKg: profileWeightKg,
    );

    await _repository.saveMeasurement(baseline);
    return <BodyMeasurementEntry>[baseline, ...items];
  }

  Future<List<BodyMeasurementEntry>> _itemsReady() async {
    final current = _currentItems;
    if (current != null) {
      return current;
    }

    await _repository.initialize();
    return _sorted(await _repository.loadMeasurements());
  }

  Future<void> _syncProfileWithLatestWeight(
    List<BodyMeasurementEntry> items,
  ) async {
    try {
      final settings = await ref.read(settingsControllerProvider.future);
      final sorted = _sorted(items);
      double latestWeight = 0;

      for (final item in sorted) {
        final weight = item.weightKg;
        if (weight != null && weight > 0) {
          latestWeight = weight;
          break;
        }
      }

      if ((settings.profile.weightKg - latestWeight).abs() < 0.0001) {
        return;
      }

      await ref
          .read(settingsControllerProvider.notifier)
          .setCurrentWeight(latestWeight);
    } catch (error, stackTrace) {
      debugPrint('Não foi possível sincronizar o peso atual: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  List<BodyMeasurementEntry> _sorted(List<BodyMeasurementEntry> items) {
    return <BodyMeasurementEntry>[...items]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
  }

  List<BodyMeasurementEntry>? get _currentItems {
    return switch (state) {
      AsyncData<List<BodyMeasurementEntry>>(:final value) => value,
      _ => null,
    };
  }
}
