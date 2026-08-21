import '../models/workout_generation_request.dart';

class SafetyScreeningResult {
  const SafetyScreeningResult({
    required this.canGenerate,
    required this.message,
  });

  final bool canGenerate;
  final String message;
}

class SafetyScreeningService {
  const SafetyScreeningService();

  SafetyScreeningResult evaluate(WorkoutGenerationRequest request) {
    if (request.hasUnassessedPainOrRestriction) {
      return const SafetyScreeningResult(
        canGenerate: false,
        message:
            'O gerador não cria um treino para contornar dor aguda ou uma '
            'restrição ainda não avaliada. Procure orientação profissional '
            'antes de gerar o plano.',
      );
    }

    return const SafetyScreeningResult(
      canGenerate: true,
      message:
          'Triagem concluída. O plano ainda pode ser revisado e editado antes '
          'de ser salvo.',
    );
  }
}
