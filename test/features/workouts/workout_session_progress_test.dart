import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/workouts/domain/models/active_workout_session.dart';
import 'package:pulse/features/workouts/domain/models/workout_session_progress.dart';
import 'package:pulse/models/exercise.dart';

void main() {
  const exercise = Exercise(
    id: 'supino',
    name: 'Supino',
    muscle: 'Peito',
    description: '',
    reps: '3x 10',
    rest: '60 seg',
  );

  test('calcula o progresso real pelas séries concluídas', () {
    final session = ActiveWorkoutSession(
      id: 'session-1',
      routineName: 'Treino A',
      startedAt: DateTime(2026, 7, 30),
      elapsedSeconds: 120,
      exercises: <ActiveWorkoutExercise>[
        ActiveWorkoutExercise(
          exercise: exercise,
          sets: const <ActiveWorkoutSet>[
            ActiveWorkoutSet(setNumber: 1, isCompleted: true),
            ActiveWorkoutSet(setNumber: 2, isCompleted: true),
            ActiveWorkoutSet(setNumber: 3),
          ],
        ),
      ],
    );

    final progress = WorkoutSessionProgress.fromSession(session);

    expect(progress.completedSets, 2);
    expect(progress.totalSets, 3);
    expect(progress.remainingSets, 1);
    expect(progress.percentage, 67);
    expect(progress.completedExercises, 0);
    expect(progress.isComplete, isFalse);
  });

  test('marca exercício e sessão como completos', () {
    final session = ActiveWorkoutSession(
      id: 'session-2',
      routineName: 'Treino A',
      startedAt: DateTime(2026, 7, 30),
      elapsedSeconds: 120,
      exercises: <ActiveWorkoutExercise>[
        ActiveWorkoutExercise(
          exercise: exercise,
          sets: const <ActiveWorkoutSet>[
            ActiveWorkoutSet(setNumber: 1, isCompleted: true),
            ActiveWorkoutSet(setNumber: 2, isCompleted: true),
            ActiveWorkoutSet(setNumber: 3, isCompleted: true),
          ],
        ),
      ],
    );

    final progress = WorkoutSessionProgress.fromSession(session);

    expect(progress.percentage, 100);
    expect(progress.completedExercises, 1);
    expect(progress.isComplete, isTrue);
  });
}
