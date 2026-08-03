import '../models/pulse_ai_models.dart';

abstract interface class PulseAiRepository {
  Future<PulseAiResponse> analyze(PulseAiRequest request);
}

class PulseAiOfflineException implements Exception {
  const PulseAiOfflineException();

  @override
  String toString() => 'O assistente está indisponível sem conexão.';
}

class PulseAiLimitReachedException implements Exception {
  const PulseAiLimitReachedException();

  @override
  String toString() => 'O limite temporário do assistente foi atingido.';
}
