import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/personal_workout_import/domain/models/personal_workout_import.dart';
import 'package:pulse/features/workouts/domain/models/advanced_workout_prescription.dart';

void main() {
  test(
    'importação estrutura repetições por série, RIR, cadência e técnica',
    () {
      const draft = PersonalImportExerciseDraft(
        rawName: 'Supino Reto com Barra',
        seriesCount: 3,
        repetitions: '15-12-10',
        rest: '90s',
        note: '',
        selectedExerciseId: 'p1',
        suggestedExerciseIds: <String>['p1'],
        techniques: <String>['drop-set'],
        intensity: 'RIR 2',
        cadence: '3-1-1-0',
        alternatives: <String>[
          'Supino Reto com Barra',
          'Supino Reto com Halteres',
        ],
      );

      final exercise = draft.toExercise(
        stamp: 1,
        routineIndex: 0,
        exerciseIndex: 0,
      );
      final prescription = exercise.advancedPrescription;

      expect(prescription.isEmpty, isFalse);
      expect(prescription.activePrescription?.sets, hasLength(3));
      expect(
        prescription.activePrescription?.sets.map((set) => set.target),
        <String>['15 reps', '12 reps', '10 reps'],
      );
      expect(prescription.activePrescription?.sets.first.targetRir, 2);
      expect(prescription.activePrescription?.sets.first.cadence, '3-1-1-0');
      expect(
        prescription.activePrescription?.sets.first.technique,
        WorkoutTechnique.dropSet,
      );
      expect(prescription.alternatives.single.exerciseId, 'p2');
    },
  );

  test('não confunde faixa 08 A 12 com repetições diferentes por série', () {
    const draft = PersonalImportExerciseDraft(
      rawName: 'Elevação Frontal com Corda',
      seriesCount: 2,
      repetitions: '08 A 12',
      rest: '60s',
      note: '',
      suggestedExerciseIds: <String>[],
    );

    final exercise = draft.toExercise(
      stamp: 2,
      routineIndex: 0,
      exerciseIndex: 0,
    );

    expect(exercise.advancedPrescription.isEmpty, isTrue);
    expect(exercise.reps, '2x 08 A 12');
  });
}
