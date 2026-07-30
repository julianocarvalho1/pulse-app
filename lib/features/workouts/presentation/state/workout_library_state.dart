import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../../models/exercise.dart';

@immutable
class WorkoutLibraryState {
  WorkoutLibraryState({
    required List<Exercise> customExercises,
    required List<WorkoutRoutine> routines,
    required this.activeProgramName,
  }) : customExercises = UnmodifiableListView<Exercise>(
         List<Exercise>.from(customExercises),
       ),
       routines = UnmodifiableListView<WorkoutRoutine>(
         List<WorkoutRoutine>.from(routines),
       );

  factory WorkoutLibraryState.initial() {
    return WorkoutLibraryState(
      customExercises: const <Exercise>[],
      routines: const <WorkoutRoutine>[],
      activeProgramName: '',
    );
  }

  final List<Exercise> customExercises;
  final List<WorkoutRoutine> routines;
  final String activeProgramName;

  List<Exercise> get allExercises => List<Exercise>.unmodifiable(<Exercise>[
    ...exerciseDatabase,
    ...customExercises,
  ]);

  WorkoutLibraryState copyWith({
    List<Exercise>? customExercises,
    List<WorkoutRoutine>? routines,
    String? activeProgramName,
  }) {
    return WorkoutLibraryState(
      customExercises: customExercises ?? this.customExercises,
      routines: routines ?? this.routines,
      activeProgramName: activeProgramName ?? this.activeProgramName,
    );
  }
}
