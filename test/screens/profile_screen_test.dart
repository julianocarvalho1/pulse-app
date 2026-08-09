import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/workouts/domain/models/workout_history_item.dart';
import 'package:pulse/features/workouts/presentation/providers/workout_controller.dart';
import 'package:pulse/features/workouts/presentation/state/workout_state.dart';
import 'package:pulse/screens/profile_screen.dart';
import 'package:pulse/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('histórico só é excluído depois da confirmação', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final palette = pulsePalettes.first;
    AppColors.configure(Brightness.light, primaryColor: palette.lightPrimary);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutControllerProvider.overrideWith(_FakeWorkoutController.new),
        ],
        child: MaterialApp(
          theme: buildPulseLightTheme(palette.lightPrimary),
          home: const Scaffold(body: ProfileScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final historyItems = find.byKey(const Key('history-test'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();
    final historyItem = historyItems.hitTestable().first;

    await tester.drag(historyItem, const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.text('Excluir registro do histórico?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(historyItems, findsWidgets);

    await tester.drag(historyItem, const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDeleteHistoryButton')));
    await tester.pumpAndSettle();

    expect(historyItems, findsNothing);
    expect(find.text('Registro excluído do histórico.'), findsOneWidget);
  });
}

class _FakeWorkoutController extends WorkoutController {
  @override
  WorkoutState build() =>
      WorkoutState.initial(preMadePrograms: const []).copyWith(
        isInitialized: true,
        history: <WorkoutHistoryItem>[
          WorkoutHistoryItem(
            id: 'history-test',
            routineName: 'Treino de teste',
            date: DateTime(2026, 8, 9, 10),
            duration: '00:01:00',
            exercises: const [],
            notes: 'Teste de lançamento',
          ),
        ],
      );

  @override
  Future<void> deleteHistoryItem(String id) async {
    state = state.copyWith(
      history: state.history.where((item) => item.id != id).toList(),
    );
  }
}
