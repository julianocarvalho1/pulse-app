import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/workouts/domain/models/cardio_log.dart';
import 'package:pulse/features/workouts/domain/models/exercise_log.dart';
import 'package:pulse/features/workouts/domain/models/free_activity_log.dart';
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
          notes: 'Usei a máquina do segundo andar.',
          isLoadComparable: false,
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
    expect(find.text('Anotações'), findsOneWidget);
    expect(find.text('Usei a máquina do segundo andar.'), findsOneWidget);
    expect(
      find.text('Carga não usada na comparação de progressão.'),
      findsOneWidget,
    );
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

  testWidgets('detalhes de cardio mostram métricas reais sem calorias', (
    tester,
  ) async {
    final workout = WorkoutHistoryItem(
      id: 'cardio-1',
      routineName: 'Cardio • Bicicleta',
      date: DateTime(2026, 7, 31, 14),
      duration: '42:00',
      exercises: const <ExerciseLog>[],
      cardio: const <CardioLog>[
        CardioLog(
          modality: CardioModality.stationaryBike,
          plannedDurationMinutes: 45,
          actualDurationMinutes: 42,
          distanceKm: 16.4,
          averageSpeedKmh: 23.4,
          perceivedEffort: 8,
          averageHeartRateBpm: 148,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildPulseLightTheme(pulsePalettes[1].lightPrimary),
        home: WorkoutHistoryDetailScreen(workout: workout),
      ),
    );

    expect(find.text('Detalhes do cardio'), findsOneWidget);
    expect(find.text('CARDIO'), findsOneWidget);
    expect(find.text('Bicicleta'), findsOneWidget);
    expect(find.text('42 min realizados'), findsOneWidget);
    expect(find.text('16,4 km'), findsWidgets);
    expect(find.text('Esforço 8/10'), findsOneWidget);
    expect(find.textContaining('calorias'), findsNothing);
    expect(find.text('EXERCÍCIOS REALIZADOS'), findsNothing);
  });

  testWidgets('detalhes de atividade livre mostram substituição e observação', (
    tester,
  ) async {
    final activity = WorkoutHistoryItem(
      id: 'activity-1',
      routineName: 'Atividade • CrossFit',
      date: DateTime(2026, 8, 2, 18),
      duration: '55:00',
      exercises: const <ExerciseLog>[],
      freeActivities: const <FreeActivityLog>[
        FreeActivityLog(
          type: FreeActivityType.crossfit,
          durationMinutes: 55,
          intensity: FreeActivityIntensity.intense,
          replacedPlannedWorkout: true,
          notes: 'Aula com as amigas.',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildPulseLightTheme(pulsePalettes[1].lightPrimary),
        home: WorkoutHistoryDetailScreen(workout: activity),
      ),
    );

    expect(find.text('Detalhes da atividade'), findsOneWidget);
    expect(find.text('ATIVIDADE'), findsOneWidget);
    expect(find.text('ATIVIDADE REALIZADA'), findsOneWidget);
    expect(find.text('CrossFit'), findsOneWidget);
    expect(find.text('55 min'), findsWidgets);
    expect(find.text('Intensa'), findsWidgets);
    expect(find.text('Aula com as amigas.'), findsOneWidget);
    expect(find.text('EXERCÍCIOS REALIZADOS'), findsNothing);
  });
}
