import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/workout_generator/domain/models/workout_generation_request.dart';
import 'package:pulse/features/workout_generator/domain/models/workout_generation_result.dart';
import 'package:pulse/features/workout_generator/domain/services/workout_generation_service.dart';
import 'package:pulse/features/workouts/domain/models/cardio_log.dart';

void main() {
  const service = WorkoutGenerationService();

  test('gera programa determinístico e validado com três fichas', () {
    final request = WorkoutGenerationRequest(
      goal: WorkoutGoal.hypertrophy,
      level: TrainingLevel.intermediate,
      planType: GeneratedPlanType.strength,
      daysPerWeek: 3,
      sessionDurationMinutes: 60,
      environment: TrainingEnvironment.fullGym,
    );

    final first = service.generate(request);
    final second = service.generate(request);

    expect(first.validation.isValid, isTrue);
    expect(first.program.routines, hasLength(3));
    expect(
      first.program.routines
          .expand((routine) => routine.exercises)
          .map((exercise) => exercise.id),
      second.program.routines
          .expand((routine) => routine.exercises)
          .map((exercise) => exercise.id),
    );
  });

  test('não inclui exercício marcado como evitado', () {
    final request = WorkoutGenerationRequest(
      goal: WorkoutGoal.strength,
      level: TrainingLevel.intermediate,
      planType: GeneratedPlanType.strength,
      daysPerWeek: 2,
      sessionDurationMinutes: 45,
      environment: TrainingEnvironment.freeWeights,
      avoidedExerciseIds: const <String>{'p1', 'c3', 'pe1'},
    );

    final plan = service.generate(request);
    final generatedIds = plan.program.routines
        .expand((routine) => routine.exercises)
        .map((exercise) => exercise.id)
        .toSet();

    expect(generatedIds.intersection(request.avoidedExerciseIds), isEmpty);
  });

  test('bloqueia geração quando a triagem indica restrição não avaliada', () {
    final request = WorkoutGenerationRequest(
      goal: WorkoutGoal.hypertrophy,
      level: TrainingLevel.beginner,
      planType: GeneratedPlanType.strength,
      daysPerWeek: 3,
      sessionDurationMinutes: 45,
      environment: TrainingEnvironment.fullGym,
      hasUnassessedPainOrRestriction: true,
    );

    expect(
      () => service.generate(request),
      throwsA(isA<WorkoutGenerationException>()),
    );
  });

  test('gera programa somente de cardio sem exercícios artificiais', () {
    final request = WorkoutGenerationRequest(
      goal: WorkoutGoal.conditioning,
      level: TrainingLevel.beginner,
      planType: GeneratedPlanType.cardio,
      daysPerWeek: 4,
      sessionDurationMinutes: 30,
      environment: TrainingEnvironment.fullGym,
      cardioModality: CardioModality.stationaryBike,
    );

    final plan = service.generate(request);

    expect(plan.validation.isValid, isTrue);
    expect(plan.program.routines, hasLength(4));
    expect(
      plan.program.routines.every((routine) => routine.exercises.isEmpty),
      isTrue,
    );
    expect(
      plan.program.routines.every(
        (routine) =>
            routine.cardio.single.modality == CardioModality.stationaryBike,
      ),
      isTrue,
    );
    expect(
      plan.program.routines.every(
        (routine) =>
            routine.cardio.single.plan.purpose == CardioPurpose.standalone,
      ),
      isTrue,
    );
    expect(
      plan.program.routines.every(
        (routine) =>
            routine.cardio.single.plan.intensity == CardioIntensity.light,
      ),
      isTrue,
    );
  });
}
