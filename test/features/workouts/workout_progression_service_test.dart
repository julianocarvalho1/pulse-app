import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/workouts/domain/models/exercise_log.dart';
import 'package:pulse/features/workouts/domain/models/workout_history_item.dart';
import 'package:pulse/features/workouts/domain/models/workout_set.dart';
import 'package:pulse/features/workouts/domain/services/workout_progression_service.dart';
import 'package:pulse/models/exercise.dart';

void main() {
  const exercise = Exercise(
    id: 'supino',
    name: 'Supino',
    muscle: 'Peito',
    description: '',
    reps: '3x 8-10',
    rest: '60 seg',
  );

  const service = WorkoutProgressionService();

  test('sugere mais uma repetição dentro da faixa', () {
    final history = <WorkoutHistoryItem>[
      WorkoutHistoryItem(
        id: 'history-1',
        routineName: 'Treino A',
        date: DateTime(2026, 7, 29),
        duration: '30:00',
        exercises: <ExerciseLog>[
          ExerciseLog(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            sets: const <ExerciseSet>[
              ExerciseSet(reps: 8, weight: 40),
              ExerciseSet(reps: 9, weight: 40),
              ExerciseSet(reps: 8, weight: 40),
            ],
          ),
        ],
      ),
    ];

    final suggestion = service.buildSuggestion(
      exercise: exercise,
      history: history,
    );

    expect(suggestion.lastPerformance, '40 kg × 9');
    expect(suggestion.nextTarget, contains('10 repetições'));
  });

  test('sugere aumento conservador quando todas as séries atingem o topo', () {
    final history = <WorkoutHistoryItem>[
      WorkoutHistoryItem(
        id: 'history-2',
        routineName: 'Treino A',
        date: DateTime(2026, 7, 29),
        duration: '30:00',
        exercises: <ExerciseLog>[
          ExerciseLog(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            sets: const <ExerciseSet>[
              ExerciseSet(reps: 10, weight: 40),
              ExerciseSet(reps: 10, weight: 40),
              ExerciseSet(reps: 10, weight: 40),
            ],
          ),
        ],
      ),
    ];

    final suggestion = service.buildSuggestion(
      exercise: exercise,
      history: history,
    );

    expect(suggestion.nextTarget, contains('42,5 kg'));
    expect(suggestion.nextTarget, contains('8 repetições'));
  });
}
