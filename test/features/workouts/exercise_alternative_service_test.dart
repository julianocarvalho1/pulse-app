import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/workouts/domain/models/advanced_workout_prescription.dart';
import 'package:pulse/features/workouts/domain/services/exercise_alternative_service.dart';
import 'package:pulse/models/exercise.dart';

void main() {
  const service = ExerciseAlternativeService();
  const alternative = ExerciseAlternative(
    exerciseId: 'machine',
    name: 'Supino Máquina',
    muscle: 'Peito',
  );
  const current = Exercise(
    id: 'barbell',
    name: 'Supino com Barra',
    muscle: 'Peito',
    description: '',
    reps: '4x 8-10',
    rest: '90 seg',
    advancedPrescription: AdvancedExercisePrescription(
      activeWeek: 2,
      weeks: <WorkoutWeekPrescription>[
        WorkoutWeekPrescription(
          weekNumber: 2,
          sets: <WorkoutSetPrescription>[
            WorkoutSetPrescription(setNumber: 1, target: '8-10'),
          ],
        ),
      ],
      alternatives: <ExerciseAlternative>[alternative],
    ),
  );

  test('troca a identidade e preserva a prescrição do exercício', () {
    const machine = Exercise(
      id: 'machine',
      name: 'Supino Máquina',
      muscle: 'Peito',
      description: 'Máquina articulada',
      reps: '3x 12',
      rest: '60 seg',
    );

    final replacement = service.buildReplacement(
      current: current,
      selected: alternative,
      catalog: const <Exercise>[machine],
    );

    expect(replacement.id, 'machine');
    expect(replacement.reps, '4x 8-10');
    expect(replacement.rest, '90 seg');
    expect(replacement.advancedPrescription.activeWeek, 2);
    expect(
      replacement.advancedPrescription.alternatives.single.exerciseId,
      'barbell',
    );
  });

  test(
    'recusa alternativa de outro músculo inclusive com metadado incorreto',
    () {
      final leg = current.copyWith(
        id: 'leg',
        name: 'Agachamento',
        muscle: 'Pernas',
      );
      const selected = ExerciseAlternative(
        exerciseId: 'leg',
        name: 'Agachamento',
        muscle: 'Peito',
      );
      expect(service.isAllowed(current, selected, [leg]), isFalse);
      expect(
        () => service.buildReplacement(
          current: current,
          selected: selected,
          catalog: [leg],
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'cria exercício temporário quando alternativa não existe no catálogo',
    () {
      const unknown = ExerciseAlternative(
        exerciseId: '',
        name: 'Variação do personal',
        muscle: 'Peito',
      );

      final replacement = service.buildReplacement(
        current: current,
        selected: unknown,
        catalog: const <Exercise>[],
      );

      expect(replacement.name, 'Variação do personal');
      expect(replacement.id, startsWith('alternative_'));
      expect(replacement.reps, current.reps);
    },
  );
}
