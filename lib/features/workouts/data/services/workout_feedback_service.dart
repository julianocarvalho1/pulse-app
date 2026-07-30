import 'package:flutter_tts/flutter_tts.dart';

abstract interface class WorkoutFeedbackService {
  Future<void> configure();

  Future<void> playRestFinished({required bool enabled});

  Future<void> dispose();
}

class DeviceWorkoutFeedbackService implements WorkoutFeedbackService {
  DeviceWorkoutFeedbackService({FlutterTts? flutterTts})
    : _flutterTts = flutterTts ?? FlutterTts();

  final FlutterTts _flutterTts;

  @override
  Future<void> configure() async {
    await _flutterTts.setLanguage('pt-BR');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
  }

  @override
  Future<void> playRestFinished({required bool enabled}) async {
    if (!enabled) {
      return;
    }

    try {
      await _flutterTts.speak('Descanso finalizado. Bora pra cima!');
    } catch (_) {
      // O alerta visual e o cronômetro continuam funcionando mesmo
      // quando o mecanismo de voz não estiver disponível.
    }
  }

  @override
  Future<void> dispose() async {
    await _flutterTts.stop();
  }
}
