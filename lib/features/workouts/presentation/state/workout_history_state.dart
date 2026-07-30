import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../domain/models/workout_history_item.dart';

@immutable
class WorkoutHistoryState {
  WorkoutHistoryState({required List<WorkoutHistoryItem> items})
    : items = UnmodifiableListView<WorkoutHistoryItem>(
        List<WorkoutHistoryItem>.from(items),
      );

  factory WorkoutHistoryState.initial() {
    return WorkoutHistoryState(items: const <WorkoutHistoryItem>[]);
  }

  final List<WorkoutHistoryItem> items;

  WorkoutHistoryState copyWith({List<WorkoutHistoryItem>? items}) {
    return WorkoutHistoryState(items: items ?? this.items);
  }
}
