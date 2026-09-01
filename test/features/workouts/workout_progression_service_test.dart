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

  test('avança as séries mais baixas sem ultrapassar a faixa', () {
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

    expect(suggestion.lastPerformance, '40 kg: 8 / 9 / 8 reps');
    expect(suggestion.nextTarget, contains('pelo menos 9 repetições'));
    expect(suggestion.nextTarget, contains('sem passar de 10'));
  });

  test('não inventa carga quando todas as séries atingem o topo', () {
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

    expect(suggestion.nextTarget, contains('menor incremento de carga'));
    expect(suggestion.nextTarget, contains('retorne a 8 repetições'));
    expect(suggestion.nextTarget, isNot(contains('42,5 kg')));
  });

  test('normaliza prescrição descendente antes de limitar a progressão', () {
    const descendingExercise = Exercise(
      id: 'elevacao-lateral',
      name: 'Elevação lateral',
      muscle: 'Ombros',
      description: '',
      reps: '15-12-10',
      rest: '60 seg',
    );
    final history = <WorkoutHistoryItem>[
      WorkoutHistoryItem(
        id: 'history-descending',
        routineName: 'Treino B',
        date: DateTime(2026, 8, 9),
        duration: '30:00',
        exercises: <ExerciseLog>[
          ExerciseLog(
            exerciseId: descendingExercise.id,
            exerciseName: descendingExercise.name,
            sets: <ExerciseSet>[
              ExerciseSet(reps: 15, weight: 8),
              ExerciseSet(reps: 12, weight: 8),
              ExerciseSet(reps: 10, weight: 8),
            ],
          ),
        ],
      ),
    ];

    final suggestion = service.buildSuggestion(
      exercise: descendingExercise,
      history: history,
    );

    expect(suggestion.nextTarget, contains('Prescrição cumprida'));
  });

  test('prescrição fixa nunca sugere uma décima terceira repetição', () {
    const fixedExercise = Exercise(
      id: 'crucifixo',
      name: 'Crucifixo',
      muscle: 'Peito',
      description: '',
      reps: '3x 12',
      rest: '60 seg',
    );
    final history = <WorkoutHistoryItem>[
      WorkoutHistoryItem(
        id: 'history-fixed',
        routineName: 'Treino A',
        date: DateTime(2026, 8, 9),
        duration: '30:00',
        exercises: <ExerciseLog>[
          ExerciseLog(
            exerciseId: fixedExercise.id,
            exerciseName: fixedExercise.name,
            sets: const <ExerciseSet>[
              ExerciseSet(reps: 12, weight: 0),
              ExerciseSet(reps: 12, weight: 0),
              ExerciseSet(reps: 12, weight: 0),
            ],
          ),
        ],
      ),
    ];

    final suggestion = service.buildSuggestion(
      exercise: fixedExercise,
      history: history,
    );

    expect(suggestion.nextTarget, contains('Prescrição cumprida'));
    expect(suggestion.nextTarget, isNot(contains('13')));
  });

  test('ignora carga marcada como não comparável', () {
    final history = <WorkoutHistoryItem>[
      WorkoutHistoryItem(
        id: 'history-new-machine',
        routineName: 'Treino A',
        date: DateTime(2026, 8, 10),
        duration: '30:00',
        exercises: <ExerciseLog>[
          ExerciseLog(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            isLoadComparable: false,
            sets: const <ExerciseSet>[
              ExerciseSet(reps: 10, weight: 80),
              ExerciseSet(reps: 10, weight: 80),
              ExerciseSet(reps: 10, weight: 80),
            ],
          ),
        ],
      ),
      WorkoutHistoryItem(
        id: 'history-comparable',
        routineName: 'Treino A',
        date: DateTime(2026, 8, 8),
        duration: '30:00',
        exercises: <ExerciseLog>[
          ExerciseLog(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            sets: const <ExerciseSet>[
              ExerciseSet(reps: 8, weight: 40),
              ExerciseSet(reps: 8, weight: 40),
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

    expect(suggestion.lastPerformance, contains('40 kg'));
    expect(suggestion.lastPerformance, isNot(contains('80 kg')));
  });
}
