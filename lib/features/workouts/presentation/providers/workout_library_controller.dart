import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/exercise.dart';
import '../../domain/models/cardio_log.dart';
import '../../domain/repositories/workout_repository.dart';
import '../state/workout_library_state.dart';
import 'workout_dependencies.dart';

final workoutLibraryControllerProvider =
    NotifierProvider<WorkoutLibraryController, WorkoutLibraryState>(
      WorkoutLibraryController.new,
    );

class WorkoutLibraryController extends Notifier<WorkoutLibraryState> {
  WorkoutRepository get _repository => ref.read(workoutRepositoryProvider);

  @override
  WorkoutLibraryState build() => WorkoutLibraryState.initial();

  void hydrate({
    required List<Exercise> customExercises,
    required List<WorkoutRoutine> routines,
    required String activeProgramName,
  }) {
    state = WorkoutLibraryState(
      customExercises: customExercises,
      routines: routines,
      activeProgramName: activeProgramName,
    );
  }

  void reset() {
    state = WorkoutLibraryState.initial();
  }

  void setActiveProgram(String programName) {
    if (state.activeProgramName == programName) {
      return;
    }

    state = state.copyWith(activeProgramName: programName);
    _persist(
      () => _repository.saveActiveProgramName(programName),
      'salvar programa ativo',
    );
  }

  void createCustomExercise(String name, String muscle) {
    final exercise = Exercise(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      muscle: muscle,
      description: 'Exercicio personalizado.',
      reps: '3x 10-12',
      rest: '60 seg',
    );

    final updated = <Exercise>[...state.customExercises, exercise];
    state = state.copyWith(customExercises: updated);

    _persist(
      () => _repository.saveCustomExercises(updated),
      'salvar exercício personalizado',
    );
  }

  void createRoutine(
    String name,
    String focus,
    String groupName,
    List<Exercise> exercises, {
    List<RoutineCardio> cardio = const <RoutineCardio>[],
  }) {
    final uniqueId =
        '${DateTime.now().millisecondsSinceEpoch}_${name.hashCode}_${exercises.length}';

    final routine = WorkoutRoutine(
      id: uniqueId,
      name: name,
      focus: focus,
      groupName: groupName,
      exercises: exercises,
      cardio: cardio,
    );

    final updatedRoutines = <WorkoutRoutine>[...state.routines, routine];
    var activeProgramName = state.activeProgramName;

    if (activeProgramName.isEmpty && groupName.isNotEmpty) {
      activeProgramName = groupName;
      _persist(
        () => _repository.saveActiveProgramName(activeProgramName),
        'salvar programa ativo',
      );
    }

    state = state.copyWith(
      routines: updatedRoutines,
      activeProgramName: activeProgramName,
    );

    _persist(() => _repository.saveRoutines(updatedRoutines), 'salvar fichas');
  }

  void updateRoutine(
    String id,
    String newName,
    String newFocus,
    String newGroupName,
    List<Exercise> newExercises, {
    List<RoutineCardio>? newCardio,
  }) {
    final index = state.routines.indexWhere((routine) => routine.id == id);

    if (index < 0) {
      return;
    }

    final updatedRoutines = List<WorkoutRoutine>.from(state.routines);
    updatedRoutines[index] = updatedRoutines[index].copyWith(
      name: newName,
      focus: newFocus,
      groupName: newGroupName,
      exercises: newExercises,
      cardio: newCardio,
    );

    state = state.copyWith(routines: updatedRoutines);
    _persist(() => _repository.saveRoutines(updatedRoutines), 'salvar fichas');
  }

  void updateRoutineCardio(String id, List<RoutineCardio> cardio) {
    final index = state.routines.indexWhere((routine) => routine.id == id);

    if (index < 0) {
      return;
    }

    final updatedRoutines = List<WorkoutRoutine>.from(state.routines);
    updatedRoutines[index] = updatedRoutines[index].copyWith(cardio: cardio);

    state = state.copyWith(routines: updatedRoutines);
    _persist(
      () => _repository.saveRoutines(updatedRoutines),
      'salvar cardio da ficha',
    );
  }

