import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/exercise_log.dart';
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
    required String notes,
    required WorkoutSessionStatus status,
  }) async {
    final item = WorkoutHistoryItem(
      id: id,
      routineName: routineName.isEmpty ? 'Treino Avulso' : routineName,
      date: DateTime.now(),
      duration: duration,
      exercises: exercises,
      notes: notes,
      status: status,
    );

    final previous = state.items;
    final updated = <WorkoutHistoryItem>[
      item,
      ...previous.where((existing) => existing.id != id),
    ];
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
