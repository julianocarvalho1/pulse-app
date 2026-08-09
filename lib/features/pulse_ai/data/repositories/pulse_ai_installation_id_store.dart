import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class PulseAiInstallationIdStore {
  static const String _preferenceKey = 'pulse_ai_installation_id_v1';

  Future<String>? _pendingId;

  Future<String> getOrCreate() => _pendingId ??= _loadOrCreate();

  Future<String> _loadOrCreate() async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getString(_preferenceKey)?.trim();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    final generated = 'pi_${base64UrlEncode(bytes).replaceAll('=', '')}';
    await preferences.setString(_preferenceKey, generated);
    return generated;
  }
}
