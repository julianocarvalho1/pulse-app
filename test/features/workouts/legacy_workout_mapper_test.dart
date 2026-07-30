import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/workouts/data/mappers/legacy_workout_mapper.dart';
import 'package:pulse/features/workouts/domain/models/workout_history_item.dart';
import 'package:pulse/features/workouts/domain/models/workout_session_status.dart';
import 'package:pulse/features/workouts/domain/models/workout_set.dart';

void main() {
  group('LegacyWorkoutMapper', () {
    test('converte séries e faixa de repetições', () {
      final config = LegacyWorkoutMapper.parseExerciseConfig(
        reps: '4x 8-10',
        rest: '60 seg',
      );

      expect(config.seriesCount, 4);
      expect(config.minimumReps, 8);
      expect(config.maximumReps, 10);
      expect(config.recommendedRestSeconds, 60);
    });

    test('converte faixa de descanso em minutos', () {
      final config = LegacyWorkoutMapper.parseExerciseConfig(
        reps: '3x 10-12',
        rest: '1 a 2 min',
      );

      expect(config.minimumRestSeconds, 60);
      expect(config.maximumRestSeconds, 120);
      expect(config.recommendedRestSeconds, 90);
    });
  });

  test('ExerciseSet calcula volume', () {
    const set = ExerciseSet(reps: 10, weight: 20);

    expect(set.volume, 200);
  });

  test('histórico antigo assume status concluído', () {
    final item = WorkoutHistoryItem.fromMap({
      'id': '1',
      'routineName': 'Treino A',
      'date': '2026-07-29T10:00:00.000',
      'duration': '45:00',
      'exercises': <Map<String, dynamic>>[],
      'notes': '',
    });

    expect(item.status, WorkoutSessionStatus.completed);
  });
}
