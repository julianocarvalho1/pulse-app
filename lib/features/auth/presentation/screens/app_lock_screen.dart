import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_theme.dart';
import '../../domain/app_auth_state.dart';
import '../providers/auth_controller.dart';

class AppLockScreen extends ConsumerWidget {
  const AppLockScreen({required this.authState, super.key});

  final AppAuthState authState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAuthenticating = authState.isAuthenticating;
    final isUnavailable = authState.status == AppAuthStatus.unavailable;
    final hasError = authState.status == AppAuthStatus.error;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -110,
              right: -90,
              child: _GlowOrb(
                size: 260,
                color: colorScheme.primary.withValues(alpha: 0.16),
              ),
            ),
            Positioned(
              bottom: -140,
              left: -100,
              child: _GlowOrb(
                size: 300,
                color: colorScheme.primary.withValues(alpha: 0.08),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PulseLogo(primaryColor: colorScheme.primary),
                      const SizedBox(height: 30),
                      Text(
                        'PULSE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 7,
                        ),
                      ),
                      const SizedBox(height: 44),
                      Text(
                        isUnavailable
                            ? 'PROTEÇÃO INDISPONÍVEL'
                            : hasError
                            ? 'NÃO FOI POSSÍVEL DESBLOQUEAR'
                            : 'SEU TREINO ESTÁ PROTEGIDO',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.7,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Olá, ${authState.userName}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isUnavailable
                            ? 'Configure a segurança do aparelho ou continue temporariamente sem o bloqueio do PULSE.'
                            : 'Use impressão digital, reconhecimento facial, PIN, padrão ou senha do aparelho para acessar seus dados.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          height: 1.55,
                        ),
                      ),
                      if (authState.message != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            authState.message!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 34),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isAuthenticating || isUnavailable
                              ? null
                              : () {
                                  ref
                                      .read(authControllerProvider.notifier)
                                      .unlock();
                                },
                          icon: isAuthenticating
                              ? SizedBox(
                                  width: 21,
                                  height: 21,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(Icons.fingerprint_rounded, size: 26),
                          label: Text(
                            isAuthenticating
                                ? 'VERIFICANDO'
                                : hasError
                                ? 'TENTAR NOVAMENTE'
                                : 'DESBLOQUEAR PULSE',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.black,
                            disabledBackgroundColor: colorScheme.primary
                                .withValues(alpha: 0.55),
                            disabledForegroundColor: Colors.black54,
                            minimumSize: const Size.fromHeight(58),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                      if (isUnavailable) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              ref
                                  .read(authControllerProvider.notifier)
                                  .disableLockAndUnlock();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(54),
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              'CONTINUAR SEM BLOQUEIO',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.9,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: AppColors.textSecondary,
                            size: 17,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'A autenticação acontece no próprio aparelho.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseLogo extends StatelessWidget {
  const _PulseLogo({required this.primaryColor});

  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: primaryColor.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.22),
            blurRadius: 36,
            spreadRadius: 7,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          'assets/icon.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                color: Colors.black,
                size: 44,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
