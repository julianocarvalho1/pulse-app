import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/exercise.dart';
import '../../data/catalogs/pre_made_workout_catalog.dart';
import '../../domain/models/cardio_log.dart';
import 'workout_library_controller.dart';

final workoutCatalogControllerProvider =
    NotifierProvider<WorkoutCatalogController, List<WorkoutProgram>>(
      WorkoutCatalogController.new,
    );

class WorkoutCatalogController extends Notifier<List<WorkoutProgram>> {
  @override
  List<WorkoutProgram> build() {
    return List<WorkoutProgram>.unmodifiable(buildPreMadeWorkoutPrograms());
  }

  bool isProgramImported(WorkoutProgram program) {
    if (program.routines.isEmpty) {
      return false;
    }

    return program.routines.every(
      (routine) => _isCatalogRoutineImported(program, routine),
    );
  }

  bool importProgram(WorkoutProgram program) {
    final missingRoutines = program.routines
        .where((routine) => !_isCatalogRoutineImported(program, routine))
        .map(
          (routine) => WorkoutRoutine(
            id: _catalogRoutineId(program, routine),
            name: routine.name,
            focus: routine.focus,
            groupName: program.name,
            exercises: List<Exercise>.from(routine.exercises),
            cardio: List<RoutineCardio>.from(routine.cardio),
          ),
        )
        .toList();

    if (missingRoutines.isEmpty) {
      return false;
    }

    ref
        .read(workoutLibraryControllerProvider.notifier)
        .addCatalogRoutines(
          routines: missingRoutines,
          activeProgramName: program.name,
        );
    return true;
  }

  void importRoutine(WorkoutRoutine routine) {
    final imported = WorkoutRoutine(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: routine.name,
      focus: routine.focus,
      groupName: '',
      exercises: List<Exercise>.from(routine.exercises),
      cardio: List<RoutineCardio>.from(routine.cardio),
    );

    ref
        .read(workoutLibraryControllerProvider.notifier)
        .addImportedRoutine(imported);
  }

  bool _isCatalogRoutineImported(
    WorkoutProgram program,
    WorkoutRoutine catalogRoutine,
  ) {
    final savedRoutines = ref.read(workoutLibraryControllerProvider).routines;
    final stableId = _catalogRoutineId(program, catalogRoutine);

    return savedRoutines.any((savedRoutine) {
      final hasStableId = savedRoutine.id == stableId;
      final hasLegacyId = savedRoutine.id.endsWith('_${catalogRoutine.id}');
      final matchesLegacyMetadata =
          savedRoutine.groupName == program.name &&
          savedRoutine.name == catalogRoutine.name;

      return hasStableId || hasLegacyId || matchesLegacyMetadata;
    });
  }

  String _catalogRoutineId(WorkoutProgram program, WorkoutRoutine routine) {
    return 'catalog_${program.id}_${routine.id}';
  }
}
