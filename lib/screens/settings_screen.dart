import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/domain/app_auth_state.dart';
import '../features/auth/presentation/providers/auth_controller.dart';
import '../features/onboarding/presentation/providers/onboarding_controller.dart';
import '../features/progress/presentation/providers/progress_controller.dart';
import '../features/settings/domain/pulse_settings.dart';
import '../features/settings/presentation/providers/settings_controller.dart';
import '../features/workouts/presentation/providers/workout_controller.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsControllerProvider);

    return settingsAsync.when(
      loading: () => const _SettingsLoadingView(),
      error: (error, stackTrace) => _SettingsErrorView(
        onRetry: () {
          ref.read(settingsControllerProvider.notifier).reload();
        },
      ),
      data: (settings) => _SettingsContent(settings: settings),
    );
  }
}

class _SettingsContent extends ConsumerWidget {
  const _SettingsContent({required this.settings});

  final PulseSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authControllerProvider);
    final authState = switch (authAsync) {
      AsyncData<AppAuthState>(:final value) => value,
      _ => null,
    };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Configurações',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('CONTA'),
            const SizedBox(height: 12),
            _sectionCard(
              context,
              children: [
                ListTile(
                  leading: _iconBox(context, Icons.person_outline),
                  title: Text(
                    settings.profile.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    _profileSubtitle(settings),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            _sectionTitle('APARÊNCIA'),
            const SizedBox(height: 12),
            _sectionCard(
              context,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cor principal',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'A cor selecionada é aplicada em botões, indicadores e destaques.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 14,
                        runSpacing: 16,
                        children: pulsePalettes.map((palette) {
                          final selected =
                              settings.themeColorValue ==
                              palette.primary.toARGB32();

                          return Semantics(
                            label: 'Tema ${palette.name}',
                            button: true,
                            selected: selected,
                            child: GestureDetector(
                              onTap: () {
                                ref
                                    .read(settingsControllerProvider.notifier)
                                    .changeThemeColor(
                                      palette.primary.toARGB32(),
                                    );
                              },
                              child: SizedBox(
                                width: 64,
                                child: Column(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: palette.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: selected
                                              ? Colors.white
                                              : Colors.transparent,
                                          width: 3,
                                        ),
                                        boxShadow: selected
                                            ? [
                                                BoxShadow(
                                                  color: palette.primary
                                                      .withValues(alpha: 0.45),
                                                  blurRadius: 12,
                                                  spreadRadius: 2,
                                                ),
                                              ]
                                            : const [],
                                      ),
                                      child: selected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.black,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(height: 7),
                                    Text(
                                      palette.name,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: selected
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                        fontSize: 10,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            _sectionTitle('ALERTAS DURANTE O TREINO'),
            const SizedBox(height: 12),
            _sectionCard(
              context,
              children: [
                SwitchListTile(
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                  title: const Text(
                    'Aviso por voz ao fim do descanso',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Fala quando é hora de iniciar a próxima série.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  value: settings.voiceAfterRest,
                  onChanged: (value) async {
                    await ref
                        .read(settingsControllerProvider.notifier)
                        .setVoiceAfterRest(value);

                    if (context.mounted) {
                      ref
                          .read(workoutControllerProvider.notifier)
                          .setVoiceAfterRest(value);
                    }
                  },
                ),
                const Divider(color: AppColors.border, height: 1),
                SwitchListTile(
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                  title: const Text(
                    'Lembrete de inatividade',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Salva sua preferência para os lembretes futuros.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  value: settings.inactivityReminder,
                  onChanged: (value) {
                    ref
                        .read(settingsControllerProvider.notifier)
                        .setInactivityReminder(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
            _sectionTitle('PREFERÊNCIAS GERAIS'),
            const SizedBox(height: 12),
            _sectionCard(
              context,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.straighten,
                    color: AppColors.textSecondary,
                  ),
                  title: const Text(
                    'Sistema de medidas',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: DropdownButton<MeasurementSystem>(
                    value: settings.measurementSystem,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    underline: const SizedBox(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: MeasurementSystem.metric,
                        child: Text('Kg / Cm'),
                      ),
                      DropdownMenuItem(
                        value: MeasurementSystem.imperial,
                        child: Text('Lbs / In'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .setMeasurementSystem(value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            _sectionTitle('SEGURANÇA'),
            const SizedBox(height: 12),
            _sectionCard(
              context,
              children: [
                SwitchListTile(
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                  secondary: const Icon(
                    Icons.lock_outline,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Proteger o PULSE',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Usa biometria, rosto, PIN, padrão ou senha do aparelho.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  value: authState?.isLockEnabled ?? false,
                  onChanged: authState == null
                      ? null
                      : (value) async {
                          final enabled = await ref
                              .read(authControllerProvider.notifier)
                              .setLockEnabled(value);

                          if (!enabled && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Configure uma forma de desbloqueio no aparelho antes de ativar a proteção.',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                ),
              ],
            ),
            const SizedBox(height: 30),
            _sectionTitle('DADOS E APLICATIVO'),
            const SizedBox(height: 12),
            _sectionCard(
              context,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.info_outline,
                    color: AppColors.textSecondary,
                  ),
                  title: const Text(
                    'Sobre o PULSE',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'PULSE',
                      applicationVersion: '1.0.0',
                      applicationLegalese: 'Diário inteligente de musculação.',
                      applicationIcon: Icon(
                        Icons.fitness_center,
                        color: Theme.of(context).colorScheme.primary,
                        size: 40,
                      ),
                    );
                  },
                ),
                const Divider(color: AppColors.border, height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Apagar todos os dados',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                  subtitle: const Text(
                    'Remove perfil, fichas, histórico e preferências deste aparelho.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () => _confirmFactoryReset(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmFactoryReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Apagar todos os dados?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Essa ação apagará perfil, fichas, histórico e preferências salvas neste aparelho. Não será possível desfazer.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Apagar tudo'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await ref.read(workoutControllerProvider.notifier).factoryReset();
    await ref.read(bodyMeasurementsControllerProvider.notifier).clearAll();
    await ref
        .read(settingsControllerProvider.notifier)
        .resetToDefaults(clearStorage: false);
    await ref.read(authControllerProvider.notifier).resetAfterFactoryReset();
    ref.read(onboardingControllerProvider.notifier).resetAfterFactoryReset();

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Os dados locais do PULSE foram apagados.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _profileSubtitle(PulseSettings settings) {
    final profile = settings.profile;
    final parts = <String>[];

    if (profile.weightKg > 0) {
      if (settings.measurementSystem == MeasurementSystem.metric) {
        parts.add('${profile.weightKg.toStringAsFixed(1)} kg');
      } else {
        final pounds = profile.weightKg * 2.2046226218;
        parts.add('${pounds.toStringAsFixed(1)} lbs');
      }
    }

    if (profile.age > 0) {
      parts.add('${profile.age} anos');
    }

    return parts.isEmpty
        ? 'Edite seus dados pessoais na tela Perfil.'
        : parts.join(' • ');
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.textSecondary,
        letterSpacing: 1,
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required List<Widget> children}) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _iconBox(BuildContext context, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.primary),
    );
  }
}

class _SettingsLoadingView extends StatelessWidget {
  const _SettingsLoadingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _SettingsErrorView extends StatelessWidget {
  const _SettingsErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Não foi possível carregar as configurações.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
