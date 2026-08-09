import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/exercise.dart';
import '../../../../theme/app_theme.dart';
import '../../../exercises/domain/exercise_catalog.dart';
import '../../../onboarding/domain/onboarding_profile.dart';
import '../../../onboarding/presentation/providers/onboarding_controller.dart';
import '../../../workouts/domain/models/cardio_log.dart';
import '../../domain/models/workout_generation_request.dart';
import '../../domain/models/workout_generation_result.dart';
import '../../domain/services/workout_generation_service.dart';
import 'generated_workout_preview_screen.dart';

class WorkoutGeneratorScreen extends ConsumerStatefulWidget {
  const WorkoutGeneratorScreen({super.key});

  @override
  ConsumerState<WorkoutGeneratorScreen> createState() =>
      _WorkoutGeneratorScreenState();
}

class _WorkoutGeneratorScreenState
    extends ConsumerState<WorkoutGeneratorScreen> {
  WorkoutGoal _goal = WorkoutGoal.hypertrophy;
  TrainingLevel _level = TrainingLevel.beginner;
  GeneratedPlanType _planType = GeneratedPlanType.strength;
  TrainingEnvironment _environment = TrainingEnvironment.fullGym;
  CardioModality _cardioModality = CardioModality.treadmill;
  int _daysPerWeek = 3;
  int _duration = 45;
  bool? _hasRestriction;
  final Set<String> _priorityMuscles = <String>{};
  final Set<String> _avoidedExerciseIds = <String>{};
  bool _usedOnboardingPreferences = false;

  static const _service = WorkoutGenerationService();
  static const List<String> _muscles = <String>[
    'Peito',
    'Costas',
    'Ombros',
    'Bíceps',
    'Tríceps',
    'Pernas',
    'Panturrilha',
    'Abdômen',
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_loadOnboardingPreferences());
  }

  Future<void> _loadOnboardingPreferences() async {
    try {
      final state = await ref.read(onboardingControllerProvider.future);
      if (!mounted || !state.profile.isPersonalized) {
        return;
      }

      setState(() => _applyOnboardingProfile(state.profile));
    } catch (_) {
      // O gerador continua utilizável com os valores padrão.
    }
  }

  void _applyOnboardingProfile(OnboardingProfile profile) {
    _goal = switch (profile.goal) {
      TrainingGoal.hypertrophy => WorkoutGoal.hypertrophy,
      TrainingGoal.strength => WorkoutGoal.strength,
      TrainingGoal.fatLoss => WorkoutGoal.weightLoss,
      TrainingGoal.conditioning ||
      TrainingGoal.generalHealth => WorkoutGoal.conditioning,
    };
    _level = switch (profile.experience) {
      TrainingExperience.beginner => TrainingLevel.beginner,
      TrainingExperience.intermediate => TrainingLevel.intermediate,
      TrainingExperience.advanced => TrainingLevel.advanced,
    };
    _planType = switch (profile.goal) {
      TrainingGoal.fatLoss ||
      TrainingGoal.generalHealth => GeneratedPlanType.mixed,
      TrainingGoal.conditioning => GeneratedPlanType.cardio,
      _ => GeneratedPlanType.strength,
    };
    _daysPerWeek = _nearestOption(profile.trainingDaysPerWeek, const <int>[
      2,
      3,
      4,
      5,
    ]);
    _duration = _nearestOption(profile.sessionDurationMinutes, const <int>[
      30,
      45,
      60,
      75,
      90,
    ]);
    _environment = _environmentFor(profile);

    for (final avoidedName in profile.avoidedExercises) {
      for (final exercise in exerciseDatabase) {
        if (ExerciseCatalog.matches(exercise, avoidedName)) {
          _avoidedExerciseIds.add(exercise.id);
        }
      }
    }

    _usedOnboardingPreferences = true;
  }

  int _nearestOption(int value, List<int> options) {
    return options.reduce(
      (current, candidate) =>
          (candidate - value).abs() < (current - value).abs()
          ? candidate
          : current,
    );
  }

  TrainingEnvironment _environmentFor(OnboardingProfile profile) {
    final equipment = profile.equipment
        .map((item) => item.toLowerCase())
        .toSet();
    final preferences = profile.trainingPreferences
        .map((item) => item.toLowerCase())
        .toSet();
    final prefersMachines = preferences.contains('mais máquinas');
    final hasMachines = equipment.any(
      (item) => item == 'máquinas' || item == 'polias' || item == 'smith',
    );
    final hasFreeWeights = equipment.any(
      (item) => item == 'halteres' || item == 'barras e anilhas',
    );

    if (profile.location == TrainingLocation.home ||
        (hasFreeWeights && !hasMachines)) {
      return TrainingEnvironment.freeWeights;
    }
    if (prefersMachines || (hasMachines && !hasFreeWeights)) {
      return TrainingEnvironment.machinesAndCables;
    }
    return TrainingEnvironment.fullGym;
  }

  Future<void> _generate() async {
    if (_hasRestriction == null) {
      _showMessage('Responda à triagem antes de gerar o programa.');
      return;
    }

    final request = WorkoutGenerationRequest(
      goal: _goal,
      level: _level,
      planType: _planType,
      daysPerWeek: _daysPerWeek,
      sessionDurationMinutes: _duration,
      environment: _environment,
      cardioModality: _cardioModality,
      priorityMuscles: _priorityMuscles,
      avoidedExerciseIds: _avoidedExerciseIds,
      hasUnassessedPainOrRestriction: _hasRestriction!,
    );

    try {
      final plan = _service.generate(request);
      if (!mounted) return;
      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => GeneratedWorkoutPreviewScreen(plan: plan),
        ),
      );
      if (saved == true && mounted) Navigator.pop(context, true);
    } on WorkoutGenerationException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _addAvoidedExercise() async {
    final exercise = await showSearch<Exercise?>(
      context: context,
      delegate: _ExerciseSearchDelegate(_avoidedExerciseIds),
    );
    if (exercise != null && mounted) {
      setState(() => _avoidedExerciseIds.add(exercise.id));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final blocked = _hasRestriction == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Gerar programa',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  _IntroCard(),
                  if (_usedOnboardingPreferences) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primaryBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 19,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Pré-configurado com suas respostas iniciais. '
                              'Revise tudo antes de gerar e salvar o programa.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _Section(
                    title: 'Objetivo',
                    child: _ChoiceWrap<WorkoutGoal>(
                      values: WorkoutGoal.values,
                      selected: _goal,
                      label: (value) => value.label,
                      onSelected: (value) => setState(() => _goal = value),
                    ),
                  ),
                  _Section(
                    title: 'Nível',
                    child: _ChoiceWrap<TrainingLevel>(
                      values: TrainingLevel.values,
                      selected: _level,
                      label: (value) => value.label,
                      onSelected: (value) => setState(() => _level = value),
                    ),
                  ),
                  _Section(
                    title: 'Tipo de programa',
                    child: _ChoiceWrap<GeneratedPlanType>(
                      values: GeneratedPlanType.values,
                      selected: _planType,
                      label: (value) => value.label,
                      onSelected: (value) => setState(() => _planType = value),
                    ),
                  ),
                  _Section(
                    title: 'Dias por semana',
                    child: _ChoiceWrap<int>(
                      values: const <int>[2, 3, 4, 5],
                      selected: _daysPerWeek,
                      label: (value) => '${value}x',
                      onSelected: (value) =>
                          setState(() => _daysPerWeek = value),
                    ),
                  ),
                  _Section(
                    title: 'Duração por sessão',
                    child: _ChoiceWrap<int>(
                      values: const <int>[30, 45, 60, 75, 90],
                      selected: _duration,
                      label: (value) => '$value min',
                      onSelected: (value) => setState(() => _duration = value),
                    ),
                  ),
                  if (_planType != GeneratedPlanType.cardio) ...[
                    _Section(
                      title: 'Estrutura disponível',
                      child: Column(
                        children: TrainingEnvironment.values
                            .map((value) {
                              final selected = value == _environment;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color: selected
                                      ? AppColors.primarySoft
                                      : AppColors.surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: selected
                                          ? AppColors.primaryBorder
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () =>
                                        setState(() => _environment = value),
                                    child: Padding(
                                      padding: const EdgeInsets.all(13),
                                      child: Row(
                                        children: [
                                          Icon(
                                            selected
                                                ? Icons.check_circle_rounded
                                                : Icons.circle_outlined,
                                            color: selected
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                : AppColors.textMuted,
                                          ),
                                          const SizedBox(width: 11),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  value.label,
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.textPrimary,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  value.description,
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.textSecondary,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            })
                            .toList(growable: false),
                      ),
                    ),
                    _Section(
                      title: 'Prioridades opcionais',
                      subtitle:
                          'Escolha até dois grupos para receber mais atenção.',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _muscles
                            .map((muscle) {
                              final selected = _priorityMuscles.contains(
                                muscle,
                              );
                              return FilterChip(
                                label: Text(muscle),
                                selected: selected,
                                onSelected: (value) {
                                  setState(() {
                                    if (value) {
                                      if (_priorityMuscles.length < 2) {
                                        _priorityMuscles.add(muscle);
                                      }
                                    } else {
                                      _priorityMuscles.remove(muscle);
                                    }
                                  });
                                },
                              );
                            })
                            .toList(growable: false),
                      ),
                    ),
                    _Section(
                      title: 'Movimentos evitados',
                      subtitle:
                          'O gerador não usará os exercícios selecionados.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _addAvoidedExercise,
                            icon: const Icon(Icons.block_outlined),
                            label: const Text('Selecionar exercício'),
                          ),
                          if (_avoidedExerciseIds.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: exerciseDatabase
                                  .where(
                                    (exercise) => _avoidedExerciseIds.contains(
                                      exercise.id,
                                    ),
                                  )
                                  .map(
                                    (exercise) => InputChip(
                                      label: Text(exercise.name),
                                      onDeleted: () => setState(
                                        () => _avoidedExerciseIds.remove(
                                          exercise.id,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (_planType != GeneratedPlanType.strength)
                    _Section(
                      title: 'Cardio preferido',
                      child: DropdownButtonFormField<CardioModality>(
                        initialValue: _cardioModality,
                        decoration: const InputDecoration(
                          labelText: 'Modalidade',
                        ),
                        items: CardioModality.values
                            .map((value) {
                              return DropdownMenuItem<CardioModality>(
                                value: value,
                                child: Text(value.label),
                              );
                            })
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _cardioModality = value);
                          }
                        },
                      ),
                    ),
                  _Section(
                    title: 'Triagem de segurança',
                    subtitle:
                        'Você sente dor aguda ou possui uma restrição ainda não avaliada por profissional?',
                    child: Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Não'),
                            selected: _hasRestriction == false,
                            onSelected: (_) =>
                                setState(() => _hasRestriction = false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Sim'),
                            selected: _hasRestriction == true,
                            onSelected: (_) =>
                                setState(() => _hasRestriction = true),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (blocked)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        'O PULSE não gera treino para contornar dor ou uma '
                        'restrição não avaliada. Procure orientação profissional '
                        'antes de usar o gerador.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.viewPaddingOf(context).bottom + 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: blocked ? null : _generate,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Gerar e revisar programa'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'O gerador usa somente exercícios do catálogo do PULSE, aplica '
              'regras locais e valida o plano antes de mostrá-lo. Nenhuma API '
              'externa é necessária.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ChoiceWrap<T> extends StatelessWidget {
  const _ChoiceWrap({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values
          .map((value) {
            return ChoiceChip(
              label: Text(label(value)),
              selected: value == selected,
              onSelected: (_) => onSelected(value),
            );
          })
          .toList(growable: false),
    );
  }
}

class _ExerciseSearchDelegate extends SearchDelegate<Exercise?> {
  _ExerciseSearchDelegate(this.avoidedIds);

  final Set<String> avoidedIds;

  List<Exercise> _matches() {
    final normalized = query.trim().toLowerCase();
    return exerciseDatabase
        .where((exercise) {
          if (avoidedIds.contains(exercise.id)) return false;
          if (normalized.isEmpty) return true;
          return exercise.name.toLowerCase().contains(normalized) ||
              exercise.muscle.toLowerCase().contains(normalized);
        })
        .toList(growable: false);
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final items = _matches();
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final exercise = items[index];
        return ListTile(
          title: Text(exercise.name),
          subtitle: Text(exercise.muscle),
          onTap: () => close(context, exercise),
        );
      },
    );
  }
}
