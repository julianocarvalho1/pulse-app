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
    } on PulseAiLimitReachedException {
      return _localResponse(
        request,
        'A cota gratuita da IA está temporariamente indisponível. O PULSE usou a análise local.',
      );
    } on PulseAiOfflineException {
      return _localResponse(
        request,
        'Não foi possível acessar a internet. O PULSE usou a análise local.',
      );
    } catch (_) {
      return _localResponse(
        request,
        'A IA conectada não respondeu. O PULSE usou a análise local sem alterar sua ficha.',
      );
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
