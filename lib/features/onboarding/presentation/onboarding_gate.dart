import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/domain/pulse_settings.dart';
import '../../settings/presentation/providers/settings_controller.dart';
import '../../workouts/presentation/providers/workout_controller.dart';
import '../../workouts/presentation/state/workout_state.dart';
import '../../../theme/app_theme.dart';
import 'providers/onboarding_controller.dart';
import 'screens/onboarding_screen.dart';

class OnboardingGate extends ConsumerStatefulWidget {
  const OnboardingGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends ConsumerState<OnboardingGate> {
  bool _migrationRequested = false;

  @override
  Widget build(BuildContext context) {
    final onboardingAsync = ref.watch(onboardingControllerProvider);
    final settingsAsync = ref.watch(settingsControllerProvider);
    final workoutState = ref.watch(workoutControllerProvider);

    return onboardingAsync.when(
      loading: () => const _OnboardingLoadingView(),
      error: (error, stackTrace) {
        return _OnboardingErrorView(
          onRetry: () {
            ref.read(onboardingControllerProvider.notifier).reload();
          },
        );
      },
      data: (onboardingState) {
        final settings = switch (settingsAsync) {
          AsyncData<PulseSettings>(:final value) => value,
          _ => null,
        };

        if (settings == null) {
          return const _OnboardingLoadingView();
        }

        if (!onboardingState.hasCompletionDecision &&
            _hasExistingUserData(workoutState, settings)) {
          _requestLegacyMigration(settings);
          return const _OnboardingLoadingView();
        }

        if (!onboardingState.profile.isCompleted) {
          return OnboardingScreen(initialProfile: onboardingState.profile);
        }

        return widget.child;
      },
    );
  }

  bool _hasExistingUserData(WorkoutState workoutState, PulseSettings settings) {
    final profile = settings.profile;
    final hasCustomizedProfile =
        profile.displayName != 'Atleta' ||
        profile.weightKg > 0 ||
        profile.heightCm > 0 ||
        profile.age > 0;

    return workoutState.myRoutines.isNotEmpty ||
        workoutState.history.isNotEmpty ||
        workoutState.customExercises.isNotEmpty ||
        workoutState.activeProgramName.isNotEmpty ||
        hasCustomizedProfile;
  }

  void _requestLegacyMigration(PulseSettings settings) {
    if (_migrationRequested) {
      return;
    }

    _migrationRequested = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref
            .read(onboardingControllerProvider.notifier)
            .migrateExistingUser(settings: settings);
      } finally {
        if (mounted) {
          _migrationRequested = false;
        }
      }
    });
  }
}

class _OnboardingLoadingView extends StatelessWidget {
  const _OnboardingLoadingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _OnboardingErrorView extends StatelessWidget {
  const _OnboardingErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_search_rounded,
                    size: 54,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'NÃ£o foi possÃ­vel carregar suas preferÃªncias iniciais.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Seus treinos nÃ£o foram apagados. Tente carregar novamente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onRetry,
                      child: const Text('TENTAR NOVAMENTE'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
