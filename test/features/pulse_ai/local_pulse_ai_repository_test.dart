import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/pulse_ai/data/repositories/local_pulse_ai_repository.dart';
import 'package:pulse/features/pulse_ai/domain/models/pulse_ai_models.dart';
import 'package:pulse/models/exercise.dart';

void main() {
  const repository = LocalPulseAiRepository(responseDelay: Duration.zero);

  const chestPress = Exercise(
    id: 'chest_press',
    name: 'Supino Máquina',
    muscle: 'Peito',
    description: 'Exercício principal.',
    reps: '3x 10',
    rest: '60 seg',
  );
  const dumbbellPress = Exercise(
    id: 'dumbbell_press',
    name: 'Supino com Halteres',
    muscle: 'Peito',
    description: 'Alternativa com halteres.',
    reps: '3x 10',
    rest: '60 seg',
  );
  const cableFly = Exercise(
    id: 'cable_fly',
    name: 'Crossover',
    muscle: 'Peito',
    description: 'Alternativa na polia.',
    reps: '3x 12',
    rest: '60 seg',
  );
  const row = Exercise(
    id: 'row',
    name: 'Remada',
    muscle: 'Costas',
    description: 'Exercício de costas.',
    reps: '3x 10',
    rest: '60 seg',
  );

  WorkoutRoutine routine({List<Exercise>? exercises}) {
    return WorkoutRoutine(
      id: 'routine_1',
      name: 'Treino A',
      focus: 'Peito e costas',
      exercises: exercises ?? const <Exercise>[chestPress, row],
    );
  }

  test('sugere somente alternativas do mesmo músculo e do catálogo', () async {
    final response = await repository.analyze(
      PulseAiRequest(
        mode: PulseAiAssistantMode.suggestReplacement,
        routine: routine(),
        catalog: const <Exercise>[chestPress, dumbbellPress, cableFly, row],
        selectedExerciseId: chestPress.id,
      ),
    );

    expect(
      response.alternatives.map((alternative) => alternative.exerciseId),
      containsAll(<String>[dumbbellPress.id, cableFly.id]),
    );
    expect(
      response.alternatives.every(
        (alternative) => alternative.muscle == 'Peito',
      ),
      isTrue,
    );
    expect(
      response.alternatives.any(
        (alternative) => alternative.exerciseId == chestPress.id,
      ),
      isFalse,
    );
    expect(
      response.alternatives.any(
        (alternative) => alternative.exerciseId == row.id,
      ),
      isFalse,
    );
  });

  test(
    'não inventa alternativa quando o catálogo não possui compatível',
    () async {
      final response = await repository.analyze(
        PulseAiRequest(
          mode: PulseAiAssistantMode.suggestReplacement,
          routine: routine(exercises: const <Exercise>[row]),
          catalog: const <Exercise>[row, chestPress],
          selectedExerciseId: row.id,
        ),
      );

      expect(response.alternatives, isEmpty);
      expect(response.insights.last.title, 'Sem alternativa compatível');
    },
  );

  test('explicação é informativa e não oferece alteração aplicável', () async {
    final response = await repository.analyze(
      PulseAiRequest(
        mode: PulseAiAssistantMode.explainWorkout,
        routine: routine(),
        catalog: const <Exercise>[chestPress, row],
      ),
    );

    expect(response.generatedLocally, isTrue);
    expect(response.insights, isNotEmpty);
    expect(response.hasApplicableChange, isFalse);
  });

  test('revisão descreve a distribuição cadastrada', () async {
    final response = await repository.analyze(
      PulseAiRequest(
        mode: PulseAiAssistantMode.reviewRoutine,
        routine: routine(),
        catalog: const <Exercise>[chestPress, row],
      ),
    );

    final distribution = response.insights.first.body;
    expect(distribution, contains('Peito: 1 exercício'));
    expect(distribution, contains('Costas: 1 exercício'));
    expect(response.hasApplicableChange, isFalse);
  });
  test('analisa progresso usando somente o resumo numérico', () async {
    final response = await repository.analyze(
      const PulseAiRequest(
        mode: PulseAiAssistantMode.analyzeProgress,
        progress: PulseAiProgressSnapshot(
          periodLabel: 'Últimos 3 meses',
          workouts: 12,
          completedWorkouts: 10,
          incompleteWorkouts: 2,
          activeDays: 9,
          durationSeconds: 18000,
          totalSets: 120,
          totalReps: 950,
          totalVolume: 18250,
          weeklyFrequency: 1.8,
          currentStreak: 2,
          longestStreak: 5,
          volumeChange: 12,
        ),
      ),
    );

    expect(response.title, 'Leitura do seu progresso');
    expect(response.insights.first.body, contains('12 atividades'));
    expect(response.insights.first.body, contains('9 dias ativos'));
    expect(response.generatedLocally, isTrue);
  });

  test('explica exercício e a prescrição cadastrada', () async {
    final response = await repository.analyze(
      const PulseAiRequest(
        mode: PulseAiAssistantMode.explainExercise,
        exercise: chestPress,
      ),
    );

    expect(response.title, chestPress.name);
    expect(response.insights.first.body, contains('peito'));
    expect(response.insights[1].body, contains('3x 10'));
  });

  test('inclui atividades livres na leitura do progresso', () async {
    final response = await repository.analyze(
      const PulseAiRequest(
        mode: PulseAiAssistantMode.analyzeProgress,
        progress: PulseAiProgressSnapshot(
          periodLabel: 'Últimas 4 semanas',
          workouts: 5,
          completedWorkouts: 5,
          incompleteWorkouts: 0,
          activeDays: 5,
          durationSeconds: 12000,
          totalSets: 40,
          totalReps: 320,
          totalVolume: 6400,
          weeklyFrequency: 1.25,
          currentStreak: 1,
          longestStreak: 3,
          strengthSessions: 4,
          freeActivitySessions: 1,
          substituteActivities: 1,
          freeActivityMinutes: 60,
          freeActivityLabels: <String>['CrossFit'],
        ),
      ),
    );

    final activityInsight = response.insights.firstWhere(
      (insight) => insight.title == 'Atividades fora da ficha',
    );

    expect(activityInsight.body, contains('60 minutos'));
    expect(activityInsight.body, contains('CrossFit'));
    expect(activityInsight.body, contains('sem marcar nenhuma ficha'));
  });
}
