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
        model: 'gemini-test',
      ),
    );
    final repository = RemotePulseAiRepository(client: client);

    final response = await repository.analyze(
      request(PulseAiAssistantMode.reviewRoutine),
    );

    expect(response.generatedLocally, isFalse);
    expect(response.providerModel, 'gemini-test');
    expect(response.insights.first.title, 'Análise da ficha');
    expect(response.insights.first.body, isNot(contains('**')));
    expect(response.insights.length, greaterThan(1));
  });

  test('não envia nome da ficha, foco nem observações livres', () async {
    final client = _RecordingClient(
      const PulseAiRemoteAnswer(answer: 'Resposta segura.'),
    );
    final repository = RemotePulseAiRepository(client: client);

    await repository.analyze(request(PulseAiAssistantMode.explainWorkout));

    expect(client.lastMessage, contains('Supino Máquina'));
    expect(client.lastMessage, contains('3x 10'));
    expect(client.lastMessage, isNot(contains('Nome privado da ficha')));
    expect(client.lastMessage, isNot(contains('Observação privada de foco')));
    expect(
      client.lastMessage,
      isNot(contains('Não enviar esta anotação pessoal.')),
    );
  });

  test('substituições continuam limitadas ao catálogo do PULSE', () async {
    final client = _RecordingClient(
      const PulseAiRemoteAnswer(
        answer: 'A opção permitida trabalha o mesmo grupo muscular.',
      ),
    );
    final repository = RemotePulseAiRepository(client: client);

    final response = await repository.analyze(
      request(PulseAiAssistantMode.suggestReplacement),
    );

    expect(response.alternatives, hasLength(1));
    expect(response.alternatives.single.exerciseId, alternative.id);
    expect(client.lastMessage, contains(alternative.name));
    expect(client.lastMessage, contains('Não cite nenhuma alternativa fora'));
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
  String lastMessage = '';

  @override
  Future<PulseAiRemoteAnswer> ask(String message) async {
    lastMessage = message;
    return response;
  }
}

class _ThrowingRepository implements PulseAiRepository {
  const _ThrowingRepository(this.error);

  final Object error;

  @override
  Future<PulseAiResponse> analyze(PulseAiRequest request) async {
    throw error;
  }
}
