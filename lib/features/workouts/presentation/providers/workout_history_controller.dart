import 'dart:async';

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

  void addWorkout({
    required String routineName,
    required String duration,
    required List<ExerciseLog> exercises,
    required String notes,
    required WorkoutSessionStatus status,
  }) {
    final item = WorkoutHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      routineName: routineName.isEmpty ? 'Treino Avulso' : routineName,
      date: DateTime.now(),
      duration: duration,
      exercises: exercises,
      notes: notes,
      status: status,
    );

    final updated = <WorkoutHistoryItem>[item, ...state.items];
    state = state.copyWith(items: updated);
    _persist(() => _repository.saveHistory(updated), 'salvar histórico');
  }

  void deleteHistoryItem(String id) {
    final updated = state.items.where((item) => item.id != id).toList();

    if (updated.length == state.items.length) {
      return;
    }

    state = state.copyWith(items: updated);
    _persist(
      () => _repository.saveHistory(updated),
      'excluir item do histórico',
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
