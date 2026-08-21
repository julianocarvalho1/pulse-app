import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/pulse_backup_service.dart';

final pulseBackupServiceProvider = Provider<PulseBackupService>(
  (ref) => PulseBackupService(),
);
