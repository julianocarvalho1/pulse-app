import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

import '../../../providers/workout_provider.dart';
import '../../../theme/app_theme.dart';
import '../domain/app_auth_state.dart';
import 'providers/auth_controller.dart';
import 'screens/app_lock_screen.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.paused) {
      return;
    }

    final authAsync = ref.read(authControllerProvider);

    final authState = switch (authAsync) {
      AsyncData<AppAuthState>(:final value) => value,
      _ => null,
    };

    if (authState == null ||
        !authState.isLockEnabled ||
        !authState.isUnlocked) {
      return;
    }

    ref.read(authControllerProvider.notifier).lock();
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = context.watch<WorkoutProvider>();

    final authAsync = ref.watch(authControllerProvider);

    if (!workoutProvider.isInitialized) {
      return const _PulseBootstrapScreen();
    }

    return authAsync.when(
      loading: () => const _PulseBootstrapScreen(),
      error: (error, stackTrace) {
        return _AuthInitializationError(
          onRetry: () {
            ref.read(authControllerProvider.notifier).reload();
          },
        );
      },
      data: (authState) {
        if (authState.isUnlocked) {
          return widget.child;
        }

        return AppLockScreen(authState: authState);
      },
    );
  }
}

class _PulseBootstrapScreen extends StatelessWidget {
  const _PulseBootstrapScreen();

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  'assets/icon.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.fitness_center_rounded,
                      color: primaryColor,
                      size: 38,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'PREPARANDO SEU TREINO',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthInitializationError extends StatelessWidget {
  const _AuthInitializationError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

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
                  Icon(Icons.lock_reset_rounded, color: primaryColor, size: 58),
                  const SizedBox(height: 22),
                  const Text(
                    'Não foi possível preparar a proteção do PULSE.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tente novamente. Seus treinos não foram apagados.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'TENTAR NOVAMENTE',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
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
