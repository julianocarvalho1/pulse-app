import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/workouts/domain/models/exercise_log.dart';
import 'package:pulse/features/workouts/domain/models/workout_history_item.dart';
import 'package:pulse/features/workouts/domain/models/workout_session_status.dart';
import 'package:pulse/features/workouts/domain/models/workout_set.dart';
import 'package:pulse/screens/workout_history_detail_screen.dart';
import 'package:pulse/theme/app_theme.dart';

void main() {
  testWidgets('detalhes do treino mostram resumo e omitem carga zerada', (
    tester,
  ) async {
    final workout = WorkoutHistoryItem(
      id: 'history-1',
      routineName: 'Treino A',
      date: DateTime(2026, 7, 31, 12, 30),
      duration: '45:10',
      exercises: [
        ExerciseLog(
          exerciseId: 'p12',
          exerciseName: 'Supino Reto Articulado',
          sets: const [
            ExerciseSet(reps: 8, weight: 0),
            ExerciseSet(reps: 10, weight: 20),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildPulseLightTheme(pulsePalettes[1].lightPrimary),
        home: WorkoutHistoryDetailScreen(workout: workout),
      ),
    );

    expect(find.text('Detalhes do treino'), findsOneWidget);
    expect(find.text('Treino A'), findsOneWidget);
    expect(find.text('Supino Reto Articulado'), findsOneWidget);
    expect(find.textContaining('2 séries'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('0.0 kg'), findsNothing);
    expect(find.text('20 kg'), findsOneWidget);
  });

  testWidgets('treino incompleto destaca o histórico parcial', (tester) async {
    final workout = WorkoutHistoryItem(
      id: 'history-2',
      routineName: 'Treino B',
      date: DateTime(2026, 7, 31, 13, 20),
      duration: '00:37',
      status: WorkoutSessionStatus.incomplete,
      exercises: [
        ExerciseLog(
          exerciseId: 'c1',
          exerciseName: 'Puxada Frontal Aberta',
          sets: const [ExerciseSet(reps: 10, weight: 0)],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildPulseLightTheme(pulsePalettes[1].lightPrimary),
        home: WorkoutHistoryDetailScreen(workout: workout),
      ),
    );

    expect(find.text('INCOMPLETO'), findsOneWidget);
    expect(find.text('Treino encerrado antes do fim.'), findsOneWidget);
    expect(find.text('Histórico parcial salvo'), findsOneWidget);
    expect(
      find.text(
        'Somente exercícios e séries concluídos foram registrados neste treino.',
      ),
      findsOneWidget,
    );
  });
}
