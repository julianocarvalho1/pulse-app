import '../../../../models/exercise.dart';
import '../models/workout_generation_request.dart';
import '../models/workout_generation_result.dart';

class WorkoutValidationService {
  const WorkoutValidationService();

  WorkoutValidationResult validate({
    required WorkoutGenerationRequest request,
    required WorkoutProgram program,
    required Set<String> allowedExerciseIds,
  }) {
    final issues = <WorkoutValidationIssue>[];

    if (program.routines.length != request.daysPerWeek) {
      issues.add(
        const WorkoutValidationIssue(
          code: 'routine_count',
          message: 'O número de fichas não corresponde aos dias selecionados.',
          severity: WorkoutValidationSeverity.error,
        ),
      );
    }

    if (program.routines.isEmpty) {
      issues.add(
        const WorkoutValidationIssue(
          code: 'empty_program',
          message: 'O programa não possui fichas.',
          severity: WorkoutValidationSeverity.error,
        ),
      );
    }

    for (final routine in program.routines) {
      if (routine.totalActivities == 0) {
        issues.add(
          WorkoutValidationIssue(
            code: 'empty_routine_${routine.id}',
            message: '${routine.name} não possui atividades.',
            severity: WorkoutValidationSeverity.error,
          ),
        );
      }

      if (request.includesStrength && routine.exercises.length < 3) {
        issues.add(
          WorkoutValidationIssue(
            code: 'underfilled_${routine.id}',
            message:
                '${routine.name} ficou com poucos exercícios para formar uma ficha segura.',
            severity: WorkoutValidationSeverity.error,
          ),
        );
      }

      final seenIds = <String>{};
      for (final exercise in routine.exercises) {
        if (!seenIds.add(exercise.id)) {
          issues.add(
            WorkoutValidationIssue(
              code: 'duplicate_${routine.id}_${exercise.id}',
              message: '${routine.name} contém um exercício repetido.',
              severity: WorkoutValidationSeverity.error,
            ),
          );
        }

        if (!allowedExerciseIds.contains(exercise.id)) {
          issues.add(
            WorkoutValidationIssue(
              code: 'equipment_${routine.id}_${exercise.id}',
              message:
                  '${exercise.name} não corresponde ao ambiente selecionado.',
              severity: WorkoutValidationSeverity.error,
            ),
          );
        }

        if (request.avoidedExerciseIds.contains(exercise.id)) {
          issues.add(
            WorkoutValidationIssue(
              code: 'avoided_${routine.id}_${exercise.id}',
              message: '${exercise.name} foi marcado como movimento evitado.',
              severity: WorkoutValidationSeverity.error,
            ),
          );
        }
      }

      final estimatedMinutes = _estimatedDurationMinutes(routine);
      if (estimatedMinutes > request.sessionDurationMinutes + 10) {
        issues.add(
          WorkoutValidationIssue(
            code: 'duration_${routine.id}',
            message:
                '${routine.name} pode ultrapassar o tempo disponível em '
                'aproximadamente ${estimatedMinutes - request.sessionDurationMinutes} minutos.',
            severity: WorkoutValidationSeverity.warning,
          ),
        );
      }
    }

    if (request.includesStrength) {
      final coveredMuscles = program.routines
          .expand((routine) => routine.exercises)
          .map((exercise) => exercise.muscle)
          .toSet();
      for (final essential in const <String>['Peito', 'Costas', 'Pernas']) {
        if (!coveredMuscles.contains(essential)) {
          issues.add(
            WorkoutValidationIssue(
              code: 'missing_muscle_$essential',
              message: 'O programa não cobre o grupo $essential.',
              severity: WorkoutValidationSeverity.error,
            ),
          );
        }
      }
    }

    if (request.includesStrength &&
        program.routines.every((routine) => routine.exercises.isEmpty)) {
      issues.add(
        const WorkoutValidationIssue(
          code: 'missing_strength',
          message:
              'O plano deveria conter musculação, mas não contém exercícios.',
          severity: WorkoutValidationSeverity.error,
        ),
      );
    }

    if (request.includesCardio &&
        program.routines.every((routine) => routine.cardio.isEmpty)) {
      issues.add(
        const WorkoutValidationIssue(
          code: 'missing_cardio',
          message:
              'O plano deveria conter cardio, mas não contém etapas de cardio.',
          severity: WorkoutValidationSeverity.error,
        ),
      );
    }

    return WorkoutValidationResult(issues: issues);
  }

  int _estimatedDurationMinutes(WorkoutRoutine routine) {
    var total = 0;

    for (final exercise in routine.exercises) {
      final setMatch = RegExp(r'^\s*(\d+)').firstMatch(exercise.reps);
      final sets = int.tryParse(setMatch?.group(1) ?? '') ?? 3;
      final restMatch = RegExp(r'(\d+)').firstMatch(exercise.rest);
      final restSeconds = int.tryParse(restMatch?.group(1) ?? '') ?? 60;
      total += ((sets * (40 + restSeconds)) / 60).ceil();
    }

    for (final cardio in routine.cardio) {
      total += cardio.plannedDurationMinutes;
    }

    return total;
  }
}
