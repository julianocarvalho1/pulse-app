import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/workouts/domain/models/active_workout_session.dart';
import 'package:pulse/features/workouts/domain/models/advanced_workout_prescription.dart';
import 'package:pulse/features/workouts/domain/models/cardio_log.dart';
import 'package:pulse/models/exercise.dart';

void main() {
  test('active workout session keeps set progress in map conversion', () {
    final session = ActiveWorkoutSession(
      id: 'active',
      routineName: 'Treino A',
      startedAt: DateTime(2026, 7, 29, 20),
      elapsedSeconds: 125,
      notes: 'Boa execução',
      restSeconds: 48,
      restEndsAt: DateTime(2026, 7, 29, 20, 3),
      isRestPaused: false,
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
              targetText: '8–10 reps',
              targetRir: 2,
              cadence: '3-1-1-0',
              technique: WorkoutTechnique.isometry,
              prescribedRestSeconds: 90,
            ),
            ActiveWorkoutSet(setNumber: 2, weightText: '20', repsText: '9'),
          ],
        ),
      ],
      cardio: const <ActiveCardioEntry>[
        ActiveCardioEntry(
          id: 'cardio-1',
          modality: CardioModality.elliptical,
          plannedDurationMinutes: 20,
          actualDurationMinutes: 18,
          perceivedEffort: 7,
          isCompleted: true,
        ),
      ],
    );

    final restored = ActiveWorkoutSession.fromMap(session.toMap());

    expect(restored.routineName, 'Treino A');
    expect(restored.elapsedSeconds, 125);
    expect(restored.notes, 'Boa execução');
    expect(restored.restSeconds, 48);
    expect(restored.restEndsAt, DateTime(2026, 7, 29, 20, 3));
    expect(restored.isRestPaused, isFalse);
    expect(restored.exercises.single.exercise.id, 'supino');
    expect(restored.exercises.single.sets.first.isCompleted, isTrue);
    expect(restored.exercises.single.sets.first.targetText, '8–10 reps');
    expect(restored.exercises.single.sets.first.targetRir, 2);
    expect(
      restored.exercises.single.sets.first.technique,
      WorkoutTechnique.isometry,
    );
    expect(restored.exercises.single.sets.last.repsText, '9');
    expect(restored.cardio.single.modality, CardioModality.elliptical);
    expect(restored.cardio.single.actualDurationMinutes, 18);
    expect(restored.cardio.single.isCompleted, isTrue);
  });
}
