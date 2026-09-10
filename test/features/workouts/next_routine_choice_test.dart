import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse/features/workouts/presentation/providers/workout_history_controller.dart';
import 'package:pulse/features/workouts/presentation/providers/workout_library_controller.dart';
import 'package:pulse/features/workouts/presentation/providers/workout_selectors.dart';
import 'package:pulse/features/workouts/domain/models/workout_history_item.dart';
import 'package:pulse/features/workouts/domain/models/workout_session_status.dart';
import 'package:pulse/features/workouts/presentation/state/workout_state.dart';
import 'package:pulse/models/exercise.dart';

void main() {
  final routines = ['a', 'b', 'c']
      .map(
        (id) => WorkoutRoutine(
          id: id,
          name: id,
          focus: '',
          groupName: 'ABC',
          exercises: const [],
        ),
      )
      .toList();
  WorkoutHistoryItem session(
    String name,
    int day, {
    String? next,
    bool incomplete = true,
  }) => WorkoutHistoryItem(
    id: '$day',
    routineName: name,
    date: DateTime(2026, 9, day),
    duration: '10:00',
    exercises: const [],
    nextRoutineId: next,
    status: incomplete
        ? WorkoutSessionStatus.incomplete
        : WorkoutSessionStatus.completed,
  );
  String? select(List<WorkoutHistoryItem> history) =>
      WorkoutState.initial(preMadePrograms: const [])
          .copyWith(
            activeProgramName: 'ABC',
            myRoutines: routines,
            history: history,
          )
          .nextRoutineToTrain
          ?.id;

  test('incomplete workout can advance or stay, without becoming complete', () {
    final advance = session('a', 1, next: 'b');
    expect(select([advance]), 'b');
    expect(advance.isIncomplete, isTrue);
    expect(select([session('b', 2, next: 'b'), advance]), 'b');
  });
  test('new complete session supersedes choice and wraps saved order', () {
    expect(
      select([session('a', 1, next: 'b'), session('b', 2, incomplete: false)]),
      'c',
    );
    expect(select([session('c', 3, incomplete: false)]), 'a');
  });
  test(
    'legacy incomplete and deleted targets preserve complete-only fallback',
    () {
      expect(select([session('a', 1)]), 'a');
      expect(
        select([
          session('b', 2, next: 'deleted'),
          session('a', 1, incomplete: false),
        ]),
        'b',
      );
    },
  );
  test('extra workout does not override explicit choice', () {
    expect(
      select([
        session('extra', 2, incomplete: false),
        session('a', 1, next: 'b'),
      ]),
      'b',
    );
  });
  test(
    'reactive selector honors restored choice and subsequent completion',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(workoutLibraryControllerProvider.notifier)
          .hydrate(
            customExercises: const [],
            routines: routines,
            activeProgramName: 'ABC',
          );
      container.read(workoutHistoryControllerProvider.notifier).hydrate([
        session('a', 1, next: 'b'),
      ]);
      expect(container.read(nextRoutineToTrainProvider)?.id, 'b');
      container.read(workoutHistoryControllerProvider.notifier).hydrate([
        session('b', 2, incomplete: false),
        session('a', 1, next: 'b'),
      ]);
      expect(container.read(nextRoutineToTrainProvider)?.id, 'c');
    },
  );
}
