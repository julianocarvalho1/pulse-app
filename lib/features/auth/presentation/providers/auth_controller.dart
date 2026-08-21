import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../data/auth_local_service.dart';
import '../../domain/app_auth_state.dart';

final authLocalServiceProvider = Provider<AuthLocalService>(
  (ref) => AuthLocalService(),
);

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AppAuthState>(AuthController.new);

class AuthController extends AsyncNotifier<AppAuthState> {
  AuthLocalService get _service => ref.read(authLocalServiceProvider);

  @override
  Future<AppAuthState> build() {
    return _loadInitialState();
  }

  Future<AppAuthState> _loadInitialState() async {
    final snapshot = await _service.loadSnapshot();

    if (!snapshot.isLockEnabled) {
      return AppAuthState(
        status: AppAuthStatus.unlocked,
        isLockEnabled: false,
        canAuthenticate: snapshot.canAuthenticate,
        userName: snapshot.userName,
      );
    }

    if (!snapshot.canAuthenticate) {
      return AppAuthState(
        status: AppAuthStatus.unavailable,
        isLockEnabled: true,
        canAuthenticate: false,
        userName: snapshot.userName,
        message:
            'Este aparelho não possui uma forma de desbloqueio configurada.',
      );
    }

    return AppAuthState(
      status: AppAuthStatus.locked,
      isLockEnabled: true,
      canAuthenticate: true,
      userName: snapshot.userName,
    );
  }

  Future<void> unlock() async {
    final current = _currentValue;

    if (current == null || current.isAuthenticating) {
      return;
    }

    if (!current.isLockEnabled) {
      state = AsyncData(
        current.copyWith(status: AppAuthStatus.unlocked, clearMessage: true),
      );
      return;
    }

    if (!current.canAuthenticate) {
      state = AsyncData(
        current.copyWith(
          status: AppAuthStatus.unavailable,
          message:
              'Configure impressão digital, reconhecimento facial, PIN, padrão ou senha no aparelho.',
        ),
      );
      return;
    }

    state = AsyncData(
      current.copyWith(
        status: AppAuthStatus.authenticating,
        clearMessage: true,
      ),
    );

    try {
      final authenticated = await _service.authenticate();

      if (!authenticated) {
        state = AsyncData(
          current.copyWith(
            status: AppAuthStatus.locked,
            message: 'Autenticação cancelada.',
          ),
        );
        return;
      }

      state = AsyncData(
        current.copyWith(status: AppAuthStatus.unlocked, clearMessage: true),
      );
    } on LocalAuthException catch (error) {
      state = AsyncData(_stateFromLocalAuthError(current, error));
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          status: AppAuthStatus.error,
          message: 'Não foi possível desbloquear o PULSE. Tente novamente.',
        ),
      );
    }
  }

  Future<bool> setLockEnabled(bool enabled) async {
    final current = _currentValue;
    if (current == null) {
      return false;
    }

    if (!enabled) {
      await _service.setLockEnabled(false);
      state = AsyncData(
        current.copyWith(
          status: AppAuthStatus.unlocked,
          isLockEnabled: false,
          clearMessage: true,
        ),
      );
      return true;
    }

    final canAuthenticate = await _service.refreshAuthenticationCapability();

    if (!canAuthenticate) {
      state = AsyncData(
        current.copyWith(
          status: AppAuthStatus.unlocked,
          isLockEnabled: false,
          canAuthenticate: false,
          message:
              'Configure uma forma de desbloqueio no aparelho antes de ativar esta proteção.',
        ),
      );
      return false;
    }

    await _service.setLockEnabled(true);

    // O app permanece aberto. A proteção será exigida na próxima
    // abertura ou quando o aplicativo voltar do segundo plano.
    state = AsyncData(
      current.copyWith(
        status: AppAuthStatus.unlocked,
        isLockEnabled: true,
        canAuthenticate: true,
        clearMessage: true,
      ),
    );
    return true;
  }

  Future<void> disableLockAndUnlock() async {
    await setLockEnabled(false);
  }

  Future<void> updateUserName(String name) async {
    final normalizedName = name.trim().isEmpty ? 'Atleta' : name.trim();
    await _service.setUserName(normalizedName);

    final current = _currentValue;
    if (current == null) {
      return;
    }

    state = AsyncData(
      current.copyWith(userName: normalizedName, clearMessage: true),
    );
  }

  Future<void> resetAfterFactoryReset() async {
    await _service.setLockEnabled(false);
    await _service.setUserName('Atleta');

    state = const AsyncData(
      AppAuthState(
        status: AppAuthStatus.unlocked,
        isLockEnabled: false,
        canAuthenticate: true,
        userName: 'Atleta',
      ),
    );
  }

  void lock() {
    final current = _currentValue;

    if (current == null || !current.isLockEnabled || current.isAuthenticating) {
      return;
    }

    state = AsyncData(
      current.copyWith(status: AppAuthStatus.locked, clearMessage: true),
    );
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadInitialState);
  }

  AppAuthState? get _currentValue {
    return switch (state) {
      AsyncData<AppAuthState>(:final value) => value,
      _ => null,
    };
  }

  AppAuthState _stateFromLocalAuthError(
    AppAuthState current,
    LocalAuthException error,
  ) {
    switch (error.code) {
      case LocalAuthExceptionCode.userCanceled:
      case LocalAuthExceptionCode.systemCanceled:
      case LocalAuthExceptionCode.timeout:
        return current.copyWith(
          status: AppAuthStatus.locked,
          message: 'Autenticação cancelada.',
        );

      case LocalAuthExceptionCode.temporaryLockout:
        return current.copyWith(
          status: AppAuthStatus.locked,
          message: 'Muitas tentativas. Aguarde um momento e tente novamente.',
        );

      case LocalAuthExceptionCode.biometricLockout:
        return current.copyWith(
          status: AppAuthStatus.locked,
          message:
              'A biometria foi bloqueada. Use o PIN, padrão ou senha do aparelho.',
        );

      case LocalAuthExceptionCode.noCredentialsSet:
      case LocalAuthExceptionCode.noBiometricsEnrolled:
      case LocalAuthExceptionCode.noBiometricHardware:
      case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
      case LocalAuthExceptionCode.uiUnavailable:
        return current.copyWith(
          status: AppAuthStatus.unavailable,
          canAuthenticate: false,
          message:
              'Nenhuma forma de desbloqueio está disponível neste aparelho.',
        );

      case LocalAuthExceptionCode.authInProgress:
        return current.copyWith(
          status: AppAuthStatus.authenticating,
          message: 'A autenticação já está em andamento.',
        );

      case LocalAuthExceptionCode.userRequestedFallback:
        return current.copyWith(
          status: AppAuthStatus.locked,
          message: 'Use o PIN, padrão ou senha do aparelho para continuar.',
        );

      case LocalAuthExceptionCode.deviceError:
      case LocalAuthExceptionCode.unknownError:
        return current.copyWith(
          status: AppAuthStatus.error,
          message:
              error.description ??
              'O aparelho não conseguiu concluir a autenticação.',
        );
    }
  }
}
