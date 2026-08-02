import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/domain/pulse_settings.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/onboarding_profile.dart';
import '../providers/onboarding_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({
    required this.initialProfile,
    this.isEditing = false,
    super.key,
  });

  final OnboardingProfile initialProfile;
  final bool isEditing;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _pageCount = 5;
  static const List<int> _durationOptions = <int>[30, 45, 60, 75, 90];
  static const List<String> _equipmentOptions = <String>[
    'Máquinas',
    'Halteres',
    'Barras e anilhas',
    'Polias',
    'Smith',
    'Elásticos',
    'Peso corporal',
  ];
  static const List<String> _preferenceOptions = <String>[
    'Treinos objetivos',
    'Mais máquinas',
    'Mais pesos livres',
    'Poucas técnicas avançadas',
    'Evitar exercícios de alto impacto',
    'Dar prioridade aos exercícios favoritos',
  ];

  late final PageController _pageController;
  late final TextEditingController _nameController;
  late final TextEditingController _avoidedExercisesController;

  late TrainingExperience _experience;
  late TrainingGoal _goal;
  late int _trainingDaysPerWeek;
  late int _sessionDurationMinutes;
  late TrainingLocation _location;
  late Set<String> _equipment;
  late Set<String> _trainingPreferences;
  late MeasurementSystem _measurementSystem;
  late OnboardingNextStep _nextStep;

  int _currentPage = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final initial = widget.initialProfile;
    _pageController = PageController();
    _nameController = TextEditingController(
      text: initial.displayName == 'Atleta' ? '' : initial.displayName,
    );
    _avoidedExercisesController = TextEditingController(
      text: initial.avoidedExercises.join(', '),
    );
    _experience = initial.experience;
    _goal = initial.goal;
    _trainingDaysPerWeek = initial.trainingDaysPerWeek;
    _sessionDurationMinutes = initial.sessionDurationMinutes;
    _location = initial.location;
    _equipment = initial.equipment.toSet();
    _trainingPreferences = initial.trainingPreferences.toSet();
    _measurementSystem = initial.measurementSystem;
    _nextStep = initial.nextStep;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _avoidedExercisesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  if (widget.isEditing)
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    )
                  else
                    Container(
                      width: 42,
                      height: 42,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Image.asset(
                        'assets/icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.fitness_center_rounded,
                            color: primaryColor,
                          );
                        },
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isEditing
                              ? 'PREFERÊNCIAS DE TREINO'
                              : 'CONFIGURE SEU PULSE',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Etapa ${_currentPage + 1} de $_pageCount',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${((_currentPage + 1) / _pageCount * 100).round()}%',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 5,
                  value: (_currentPage + 1) / _pageCount,
                  color: primaryColor,
                  backgroundColor: AppColors.surface,
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildIdentityPage(context),
                  _buildRoutinePage(context),
                  _buildEnvironmentPage(context),
                  _buildPreferencesPage(context),
                  _buildFinalPage(context),
                ],
              ),
            ),
            _buildBottomActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityPage(BuildContext context) {
    return _pageContainer(
      children: [
        _pageHeading(
          context,
          icon: Icons.waving_hand_rounded,
          title: widget.isEditing
              ? 'Vamos atualizar seu perfil'
              : 'Bem-vindo ao PULSE',
          description:
              'Usaremos estas respostas para organizar a experiência. Elas não substituem orientação profissional.',
        ),
        const SizedBox(height: 26),
        const _FieldLabel('COMO DEVEMOS CHAMAR VOCÊ?'),
        const SizedBox(height: 10),
        TextField(
          controller: _nameController,
          enabled: !_isSaving,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          maxLength: 40,
          decoration: const InputDecoration(
            hintText: 'Nome ou apelido',
            counterText: '',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 26),
        const _FieldLabel('QUAL É SUA EXPERIÊNCIA COM MUSCULAÇÃO?'),
        const SizedBox(height: 10),
        ...TrainingExperience.values.map(
          (value) => _selectionCard(
            context,
            selected: _experience == value,
            title: value.label,
            description: value.description,
            icon: switch (value) {
              TrainingExperience.beginner => Icons.flag_outlined,
              TrainingExperience.intermediate => Icons.trending_up_rounded,
              TrainingExperience.advanced => Icons.workspace_premium_outlined,
            },
            onTap: () => setState(() => _experience = value),
          ),
        ),
      ],
    );
  }

  Widget _buildRoutinePage(BuildContext context) {
    return _pageContainer(
      children: [
        _pageHeading(
          context,
          icon: Icons.track_changes_rounded,
          title: 'Sua rotina de treino',
          description:
              'Escolha o objetivo principal e uma frequência que caiba na sua semana.',
        ),
        const SizedBox(height: 26),
        const _FieldLabel('OBJETIVO PRINCIPAL'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TrainingGoal.values
              .map(
                (value) => ChoiceChip(
                  label: Text(value.label),
                  selected: _goal == value,
                  onSelected: (_) => setState(() => _goal = value),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 28),
        const _FieldLabel('QUANTOS DIAS POR SEMANA?'),
        const SizedBox(height: 12),
        Row(
          children: List<Widget>.generate(6, (index) {
            final value = index + 2;
            final selected = _trainingDaysPerWeek == value;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == 5 ? 0 : 7),
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: '$value dias por semana',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() => _trainingDaysPerWeek = value);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        '$value',
                        style: TextStyle(
                          color: selected
                              ? AppColors.onPrimary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 28),
        const _FieldLabel('TEMPO DISPONÍVEL POR SESSÃO'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _durationOptions
              .map(
                (value) => ChoiceChip(
                  label: Text('$value min'),
                  selected: _sessionDurationMinutes == value,
                  onSelected: (_) {
                    setState(() => _sessionDurationMinutes = value);
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildEnvironmentPage(BuildContext context) {
    return _pageContainer(
      children: [
        _pageHeading(
          context,
          icon: Icons.fitness_center_rounded,
          title: 'Onde você treina?',
          description:
              'Isso ajudará o PULSE a priorizar exercícios compatíveis com os equipamentos disponíveis.',
        ),
        const SizedBox(height: 26),
        const _FieldLabel('LOCAL DE TREINO'),
        const SizedBox(height: 10),
        ...TrainingLocation.values.map(
          (value) => _selectionCard(
            context,
            selected: _location == value,
            title: value.label,
            description: switch (value) {
              TrainingLocation.gym => 'Máquinas, pesos livres e polias.',
              TrainingLocation.home =>
                'Equipamentos próprios ou peso corporal.',
              TrainingLocation.both =>
                'Quero flexibilidade para os dois locais.',
            },
            icon: switch (value) {
              TrainingLocation.gym => Icons.apartment_rounded,
              TrainingLocation.home => Icons.home_outlined,
              TrainingLocation.both => Icons.swap_horiz_rounded,
            },
            onTap: () => setState(() => _location = value),
          ),
        ),
        const SizedBox(height: 24),
        const _FieldLabel('EQUIPAMENTOS DISPONÍVEIS'),
        const SizedBox(height: 6),
        Text(
          'Selecione tudo que costuma ter à disposição.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _equipmentOptions
              .map(
                (value) => FilterChip(
                  label: Text(value),
                  selected: _equipment.contains(value),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _equipment.add(value);
                      } else {
                        _equipment.remove(value);
                      }
                    });
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildPreferencesPage(BuildContext context) {
    return _pageContainer(
      children: [
        _pageHeading(
          context,
          icon: Icons.tune_rounded,
          title: 'Preferências e cuidados',
          description:
              'Estas opções serão usadas como filtros e lembretes. O PULSE não faz diagnóstico nem prescreve reabilitação.',
        ),
        const SizedBox(height: 26),
        const _FieldLabel('COMO VOCÊ PREFERE TREINAR?'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _preferenceOptions
              .map(
                (value) => FilterChip(
                  label: Text(value),
                  selected: _trainingPreferences.contains(value),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _trainingPreferences.add(value);
                      } else {
                        _trainingPreferences.remove(value);
                      }
                    });
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 28),
        const _FieldLabel('EXERCÍCIOS QUE DESEJA EVITAR'),
        const SizedBox(height: 6),
        Text(
          'Opcional. Separe os nomes por vírgulas. Você poderá alterar depois.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _avoidedExercisesController,
          enabled: !_isSaving,
          minLines: 3,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Ex.: agachamento livre, corrida, mergulho',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildFinalPage(BuildContext context) {
    return _pageContainer(
      children: [
        _pageHeading(
          context,
          icon: Icons.rocket_launch_rounded,
          title: 'Só falta escolher o próximo passo',
          description:
              'Nada será alterado automaticamente. Você sempre confirma fichas, exercícios e cargas.',
        ),
        const SizedBox(height: 26),
        const _FieldLabel('SISTEMA DE MEDIDAS'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _compactChoice(
                context,
                selected: _measurementSystem == MeasurementSystem.metric,
                title: 'Kg / Cm',
                onTap: () {
                  setState(() => _measurementSystem = MeasurementSystem.metric);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _compactChoice(
                context,
                selected: _measurementSystem == MeasurementSystem.imperial,
                title: 'Lbs / In',
                onTap: () {
                  setState(
                    () => _measurementSystem = MeasurementSystem.imperial,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const _FieldLabel('COMO DESEJA COMEÇAR?'),
        const SizedBox(height: 10),
        ...OnboardingNextStep.values.map(
          (value) => _selectionCard(
            context,
            selected: _nextStep == value,
            title: value.label,
            description: value.description,
            icon: value == OnboardingNextStep.createRoutine
                ? Icons.edit_note_rounded
                : Icons.library_add_rounded,
            onTap: () => setState(() => _nextStep = value),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            _nextStep == OnboardingNextStep.createRoutine
                ? 'Próximo passo: abra Treinos e toque em “Nova Ficha”.'
                : 'Próximo passo: abra Treinos, entre no catálogo e importe um programa.',
            style: const TextStyle(fontWeight: FontWeight.w700, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    final isLastPage = _currentPage == _pageCount - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : _previous,
                child: const Text('VOLTAR'),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentPage == 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : isLastPage
                  ? _complete
                  : _next,
              child: _isSaving
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : Text(isLastPage ? 'CONCLUIR' : 'CONTINUAR'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageContainer({required List<Widget> children}) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _pageHeading(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _selectionCard(
    BuildContext context, {
    required bool selected,
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final selectedColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: selected
                  ? selectedColor.withValues(alpha: 0.10)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? selectedColor : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? selectedColor : AppColors.textSecondary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? selectedColor : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _compactChoice(
    BuildContext context, {
    required bool selected,
    required String title,
    required VoidCallback onTap,
  }) {
    final color = Theme.of(context).colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: selected ? color : AppColors.border),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? AppColors.onPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Future<void> _next() async {
    if (_currentPage == 0 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe seu nome ou apelido para continuar.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (widget.isEditing) {
      setState(() => _currentPage++);
      await _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(onboardingControllerProvider.notifier)
          .saveDraft(_buildProfile());

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _currentPage++;
      });

      await _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    } catch (error, stackTrace) {
      debugPrint('Erro ao salvar rascunho do onboarding: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() => _isSaving = false);
      _showSaveError();
    }
  }

  void _previous() {
    if (_currentPage <= 0) {
      return;
    }

    setState(() => _currentPage--);
    _pageController.animateToPage(
      _currentPage,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _complete() async {
    setState(() => _isSaving = true);

    try {
      await ref
          .read(onboardingControllerProvider.notifier)
          .complete(_buildProfile());

      if (!mounted) {
        return;
      }

      if (widget.isEditing) {
        Navigator.of(context).pop(true);
      }
    } catch (error, stackTrace) {
      debugPrint('Erro ao concluir onboarding: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() => _isSaving = false);
      _showSaveError();
    }
  }

  OnboardingProfile _buildProfile() {
    return OnboardingProfile(
      name: _nameController.text,
      experience: _experience,
      goal: _goal,
      trainingDaysPerWeek: _trainingDaysPerWeek,
      sessionDurationMinutes: _sessionDurationMinutes,
      location: _location,
      equipment: _equipment.toList(),
      avoidedExercises: _parseCommaSeparated(_avoidedExercisesController.text),
      trainingPreferences: _trainingPreferences.toList(),
      measurementSystem: _measurementSystem,
      nextStep: _nextStep,
      isCompleted: false,
      isPersonalized: true,
    );
  }

  List<String> _parseCommaSeparated(String value) {
    return value
        .split(RegExp(r'[,;\n]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  void _showSaveError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Não foi possível salvar. Tente novamente.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.7,
      ),
    );
  }
}
