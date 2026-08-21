import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/domain/app_auth_state.dart';
import '../features/auth/presentation/providers/auth_controller.dart';
import '../features/onboarding/domain/onboarding_profile.dart';
import '../features/onboarding/presentation/providers/onboarding_controller.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/settings/domain/pulse_settings.dart';
import '../features/settings/presentation/providers/settings_controller.dart';
import '../features/workouts/presentation/providers/workout_controller.dart';
import '../theme/app_theme.dart';
import 'about_pulse_screen.dart';
import 'data_backup_screen.dart';
import 'how_to_use_screen.dart';
import 'privacy_ai_info_screen.dart';
import 'personal_data_sheet.dart';

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

    final onboardingAsync = ref.watch(onboardingControllerProvider);
    final onboardingProfile = switch (onboardingAsync) {
      AsyncData<OnboardingState>(:final value) => value.profile,
      _ => OnboardingProfile.defaults().copyWith(
        name: settings.profile.displayName,
        measurementSystem: settings.measurementSystem,
        isCompleted: true,
      ),
    };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Configurações',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          32 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('PERFIL E TREINO'),
            const SizedBox(height: 12),
            _sectionCard(
              context,
              children: [
                ListTile(
                  leading: _iconBox(context, Icons.badge_outlined),
                  title: const Text(
                    'Dados pessoais',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(_profileSubtitle(settings)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showPersonalDataSheet(context, settings),
                ),
                Divider(color: AppColors.border, height: 1),
                ListTile(
                  leading: _iconBox(context, Icons.tune_rounded),
                  title: const Text(
                    'Preferências de treino',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    _trainingPreferencesSubtitle(onboardingProfile),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final updated = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OnboardingScreen(
                          initialProfile: onboardingProfile,
                          isEditing: true,
                        ),
                      ),
                    );

                    if (updated == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Preferências de treino atualizadas.'),
                        ),
                      );
                    }
                  },
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
                        'Tema do aplicativo',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _themeModeDescription(settings.themeMode),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<PulseThemeMode>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                              value: PulseThemeMode.system,
                              icon: Icon(Icons.brightness_auto_outlined),
                              label: Text('Sistema'),
                            ),
                            ButtonSegment(
                              value: PulseThemeMode.light,
                              icon: Icon(Icons.light_mode_outlined),
                              label: Text('Claro'),
                            ),
                            ButtonSegment(
                              value: PulseThemeMode.dark,
                              icon: Icon(Icons.dark_mode_outlined),
                              label: Text('Escuro'),
                            ),
                          ],
                          selected: <PulseThemeMode>{settings.themeMode},
                          onSelectionChanged: (selection) {
                            ref
                                .read(settingsControllerProvider.notifier)
                                .setThemeMode(selection.first);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: AppColors.border, height: 1),
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
                      Text(
                        'Aplicada em ações e destaques. No modo claro, o tom é suavizado automaticamente.',
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
                          final brightness = Theme.of(context).brightness;
                          final displayColor = palette.colorFor(brightness);
                          final selected = palette.matches(
                            settings.themeColorValue,
                          );
                          final checkColor =
                              ThemeData.estimateBrightnessForColor(
                                    displayColor,
                                  ) ==
                                  Brightness.dark
                              ? Colors.white
                              : Colors.black;

                          return Semantics(
                            label: 'Cor ${palette.name}',
                            button: true,
                            selected: selected,
                            child: GestureDetector(
                              onTap: () {
                                ref
                                    .read(settingsControllerProvider.notifier)
                                    .changeThemeColor(palette.storageValue);
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
                                        color: displayColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: selected
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.onSurface
                                              : Colors.transparent,
                                          width: 3,
                                        ),
                                        boxShadow: selected
                                            ? [
                                                BoxShadow(
                                                  color: displayColor
                                                      .withValues(
                                                        alpha:
                                                            brightness ==
                                                                Brightness.light
                                                            ? 0.18
                                                            : 0.32,
                                                      ),
                                                  blurRadius: 12,
                                                  spreadRadius: 2,
                                                ),
                                              ]
                                            : const [],
                                      ),
                                      child: selected
                                          ? Icon(Icons.check, color: checkColor)
                                          : null,
                                    ),
                                    const SizedBox(height: 7),
                                    Text(
                                      palette.name,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: selected
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onSurface
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
            _sectionTitle('TREINO E UNIDADES'),
            const SizedBox(height: 12),
            _sectionCard(
              context,
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.record_voice_over_outlined),
                  title: const Text(
                    'Aviso por voz ao fim do descanso',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Fala quando é hora de iniciar a próxima série.',
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
                Divider(color: AppColors.border, height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text(
                    'Lembrete de inatividade',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Salva sua preferência para os lembretes futuros.',
                  ),
                  value: settings.inactivityReminder,
                  onChanged: (value) {
                    ref
                        .read(settingsControllerProvider.notifier)
                        .setInactivityReminder(value);
                  },
                ),
                Divider(color: AppColors.border, height: 1),
                ListTile(
                  leading: const Icon(Icons.straighten),
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
                  secondary: const Icon(Icons.lock_outline),
                  title: const Text(
                    'Proteger o PULSE',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Usa biometria, rosto, PIN, padrão ou senha do aparelho.',
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
                              ),
                            );
                          }
                        },
                ),
              ],
            ),
            const SizedBox(height: 30),
            _sectionTitle('AJUDA E TRANSPARÊNCIA'),
            const SizedBox(height: 12),
            _sectionCard(
              context,
              children: [
                ListTile(
                  leading: _iconBox(context, Icons.menu_book_outlined),
                  title: const Text(
                    'Como usar o PULSE',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Guia rápido de treinos, progresso e atividades.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HowToUseScreen()),
                    );
                  },
                ),
                Divider(color: AppColors.border, height: 1),
                ListTile(
                  leading: _iconBox(context, Icons.shield_outlined),
                  title: const Text(
                    'Privacidade e assistência',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Entenda o uso de dados e o Assistente PULSE.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyAiInfoScreen(),
                      ),
                    );
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
                  leading: _iconBox(context, Icons.cloud_sync_outlined),
                  title: const Text(
                    'Dados e backup',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Exportar, importar ou apagar dados do aparelho.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DataBackupScreen(),
                      ),
                    );
                  },
                ),
                Divider(color: AppColors.border, height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text(
                    'Sobre o PULSE',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AboutPulseScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _profileSubtitle(PulseSettings settings) {
    final profile = settings.profile;
    final parts = <String>[profile.displayName];

    if (profile.weightKg > 0) {
      if (settings.measurementSystem == MeasurementSystem.metric) {
        parts.add('${profile.weightKg.toStringAsFixed(1)} kg');
      } else {
        parts.add(
          '${(profile.weightKg * 2.2046226218).toStringAsFixed(1)} lbs',
        );
      }
    }

    if (profile.age > 0) {
      parts.add('${profile.age} anos');
    }

    return parts.join(' • ');
  }

  String _trainingPreferencesSubtitle(OnboardingProfile profile) {
    if (!profile.isPersonalized) {
      return 'Objetivo, rotina, local e equipamentos';
    }

    return '${profile.goal.label} • ${profile.trainingDaysPerWeek}x por semana • ${profile.sessionDurationMinutes} min';
  }

  String _themeModeDescription(PulseThemeMode mode) {
    return switch (mode) {
      PulseThemeMode.system =>
        'Acompanha automaticamente o tema claro ou escuro do aparelho.',
      PulseThemeMode.light => 'Mantém o PULSE sempre no tema claro.',
      PulseThemeMode.dark => 'Mantém o PULSE sempre no tema escuro.',
    };
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
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
        side: BorderSide(color: AppColors.border),
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
              const Icon(Icons.error_outline, size: 42),
              const SizedBox(height: 12),
              const Text(
                'Não foi possível carregar as configurações.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
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
