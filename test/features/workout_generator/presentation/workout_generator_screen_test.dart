import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/onboarding/data/onboarding_local_service.dart';
import 'package:pulse/features/onboarding/domain/onboarding_profile.dart';
import 'package:pulse/features/onboarding/presentation/providers/onboarding_controller.dart';
import 'package:pulse/features/settings/domain/pulse_settings.dart';
import 'package:pulse/features/workout_generator/presentation/screens/workout_generator_screen.dart';
import 'package:pulse/theme/app_theme.dart';

void main() {
  testWidgets(
    'aplica preferências mesmo quando o perfil termina de carregar depois',
    (tester) async {
      final service = _DelayedOnboardingLocalService();
      final palette = pulsePalettes[1];
      AppColors.configure(Brightness.light, primaryColor: palette.lightPrimary);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingLocalServiceProvider.overrideWithValue(service),
          ],
          child: MaterialApp(
            theme: buildPulseLightTheme(palette.lightPrimary),
            home: const WorkoutGeneratorScreen(),
          ),
        ),
      );

      expect(
        find.textContaining('Pré-configurado com suas respostas iniciais'),
        findsNothing,
      );

      service.complete(
        OnboardingProfile(
          name: 'Atleta teste',
          experience: TrainingExperience.advanced,
          goal: TrainingGoal.strength,
          trainingDaysPerWeek: 7,
          sessionDurationMinutes: 90,
          location: TrainingLocation.home,
          equipment: const <String>['Halteres'],
          avoidedExercises: const <String>['Supino reto'],
          trainingPreferences: const <String>[],
          measurementSystem: MeasurementSystem.metric,
          nextStep: OnboardingNextStep.createRoutine,
          isCompleted: true,
          isPersonalized: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Pré-configurado com suas respostas iniciais'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Força'))
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Avançado'))
            .selected,
        isTrue,
      );

      await tester.scrollUntilVisible(
        find.text('5x'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '5x'))
            .selected,
        isTrue,
      );

      await tester.scrollUntilVisible(
        find.text('90 min'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '90 min'))
            .selected,
        isTrue,
      );

      await tester.scrollUntilVisible(
        find.text('Supino Reto com Barra'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.widgetWithText(InputChip, 'Supino Reto com Barra'),
        findsOneWidget,
      );
    },
  );
}

class _DelayedOnboardingLocalService extends OnboardingLocalService {
  final Completer<OnboardingState> _completer = Completer<OnboardingState>();

  @override
  Future<OnboardingState> load() => _completer.future;

  void complete(OnboardingProfile profile) {
    _completer.complete(
      OnboardingState(profile: profile, hasCompletionDecision: true),
    );
  }
}
