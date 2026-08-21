import 'package:shared_preferences/shared_preferences.dart';

import '../../settings/domain/pulse_settings.dart';
import '../domain/onboarding_profile.dart';

class OnboardingLocalService {
  static const String _completedKey = 'onboarding_completed_v1';
  static const String _nameKey = 'onboarding_name';
  static const String _experienceKey = 'onboarding_experience';
  static const String _goalKey = 'onboarding_goal';
  static const String _trainingDaysKey = 'onboarding_training_days';
  static const String _sessionDurationKey = 'onboarding_session_duration';
  static const String _locationKey = 'onboarding_location';
  static const String _equipmentKey = 'onboarding_equipment';
  static const String _avoidedExercisesKey = 'onboarding_avoided_exercises';
  static const String _trainingPreferencesKey =
      'onboarding_training_preferences';
  static const String _measurementSystemKey = 'onboarding_measurement_system';
  static const String _nextStepKey = 'onboarding_next_step';
  static const String _personalizedKey = 'onboarding_personalized';

  Future<OnboardingState> load() async {
    final preferences = await SharedPreferences.getInstance();
    final defaults = OnboardingProfile.defaults();
    final hasCompletionDecision = preferences.containsKey(_completedKey);

    return OnboardingState(
      hasCompletionDecision: hasCompletionDecision,
      profile: OnboardingProfile(
        name: preferences.getString(_nameKey) ?? defaults.name,
        experience: _enumByName(
          TrainingExperience.values,
          preferences.getString(_experienceKey),
          defaults.experience,
        ),
        goal: _enumByName(
          TrainingGoal.values,
          preferences.getString(_goalKey),
          defaults.goal,
        ),
        trainingDaysPerWeek:
            preferences.getInt(_trainingDaysKey) ??
            defaults.trainingDaysPerWeek,
        sessionDurationMinutes:
            preferences.getInt(_sessionDurationKey) ??
            defaults.sessionDurationMinutes,
        location: _enumByName(
          TrainingLocation.values,
          preferences.getString(_locationKey),
          defaults.location,
        ),
        equipment:
            preferences.getStringList(_equipmentKey) ?? defaults.equipment,
        avoidedExercises:
            preferences.getStringList(_avoidedExercisesKey) ??
            defaults.avoidedExercises,
        trainingPreferences:
            preferences.getStringList(_trainingPreferencesKey) ??
            defaults.trainingPreferences,
        measurementSystem: _enumByName(
          MeasurementSystem.values,
          preferences.getString(_measurementSystemKey),
          defaults.measurementSystem,
        ),
        nextStep: _enumByName(
          OnboardingNextStep.values,
          preferences.getString(_nextStepKey),
          defaults.nextStep,
        ),
        isCompleted: preferences.getBool(_completedKey) ?? false,
        isPersonalized: preferences.getBool(_personalizedKey) ?? false,
      ).normalized(),
    );
  }

  Future<void> save(OnboardingProfile profile) async {
    final preferences = await SharedPreferences.getInstance();
    final normalized = profile.normalized();

    await Future.wait(<Future<bool>>[
      preferences.setBool(_completedKey, normalized.isCompleted),
      preferences.setString(_nameKey, normalized.displayName),
      preferences.setString(_experienceKey, normalized.experience.name),
      preferences.setString(_goalKey, normalized.goal.name),
      preferences.setInt(_trainingDaysKey, normalized.trainingDaysPerWeek),
      preferences.setInt(
        _sessionDurationKey,
        normalized.sessionDurationMinutes,
      ),
      preferences.setString(_locationKey, normalized.location.name),
      preferences.setStringList(_equipmentKey, normalized.equipment),
      preferences.setStringList(
        _avoidedExercisesKey,
        normalized.avoidedExercises,
      ),
      preferences.setStringList(
        _trainingPreferencesKey,
        normalized.trainingPreferences,
      ),
      preferences.setString(
        _measurementSystemKey,
        normalized.measurementSystem.name,
      ),
      preferences.setString(_nextStepKey, normalized.nextStep.name),
      preferences.setBool(_personalizedKey, normalized.isPersonalized),
    ]);
  }

  T _enumByName<T extends Enum>(
    List<T> values,
    String? storedName,
    T fallback,
  ) {
    for (final value in values) {
      if (value.name == storedName) {
        return value;
      }
    }

    return fallback;
  }
}
