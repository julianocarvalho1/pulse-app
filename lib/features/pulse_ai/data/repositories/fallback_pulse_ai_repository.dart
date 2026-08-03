import '../../domain/models/pulse_ai_models.dart';
import '../../domain/repositories/pulse_ai_repository.dart';

class FallbackPulseAiRepository implements PulseAiRepository {
  const FallbackPulseAiRepository({
    required this.primary,
    required this.fallback,
  });

  final PulseAiRepository primary;
  final PulseAiRepository fallback;

  @override
  Future<PulseAiResponse> analyze(PulseAiRequest request) async {
    try {
      return await primary.analyze(request);
    } on PulseAiOfflineException {
      return _localResponse(
        request,
        'Sem internet: resposta rápida gerada no aparelho.',
      );
    } on PulseAiLimitReachedException {
      return _localResponse(request, 'Resposta rápida gerada no aparelho.');
    } catch (_) {
      return _localResponse(request, 'Resposta rápida gerada no aparelho.');
    }
  }

  Future<PulseAiResponse> _localResponse(
    PulseAiRequest request,
    String message,
  ) async {
    final response = await fallback.analyze(request);
    return response.copyWith(
      generatedLocally: true,
      fallbackMessage: message,
      clearProviderModel: true,
    );
  }
}
