import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/workouts/data/catalogs/pre_made_workout_catalog.dart';
import 'package:pulse/models/exercise.dart';

void main() {
  group('catálogo de programas prontos', () {
    test('mantém os programas legados e adiciona três novas divisões', () {
      final programs = buildPreMadeWorkoutPrograms();
      final ids = programs.map((program) => program.id).toSet();

      expect(programs, hasLength(5));
      expect(
        ids,
        containsAll(<String>{
          'prog_hipertrofia_abc',
          'prog_seca_tudo',
          'prog_adaptacao_3_dias',
          'prog_superior_inferior_4_dias',
          'prog_ppl_5_dias',
        }),
      );
    });

    test('preserva os identificadores estáveis das fichas antigas', () {
      final programs = buildPreMadeWorkoutPrograms();
      final hypertrophy = programs.firstWhere(
        (program) => program.id == 'prog_hipertrofia_abc',
      );
      final conditioning = programs.firstWhere(
        (program) => program.id == 'prog_seca_tudo',
      );

      expect(hypertrophy.routines.map((routine) => routine.id), <String>[
        'rout_hip_A',
        'rout_hip_B',
        'rout_hip_C',
      ]);
      expect(conditioning.routines.map((routine) => routine.id), <String>[
        'rout_seca_A',
        'rout_seca_B',
      ]);
    });

    test('todos os programas têm metadados completos e coerentes', () {
      final programs = buildPreMadeWorkoutPrograms();

      for (final program in programs) {
        expect(program.level.trim(), isNotEmpty, reason: program.name);
        expect(program.objective.trim(), isNotEmpty, reason: program.name);
        expect(
          program.estimatedDuration.trim(),
          isNotEmpty,
          reason: program.name,
        );
        expect(
          program.frequencyPerWeek,
          program.routines.length,
          reason: program.name,
        );
        expect(program.routines, isNotEmpty, reason: program.name);
      }
    });

    test('identificadores de programas e fichas não se repetem', () {
      final programs = buildPreMadeWorkoutPrograms();
      final programIds = programs.map((program) => program.id).toList();
      final routineIds = programs
          .expand((program) => program.routines)
          .map((routine) => '${routine.groupName}:${routine.id}')
          .toList();

      expect(programIds.toSet(), hasLength(programIds.length));
      expect(routineIds.toSet(), hasLength(routineIds.length));
    });

    test('fichas pertencem ao programa e possuem prescrições utilizáveis', () {
      final programs = buildPreMadeWorkoutPrograms();

      for (final program in programs) {
        for (final routine in program.routines) {
          expect(routine.groupName, program.name);
          expect(routine.totalActivities, greaterThan(0));

          for (final exercise in routine.exercises) {
            expect(exercise.id.trim(), isNotEmpty);
            expect(exercise.name.trim(), isNotEmpty);
            expect(exercise.reps.trim(), isNotEmpty);
            expect(exercise.rest.trim(), isNotEmpty);
          }
        }
      }
    });

    test('metadados sobrevivem à serialização do programa', () {
      final original = buildPreMadeWorkoutPrograms().first;
      final restored = WorkoutProgram.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.level, original.level);
      expect(restored.objective, original.objective);
      expect(restored.frequencyPerWeek, original.frequencyPerWeek);
      expect(restored.estimatedDuration, original.estimatedDuration);
      expect(restored.routines, hasLength(original.routines.length));
    });

    test('programa de condicionamento inclui cardio planejado', () {
      final program = buildPreMadeWorkoutPrograms().firstWhere(
        (item) => item.id == 'prog_seca_tudo',
      );

      expect(
        program.routines.every((routine) => routine.cardio.isNotEmpty),
        isTrue,
      );
      expect(
        program.routines
            .expand((routine) => routine.cardio)
            .every((cardio) => cardio.plannedDurationMinutes > 0),
        isTrue,
      );
    });
  });
}
