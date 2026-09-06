import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/exercises/domain/exercise_catalog.dart';
import 'package:pulse/features/workouts/data/catalogs/core_extra_session_catalog.dart';
import 'package:pulse/features/workouts/domain/models/workout_history_item.dart';
import 'package:pulse/features/workouts/domain/models/workout_set.dart';
import 'package:pulse/features/workouts/presentation/state/workout_state.dart';
import 'package:pulse/models/exercise.dart';

void main() {
  group('CoreExtraSessionCatalog', () {
    test('oferece três sessões extras com identidades únicas', () {
      final routines = CoreExtraSessionCatalog.routines;

      expect(routines, hasLength(3));
      expect(routines.map((item) => item.id).toSet(), hasLength(3));
      expect(
        routines.map((item) => item.name),
        containsAll(<String>[
          'Core expresso',
          'Core completo',
          'Core em circuito',
        ]),
      );
      expect(routines.every((item) => item.groupName.isEmpty), isTrue);
      expect(routines.every((item) => item.exercises.isNotEmpty), isTrue);

      final circuit = routines.firstWhere(
        (item) => item.id == 'extra_core_circuit',
      );
      expect(
        circuit.exercises.every(
          (exercise) => WorkoutSetTarget.fromText(exercise.reps).isTimed,
        ),
        isTrue,
      );
    });

    test('usa somente exercícios e mídias aprovados no catálogo', () {
      final exercises = CoreExtraSessionCatalog.routines
          .expand((routine) => routine.exercises)
          .toList(growable: false);

      expect(
        exercises.every(
          (exercise) => ExerciseCatalog.definitionFor(exercise) != null,
        ),
        isTrue,
      );
      expect(
        exercises.every(
          (exercise) => ExerciseCatalog.repDbMediaFor(exercise) != null,
        ),
        isTrue,
      );
      expect(
        exercises.every(
          (exercise) =>
              File(ExerciseCatalog.mediaPathFor(exercise)).existsSync(),
        ),
        isTrue,
      );
    });

    test('um extra no histórico não altera a próxima ficha do ABC', () {
      final routineA = WorkoutRoutine(
        id: 'a',
        name: 'Superior',
        focus: 'Peito',
        groupName: 'ABC',
        exercises: const <Exercise>[],
      );
      final routineB = WorkoutRoutine(
        id: 'b',
        name: 'Inferior',
        focus: 'Costas',
        groupName: 'ABC',
        exercises: const <Exercise>[],
      );
      final extra = CoreExtraSessionCatalog.routines.first;
      final state =
          WorkoutState.initial(
            preMadePrograms: const <WorkoutProgram>[],
          ).copyWith(
            activeProgramName: 'ABC',
            myRoutines: <WorkoutRoutine>[routineA, routineB],
            history: <WorkoutHistoryItem>[
              WorkoutHistoryItem(
                id: 'extra-history',
                routineName: extra.name,
                date: DateTime(2026, 9, 2),
                duration: '10:00',
                exercises: const [],
              ),
              WorkoutHistoryItem(
                id: 'a-history',
                routineName: routineA.name,
                date: DateTime(2026, 9, 1),
                duration: '45:00',
                exercises: const [],
              ),
            ],
          );

      expect(state.nextRoutineToTrain?.id, routineB.id);
    });
  });
}
