import 'package:flutter/foundation.dart';

enum AppAuthStatus { locked, unlocked, authenticating, unavailable, error }

@immutable
class AppAuthState {
  const AppAuthState({
    required this.status,
    required this.isLockEnabled,
    required this.canAuthenticate,
    required this.userName,
    this.message,
  });

  final AppAuthStatus status;
  final bool isLockEnabled;
  final bool canAuthenticate;
  final String userName;
  final String? message;

  bool get isUnlocked => status == AppAuthStatus.unlocked;
  bool get isAuthenticating => status == AppAuthStatus.authenticating;

  AppAuthState copyWith({
    AppAuthStatus? status,
    bool? isLockEnabled,
    bool? canAuthenticate,
    String? userName,
    String? message,
    bool clearMessage = false,
  }) {
    return AppAuthState(
      status: status ?? this.status,
      isLockEnabled: isLockEnabled ?? this.isLockEnabled,
      canAuthenticate: canAuthenticate ?? this.canAuthenticate,
      userName: userName ?? this.userName,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}
