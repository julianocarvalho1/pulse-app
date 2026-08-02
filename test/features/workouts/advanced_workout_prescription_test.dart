import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/workouts/domain/models/advanced_workout_prescription.dart';
import 'package:pulse/models/exercise.dart';

void main() {
  const prescription = AdvancedExercisePrescription(
    activeWeek: 2,
    weeks: <WorkoutWeekPrescription>[
      WorkoutWeekPrescription(
        weekNumber: 1,
        label: 'Acúmulo',
        sets: <WorkoutSetPrescription>[
          WorkoutSetPrescription(
            setNumber: 1,
            target: '10–12 reps',
            restSeconds: 60,
            targetRir: 2,
            cadence: '3-1-1-0',
          ),
        ],
      ),
      WorkoutWeekPrescription(
        weekNumber: 2,
        label: 'Intensificação',
        sets: <WorkoutSetPrescription>[
          WorkoutSetPrescription(
            setNumber: 1,
            target: '6–8 reps',
            restSeconds: 120,
            targetRir: 1,
            technique: WorkoutTechnique.restPause,
            notes: 'Somente na última série.',
          ),
          WorkoutSetPrescription(
            setNumber: 2,
            target: '6–8 reps',
            restSeconds: 120,
            targetRir: 1,
          ),
        ],
      ),
    ],
    alternatives: <ExerciseAlternative>[
      ExerciseAlternative(
        exerciseId: 'p2',
        name: 'Supino Reto com Halteres',
        muscle: 'Peito',
      ),
    ],
  );

  test('prescrição avançada preserva semanas, séries e alternativas', () {
    final restored = AdvancedExercisePrescription.fromMap(prescription.toMap());

    expect(restored.activeWeek, 2);
    expect(restored.weeks, hasLength(2));
    expect(restored.activePrescription?.label, 'Intensificação');
    expect(restored.activePrescription?.sets, hasLength(2));
    expect(
      restored.activePrescription?.sets.first.technique,
      WorkoutTechnique.restPause,
    );
    expect(restored.alternatives.single.exerciseId, 'p2');
  });

  test('Exercise antigo continua válido sem prescrição avançada', () {
    final exercise = Exercise.fromMap(<String, dynamic>{
      'id': 'p1',
      'name': 'Supino',
      'muscle': 'Peito',
      'description': '',
      'reps': '3x 10',
      'rest': '60 seg',
    });

    expect(exercise.advancedPrescription.isEmpty, isTrue);
    expect(exercise.reps, '3x 10');
  });

  test('Exercise serializa prescrição avançada sem perder dados', () {
    const exercise = Exercise(
      id: 'p1',
      name: 'Supino',
      muscle: 'Peito',
      description: '',
      reps: '3x 10',
      rest: '60 seg',
      advancedPrescription: prescription,
    );

    final restored = Exercise.fromMap(exercise.toMap());

    expect(restored.advancedPrescription.activeWeek, 2);
    expect(
      restored.advancedPrescription.activePrescription?.sets.first.targetRir,
      1,
    );
    expect(
      restored.advancedPrescription.alternatives.single.name,
      contains('Halteres'),
    );
  });
  test(
    'prescrição principal usa a primeira configuração sem apagar as demais',
    () {
      final restored = AdvancedExercisePrescription.fromMap(
        prescription.toMap(),
      );

      expect(restored.primaryPrescription?.weekNumber, 1);
      expect(restored.primaryPrescription?.label, 'Acúmulo');
      expect(restored.primaryPrescription?.sets.single.target, '10–12 reps');
      expect(restored.weeks, hasLength(2));
      expect(restored.activeWeek, 2);
    },
  );

  test('resumo simplificado não expõe planejamento por semanas', () {
    expect(prescription.summary, contains('1 série detalhada'));
    expect(prescription.summary, contains('1 alternativa'));
    expect(prescription.summary.toLowerCase(), isNot(contains('semana')));
  });
}
