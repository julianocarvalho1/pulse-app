import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/workouts/domain/models/active_workout_session.dart';
import 'package:pulse/models/exercise.dart';

void main() {
  test('active workout session keeps set progress in map conversion', () {
    final session = ActiveWorkoutSession(
      id: 'active',
      routineName: 'Treino A',
      startedAt: DateTime(2026, 7, 29, 20),
      elapsedSeconds: 125,
      notes: 'Boa execução',
      exercises: [
        ActiveWorkoutExercise(
          exercise: const Exercise(
            id: 'supino',
            name: 'Supino',
            muscle: 'Peito',
            description: 'Controle a descida.',
            reps: '3x 8-10',
            rest: '90 seg',
          ),
          sets: const [
            ActiveWorkoutSet(
              setNumber: 1,
              weightText: '20',
              repsText: '10',
              isCompleted: true,
            ),
            ActiveWorkoutSet(setNumber: 2, weightText: '20', repsText: '9'),
          ],
        ),
      ],
    );

    final restored = ActiveWorkoutSession.fromMap(session.toMap());

    expect(restored.routineName, 'Treino A');
    expect(restored.elapsedSeconds, 125);
    expect(restored.notes, 'Boa execução');
    expect(restored.exercises.single.exercise.id, 'supino');
    expect(restored.exercises.single.sets.first.isCompleted, isTrue);
    expect(restored.exercises.single.sets.last.repsText, '9');
  });
}
