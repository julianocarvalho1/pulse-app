import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/repositories/pulse_ai_repository.dart';

class PulseAiRemoteAnswer {
  const PulseAiRemoteAnswer({required this.answer, this.model});

  final String answer;
  final String? model;
}

abstract interface class PulseAiRemoteClient {
  Future<PulseAiRemoteAnswer> ask(String message);
}

class CloudflarePulseAiClient implements PulseAiRemoteClient {
  CloudflarePulseAiClient({
    Uri? endpoint,
    this.timeout = const Duration(seconds: 18),
  }) : endpoint =
           endpoint ??
           Uri.parse('https://pulse-ai-api.pulse-appp.workers.dev/assist');

  final Uri endpoint;
  final Duration timeout;

  @override
  Future<PulseAiRemoteAnswer> ask(String message) async {
    final client = HttpClient()..connectionTimeout = timeout;

    try {
      final request = await client.postUrl(endpoint).timeout(timeout);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.write(jsonEncode(<String, Object?>{'message': message}));

      final response = await request.close().timeout(timeout);
      final responseBody = await utf8.decoder
          .bind(response)
          .join()
          .timeout(timeout);
      final decoded = _decodeBody(responseBody);

      if (response.statusCode == HttpStatus.tooManyRequests ||
          _isQuotaError(decoded)) {
        throw const PulseAiLimitReachedException();
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorCode = decoded['error']?.toString();
        if (errorCode == 'connection_error') {
          throw const PulseAiOfflineException();
        }
        throw PulseAiRemoteException(
          decoded['message']?.toString() ??
              'O servidor do Assistente PULSE respondeu com erro.',
        );
      }

      if (decoded['ok'] != true) {
        throw PulseAiRemoteException(
          decoded['message']?.toString() ??
              'O servidor do Assistente PULSE retornou uma resposta inválida.',
        );
      }

      final answer = decoded['answer']?.toString().trim() ?? '';
      if (answer.isEmpty) {
        throw const PulseAiRemoteException(
          'A IA não retornou conteúdo para esta análise.',
        );
      }

      return PulseAiRemoteAnswer(
        answer: answer,
        model: decoded['model']?.toString(),
      );
    } on PulseAiLimitReachedException {
      rethrow;
    } on PulseAiRemoteException {
      rethrow;
    } on PulseAiOfflineException {
      rethrow;
    } on TimeoutException {
      throw const PulseAiOfflineException();
    } on SocketException {
      throw const PulseAiOfflineException();
    } on HttpException {
      throw const PulseAiOfflineException();
    } on FormatException {
      throw const PulseAiRemoteException(
        'O servidor retornou dados que o aplicativo não conseguiu interpretar.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException('Resposta JSON inválida.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  bool _isQuotaError(Map<String, dynamic> body) {
    final upstreamStatus = body['status'];
    if (upstreamStatus == HttpStatus.tooManyRequests ||
        upstreamStatus?.toString() == '${HttpStatus.tooManyRequests}') {
      return true;
    }

    final text = <Object?>[body['error'], body['message']]
        .whereType<Object>()
        .map((value) => value.toString().toLowerCase())
        .join(' ');
    return text.contains('quota') ||
        text.contains('rate limit') ||
        text.contains('resource_exhausted');
  }
}
