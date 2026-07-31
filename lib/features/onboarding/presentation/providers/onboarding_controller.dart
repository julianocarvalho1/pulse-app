import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/domain/pulse_settings.dart';
import '../../../settings/presentation/providers/settings_controller.dart';
import '../../data/onboarding_local_service.dart';
import '../../domain/onboarding_profile.dart';

final onboardingLocalServiceProvider = Provider<OnboardingLocalService>(
  (ref) => OnboardingLocalService(),
);

final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );

class OnboardingController extends AsyncNotifier<OnboardingState> {
  OnboardingLocalService get _service =>
      ref.read(onboardingLocalServiceProvider);

  @override
  Future<OnboardingState> build() {
    return _service.load();
  }

  Future<void> saveDraft(OnboardingProfile profile) async {
    final normalized = profile
        .copyWith(isCompleted: false, isPersonalized: true)
        .normalized();
    await _service.save(normalized);
    state = AsyncData(
      OnboardingState(profile: normalized, hasCompletionDecision: true),
    );
  }

  Future<void> complete(OnboardingProfile profile) async {
    final normalized = profile
        .copyWith(isCompleted: true, isPersonalized: true)
        .normalized();

    await ref
        .read(settingsControllerProvider.notifier)
        .applyOnboarding(
          name: normalized.displayName,
          measurementSystem: normalized.measurementSystem,
        );
    await _service.save(normalized);

    state = AsyncData(
      OnboardingState(profile: normalized, hasCompletionDecision: true),
    );
  }

  Future<void> migrateExistingUser({required PulseSettings settings}) async {
    final current = _currentValue;

    if (current == null || current.hasCompletionDecision) {
      return;
    }

    final migrated = current.profile
        .copyWith(
          name: settings.profile.displayName,
          measurementSystem: settings.measurementSystem,
          isCompleted: true,
          isPersonalized: false,
        )
        .normalized();

    try {
      await _service.save(migrated);
      state = AsyncData(
        OnboardingState(profile: migrated, hasCompletionDecision: true),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> reopen() async {
    final current = _currentValue;
    if (current == null) {
      return;
    }

    final reopened = current.profile.copyWith(isCompleted: false);
    await _service.save(reopened);
    state = AsyncData(
      OnboardingState(profile: reopened, hasCompletionDecision: true),
    );
  }

  void resetAfterFactoryReset() {
    state = AsyncData(
      OnboardingState(
        profile: OnboardingProfile.defaults(),
        hasCompletionDecision: false,
      ),
    );
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_service.load);
  }

  OnboardingState? get _currentValue {
    return switch (state) {
      AsyncData<OnboardingState>(:final value) => value,
      _ => null,
    };
  }
}
