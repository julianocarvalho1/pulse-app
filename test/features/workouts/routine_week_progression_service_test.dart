import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/workouts/domain/models/advanced_workout_prescription.dart';
import 'package:pulse/features/workouts/domain/services/routine_week_progression_service.dart';
import 'package:pulse/models/exercise.dart';

void main() {
  const service = RoutineWeekProgressionService();

  Exercise exercise({
    required String id,
    required int activeWeek,
    required List<int> weeks,
  }) {
    return Exercise(
      id: id,
      name: 'Exercício $id',
      muscle: 'Teste',
      description: '',
      reps: '3x 10',
      rest: '60 seg',
      advancedPrescription: AdvancedExercisePrescription(
        activeWeek: activeWeek,
        weeks: <WorkoutWeekPrescription>[
          for (final week in weeks)
            WorkoutWeekPrescription(
              weekNumber: week,
              sets: <WorkoutSetPrescription>[
                WorkoutSetPrescription(setNumber: 1, target: '${10 - week}'),
              ],
            ),
        ],
      ),
    );
  }

  test('aplica a mesma semana em todos os exercícios periodizados', () {
    final result = service.applyWeek(<Exercise>[
      exercise(id: 'a', activeWeek: 1, weeks: <int>[1, 2, 3]),
      exercise(id: 'b', activeWeek: 1, weeks: <int>[1, 2, 3]),
    ], 3);

    expect(result[0].advancedPrescription.activeWeek, 3);
    expect(result[1].advancedPrescription.activeWeek, 3);
  });

  test(
    'usa a semana anterior disponível quando um exercício não possui a alvo',
    () {
      final result = service.applyWeek(<Exercise>[
        exercise(id: 'a', activeWeek: 1, weeks: <int>[1, 2, 4]),
      ], 3);

      expect(result.single.advancedPrescription.activeWeek, 2);
    },
  );

  test('descreve alterações e informa uso de semana alternativa', () {
    final changes = service.describeChanges(<Exercise>[
      exercise(id: 'a', activeWeek: 1, weeks: <int>[1, 2]),
      exercise(id: 'b', activeWeek: 1, weeks: <int>[1, 3]),
    ], 2);

    expect(changes, hasLength(2));
    expect(changes.first.toWeek, 2);
    expect(changes.last.toWeek, 1);
    expect(changes.last.usesFallbackWeek, isTrue);
  });
}
