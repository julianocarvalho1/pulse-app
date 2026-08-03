import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/exercise.dart';
import '../../../../theme/app_theme.dart';
import '../../../workouts/domain/models/advanced_workout_prescription.dart';
import '../../../workouts/domain/services/exercise_alternative_service.dart';
import '../../../workouts/presentation/providers/workout_controller.dart';
import '../../domain/models/pulse_ai_models.dart';
import '../../domain/repositories/pulse_ai_repository.dart';
import '../providers/pulse_ai_providers.dart';

enum _AssistantPhase { idle, loading, success, error, offline, limitReached }

class PulseAiAssistantScreen extends ConsumerStatefulWidget {
  const PulseAiAssistantScreen({super.key, required this.routine});

  final WorkoutRoutine routine;

  @override
  ConsumerState<PulseAiAssistantScreen> createState() =>
      _PulseAiAssistantScreenState();
}

class _PulseAiAssistantScreenState
    extends ConsumerState<PulseAiAssistantScreen> {
  _AssistantPhase _phase = _AssistantPhase.idle;
  PulseAiAssistantMode? _activeMode;
  Exercise? _selectedExercise;
  PulseAiResponse? _response;
  String? _selectedAlternativeId;
  Object? _error;

  WorkoutRoutine _resolveRoutine(List<WorkoutRoutine> routines) {
    return routines.firstWhere(
      (routine) => routine.id == widget.routine.id,
      orElse: () => widget.routine,
    );
  }

  Future<void> _startMode(
    PulseAiAssistantMode mode,
    WorkoutRoutine routine,
  ) async {
    Exercise? selectedExercise;
    if (mode == PulseAiAssistantMode.suggestReplacement) {
      selectedExercise = await _chooseExercise(routine);
      if (selectedExercise == null || !mounted) {
        return;
      }
    }

    await _runAnalysis(
      mode: mode,
      routine: routine,
      selectedExercise: selectedExercise,
    );
  }

  Future<Exercise?> _chooseExercise(WorkoutRoutine routine) {
    if (routine.exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta ficha não possui exercícios para substituir.'),
        ),
      );
      return Future<Exercise?>.value();
    }

    return showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: FractionallySizedBox(
            heightFactor: 0.78,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Qual exercício você quer trocar?',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'O assistente consultará apenas alternativas existentes na biblioteca do PULSE.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppColors.border),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
                    itemCount: routine.exercises.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final exercise = routine.exercises[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        tileColor: AppColors.surfaceLight.withValues(
                          alpha: 0.45,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primarySoft,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        title: Text(
                          exercise.name,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${exercise.muscle} • ${exercise.reps}',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textMuted,
                        ),
                        onTap: () => Navigator.pop(sheetContext, exercise),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _runAnalysis({
    required PulseAiAssistantMode mode,
    required WorkoutRoutine routine,
    Exercise? selectedExercise,
  }) async {
    setState(() {
      _phase = _AssistantPhase.loading;
      _activeMode = mode;
      _selectedExercise = selectedExercise;
      _response = null;
      _selectedAlternativeId = null;
      _error = null;
    });

    final catalog = ref.read(workoutControllerProvider).allExercises;
    try {
      final response = await ref
          .read(pulseAiRepositoryProvider)
          .analyze(
            PulseAiRequest(
              mode: mode,
              routine: routine,
              catalog: catalog,
              selectedExerciseId: selectedExercise?.id,
            ),
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _response = response;
        _phase = _AssistantPhase.success;
      });
    } on PulseAiOfflineException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _phase = _AssistantPhase.offline;
      });
    } on PulseAiLimitReachedException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _phase = _AssistantPhase.limitReached;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _phase = _AssistantPhase.error;
      });
    }
  }

  Future<void> _retry(WorkoutRoutine routine) async {
    final mode = _activeMode;
    if (mode == null) {
      _reset();
      return;
    }
    await _runAnalysis(
      mode: mode,
      routine: routine,
      selectedExercise: _selectedExercise,
    );
  }

  void _reset() {
    setState(() {
      _phase = _AssistantPhase.idle;
      _activeMode = null;
      _selectedExercise = null;
      _response = null;
      _selectedAlternativeId = null;
      _error = null;
    });
  }

  Future<void> _confirmAndApply(
    WorkoutRoutine routine,
    List<Exercise> catalog,
  ) async {
    final response = _response;
    final alternativeId = _selectedAlternativeId;
    if (response == null ||
        response.selectedExerciseId == null ||
        alternativeId == null) {
      return;
    }

    Exercise? current;
    var currentIndex = -1;
    for (var index = 0; index < routine.exercises.length; index++) {
      final exercise = routine.exercises[index];
      if (exercise.id == response.selectedExerciseId) {
        current = exercise;
        currentIndex = index;
        break;
      }
    }

    Exercise? catalogReplacement;
    for (final exercise in catalog) {
      if (exercise.id == alternativeId) {
        catalogReplacement = exercise;
        break;
      }
    }

    if (current == null || currentIndex < 0 || catalogReplacement == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A alternativa selecionada não está mais disponível.'),
        ),
      );
      return;
    }

    final Exercise currentExercise = current;
    final Exercise replacementExercise = catalogReplacement;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Aplicar substituição?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _ChangeLine(label: 'Sai', value: currentExercise.name),
            const SizedBox(height: 10),
            _ChangeLine(label: 'Entra', value: replacementExercise.name),
            const SizedBox(height: 14),
            Text(
              'Séries, repetições, descanso e detalhes avançados serão preservados. A alteração só acontece após sua confirmação.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final replacement = const ExerciseAlternativeService().buildReplacement(
      current: currentExercise,
      selected: ExerciseAlternative(
        exerciseId: replacementExercise.id,
        name: replacementExercise.name,
        muscle: replacementExercise.muscle,
      ),
      catalog: catalog,
    );
    final updatedExercises = List<Exercise>.from(routine.exercises);
    updatedExercises[currentIndex] = replacement;

    ref
        .read(workoutControllerProvider.notifier)
        .updateRoutine(
          routine.id,
          routine.name,
          routine.focus,
          routine.groupName,
          updatedExercises,
          newCardio: routine.cardio,
        );

    if (!mounted) {
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(workoutControllerProvider);
    final routine = _resolveRoutine(workoutState.myRoutines);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Assistente PULSE'),
        actions: <Widget>[
          if (_phase != _AssistantPhase.idle)
            IconButton(
              tooltip: 'Nova análise',
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: switch (_phase) {
          _AssistantPhase.idle => _buildHome(routine),
          _AssistantPhase.loading => _buildLoading(),
          _AssistantPhase.success => _buildResult(
            routine,
            workoutState.allExercises,
          ),
          _AssistantPhase.error => _buildErrorState(
            icon: Icons.error_outline_rounded,
            title: 'Não foi possível concluir',
            message:
                'O assistente encontrou um erro temporário. Sua ficha não foi alterada.',
            routine: routine,
          ),
          _AssistantPhase.offline => _buildErrorState(
            icon: Icons.cloud_off_rounded,
            title: 'Sem conexão',
            message:
                'O modo conectado precisa de internet. O restante do PULSE continua funcionando normalmente.',
            routine: routine,
          ),
          _AssistantPhase.limitReached => _buildErrorState(
            icon: Icons.hourglass_bottom_rounded,
            title: 'Limite temporário atingido',
            message:
                'Tente novamente mais tarde. Nenhuma alteração foi feita na ficha.',
            routine: routine,
          ),
        },
      ),
    );
  }

  Widget _buildHome(WorkoutRoutine routine) {
    return SingleChildScrollView(
      key: const ValueKey<String>('assistant-home'),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _AssistantHero(routine: routine),
          const SizedBox(height: 22),
          Text(
            'COMO POSSO AJUDAR?',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 10),
          for (final mode in PulseAiAssistantMode.values) ...<Widget>[
            _AssistantOptionCard(
              mode: mode,
              enabled:
                  mode != PulseAiAssistantMode.suggestReplacement ||
                  routine.exercises.isNotEmpty,
              onTap: () => _startMode(mode, routine),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          const _PrivacyAndSafetyCard(),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    final mode = _activeMode;
    return Center(
      key: const ValueKey<String>('assistant-loading'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              mode?.title ?? 'Analisando a ficha',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Organizando uma resposta segura e estruturada…',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(WorkoutRoutine routine, List<Exercise> catalog) {
    final response = _response;
    if (response == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      key: const ValueKey<String>('assistant-result'),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.paddingOf(context).bottom + 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  AppColors.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        _modeIcon(response.mode),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        response.title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  response.summary,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                if (response.generatedLocally) ...<Widget>[
                  const SizedBox(height: 12),
                  const _LocalPreviewBadge(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final insight in response.insights) ...<Widget>[
            _InsightCard(insight: insight),
            const SizedBox(height: 10),
          ],
          if (response.alternatives.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              'ESCOLHA UMA ALTERNATIVA',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            for (final alternative in response.alternatives) ...<Widget>[
              _AlternativeCard(
                alternative: alternative,
                selected: _selectedAlternativeId == alternative.exerciseId,
                onTap: () => setState(
                  () => _selectedAlternativeId = alternative.exerciseId,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
          const SizedBox(height: 6),
          _SafetyNote(text: response.safetyNote),
          const SizedBox(height: 18),
          if (response.hasApplicableChange)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _selectedAlternativeId == null
                    ? null
                    : () => _confirmAndApply(routine, catalog),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('REVISAR E APLICAR'),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('FAZER OUTRA ANÁLISE'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState({
    required IconData icon,
    required String title,
    required String message,
    required WorkoutRoutine routine,
  }) {
    return Center(
      key: ValueKey<String>('assistant-error-${_phase.name}'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => _retry(routine),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
            TextButton(
              onPressed: _reset,
              child: const Text('Voltar ao início'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _modeIcon(PulseAiAssistantMode mode) {
    return switch (mode) {
      PulseAiAssistantMode.explainWorkout => Icons.menu_book_rounded,
      PulseAiAssistantMode.suggestReplacement => Icons.swap_horiz_rounded,
      PulseAiAssistantMode.reviewRoutine => Icons.fact_check_rounded,
    };
  }
}

class _AssistantHero extends StatelessWidget {
  const _AssistantHero({required this.routine});

  final WorkoutRoutine routine;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.22),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Assistente PULSE',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Piloto seguro para analisar fichas',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            routine.name,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${routine.typeLabel} • ${routine.activitySummary}',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          const _LocalPreviewBadge(),
        ],
      ),
    );
  }
}

class _AssistantOptionCard extends StatelessWidget {
  const _AssistantOptionCard({
    required this.mode,
    required this.enabled,
    required this.onTap,
  });

  final PulseAiAssistantMode mode;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (mode) {
      PulseAiAssistantMode.explainWorkout => Icons.menu_book_rounded,
      PulseAiAssistantMode.suggestReplacement => Icons.swap_horiz_rounded,
      PulseAiAssistantMode.reviewRoutine => Icons.fact_check_rounded,
    };

    return Opacity(
      opacity: enabled ? 1 : 0.52,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        mode.title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mode.description,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyAndSafetyCard extends StatelessWidget {
  const _PrivacyAndSafetyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.shield_outlined, size: 20, color: AppColors.info),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nesta etapa, a análise é simulada localmente e nenhum dado é enviado. O assistente não diagnostica lesões e nunca altera a ficha sem confirmação.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalPreviewBadge extends StatelessWidget {
  const _LocalPreviewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.phone_android_rounded,
            size: 13,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 5),
          Text(
            'PILOTO LOCAL • SEM ENVIO DE DADOS',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final PulseAiInsight insight;

  @override
  Widget build(BuildContext context) {
    final color = switch (insight.tone) {
      PulseAiInsightTone.neutral => AppColors.info,
      PulseAiInsightTone.positive => AppColors.success,
      PulseAiInsightTone.attention => AppColors.warning,
    };
    final icon = switch (insight.tone) {
      PulseAiInsightTone.neutral => Icons.lightbulb_outline_rounded,
      PulseAiInsightTone.positive => Icons.check_circle_outline_rounded,
      PulseAiInsightTone.attention => Icons.info_outline_rounded,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  insight.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  insight.body,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.42,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlternativeCard extends StatelessWidget {
  const _AlternativeCard({
    required this.alternative,
    required this.selected,
    required this.onTap,
  });

  final PulseAiExerciseAlternative alternative;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? primary : Colors.transparent,
                  border: Border.all(
                    color: selected ? primary : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: AppColors.onPrimary,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      alternative.name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      alternative.muscle.toUpperCase(),
                      style: TextStyle(
                        color: primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      alternative.reason,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SafetyNote extends StatelessWidget {
  const _SafetyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.health_and_safety_outlined,
            size: 19,
            color: AppColors.warning,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangeLine extends StatelessWidget {
  const _ChangeLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 48,
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
