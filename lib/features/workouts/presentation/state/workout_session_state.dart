import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../../models/exercise.dart';
import '../../domain/models/active_workout_session.dart';

const Object _unsetSessionValue = Object();

@immutable
class WorkoutSessionState {
  WorkoutSessionState({
    required this.voiceAfterRest,
    required this.isWorkoutActive,
    required List<Exercise> exercises,
    required this.routineName,
    required this.activeSession,
    required this.isResting,
    this.isRestPaused = false,
    required this.restSeconds,
    required this.isFinishing,
  }) : exercises = UnmodifiableListView<Exercise>(
         List<Exercise>.from(exercises),
       );

  factory WorkoutSessionState.initial({bool voiceAfterRest = true}) {
    return WorkoutSessionState(
      voiceAfterRest: voiceAfterRest,
      isWorkoutActive: false,
      exercises: const <Exercise>[],
      routineName: 'Treino do Dia',
      activeSession: null,
      isResting: false,
      restSeconds: 0,
      isFinishing: false,
    );
  }

  final bool voiceAfterRest;
  final bool isWorkoutActive;
  final List<Exercise> exercises;
  final String routineName;
  final ActiveWorkoutSession? activeSession;
  final bool isResting;
  final bool isRestPaused;
  final int restSeconds;
  final bool isFinishing;

  WorkoutSessionState copyWith({
    bool? voiceAfterRest,
    bool? isWorkoutActive,
    List<Exercise>? exercises,
    String? routineName,
    Object? activeSession = _unsetSessionValue,
    bool? isResting,
    bool? isRestPaused,
    int? restSeconds,
    bool? isFinishing,
  }) {
    return WorkoutSessionState(
      voiceAfterRest: voiceAfterRest ?? this.voiceAfterRest,
      isWorkoutActive: isWorkoutActive ?? this.isWorkoutActive,
      exercises: exercises ?? this.exercises,
      routineName: routineName ?? this.routineName,
      activeSession: identical(activeSession, _unsetSessionValue)
          ? this.activeSession
          : activeSession as ActiveWorkoutSession?,
      isResting: isResting ?? this.isResting,
      isRestPaused: isRestPaused ?? this.isRestPaused,
      restSeconds: restSeconds ?? this.restSeconds,
      isFinishing: isFinishing ?? this.isFinishing,
    );
  }
}
