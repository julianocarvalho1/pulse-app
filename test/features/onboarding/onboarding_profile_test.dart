import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/onboarding/domain/onboarding_profile.dart';

void main() {
  test('normaliza nome, limites e listas sem duplicatas', () {
    final profile = OnboardingProfile.defaults().copyWith(
      name: '  Juliano  ',
      trainingDaysPerWeek: 10,
      sessionDurationMinutes: 10,
      equipment: const <String>['Halteres', ' halteres ', '', 'Polias'],
      avoidedExercises: const <String>['Corrida', 'corrida', ''],
    );

    final normalized = profile.normalized();

    expect(normalized.name, 'Juliano');
    expect(normalized.trainingDaysPerWeek, 7);
    expect(normalized.sessionDurationMinutes, 20);
    expect(normalized.equipment, <String>['Halteres', 'Polias']);
    expect(normalized.avoidedExercises, <String>['Corrida']);
  });

  test('usa Atleta quando o nome está vazio', () {
    final profile = OnboardingProfile.defaults().normalized();

    expect(profile.displayName, 'Atleta');
    expect(profile.name, 'Atleta');
  });
}