  void deleteRoutine(String id) {
    final updatedRoutines = state.routines
        .where((routine) => routine.id != id)
        .toList();

    if (updatedRoutines.length == state.routines.length) {
      return;
    }

    state = state.copyWith(routines: updatedRoutines);
    _persist(() => _repository.saveRoutines(updatedRoutines), 'salvar fichas');
  }

  void deleteProgram(String groupName) {
    final normalizedGroup = groupName.trim();
    if (normalizedGroup.isEmpty) {
      return;
    }

    final updatedRoutines = state.routines
        .where((routine) => routine.groupName != normalizedGroup)
        .toList(growable: false);
    if (updatedRoutines.length == state.routines.length) {
      return;
    }

    var activeProgramName = state.activeProgramName;
    if (activeProgramName == normalizedGroup) {
      activeProgramName = updatedRoutines
          .map((routine) => routine.groupName.trim())
          .firstWhere((name) => name.isNotEmpty, orElse: () => '');
    }

    final usedExerciseIds = updatedRoutines
        .expand((routine) => routine.exercises)
        .map((exercise) => exercise.id)
        .toSet();
    final updatedCustomExercises = state.customExercises
        .where(
          (exercise) =>
              !exercise.id.startsWith('custom_import_') ||
              usedExerciseIds.contains(exercise.id),
        )
        .toList(growable: false);

    state = state.copyWith(
      customExercises: updatedCustomExercises,
      routines: updatedRoutines,
      activeProgramName: activeProgramName,
    );
    _persist(
      () => _repository.saveRoutines(updatedRoutines),
      'excluir programa',
    );
    _persist(
      () => _repository.saveCustomExercises(updatedCustomExercises),
      'limpar exercícios importados sem uso',
    );
    _persist(
      () => _repository.saveActiveProgramName(activeProgramName),
      'atualizar programa ativo',
    );
  }

  void addCatalogRoutines({
    required List<WorkoutRoutine> routines,
    required String activeProgramName,
  }) {
    if (routines.isEmpty) {
      return;
    }

    final updatedRoutines = <WorkoutRoutine>[...state.routines, ...routines];
    state = state.copyWith(
      routines: updatedRoutines,
      activeProgramName: activeProgramName,
    );

    _persist(
      () => _repository.saveRoutines(updatedRoutines),
      'salvar programa importado',
    );
    _persist(
      () => _repository.saveActiveProgramName(activeProgramName),
      'salvar programa ativo',
    );
  }

  void addImportedProgram(WorkoutProgram program) {
    if (program.routines.isEmpty) {
      return;
    }

    final importedCustomExercises = program.routines
        .expand((routine) => routine.exercises)
        .where((exercise) => exercise.id.startsWith('custom_import_'))
        .toList(growable: false);
    final customById = <String, Exercise>{
      for (final exercise in state.customExercises) exercise.id: exercise,
      for (final exercise in importedCustomExercises) exercise.id: exercise,
    };
    final updatedCustomExercises = customById.values.toList(growable: false);
    final updatedRoutines = <WorkoutRoutine>[
      ...state.routines,
      ...program.routines,
    ];

    state = state.copyWith(
      customExercises: updatedCustomExercises,
      routines: updatedRoutines,
      activeProgramName: program.name,
    );

    _persist(
      () => _repository.saveCustomExercises(updatedCustomExercises),
      'salvar exercícios importados',
    );
    _persist(
      () => _repository.saveRoutines(updatedRoutines),
      'salvar programa do personal',
    );
    _persist(
      () => _repository.saveActiveProgramName(program.name),
      'ativar programa do personal',
    );
  }

  void addImportedRoutine(WorkoutRoutine routine) {
    final updatedRoutines = <WorkoutRoutine>[...state.routines, routine];
    state = state.copyWith(routines: updatedRoutines);

    _persist(
      () => _repository.saveRoutines(updatedRoutines),
      'salvar ficha importada',
    );
  }

  void _persist(Future<void> Function() operation, String label) {
    unawaited(
      (() async {
        try {
          await operation();
        } catch (error, stackTrace) {
          debugPrint('Erro ao $label: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      })(),
    );
  }
}
