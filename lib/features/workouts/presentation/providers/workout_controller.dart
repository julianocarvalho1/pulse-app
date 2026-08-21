import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/exercise.dart';
import '../../domain/models/active_workout_session.dart';
import '../../domain/models/cardio_log.dart';
import '../../domain/models/exercise_log.dart';
import '../../domain/models/free_activity_log.dart';
import '../../domain/models/workout_history_item.dart';
import '../state/workout_state.dart';
import 'workout_bootstrap_controller.dart';
import 'workout_catalog_controller.dart';
import 'workout_history_controller.dart';
import 'workout_library_controller.dart';
import 'workout_session_controller.dart';

export 'workout_bootstrap_controller.dart';
export 'workout_catalog_controller.dart';
export 'workout_dependencies.dart';
export 'workout_history_controller.dart';
export 'workout_library_controller.dart';
export 'workout_selectors.dart';
export 'workout_session_controller.dart';

final workoutControllerProvider =
    NotifierProvider<WorkoutController, WorkoutState>(WorkoutController.new);

/// Fachada temporária de compatibilidade para as telas existentes.
///
/// As responsabilidades reais estão divididas entre Library, Catalog,
/// History, Session e Bootstrap. Esta classe apenas combina os estados e
/// encaminha comandos, evitando uma migração arriscada de todas as telas no
/// mesmo release.
class WorkoutController extends Notifier<WorkoutState> {
  Future<void> get initialization =>
      ref.read(workoutBootstrapControllerProvider.future);

  bool get isResting => state.isResting;
  bool get isRestPaused => state.isRestPaused;
  int get restSeconds => state.restSeconds;
  List<Exercise> get allExercises => state.allExercises;
  List<WorkoutRoutine> get myRoutines => state.myRoutines;
  List<WorkoutProgram> get preMadePrograms => state.preMadePrograms;
  List<WorkoutHistoryItem> get history => state.history;
  bool get isInitialized => state.isInitialized;
  Object? get initializationError => state.initializationError;
  bool get isWorkoutActive => state.isWorkoutActive;
  List<Exercise> get currentWorkoutExercises => state.currentWorkoutExercises;
  String get activeRoutineName => state.activeRoutineName;
  String get activeProgramName => state.activeProgramName;
  ActiveWorkoutSession? get activeSession =>
      ref.read(workoutSessionControllerProvider.notifier).activeSession;
  WorkoutRoutine? get nextRoutineToTrain => state.nextRoutineToTrain;

  @override
  WorkoutState build() {
    final bootstrap = ref.watch(workoutBootstrapControllerProvider);
    final library = ref.watch(workoutLibraryControllerProvider);
    final history = ref.watch(workoutHistoryControllerProvider);
    final session = ref.watch(workoutSessionControllerProvider);
    final catalog = ref.watch(workoutCatalogControllerProvider);

    return WorkoutState(
      customExercises: library.customExercises,
      myRoutines: library.routines,
      history: history.items,
      preMadePrograms: catalog,
      isInitialized: switch (bootstrap) {
        AsyncLoading<void>() => false,
        _ => true,
      },
      voiceAfterRest: session.voiceAfterRest,
      isWorkoutActive: session.isWorkoutActive,
      currentWorkoutExercises: session.exercises,
      activeRoutineName: session.routineName,
      activeProgramName: library.activeProgramName,
      activeSession: session.activeSession,
      isResting: session.isResting,
      isRestPaused: session.isRestPaused,
      restSeconds: session.restSeconds,
      isFinishing: session.isFinishing,
      initializationError: switch (bootstrap) {
        AsyncError<void>(:final error) => error,
        _ => null,
      },
    );
  }

  Future<void> reload() {
    return ref.read(workoutBootstrapControllerProvider.notifier).reload();
  }

  Future<void> factoryReset() {
    return ref.read(workoutBootstrapControllerProvider.notifier).factoryReset();
  }

  void setActiveProgram(String programName) {
    ref
        .read(workoutLibraryControllerProvider.notifier)
        .setActiveProgram(programName);
  }

  Exercise createCustomExercise(
    String name,
    String muscle, {
    String description = 'Exercício personalizado.',
    String reps = '3x 10-12',
    String rest = '60 seg',
  }) {
    return ref
        .read(workoutLibraryControllerProvider.notifier)
        .createCustomExercise(
          name,
          muscle,
          description: description,
          reps: reps,
          rest: rest,
        );
  }

  void createRoutine(
    String name,
    String focus,
    String groupName,
    List<Exercise> exercises, {
    List<RoutineCardio> cardio = const <RoutineCardio>[],
  }) {
    ref
        .read(workoutLibraryControllerProvider.notifier)
        .createRoutine(name, focus, groupName, exercises, cardio: cardio);
  }

  void updateRoutine(
    String id,
    String newName,
    String newFocus,
    String newGroupName,
    List<Exercise> newExercises, {
    List<RoutineCardio>? newCardio,
  }) {
    ref
        .read(workoutLibraryControllerProvider.notifier)
        .updateRoutine(
          id,
          newName,
          newFocus,
          newGroupName,
          newExercises,
          newCardio: newCardio,
        );
  }

