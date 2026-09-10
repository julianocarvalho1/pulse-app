import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/cardio_log.dart';
import '../../domain/models/exercise_log.dart';
import '../../domain/models/free_activity_log.dart';
import '../../domain/models/workout_history_item.dart';
import '../../domain/models/workout_session_status.dart';
import '../../domain/repositories/workout_repository.dart';
import '../state/workout_history_state.dart';
import 'workout_dependencies.dart';

final workoutHistoryControllerProvider =
    NotifierProvider<WorkoutHistoryController, WorkoutHistoryState>(
      WorkoutHistoryController.new,
    );

class WorkoutHistoryController extends Notifier<WorkoutHistoryState> {
  WorkoutRepository get _repository => ref.read(workoutRepositoryProvider);

  @override
  WorkoutHistoryState build() => WorkoutHistoryState.initial();

  void hydrate(List<WorkoutHistoryItem> history) {
    state = WorkoutHistoryState(items: history);
  }

  void reset() {
    state = WorkoutHistoryState.initial();
  }

  Future<WorkoutHistoryItem> addWorkout({
    required String id,
    required String routineName,
    required String duration,
    required List<ExerciseLog> exercises,
    List<CardioLog> cardio = const <CardioLog>[],
    List<FreeActivityLog> freeActivities = const <FreeActivityLog>[],
    required String notes,
    required WorkoutSessionStatus status,
    DateTime? date,
    String? nextRoutineId,
  }) async {
    final item = WorkoutHistoryItem(
      id: id,
      routineName: routineName.isEmpty ? 'Treino Avulso' : routineName,
      date: date ?? DateTime.now(),
      duration: duration,
      exercises: exercises,
      cardio: cardio,
      freeActivities: freeActivities,
      notes: notes,
      status: status,
      nextRoutineId: nextRoutineId,
    );

    final previous = state.items;
    final updated = <WorkoutHistoryItem>[
      item,
      ...previous.where((existing) => existing.id != id),
    ]..sort((a, b) => b.date.compareTo(a.date));
    state = state.copyWith(items: updated);

    try {
      await _repository.saveHistory(updated);
      return item;
    } catch (error, stackTrace) {
      state = state.copyWith(items: previous);
      debugPrint('Erro ao salvar histórico: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<WorkoutHistoryItem> addCardioSession({
    required CardioLog cardio,
    String? sessionName,
  }) {
    final now = DateTime.now();
    final duration =
        '${cardio.actualDurationMinutes.toString().padLeft(2, '0')}:00';

    return addWorkout(
      id: 'cardio_${now.microsecondsSinceEpoch}',
      routineName: sessionName?.trim().isNotEmpty == true
          ? sessionName!.trim()
          : 'Cardio • ${cardio.modality.label}',
      duration: duration,
      exercises: const <ExerciseLog>[],
      cardio: <CardioLog>[cardio],
      notes: '',
      status: WorkoutSessionStatus.completed,
    );
  }

  Future<WorkoutHistoryItem> addFreeActivity({
    required FreeActivityLog activity,
    required DateTime date,
  }) {
    final now = DateTime.now();
    final normalizedDate = DateTime(
      date.year,
      date.month,
      date.day,
      now.hour,
      now.minute,
    );
    final duration =
        '${activity.durationMinutes.toString().padLeft(2, '0')}:00';

    return addWorkout(
      id: 'activity_${now.microsecondsSinceEpoch}',
      routineName: 'Atividade • ${activity.displayName}',
      duration: duration,
      exercises: const <ExerciseLog>[],
      freeActivities: <FreeActivityLog>[activity],
      notes: '',
      status: WorkoutSessionStatus.completed,
      date: normalizedDate,
    );
  }

  Future<void> deleteHistoryItem(String id) async {
    final previous = state.items;
    final updated = previous.where((item) => item.id != id).toList();

    if (updated.length == previous.length) {
      return;
    }

    state = state.copyWith(items: updated);

    try {
      await _repository.saveHistory(updated);
    } catch (error, stackTrace) {
      state = state.copyWith(items: previous);
      debugPrint('Erro ao excluir item do histórico: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}
