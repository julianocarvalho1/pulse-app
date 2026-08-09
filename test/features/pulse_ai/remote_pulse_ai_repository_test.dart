import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/pulse_ai/data/repositories/fallback_pulse_ai_repository.dart';
import 'package:pulse/features/pulse_ai/data/repositories/local_pulse_ai_repository.dart';
import 'package:pulse/features/pulse_ai/data/repositories/pulse_ai_remote_client.dart';
import 'package:pulse/features/pulse_ai/data/repositories/remote_pulse_ai_repository.dart';
import 'package:pulse/features/pulse_ai/domain/models/pulse_ai_models.dart';
import 'package:pulse/features/pulse_ai/domain/repositories/pulse_ai_repository.dart';
import 'package:pulse/models/exercise.dart';

void main() {
  const local = LocalPulseAiRepository(responseDelay: Duration.zero);

  const current = Exercise(
    id: 'current',
    name: 'Supino Máquina',
    muscle: 'Peito',
    description: 'Descrição pública.',
    reps: '3x 10',
    rest: '60 seg',
    customNote: 'Não enviar esta anotação pessoal.',
  );
  const alternative = Exercise(
    id: 'alternative',
    name: 'Supino com Halteres',
    muscle: 'Peito',
    description: 'Alternativa.',
    reps: '3x 10',
    rest: '60 seg',
  );

  WorkoutRoutine routine() => WorkoutRoutine(
    id: 'routine',
    name: 'Nome privado da ficha',
    focus: 'Observação privada de foco',
    exercises: const <Exercise>[current],
  );

  PulseAiRequest request(PulseAiAssistantMode mode) => PulseAiRequest(
    mode: mode,
    routine: routine(),
    catalog: const <Exercise>[current, alternative],
    selectedExerciseId: mode == PulseAiAssistantMode.suggestReplacement
        ? current.id
        : null,
  );

  test('usa a resposta online e mantém a estrutura segura local', () async {
    final client = _RecordingClient(
      const PulseAiRemoteAnswer(
        answer: '**Análise:** a estrutura está coerente.',
        responseId: 'response-test',
        model: 'gemini-test',
      ),
    );
    final repository = RemotePulseAiRepository(client: client);

    final response = await repository.analyze(
      request(PulseAiAssistantMode.reviewRoutine),
    );

    expect(response.generatedLocally, isFalse);
    expect(response.providerModel, 'gemini-test');
    expect(response.remoteResponseId, 'response-test');
    expect(response.insights.first.title, 'Análise da ficha');
    expect(response.insights.first.body, isNot(contains('**')));
    expect(response.insights.length, greaterThan(1));
  });

  test('não envia nome da ficha, foco nem observações livres', () async {
    final client = _RecordingClient(
      const PulseAiRemoteAnswer(
        answer: 'Resposta segura.',
        responseId: 'response-safe',
      ),
    );
    final repository = RemotePulseAiRepository(client: client);

    await repository.analyze(request(PulseAiAssistantMode.explainWorkout));

    final sentContext = jsonEncode(client.lastRequest?.context);
    expect(sentContext, contains('Supino Máquina'));
    expect(sentContext, contains('3x 10'));
    expect(sentContext, isNot(contains('Nome privado da ficha')));
    expect(sentContext, isNot(contains('Observação privada de foco')));
    expect(sentContext, isNot(contains('Não enviar esta anotação pessoal.')));
  });

  test('substituições continuam limitadas ao catálogo do PULSE', () async {
    final client = _RecordingClient(
      const PulseAiRemoteAnswer(
        answer: 'A opção permitida trabalha o mesmo grupo muscular.',
        responseId: 'response-replacement',
      ),
    );
    final repository = RemotePulseAiRepository(client: client);

    final response = await repository.analyze(
      request(PulseAiAssistantMode.suggestReplacement),
    );

    expect(response.alternatives, hasLength(1));
    expect(response.alternatives.single.exerciseId, alternative.id);
    expect(jsonEncode(client.lastRequest?.context), contains(alternative.name));
    expect(client.lastRequest?.mode, 'suggestReplacement');
  });

  test('mantém métricas de progresso no aparelho', () async {
    final client = _RecordingClient(
      const PulseAiRemoteAnswer(
        answer: 'Leitura do período.',
        responseId: 'response-progress',
      ),
    );
    final repository = RemotePulseAiRepository(client: client);

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

    expect(client.lastRequest, isNull);
    expect(response.generatedLocally, isTrue);
    expect(response.remoteResponseId, isNull);
    expect(response.fallbackMessage, contains('feita no aparelho'));
    expect(response.insights, isNotEmpty);
  });

  test('volta ao modo local quando a IA conectada falha', () async {
    final repository = FallbackPulseAiRepository(
      primary: const _ThrowingRepository(PulseAiOfflineException()),
      fallback: local,
    );

    final response = await repository.analyze(
      request(PulseAiAssistantMode.explainWorkout),
    );

    expect(response.generatedLocally, isTrue);
    expect(response.fallbackMessage, contains('Sem internet'));
    expect(response.insights, isNotEmpty);
  });
}

class _RecordingClient implements PulseAiRemoteClient {
  _RecordingClient(this.response);

  final PulseAiRemoteAnswer response;
  PulseAiRemoteRequest? lastRequest;

  @override
  Future<PulseAiRemoteAnswer> ask(PulseAiRemoteRequest request) async {
    lastRequest = request;
    return response;
  }

  @override
  Future<void> report(PulseAiRemoteReport report) async {}
}

class _ThrowingRepository implements PulseAiRepository {
  const _ThrowingRepository(this.error);

  final Object error;

  @override
  Future<PulseAiResponse> analyze(PulseAiRequest request) async {
    throw error;
  }
}
