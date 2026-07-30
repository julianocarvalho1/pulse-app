import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../../models/exercise.dart';
import '../../domain/models/active_workout_session.dart';
import '../../domain/models/workout_history_item.dart';

const Object _unsetWorkoutStateValue = Object();

@immutable
class WorkoutState {
  WorkoutState({
    required List<Exercise> customExercises,
    required List<WorkoutRoutine> myRoutines,
    required List<WorkoutHistoryItem> history,
    required List<WorkoutProgram> preMadePrograms,
    required this.isInitialized,
    required this.voiceAfterRest,
    required this.isWorkoutActive,
    required List<Exercise> currentWorkoutExercises,
    required this.activeRoutineName,
    required this.activeProgramName,
    required this.activeSession,
    required this.isResting,
    required this.restSeconds,
    this.initializationError,
  }) : customExercises = UnmodifiableListView<Exercise>(
         List<Exercise>.from(customExercises),
       ),
       myRoutines = UnmodifiableListView<WorkoutRoutine>(
         List<WorkoutRoutine>.from(myRoutines),
       ),
       history = UnmodifiableListView<WorkoutHistoryItem>(
         List<WorkoutHistoryItem>.from(history),
       ),
       preMadePrograms = UnmodifiableListView<WorkoutProgram>(
         List<WorkoutProgram>.from(preMadePrograms),
       ),
       currentWorkoutExercises = UnmodifiableListView<Exercise>(
         List<Exercise>.from(currentWorkoutExercises),
       );

  factory WorkoutState.initial({
    required List<WorkoutProgram> preMadePrograms,
  }) {
    return WorkoutState(
      customExercises: const <Exercise>[],
      myRoutines: const <WorkoutRoutine>[],
      history: const <WorkoutHistoryItem>[],
      preMadePrograms: preMadePrograms,
      isInitialized: false,
      voiceAfterRest: true,
      isWorkoutActive: false,
      currentWorkoutExercises: const <Exercise>[],
      activeRoutineName: 'Treino do Dia',
      activeProgramName: '',
      activeSession: null,
      isResting: false,
      restSeconds: 0,
    );
  }

  final List<Exercise> customExercises;
  final List<WorkoutRoutine> myRoutines;
  final List<WorkoutHistoryItem> history;
  final List<WorkoutProgram> preMadePrograms;
  final bool isInitialized;
  final bool voiceAfterRest;
  final bool isWorkoutActive;
  final List<Exercise> currentWorkoutExercises;
  final String activeRoutineName;
  final String activeProgramName;
  final ActiveWorkoutSession? activeSession;
  final bool isResting;
  final int restSeconds;
  final Object? initializationError;

  List<Exercise> get allExercises => List<Exercise>.unmodifiable(<Exercise>[
    ...exerciseDatabase,
    ...customExercises,
  ]);

  WorkoutRoutine? get nextRoutineToTrain {
    if (activeProgramName.isEmpty) {
      return null;
    }

    final programRoutines =
        myRoutines
            .where((routine) => routine.groupName == activeProgramName)
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    if (programRoutines.isEmpty) {
      return null;
    }

    WorkoutHistoryItem? lastProgramWorkout;

    for (final session in history) {
      final belongsToProgram = programRoutines.any(
        (routine) => routine.name == session.routineName,
      );

      if (belongsToProgram) {
        lastProgramWorkout = session;
        break;
      }
    }

    if (lastProgramWorkout == null) {
      return programRoutines.first;
    }

    final lastIndex = programRoutines.indexWhere(
      (routine) => routine.name == lastProgramWorkout!.routineName,
    );

    if (lastIndex < 0) {
      return programRoutines.first;
    }

    return programRoutines[(lastIndex + 1) % programRoutines.length];
  }

  WorkoutState copyWith({
    List<Exercise>? customExercises,
    List<WorkoutRoutine>? myRoutines,
    List<WorkoutHistoryItem>? history,
    List<WorkoutProgram>? preMadePrograms,
    bool? isInitialized,
    bool? voiceAfterRest,
    bool? isWorkoutActive,
    List<Exercise>? currentWorkoutExercises,
    String? activeRoutineName,
    String? activeProgramName,
    Object? activeSession = _unsetWorkoutStateValue,
    bool? isResting,
    int? restSeconds,
    Object? initializationError = _unsetWorkoutStateValue,
  }) {
    return WorkoutState(
      customExercises: customExercises ?? this.customExercises,
      myRoutines: myRoutines ?? this.myRoutines,
      history: history ?? this.history,
      preMadePrograms: preMadePrograms ?? this.preMadePrograms,
      isInitialized: isInitialized ?? this.isInitialized,
      voiceAfterRest: voiceAfterRest ?? this.voiceAfterRest,
      isWorkoutActive: isWorkoutActive ?? this.isWorkoutActive,
      currentWorkoutExercises:
          currentWorkoutExercises ?? this.currentWorkoutExercises,
      activeRoutineName: activeRoutineName ?? this.activeRoutineName,
      activeProgramName: activeProgramName ?? this.activeProgramName,
      activeSession: identical(activeSession, _unsetWorkoutStateValue)
          ? this.activeSession
          : activeSession as ActiveWorkoutSession?,
      isResting: isResting ?? this.isResting,
      restSeconds: restSeconds ?? this.restSeconds,
      initializationError:
          identical(initializationError, _unsetWorkoutStateValue)
          ? this.initializationError
          : initializationError,
    );
  }
}
