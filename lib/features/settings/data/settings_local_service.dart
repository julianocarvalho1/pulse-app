import 'package:shared_preferences/shared_preferences.dart';

import '../domain/pulse_settings.dart';

class SettingsLocalService {
  static const String _themeColorKey = 'theme_color';
  static const String _themeModeKey = 'settings_theme_mode';
  static const String _voiceAfterRestKey = 'settings_voice_after_rest';
  static const String _legacyVibrateAfterRestKey =
      'settings_vibrate_after_rest';
  static const String _inactivityReminderKey = 'settings_inactivity_reminder';
  static const String _measurementSystemKey = 'settings_measurement_system';
  static const String _userNameKey = 'user_name';
  static const String _userWeightKey = 'user_weight';
  static const String _userHeightKey = 'user_height_cm';
  static const String _userAgeKey = 'user_age';
  static const String _userPhotoPathKey = 'user_profile_photo_path';

  Future<PulseSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    final defaults = PulseSettings.defaults();

    final themeModeName = preferences.getString(_themeModeKey);
    final themeMode = PulseThemeMode.values.firstWhere(
      (mode) => mode.name == themeModeName,
      orElse: () => defaults.themeMode,
    );

    final systemName = preferences.getString(_measurementSystemKey);
    final measurementSystem = systemName == MeasurementSystem.imperial.name
        ? MeasurementSystem.imperial
        : MeasurementSystem.metric;

    final savedName = (preferences.getString(_userNameKey) ?? '').trim();

    return PulseSettings(
      themeColorValue:
          preferences.getInt(_themeColorKey) ?? defaults.themeColorValue,
      themeMode: themeMode,
      voiceAfterRest:
          preferences.getBool(_voiceAfterRestKey) ??
          preferences.getBool(_legacyVibrateAfterRestKey) ??
          defaults.voiceAfterRest,
      inactivityReminder:
          preferences.getBool(_inactivityReminderKey) ??
          defaults.inactivityReminder,
      measurementSystem: measurementSystem,
      profile: UserProfile(
        name: savedName.isEmpty ? defaults.profile.name : savedName,
        weightKg: _readDouble(preferences, _userWeightKey),
        heightCm: _readDouble(preferences, _userHeightKey),
        age: preferences.getInt(_userAgeKey) ?? 0,
        photoPath: preferences.getString(_userPhotoPathKey) ?? '',
      ),
    );
  }

  Future<void> save(PulseSettings settings) async {
    final preferences = await SharedPreferences.getInstance();

    await Future.wait([
      preferences.setInt(_themeColorKey, settings.themeColorValue),
      preferences.setString(_themeModeKey, settings.themeMode.name),
      preferences.setBool(_voiceAfterRestKey, settings.voiceAfterRest),
      preferences.setBool(_inactivityReminderKey, settings.inactivityReminder),
      preferences.setString(
        _measurementSystemKey,
        settings.measurementSystem.name,
      ),
      preferences.setString(_userNameKey, settings.profile.displayName),
      preferences.setDouble(_userWeightKey, settings.profile.weightKg),
      preferences.setDouble(_userHeightKey, settings.profile.heightCm),
      preferences.setInt(_userAgeKey, settings.profile.age),
      preferences.setString(_userPhotoPathKey, settings.profile.photoPath),
    ]);

    await preferences.remove(_legacyVibrateAfterRestKey);
  }

  Future<void> clearAll() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
  }

  double _readDouble(SharedPreferences preferences, String key) {
    final value = preferences.get(key);

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    }

    return 0;
  }
}
