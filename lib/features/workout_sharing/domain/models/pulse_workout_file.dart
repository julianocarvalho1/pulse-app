import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../../models/exercise.dart';
import '../../../workouts/domain/models/cardio_log.dart';

enum PulseWorkoutContentType {
  routine,
  program;

  String get storageValue => name;

  String get label => switch (this) {
    PulseWorkoutContentType.routine => 'Ficha',
    PulseWorkoutContentType.program => 'Programa',
  };

  static PulseWorkoutContentType fromStorage(Object? value) {
    return PulseWorkoutContentType.values.firstWhere(
      (item) => item.storageValue == value?.toString(),
      orElse: () => throw const PulseWorkoutFileException(
        'O arquivo não informa se contém uma ficha ou um programa.',
      ),
    );
  }
}

@immutable
class PulseWorkoutDocument {
  PulseWorkoutDocument({
    required this.contentType,
    required this.createdAt,
    required this.title,
    WorkoutRoutine? routine,
    WorkoutProgram? program,
    this.formatVersion = 2,
  }) : routine = routine,
       program = program {
    if (contentType == PulseWorkoutContentType.routine && routine == null) {
      throw const PulseWorkoutFileException(
        'A ficha compartilhada está vazia.',
      );
    }
    if (contentType == PulseWorkoutContentType.program && program == null) {
      throw const PulseWorkoutFileException(
        'O programa compartilhado está vazio.',
      );
    }
  }

  static const String format = 'pulse-workout';
  static const int currentVersion = 2;

  final int formatVersion;
  final PulseWorkoutContentType contentType;
  final DateTime createdAt;
  final String title;
  final WorkoutRoutine? routine;
  final WorkoutProgram? program;

  List<WorkoutRoutine> get routines => UnmodifiableListView<WorkoutRoutine>(
    contentType == PulseWorkoutContentType.routine
        ? <WorkoutRoutine>[routine!]
        : program!.routines,
  );

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'format': format,
      'formatVersion': formatVersion,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'contentType': contentType.storageValue,
      'title': title,
      'payload': contentType == PulseWorkoutContentType.routine
          ? routine!.toMap()
          : program!.toMap(),
    };
  }
}

@immutable
class PulseWorkoutImportPreview {
  PulseWorkoutImportPreview({
    required this.document,
    required List<WorkoutRoutine> resolvedRoutines,
    required List<Exercise> customExercises,
    required this.suggestedName,
    required this.unmatchedExerciseCount,
    required this.isExactDuplicate,
  }) : resolvedRoutines = UnmodifiableListView<WorkoutRoutine>(
         List<WorkoutRoutine>.from(resolvedRoutines),
       ),
       customExercises = UnmodifiableListView<Exercise>(
         List<Exercise>.from(customExercises),
       );

  final PulseWorkoutDocument document;
  final List<WorkoutRoutine> resolvedRoutines;
  final List<Exercise> customExercises;
  final String suggestedName;
  final int unmatchedExerciseCount;
  final bool isExactDuplicate;

  int get exerciseCount => resolvedRoutines.fold<int>(
    0,
    (total, routine) => total + routine.exercises.length,
  );

  int get cardioCount => resolvedRoutines.fold<int>(
    0,
    (total, routine) => total + routine.cardio.length,
  );

  PulseWorkoutImportBundle buildBundle(String requestedName) {
    final name = requestedName.trim().isEmpty
        ? suggestedName
        : requestedName.trim();
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final isProgram = document.contentType == PulseWorkoutContentType.program;

    final routines = <WorkoutRoutine>[];
    for (var index = 0; index < resolvedRoutines.length; index++) {
      final routine = resolvedRoutines[index];
      routines.add(
        routine.copyWith(
          id: 'shared_${stamp}_$index',
          name: isProgram
              ? routine.name
              : (resolvedRoutines.length == 1 ? name : routine.name),
          groupName: isProgram ? name : '',
          cardio: <RoutineCardio>[
            for (
              var cardioIndex = 0;
              cardioIndex < routine.cardio.length;
              cardioIndex++
            )
              routine.cardio[cardioIndex].copyWith(
                id: 'shared_cardio_${stamp}_${index}_$cardioIndex',
              ),
          ],
        ),
      );
    }

    return PulseWorkoutImportBundle(
      routines: routines,
      customExercises: customExercises,
      activeProgramName: isProgram ? name : '',
    );
  }
}

@immutable
class PulseWorkoutImportBundle {
  PulseWorkoutImportBundle({
    required List<WorkoutRoutine> routines,
    required List<Exercise> customExercises,
    required this.activeProgramName,
  }) : routines = UnmodifiableListView<WorkoutRoutine>(
         List<WorkoutRoutine>.from(routines),
       ),
       customExercises = UnmodifiableListView<Exercise>(
         List<Exercise>.from(customExercises),
       );

  final List<WorkoutRoutine> routines;
  final List<Exercise> customExercises;
  final String activeProgramName;
}

class PulseWorkoutFileException implements Exception {
  const PulseWorkoutFileException(this.message);

  final String message;

  @override
  String toString() => message;
}
