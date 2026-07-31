import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/presentation/auth_gate.dart';
import 'features/onboarding/presentation/onboarding_gate.dart';
import 'features/settings/domain/pulse_settings.dart';
import 'features/settings/presentation/providers/settings_controller.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/workout_plan_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/pulse_startup_splash.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const ProviderScope(child: PulseApp()));
}

class PulseApp extends ConsumerStatefulWidget {
  const PulseApp({super.key});

  @override
  ConsumerState<PulseApp> createState() => _PulseAppState();
}

class _PulseAppState extends ConsumerState<PulseApp>
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
  void didChangePlatformBrightness() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsControllerProvider);

    final loadedSettings = switch (settingsAsync) {
      AsyncData<PulseSettings>(:final value) => value,
      _ => null,
    };
    final settings = loadedSettings ?? PulseSettings.defaults();

    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final effectiveBrightness = loadedSettings == null
        ? platformBrightness
        : _resolveBrightness(settings.themeMode, platformBrightness);
    final materialThemeMode = loadedSettings == null
        ? ThemeMode.system
        : _toMaterialThemeMode(settings.themeMode);
    final selectedPalette = pulsePaletteForValue(settings.themeColorValue);
    final effectivePrimaryColor = selectedPalette.colorFor(effectiveBrightness);

    AppColors.configure(
      effectiveBrightness,
      primaryColor: effectivePrimaryColor,
    );
    final overlayStyle = pulseSystemUiOverlayStyle(effectiveBrightness);
    SystemChrome.setSystemUIOverlayStyle(overlayStyle);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: MaterialApp(
        title: 'PULSE',
        debugShowCheckedModeBanner: false,
        theme: buildPulseLightTheme(selectedPalette.lightPrimary),
        darkTheme: buildPulseDarkTheme(selectedPalette.darkPrimary),
        themeMode: materialThemeMode,
        home: const PulseStartupSplash(
          child: AuthGate(child: OnboardingGate(child: MainNavigation())),
        ),
      ),
    );
  }

  Brightness _resolveBrightness(
    PulseThemeMode themeMode,
    Brightness platformBrightness,
  ) {
    return switch (themeMode) {
      PulseThemeMode.system => platformBrightness,
      PulseThemeMode.light => Brightness.light,
      PulseThemeMode.dark => Brightness.dark,
    };
  }

  ThemeMode _toMaterialThemeMode(PulseThemeMode themeMode) {
    return switch (themeMode) {
      PulseThemeMode.system => ThemeMode.system,
      PulseThemeMode.light => ThemeMode.light,
      PulseThemeMode.dark => ThemeMode.dark,
    };
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = <Widget>[
      HomeScreen(
        onOpenWorkouts: () => _selectTab(1),
        onOpenProgress: () => _selectTab(2),
      ),
      const WorkoutPlanScreen(),
      const ProgressScreen(),
      ProfileScreen(
        onOpenWorkouts: () => _selectTab(1),
        onOpenProgress: () => _selectTab(2),
      ),
    ];
  }

  void _selectTab(int index) {
    if (_index == index) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final systemUiStyle = pulseSystemUiOverlayStyle(
      Theme.of(context).brightness,
    ).copyWith(statusBarColor: Colors.transparent);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUiStyle,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(index: _index, children: _screens),
        bottomNavigationBar: ColoredBox(
          color: AppColors.surface,
          child: SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: NavigationBar(
                height: 68,
                backgroundColor: AppColors.surface,
                indicatorColor: AppColors.primarySoft,
                selectedIndex: _index,
                onDestinationSelected: _selectTab,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: const <NavigationDestination>[
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Hoje',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.fitness_center_outlined),
                    selectedIcon: Icon(Icons.fitness_center),
                    label: 'Treinos',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.insights_outlined),
                    selectedIcon: Icon(Icons.insights_rounded),
                    label: 'Progresso',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: 'Perfil',
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
