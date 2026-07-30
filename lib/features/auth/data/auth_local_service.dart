import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthLocalSnapshot {
  const AuthLocalSnapshot({
    required this.isLockEnabled,
    required this.canAuthenticate,
    required this.userName,
  });

  final bool isLockEnabled;
  final bool canAuthenticate;
  final String userName;
}

class AuthLocalService {
  AuthLocalService({LocalAuthentication? localAuthentication})
    : _localAuthentication = localAuthentication ?? LocalAuthentication();

  static const String _appLockEnabledKey = 'app_lock_enabled';

  // Chaves antigas. São lidas durante a transição para não perder
  // a configuração existente do usuário.
  static const String _legacyPasswordKey = 'user_password';
  static const String _legacyBiometricsKey = 'usarBiometria';
  static const String _userNameKey = 'user_name';

  final LocalAuthentication _localAuthentication;

  Future<AuthLocalSnapshot> loadSnapshot() async {
    final preferences = await SharedPreferences.getInstance();

    final savedLockSetting = preferences.getBool(_appLockEnabledKey);

    final legacyPassword = preferences.getString(_legacyPasswordKey) ?? '';

    final legacyBiometrics = preferences.getBool(_legacyBiometricsKey) ?? false;

    final lockEnabled =
        savedLockSetting ?? (legacyBiometrics || legacyPassword.isNotEmpty);

    if (savedLockSetting == null) {
      await preferences.setBool(_appLockEnabledKey, lockEnabled);
    }

    final userName = (preferences.getString(_userNameKey) ?? '').trim();

    final canAuthenticate = await _canUseDeviceAuthentication();

    return AuthLocalSnapshot(
      isLockEnabled: lockEnabled,
      canAuthenticate: canAuthenticate,
      userName: userName.isEmpty ? 'Atleta' : userName,
    );
  }

  Future<bool> authenticate() {
    return _localAuthentication.authenticate(
      localizedReason:
          'Desbloqueie o PULSE para acessar seus treinos e sua evolução.',
      persistAcrossBackgrounding: true,
    );
  }

  Future<void> setLockEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_appLockEnabledKey, enabled);
  }

  Future<bool> refreshAuthenticationCapability() {
    return _canUseDeviceAuthentication();
  }

  Future<void> stopAuthentication() async {
    await _localAuthentication.stopAuthentication();
  }

  Future<bool> _canUseDeviceAuthentication() async {
    final canCheckBiometrics = await _localAuthentication.canCheckBiometrics;

    final isDeviceSupported = await _localAuthentication.isDeviceSupported();

    return canCheckBiometrics || isDeviceSupported;
  }
}
