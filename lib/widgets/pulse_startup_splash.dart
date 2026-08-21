import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/providers/auth_controller.dart';
import '../features/onboarding/presentation/providers/onboarding_controller.dart';
import '../features/settings/presentation/providers/settings_controller.dart';
import '../features/workouts/presentation/providers/workout_controller.dart';

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
  static const _minimumDisplayTime = Duration(milliseconds: 1100);

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
      duration: const Duration(milliseconds: 900),
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
    required this.logoScale,
    required this.textOpacity,
    required this.textOffset,
  });

  final Animation<double> logoScale;
  final Animation<double> textOpacity;
  final Animation<Offset> textOffset;

  static const Color _accent = Color(0xFF00E676);
  static const Color _top = Color(0xFF11171C);
  static const Color _bottom = Color(0xFF06130F);

  @override
  Widget build(BuildContext context) {
    const overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: _bottom,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: _bottom,
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[_top, Color(0xFF0B1C17), _bottom],
                  stops: <double>[0, 0.58, 1],
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.sizeOf(context).height * 0.21,
              left: -70,
              right: -70,
              child: const SizedBox(
                height: 360,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: <Color>[
                        Color(0x4300E676),
                        Color(0x1900E676),
                        Colors.transparent,
                      ],
                      stops: <double>[0, 0.48, 1],
                    ),
                  ),
                ),
              ),
            ),
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _PulseWavePainter()),
              ),
            ),
            SafeArea(
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          Container(
                            width: 244,
                            height: 244,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _accent.withValues(alpha: 0.18),
                                width: 1.2,
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: _accent.withValues(alpha: 0.14),
                                  blurRadius: 70,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          ScaleTransition(
                            scale: logoScale,
                            child: Container(
                              width: 142,
                              height: 142,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(34),
                                border: Border.all(
                                  color: _accent.withValues(alpha: 0.52),
                                  width: 1.4,
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: _accent.withValues(alpha: 0.34),
                                    blurRadius: 40,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: Image.asset(
                                  'assets/icon.png',
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.high,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const ColoredBox(
                                      color: Color(0xFFC7FF15),
                                      child: Icon(
                                        Icons.fitness_center_rounded,
                                        color: Colors.black,
                                        size: 62,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      FadeTransition(
                        opacity: textOpacity,
                        child: SlideTransition(
                          position: textOffset,
                          child: Column(
                            children: <Widget>[
                              const Text(
                                'PULSE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 8,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 13),
                              Text(
                                'Seu treino, no seu ritmo',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.35,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseWavePainter extends CustomPainter {
  const _PulseWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * 0.455;
    final path = Path()..moveTo(0, y);
    final points = <Offset>[
      Offset(size.width * 0.16, y),
      Offset(size.width * 0.19, y - 3),
      Offset(size.width * 0.205, y - 19),
      Offset(size.width * 0.222, y + 22),
      Offset(size.width * 0.24, y - 7),
      Offset(size.width * 0.265, y),
      Offset(size.width * 0.735, y),
      Offset(size.width * 0.76, y - 7),
      Offset(size.width * 0.778, y + 22),
      Offset(size.width * 0.795, y - 19),
      Offset(size.width * 0.81, y - 3),
      Offset(size.width * 0.84, y),
      Offset(size.width, y),
    ];

    for (final point in points) {
      path.lineTo(point.dx, point.dy);
    }

    final glowPaint = Paint()
      ..color = _SplashScene._accent.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawPath(path, glowPaint);

    final linePaint = Paint()
      ..color = _SplashScene._accent.withValues(alpha: 0.74)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _PulseWavePainter oldDelegate) => false;
}
