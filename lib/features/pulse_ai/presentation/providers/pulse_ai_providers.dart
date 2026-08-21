import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/fallback_pulse_ai_repository.dart';
import '../../data/repositories/local_pulse_ai_repository.dart';
import '../../data/repositories/pulse_ai_installation_id_store.dart';
import '../../data/repositories/pulse_ai_remote_client.dart';
import '../../data/repositories/remote_pulse_ai_repository.dart';
import '../../domain/repositories/pulse_ai_repository.dart';

final pulseAiInstallationIdStoreProvider = Provider<PulseAiInstallationIdStore>(
  (ref) => PulseAiInstallationIdStore(),
);

final pulseAiRemoteClientProvider = Provider<PulseAiRemoteClient>(
  (ref) => CloudflarePulseAiClient(
    installationIdStore: ref.watch(pulseAiInstallationIdStoreProvider),
  ),
);

final pulseAiLocalRepositoryProvider = Provider<LocalPulseAiRepository>(
  (ref) => const LocalPulseAiRepository(),
);

final pulseAiRepositoryProvider = Provider<PulseAiRepository>((ref) {
  final localRepository = ref.watch(pulseAiLocalRepositoryProvider);
  return FallbackPulseAiRepository(
    primary: RemotePulseAiRepository(
      client: ref.watch(pulseAiRemoteClientProvider),
    ),
    fallback: localRepository,
  );
});
