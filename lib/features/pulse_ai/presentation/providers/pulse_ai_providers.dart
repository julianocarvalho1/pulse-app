import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/local_pulse_ai_repository.dart';
import '../../domain/repositories/pulse_ai_repository.dart';

final pulseAiRepositoryProvider = Provider<PulseAiRepository>(
  (ref) => const LocalPulseAiRepository(),
);
