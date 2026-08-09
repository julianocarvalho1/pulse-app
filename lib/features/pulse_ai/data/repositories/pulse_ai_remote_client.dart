import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/repositories/pulse_ai_repository.dart';
import 'pulse_ai_installation_id_store.dart';

typedef PulseAiHttpPost =
    Future<PulseAiHttpResponse> Function(
      Uri endpoint,
      Map<String, String> headers,
      String body,
      Duration timeout,
    );

class PulseAiHttpResponse {
  const PulseAiHttpResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

class PulseAiRemoteRequest {
  const PulseAiRemoteRequest({required this.mode, required this.context});

  final String mode;
  final Map<String, Object?> context;
}

class PulseAiRemoteReport {
  const PulseAiRemoteReport({
    required this.responseId,
    required this.category,
    this.comment = '',
  });

  final String responseId;
  final String category;
  final String comment;
}

class PulseAiRemoteAnswer {
  const PulseAiRemoteAnswer({
    required this.answer,
    required this.responseId,
    this.model,
  });

  final String answer;
  final String responseId;
  final String? model;
}

abstract interface class PulseAiRemoteClient {
  Future<PulseAiRemoteAnswer> ask(PulseAiRemoteRequest request);

  Future<void> report(PulseAiRemoteReport report);
}

class CloudflarePulseAiClient implements PulseAiRemoteClient {
  CloudflarePulseAiClient({
    Uri? endpoint,
    this.timeout = const Duration(seconds: 18),
    PulseAiInstallationIdStore? installationIdStore,
    PulseAiHttpPost? httpPost,
  }) : endpoint =
           endpoint ??
           Uri.parse('https://pulse-ai-api.pulse-appp.workers.dev/assist'),
       _installationIdStore =
           installationIdStore ?? PulseAiInstallationIdStore(),
       _httpPost = httpPost ?? _defaultHttpPost;

  final Uri endpoint;
  final Duration timeout;
  final PulseAiInstallationIdStore _installationIdStore;
  final PulseAiHttpPost _httpPost;

  @override
  Future<PulseAiRemoteAnswer> ask(PulseAiRemoteRequest remoteRequest) async {
    try {
      final installationId = await _installationIdStore.getOrCreate();
      final response = await _httpPost(
        endpoint,
        <String, String>{
          HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
          HttpHeaders.acceptHeader: 'application/json',
          'X-Pulse-Install-ID': installationId,
        },
        jsonEncode(<String, Object?>{
          'version': 2,
          'mode': remoteRequest.mode,
          'context': remoteRequest.context,
        }),
        timeout,
      );
      final decoded = _decodeBody(response.body);

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
      final responseId = decoded['responseId']?.toString().trim() ?? '';
      if (answer.isEmpty || responseId.isEmpty) {
        throw const PulseAiRemoteException(
          'A IA não retornou conteúdo para esta análise.',
        );
      }

      return PulseAiRemoteAnswer(
        answer: answer,
        responseId: responseId,
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
    }
  }

  @override
  Future<void> report(PulseAiRemoteReport report) async {
    try {
      final installationId = await _installationIdStore.getOrCreate();
      final reportEndpoint = endpoint.replace(
        path: endpoint.path.replaceFirst(RegExp(r'/assist$'), '/report'),
        query: null,
        fragment: null,
      );
      final response = await _httpPost(
        reportEndpoint,
        <String, String>{
          HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
          HttpHeaders.acceptHeader: 'application/json',
          'X-Pulse-Install-ID': installationId,
        },
        jsonEncode(<String, Object?>{
          'responseId': report.responseId,
          'category': report.category,
          'comment': report.comment.trim(),
        }),
        timeout,
      );
      final decoded = _decodeBody(response.body);

      if (response.statusCode == HttpStatus.conflict &&
          decoded['error'] == 'already_reported') {
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw PulseAiRemoteException(
          decoded['message']?.toString() ??
              'Não foi possível enviar a denúncia agora.',
        );
      }

      if (decoded['ok'] != true) {
        throw const PulseAiRemoteException(
          'O servidor não confirmou o recebimento da denúncia.',
        );
      }
    } on PulseAiRemoteException {
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

Future<PulseAiHttpResponse> _defaultHttpPost(
  Uri endpoint,
  Map<String, String> headers,
  String body,
  Duration timeout,
) async {
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final request = await client.postUrl(endpoint).timeout(timeout);
    headers.forEach(request.headers.set);
    request.write(body);
    final response = await request.close().timeout(timeout);
    final responseBody = await utf8.decoder
        .bind(response)
        .join()
        .timeout(timeout);
    return PulseAiHttpResponse(
      statusCode: response.statusCode,
      body: responseBody,
    );
  } finally {
    client.close(force: true);
  }
}