  void updateRoutineCardio(String id, List<RoutineCardio> cardio) {
    ref
        .read(workoutLibraryControllerProvider.notifier)
        .updateRoutineCardio(id, cardio);
  }

  void deleteRoutine(String id) {
    ref.read(workoutLibraryControllerProvider.notifier).deleteRoutine(id);
  }

  void deleteProgram(String groupName) {
    ref
        .read(workoutLibraryControllerProvider.notifier)
        .deleteProgram(groupName);
  }

  bool isProgramImported(WorkoutProgram program) {
    return ref
        .read(workoutCatalogControllerProvider.notifier)
        .isProgramImported(program);
  }

  bool importProgram(WorkoutProgram program) {
    return ref
        .read(workoutCatalogControllerProvider.notifier)
        .importProgram(program);
  }

  void importRoutine(WorkoutRoutine routine) {
    ref.read(workoutCatalogControllerProvider.notifier).importRoutine(routine);
  }

  void addSharedContent({
    required List<WorkoutRoutine> routines,
    required List<Exercise> customExercises,
    required String activeProgramName,
  }) {
    ref
        .read(workoutLibraryControllerProvider.notifier)
        .addSharedContent(
          routines: routines,
          customExercises: customExercises,
          activeProgramName: activeProgramName,
        );
  }

  Future<WorkoutHistoryItem> addCardioSession({
    required CardioLog cardio,
    String? sessionName,
  }) {
    return ref
        .read(workoutHistoryControllerProvider.notifier)
        .addCardioSession(cardio: cardio, sessionName: sessionName);
  }

  Future<WorkoutHistoryItem> addFreeActivity({
    required FreeActivityLog activity,
    required DateTime date,
  }) {
    return ref
        .read(workoutHistoryControllerProvider.notifier)
        .addFreeActivity(activity: activity, date: date);
  }

  Future<void> deleteHistoryItem(String id) {
    return ref
        .read(workoutHistoryControllerProvider.notifier)
        .deleteHistoryItem(id);
  }

  void startRestTimer(String restString) {
    ref
        .read(workoutSessionControllerProvider.notifier)
        .startRestTimer(restString);
  }

  void stopRestTimer() {
    ref.read(workoutSessionControllerProvider.notifier).stopRestTimer();
  }

  void pauseRestTimer() {
    ref.read(workoutSessionControllerProvider.notifier).pauseRestTimer();
  }

  void resumeRestTimer() {
    ref.read(workoutSessionControllerProvider.notifier).resumeRestTimer();
  }

  void setVoiceAfterRest(bool enabled) {
    ref
        .read(workoutSessionControllerProvider.notifier)
        .setVoiceAfterRest(enabled);
  }

  bool startWorkout({bool replaceActive = false}) {
    return ref
        .read(workoutSessionControllerProvider.notifier)
        .startWorkout(replaceActive: replaceActive);
  }

  bool startRoutine(WorkoutRoutine routine, {bool replaceActive = false}) {
    return ref
        .read(workoutSessionControllerProvider.notifier)
        .startRoutine(routine, replaceActive: replaceActive);
  }

  void addExerciseToWorkout(Exercise exercise) {
    ref
        .read(workoutSessionControllerProvider.notifier)
        .addExerciseToWorkout(exercise);
  }

  void replaceExerciseInActiveWorkout(int index, Exercise replacement) {
    ref
        .read(workoutSessionControllerProvider.notifier)
        .replaceExerciseInActiveWorkout(index, replacement);
  }

  void updateActiveCardio(ActiveCardioEntry entry) {
    ref
        .read(workoutSessionControllerProvider.notifier)
        .updateActiveCardio(entry);
  }

  void saveActiveSessionProgress({
    required Map<int, List<bool>> setsStatus,
    required Map<int, List<String>> weights,
    required Map<int, List<String>> reps,
    required String notes,
  }) {
    ref
        .read(workoutSessionControllerProvider.notifier)
        .saveActiveSessionProgress(
          setsStatus: setsStatus,
          weights: weights,
          reps: reps,
          notes: notes,
        );
  }

  Future<bool> finishWorkout(
    String duration, {
    required bool isIncomplete,
    required List<ExerciseLog> logs,
    List<CardioLog> cardio = const <CardioLog>[],
    String notes = '',
  }) {
    return ref
        .read(workoutSessionControllerProvider.notifier)
        .finishWorkout(
          duration,
          isIncomplete: isIncomplete,
          logs: logs,
          cardio: cardio,
          notes: notes,
        );
  }

  Future<void> cancelWorkout() {
    return ref.read(workoutSessionControllerProvider.notifier).cancelWorkout();
  }

  RestStartOutcome startRestAfterSet(int exerciseIndex, {int? setIndex}) {
    return ref
        .read(workoutSessionControllerProvider.notifier)
        .startRestAfterSet(exerciseIndex, setIndex: setIndex);
  }

  void addRestSeconds(int seconds) {
    ref.read(workoutSessionControllerProvider.notifier).addRestSeconds(seconds);
  }
}
