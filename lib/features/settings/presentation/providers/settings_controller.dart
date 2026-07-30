import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/settings_local_service.dart';
import '../../domain/pulse_settings.dart';

final settingsLocalServiceProvider = Provider<SettingsLocalService>(
  (ref) => SettingsLocalService(),
);

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, PulseSettings>(
      SettingsController.new,
    );

class SettingsController extends AsyncNotifier<PulseSettings> {
  SettingsLocalService get _service => ref.read(settingsLocalServiceProvider);

  @override
  Future<PulseSettings> build() {
    return _service.load();
  }

  Future<void> changeThemeColor(int colorValue) async {
    final current = _currentValue;
    if (current == null || current.themeColorValue == colorValue) {
      return;
    }

    await _persist(current.copyWith(themeColorValue: colorValue));
  }

  Future<void> setVoiceAfterRest(bool enabled) async {
    final current = _currentValue;
    if (current == null) {
      return;
    }

    await _persist(current.copyWith(voiceAfterRest: enabled));
  }

  Future<void> setInactivityReminder(bool enabled) async {
    final current = _currentValue;
    if (current == null) {
      return;
    }

    await _persist(current.copyWith(inactivityReminder: enabled));
  }

  Future<void> setMeasurementSystem(MeasurementSystem measurementSystem) async {
    final current = _currentValue;
    if (current == null) {
      return;
    }

    await _persist(current.copyWith(measurementSystem: measurementSystem));
  }

  Future<void> updateProfile(UserProfile profile) async {
    final current = _currentValue;
    if (current == null) {
      return;
    }

    final normalizedProfile = profile.copyWith(
      name: profile.displayName,
      weightKg: profile.weightKg < 0 ? 0 : profile.weightKg,
      heightCm: profile.heightCm < 0 ? 0 : profile.heightCm,
      age: profile.age < 0 ? 0 : profile.age,
    );

    await _persist(current.copyWith(profile: normalizedProfile));

    await ref
        .read(authControllerProvider.notifier)
        .updateUserName(normalizedProfile.displayName);
  }

  Future<void> resetToDefaults({bool clearStorage = false}) async {
    if (clearStorage) {
      await _service.clearAll();
    }

    final defaults = PulseSettings.defaults();
    await _service.save(defaults);
    state = AsyncData(defaults);

    await ref
        .read(authControllerProvider.notifier)
        .updateUserName(defaults.profile.displayName);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_service.load);
  }

  Future<void> _persist(PulseSettings next) async {
    final previous = _currentValue;
    state = AsyncData(next);

    try {
      await _service.save(next);
    } catch (error, stackTrace) {
      if (previous != null) {
        state = AsyncData(previous);
      } else {
        state = AsyncError(error, stackTrace);
      }
      rethrow;
    }
  }

  PulseSettings? get _currentValue {
    return switch (state) {
      AsyncData<PulseSettings>(:final value) => value,
      _ => null,
    };
  }
}
