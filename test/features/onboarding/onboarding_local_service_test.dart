import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulse/features/onboarding/data/onboarding_local_service.dart';
import 'package:pulse/features/onboarding/domain/onboarding_profile.dart';
import 'package:pulse/features/settings/domain/pulse_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('primeiro acesso não possui decisão de conclusão', () async {
    final service = OnboardingLocalService();

    final state = await service.load();

    expect(state.hasCompletionDecision, isFalse);
    expect(state.profile.isCompleted, isFalse);
  });

  test('persiste e restaura todas as preferências', () async {
    final service = OnboardingLocalService();
    final profile = OnboardingProfile(
      name: 'Juliano',
      experience: TrainingExperience.intermediate,
      goal: TrainingGoal.strength,
      trainingDaysPerWeek: 5,
      sessionDurationMinutes: 75,
      location: TrainingLocation.both,
      equipment: const <String>['Halteres', 'Polias'],
      avoidedExercises: const <String>['Corrida'],
      trainingPreferences: const <String>['Treinos objetivos'],
      measurementSystem: MeasurementSystem.imperial,
      nextStep: OnboardingNextStep.importProgram,
      isCompleted: true,
      isPersonalized: true,
    );

    await service.save(profile);
    final restored = await service.load();

    expect(restored.hasCompletionDecision, isTrue);
    expect(restored.profile.isCompleted, isTrue);
    expect(restored.profile.isPersonalized, isTrue);
    expect(restored.profile.name, 'Juliano');
    expect(restored.profile.goal, TrainingGoal.strength);
    expect(restored.profile.trainingDaysPerWeek, 5);
    expect(restored.profile.sessionDurationMinutes, 75);
    expect(restored.profile.location, TrainingLocation.both);
    expect(restored.profile.equipment, <String>['Halteres', 'Polias']);
    expect(restored.profile.avoidedExercises, <String>['Corrida']);
    expect(restored.profile.trainingPreferences, <String>['Treinos objetivos']);
    expect(restored.profile.measurementSystem, MeasurementSystem.imperial);
    expect(restored.profile.nextStep, OnboardingNextStep.importProgram);
  });
}
