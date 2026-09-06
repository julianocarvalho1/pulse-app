import '../../../../models/exercise.dart';
import '../../../exercises/domain/exercise_catalog.dart';
import '../models/advanced_workout_prescription.dart';

class ExerciseAlternativeService {
  const ExerciseAlternativeService();

  bool isAllowed(
    Exercise current,
    ExerciseAlternative candidate,
    List<Exercise> catalog,
  ) {
    final resolved = _findCatalogExercise(candidate, catalog);
    final muscle = resolved?.muscle ?? candidate.muscle;
    final target = ExerciseCatalog.standardizedMuscle(muscle);
    return target != 'Outros' &&
        target == ExerciseCatalog.standardizedMuscle(current.muscle);
  }

  Exercise buildReplacement({
    required Exercise current,
    required ExerciseAlternative selected,
    required List<Exercise> catalog,
  }) {
    if (!isAllowed(current, selected, catalog)) {
      throw ArgumentError(
        'A alternativa deve trabalhar o mesmo grupo muscular.',
      );
    }
    final catalogExercise = _findCatalogExercise(selected, catalog);
    final base =
        catalogExercise ??
        Exercise(
          id: selected.exerciseId.trim().isEmpty
              ? 'alternative_${_slug(selected.name)}'
              : selected.exerciseId.trim(),
          name: selected.name.trim(),
          muscle: selected.muscle.trim().isEmpty
              ? current.muscle
              : selected.muscle.trim(),
          description: 'Alternativa de ${current.name}.',
          reps: current.reps,
          rest: current.rest,
        );

    final alternatives = <ExerciseAlternative>[
      for (final alternative in current.advancedPrescription.alternatives)
        if (!_sameAlternative(alternative, selected)) alternative,
    ];
    final original = ExerciseAlternative(
      exerciseId: current.id,
      name: current.name,
      muscle: current.muscle,
    );
    if (!alternatives.any((item) => _sameAlternative(item, original))) {
      alternatives.add(original);
    }

    return base.copyWith(
      reps: current.reps,
      rest: current.rest,
      isSuperset: current.isSuperset,
      customNote: current.customNote,
      advancedPrescription: current.advancedPrescription.copyWith(
        alternatives: alternatives,
      ),
    );
  }

  Exercise? _findCatalogExercise(
    ExerciseAlternative alternative,
    List<Exercise> catalog,
  ) {
    final id = alternative.exerciseId.trim();
    if (id.isNotEmpty) {
      for (final exercise in catalog) {
        if (exercise.id == id) {
          return exercise;
        }
      }
    }
    final targetName = _normalize(alternative.name);
    for (final exercise in catalog) {
      if (_normalize(exercise.name) == targetName) {
        return exercise;
      }
    }
    return null;
  }

  bool _sameAlternative(ExerciseAlternative first, ExerciseAlternative second) {
    final firstId = first.exerciseId.trim();
    final secondId = second.exerciseId.trim();
    if (firstId.isNotEmpty && secondId.isNotEmpty) {
      return firstId == secondId;
    }
    return _normalize(first.name) == _normalize(second.name);
  }

  String _normalize(String value) => value.trim().toLowerCase();

  String _slug(String value) {
    final slug = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return slug.isEmpty ? 'exercise' : slug;
  }
}
