import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/exercises/domain/exercise_catalog.dart';
import 'package:pulse/features/workouts/data/catalogs/pre_made_workout_catalog.dart';
import 'package:pulse/models/exercise.dart';

void main() {
  test('mantém identificadores únicos e mídia estável no catálogo', () {
    final ids = exerciseDatabase.map((exercise) => exercise.id).toSet();

    expect(ids, hasLength(exerciseDatabase.length));
    expect(
      exerciseDatabase.every(
        (exercise) => ExerciseCatalog.hasMetadata(exercise.id),
      ),
      isTrue,
    );
    expect(
      exerciseDatabase.every(
        (exercise) =>
            ExerciseCatalog.mediaPathFor(exercise).startsWith('assets/images/'),
      ),
      isTrue,
    );
  });

  test('encontra nomes em português e aliases em inglês', () {
    final chestPress = exerciseDatabase.firstWhere(
      (exercise) => exercise.id == 'p12',
    );
    final hipThrust = exerciseDatabase.firstWhere(
      (exercise) => exercise.id == 'pe12',
    );
    final straightArmPulldown = exerciseDatabase.firstWhere(
      (exercise) => exercise.id == 'c9',
    );

    expect(ExerciseCatalog.matches(chestPress, 'chest press'), isTrue);
    expect(ExerciseCatalog.matches(chestPress, 'supino máquina'), isTrue);
    expect(ExerciseCatalog.matches(hipThrust, 'hip thrust'), isTrue);
    expect(
      ExerciseCatalog.matches(straightArmPulldown, 'straight arm pulldown'),
      isTrue,
    );
  });

  test('normaliza exercício legado sem perder a prescrição', () {
    const legacyExercise = Exercise(
      id: 'ex_pm_1',
      name: 'Chest Press',
      muscle: 'Peito',
      description: 'Controle a descida.',
      reps: '4x 8-12',
      rest: '75 seg',
      customNote: 'Última série até a falha',
    );

    final normalized = ExerciseCatalog.canonicalizeIdentity(legacyExercise);

    expect(normalized.id, 'p12');
    expect(normalized.name, 'Supino Reto Articulado');
    expect(normalized.muscle, 'Peito');
    expect(normalized.description, legacyExercise.description);
    expect(normalized.reps, legacyExercise.reps);
    expect(normalized.rest, legacyExercise.rest);
    expect(normalized.customNote, legacyExercise.customNote);
  });

  test('não transforma exercícios personalizados em itens do catálogo', () {
    const customExercise = Exercise(
      id: 'custom_123',
      name: 'Chest Press adaptado',
      muscle: 'Peito',
      description: 'Exercício personalizado.',
      reps: '3x 10',
      rest: '60 seg',
    );

    final normalized = ExerciseCatalog.canonicalizeIdentity(customExercise);

    expect(identical(normalized, customExercise), isTrue);
  });

  test('programas prontos usam identidades canônicas da biblioteca', () {
    final builtInIds = exerciseDatabase.map((exercise) => exercise.id).toSet();
    final programs = buildPreMadeWorkoutPrograms();
    final programExercises = programs
        .expand((program) => program.routines)
        .expand((routine) => routine.exercises)
        .toList();

    expect(
      programExercises.every((exercise) => builtInIds.contains(exercise.id)),
      isTrue,
    );
    expect(
      programExercises.any((exercise) => exercise.name == 'Chest Press'),
      isFalse,
    );
    expect(
      programExercises.firstWhere((exercise) => exercise.id == 'p12').name,
      'Supino Reto Articulado',
    );
  });
}
