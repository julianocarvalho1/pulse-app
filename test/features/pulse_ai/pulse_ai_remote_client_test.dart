import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/pulse_ai/data/repositories/pulse_ai_installation_id_store.dart';
import 'package:pulse/features/pulse_ai/data/repositories/pulse_ai_remote_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mantém um identificador aleatório estável para a instalação', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final first = await PulseAiInstallationIdStore().getOrCreate();
    final second = await PulseAiInstallationIdStore().getOrCreate();

    expect(first, startsWith('pi_'));
    expect(first, hasLength(35));
    expect(second, first);
  });

  test('envia payload estruturado, identificador e denúncia interna', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final received = <_ReceivedRequest>[];
    Future<PulseAiHttpResponse> post(
      Uri endpoint,
      Map<String, String> headers,
      String body,
      Duration timeout,
    ) async {
      received.add(
        _ReceivedRequest(
          path: endpoint.path,
          installationId: headers['X-Pulse-Install-ID'],
          body: Map<String, dynamic>.from(jsonDecode(body) as Map),
        ),
      );
      return PulseAiHttpResponse(
        statusCode: endpoint.path == '/assist' ? 200 : 201,
        body: endpoint.path == '/assist'
            ? jsonEncode(<String, Object?>{
                'ok': true,
                'answer': 'Resposta protegida.',
                'responseId': 'response-123',
                'model': 'gemini-test',
              })
            : jsonEncode(<String, Object?>{'ok': true}),
      );
    }

    final client = CloudflarePulseAiClient(
      endpoint: Uri.parse('https://worker.test/assist'),
      timeout: const Duration(seconds: 3),
      installationIdStore: PulseAiInstallationIdStore(),
      httpPost: post,
    );
    final answer = await client.ask(
      const PulseAiRemoteRequest(
        mode: 'explainExercise',
        context: <String, Object?>{
          'exercise': <String, Object?>{'name': 'Supino reto'},
        },
      ),
    );
    await client.report(
      const PulseAiRemoteReport(
        responseId: 'response-123',
        category: 'incorrect',
        comment: 'A explicação não corresponde ao exercício.',
      ),
    );

    expect(answer.responseId, 'response-123');
    expect(received, hasLength(2));
    expect(received.first.path, '/assist');
    expect(received.first.body['version'], 2);
    expect(received.first.body['mode'], 'explainExercise');
    expect(received.first.body, isNot(contains('message')));
    expect(received.last.path, '/report');
    expect(received.last.body['responseId'], 'response-123');
    expect(received.last.installationId, received.first.installationId);
    expect(received.first.installationId, startsWith('pi_'));
  });
}

class _ReceivedRequest {
  const _ReceivedRequest({
    required this.path,
    required this.installationId,
    required this.body,
  });

  final String path;
  final String? installationId;
  final Map<String, dynamic> body;
}
