import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/workouts/domain/models/cardio_log.dart';
import 'package:pulse/models/exercise.dart';

void main() {
  const exercise = Exercise(
    id: 'e1',
    name: 'Supino',
    muscle: 'Peito',
    description: '',
    reps: '3x 10',
    rest: '60 seg',
  );
  const cardio = RoutineCardio(
    id: 'c1',
    modality: CardioModality.treadmill,
    plannedDurationMinutes: 20,
  );

  test('identifica ficha de musculação pelo conteúdo', () {
    final routine = WorkoutRoutine(
      id: 'r1',
      name: 'Treino A',
      focus: 'Peito',
      exercises: const <Exercise>[exercise],
    );

    expect(routine.type, RoutineType.strength);
    expect(routine.typeLabel, 'Musculação');
    expect(routine.activitySummary, '1 exercício');
  });

  test('identifica ficha somente de cardio', () {
    final routine = WorkoutRoutine(
      id: 'r2',
      name: 'Cardio',
      focus: 'Condicionamento',
      exercises: const <Exercise>[],
      cardio: const <RoutineCardio>[cardio],
    );

    expect(routine.type, RoutineType.cardio);
    expect(routine.activitySummary, '1 cardio');
  });

  test('identifica ficha mista', () {
    final routine = WorkoutRoutine(
      id: 'r3',
      name: 'Misto',
      focus: 'Geral',
      exercises: const <Exercise>[exercise],
      cardio: const <RoutineCardio>[cardio],
    );

    expect(routine.type, RoutineType.mixed);
    expect(routine.activitySummary, '1 exercício • 1 cardio');
  });
}
