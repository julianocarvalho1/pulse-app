import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/workouts/domain/models/workout_set.dart';

void main() {
  group('WorkoutSetTarget', () {
    test('mantém prescrições de repetições como repetições', () {
      final target = WorkoutSetTarget.fromText('3x 8-12 por lado');

      expect(target.type, WorkoutSetTargetType.repetitions);
      expect(target.plannedDurationSeconds, 0);
    });

    test('identifica segundos mesmo em faixa compacta', () {
      final target = WorkoutSetTarget.fromText('3x 30-45s');

      expect(target.type, WorkoutSetTargetType.duration);
      expect(target.plannedDurationSeconds, 30);
    });

    test('converte minutos e formato de relógio', () {
      expect(
        WorkoutSetTarget.fromText('2x 1,5 min').plannedDurationSeconds,
        90,
      );
      expect(
        WorkoutSetTarget.fromText('2x 01:15 min').plannedDurationSeconds,
        75,
      );
    });
  });

  test('série por tempo não gera volume de carga', () {
    const set = ExerciseSet(
      reps: 0,
      weight: 20,
      targetType: WorkoutSetTargetType.duration,
      plannedDurationSeconds: 30,
      actualDurationSeconds: 34,
    );

    expect(set.isTimed, isTrue);
    expect(set.volume, 0);
    expect(ExerciseSet.fromMap(set.toMap()).actualDurationSeconds, 34);
  });

  test('aquecimento é preservado mas não entra no volume de trabalho', () {
    const set = ExerciseSet(reps: 12, weight: 20, kind: WorkoutSetKind.warmUp);

    expect(set.isWarmUp, isTrue);
    expect(set.volume, 0);
    expect(ExerciseSet.fromMap(set.toMap()).kind, WorkoutSetKind.warmUp);
  });
}
