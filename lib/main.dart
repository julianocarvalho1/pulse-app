import 'package:provider/provider.dart';
import 'providers/workout_provider.dart';
import 'screens/exercises_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/workout_plan_screen.dart';
import 'screens/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        // AQUI: Adicionamos o novo cérebro que vai controlar as cores
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const FitApp(),
    ),
  );
}

class FitApp extends StatelessWidget {
  const FitApp({super.key});

  @override
  Widget build(BuildContext context) {
    // AQUI: O Consumer envolve o app e reconstrói as telas quando a cor muda
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'FitApp',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme, // AQUI: Agora a cor puxa do Provider
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();

    if (!provider.isAuthenticated) {
      return const AuthScreen();
    }

    return const MainNavigation();
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    WorkoutPlanScreen(),
    ExercisesScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: _screens),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          // AQUI: Usando a cor dinâmica no ícone selecionado do menu inferior
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Início'),
            BottomNavigationBarItem(
                icon: Icon(Icons.fitness_center), label: 'Treinos'),
            BottomNavigationBarItem(
                icon: Icon(Icons.view_list_outlined),
                activeIcon: Icon(Icons.view_list),
                label: 'Exercícios'),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart), label: 'Progresso'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}