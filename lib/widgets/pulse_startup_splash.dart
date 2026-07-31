import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/providers/auth_controller.dart';
import '../features/onboarding/presentation/providers/onboarding_controller.dart';
import '../features/settings/domain/pulse_settings.dart';
import '../features/settings/presentation/providers/settings_controller.dart';
import '../features/workouts/presentation/providers/workout_controller.dart';
import '../theme/app_theme.dart';

/// Mantém uma única experiência visual enquanto os dados essenciais do app
/// são inicializados. A tela só dá lugar ao conteúdo quando autenticação,
/// onboarding, configurações e treinos já saíram do estado de carregamento.
class PulseStartupSplash extends ConsumerStatefulWidget {
  const PulseStartupSplash({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PulseStartupSplash> createState() => _PulseStartupSplashState();
}

class _PulseStartupSplashState extends ConsumerState<PulseStartupSplash>
    with SingleTickerProviderStateMixin {
  static const _minimumDisplayTime = Duration(milliseconds: 850);

  late final AnimationController _introController;
  late final Animation<double> _logoScale;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textOffset;

  Timer? _minimumTimer;
  bool _minimumTimeElapsed = false;
  bool _showApp = false;
  bool _finishScheduled = false;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.92,
          end: 1.04,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 58,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.04,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 42,
      ),
    ]).animate(_introController);

    _textOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.22, 0.78, curve: Curves.easeOut),
    );

    _textOffset = Tween<Offset>(begin: const Offset(0, 0.16), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _introController,
            curve: const Interval(0.22, 0.82, curve: Curves.easeOutCubic),
          ),
        );

    _introController.forward();

    _minimumTimer = Timer(_minimumDisplayTime, () {
      if (!mounted) {
        return;
      }

      setState(() => _minimumTimeElapsed = true);
    });
  }

  @override
  void dispose() {
    _minimumTimer?.cancel();
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsControllerProvider);
    final authAsync = ref.watch(authControllerProvider);
    final onboardingAsync = ref.watch(onboardingControllerProvider);
    final workoutState = ref.watch(workoutControllerProvider);

    final startupDataReady =
        workoutState.isInitialized &&
        !_isLoading(settingsAsync) &&
        !_isLoading(authAsync) &&
        !_isLoading(onboardingAsync);

    _scheduleFinishWhenReady(startupDataReady);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _showApp
          ? KeyedSubtree(key: const ValueKey('pulse-app'), child: widget.child)
          : _SplashScene(
              key: const ValueKey('pulse-startup'),
              settingsAsync: settingsAsync,
              logoScale: _logoScale,
              textOpacity: _textOpacity,
              textOffset: _textOffset,
            ),
    );
  }

  bool _isLoading<T>(AsyncValue<T> value) {
    return switch (value) {
      AsyncLoading<T>() => true,
      _ => false,
    };
  }

  void _scheduleFinishWhenReady(bool startupDataReady) {
    if (!startupDataReady ||
        !_minimumTimeElapsed ||
        _showApp ||
        _finishScheduled) {
      return;
    }

    _finishScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _showApp) {
        return;
      }

      setState(() => _showApp = true);
    });
  }
}

class _SplashScene extends StatelessWidget {
  const _SplashScene({
    super.key,
    required this.settingsAsync,
    required this.logoScale,
    required this.textOpacity,
    required this.textOffset,
  });

  final AsyncValue<PulseSettings> settingsAsync;
  final Animation<double> logoScale;
  final Animation<double> textOpacity;
  final Animation<Offset> textOffset;

  @override
  Widget build(BuildContext context) {
    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;

    final settings = switch (settingsAsync) {
      AsyncData<PulseSettings>(:final value) => value,
      _ => null,
    };

    final targetBrightness = settings == null
        ? platformBrightness
        : switch (settings.themeMode) {
            PulseThemeMode.system => platformBrightness,
            PulseThemeMode.light => Brightness.light,
            PulseThemeMode.dark => Brightness.dark,
          };

    final palette = pulsePaletteForValue(
      settings?.themeColorValue ?? PulseSettings.defaults().themeColorValue,
    );
    final accent = palette.colorFor(targetBrightness);
    final isDark = targetBrightness == Brightness.dark;

    final topColor = isDark ? const Color(0xFF0F1218) : const Color(0xFFF2F5F7);
    final bottomColor = isDark
        ? const Color(0xFF112A3A)
        : const Color(0xFFE5F0F5);
    final titleColor = isDark ? Colors.white : const Color(0xFF25313D);
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFF6A7684);

    return Scaffold(
      backgroundColor: topColor,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [topColor, bottomColor],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: -120,
              right: -70,
              child: _GlowBlob(
                color: accent.withValues(alpha: isDark ? 0.24 : 0.11),
                size: 300,
              ),
            ),
            Positioned(
              bottom: -150,
              left: -90,
              child: _GlowBlob(
                color: accent.withValues(alpha: isDark ? 0.18 : 0.08),
                size: 330,
              ),
            ),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: logoScale,
                      child: Container(
                        width: 136,
                        height: 136,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(38),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(
                                alpha: isDark ? 0.24 : 0.12,
                              ),
                              blurRadius: 42,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: _SplashLogo(accent: accent),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: textOpacity,
                      child: SlideTransition(
                        position: textOffset,
                        child: Column(
                          children: [
                            Text(
                              'PULSE',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: titleColor,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.4,
                                  ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              'Seu treino. Sua evolução.',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: subtitleColor,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.1,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/splash_mark.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        return ClipOval(
          child: Image.asset(
            'assets/icon.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fitness_center_rounded,
                  color: accent,
                  size: 58,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.05), Colors.transparent],
        ),
      ),
    );
  }
}
