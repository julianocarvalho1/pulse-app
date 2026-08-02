import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/workouts/domain/models/cardio_log.dart';
import '../features/workouts/presentation/providers/workout_controller.dart';
import '../models/exercise.dart';
import '../theme/app_theme.dart';
import 'exercise_prescription_editor_screen.dart';
import '../widgets/routine_type_selector.dart';

class RoutineEditorScreen extends ConsumerStatefulWidget {
  const RoutineEditorScreen({super.key, required this.routine});

  final WorkoutRoutine routine;

  @override
  ConsumerState<RoutineEditorScreen> createState() =>
      _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends ConsumerState<RoutineEditorScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _focusController;
  late RoutineType _type;
  late List<Exercise> _exercises;
  late List<RoutineCardio> _cardio;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.routine.name);
    _focusController = TextEditingController(text: widget.routine.focus);
    _type = widget.routine.type;
    _exercises = List<Exercise>.from(widget.routine.exercises);
    _cardio = List<RoutineCardio>.from(widget.routine.cardio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusController.dispose();
    super.dispose();
  }

  Future<void> _changeType(RoutineType nextType) async {
    if (nextType == _type) {
      return;
    }

    if (nextType == RoutineType.cardio && _exercises.isNotEmpty) {
      final confirmed = await _confirmRemoval(
        title: 'Remover musculação?',
        message:
            'Ao transformar esta ficha em cardio, os exercícios de musculação serão removidos.',
        confirmLabel: 'REMOVER EXERCÍCIOS',
      );
      if (!confirmed || !mounted) {
        return;
      }
      setState(() {
        _type = nextType;
        _exercises = <Exercise>[];
      });
      return;
    }

    if (nextType == RoutineType.strength && _cardio.isNotEmpty) {
      final confirmed = await _confirmRemoval(
        title: 'Remover cardio?',
        message:
            'Ao transformar esta ficha em musculação, as etapas de cardio serão removidas.',
        confirmLabel: 'REMOVER CARDIO',
      );
      if (!confirmed || !mounted) {
        return;
      }
      setState(() {
        _type = nextType;
        _cardio = <RoutineCardio>[];
      });
      return;
    }

    setState(() => _type = nextType);
  }

  Future<bool> _confirmRemoval({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('CANCELAR'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _pickExercise() async {
    final allExercises = ref
        .read(workoutControllerProvider.notifier)
        .allExercises;
    final alreadyAddedIds = _exercises.map((exercise) => exercise.id).toSet();

    final selected = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _ExercisePickerSheet(
        exercises: allExercises,
        alreadyAddedIds: alreadyAddedIds,
      ),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() => _exercises.add(selected));
  }

  Future<void> _setActiveWeekForAll() async {
    final periodized = _exercises
        .where((exercise) => exercise.advancedPrescription.weeks.isNotEmpty)
        .toList(growable: false);
    if (periodized.isEmpty) {
      return;
    }
    final maxWeek = periodized
        .expand((exercise) => exercise.advancedPrescription.weeks)
        .map((week) => week.weekNumber)
        .reduce((a, b) => a > b ? a : b);
    final selected = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Semana ativa da ficha'),
        children: <Widget>[
          for (var week = 1; week <= maxWeek; week++)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, week),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Semana $week'),
              ),
            ),
        ],
      ),
    );
    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _exercises = <Exercise>[
        for (final exercise in _exercises)
          if (exercise.advancedPrescription.weeks.isEmpty)
            exercise
          else
            exercise.copyWith(
              advancedPrescription: exercise.advancedPrescription.copyWith(
                activeWeek:
                    exercise.advancedPrescription.weeks.any(
                      (week) => week.weekNumber == selected,
                    )
                    ? selected
                    : exercise.advancedPrescription.weeks.last.weekNumber,
              ),
            ),
      ];
    });
  }

  Future<void> _editExercisePrescription(int index) async {
    final allExercises = ref
        .read(workoutControllerProvider.notifier)
        .allExercises;
    final updated = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute<Exercise>(
        builder: (_) => ExercisePrescriptionEditorScreen(
          exercise: _exercises[index],
          availableExercises: allExercises,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() => _exercises[index] = updated);
    }
  }

  Future<void> _editCardio({RoutineCardio? existing}) async {
    final result = await showModalBottomSheet<RoutineCardio>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _RoutineCardioEditorSheet(existing: existing),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      final index = _cardio.indexWhere((item) => item.id == result.id);
      if (index >= 0) {
        _cardio[index] = result;
      } else {
        _cardio.add(result);
      }
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    final focus = _focusController.text.trim();

    if (name.isEmpty) {
      _showMessage('Informe o nome da ficha.');
      return;
    }
    if (_type.includesStrength && _exercises.isEmpty) {
      _showMessage('Adicione ao menos um exercício de musculação.');
      return;
    }
    if (_type.includesCardio && _cardio.isEmpty) {
      _showMessage('Adicione ao menos uma etapa de cardio.');
      return;
    }

    ref
        .read(workoutControllerProvider.notifier)
        .updateRoutine(
          widget.routine.id,
          name,
          focus.isEmpty ? 'Geral' : focus,
          widget.routine.groupName,
          _type.includesStrength ? _exercises : const <Exercise>[],
          newCardio: _type.includesCardio ? _cardio : const <RoutineCardio>[],
        );

    Navigator.pop(context, true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Editar ficha',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.paddingOf(context).bottom + 120,
          ),
          children: <Widget>[
            _SectionCard(
              child: Column(
                children: <Widget>[
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nome da ficha',
                      prefixIcon: Icon(Icons.edit_note_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _focusController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Foco ou objetivo',
                      prefixIcon: Icon(Icons.track_changes_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),
                  RoutineTypeSelector(
                    value: _type,
                    onChanged: (value) => _changeType(value),
                  ),
                ],
              ),
            ),
            if (_type.includesStrength) ...<Widget>[
              const SizedBox(height: 22),
              _SectionHeader(
                title: 'MUSCULAÇÃO',
                subtitle:
                    '${_exercises.length} exercício${_exercises.length == 1 ? '' : 's'}',
              ),
              if (_exercises.any(
                (exercise) => exercise.advancedPrescription.weeks.isNotEmpty,
              )) ...<Widget>[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _setActiveWeekForAll,
                    icon: const Icon(Icons.calendar_month_rounded, size: 18),
                    label: const Text('DEFINIR SEMANA ATIVA'),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              if (_exercises.isEmpty)
                const _EmptyBlock(
                  icon: Icons.fitness_center_rounded,
                  title: 'Nenhum exercício adicionado',
                  message: 'Escolha os exercícios que farão parte desta ficha.',
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _exercises.length,
                  onReorderItem: (oldIndex, newIndex) {
                    setState(() {
                      final item = _exercises.removeAt(oldIndex);
                      _exercises.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final exercise = _exercises[index];
                    return Padding(
                      key: ValueKey<String>('${exercise.id}-$index'),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: AppColors.border),
                          ),
                          onTap: () => _editExercisePrescription(index),
                          leading: ReorderableDragStartListener(
                            index: index,
                            child: Icon(
                              Icons.drag_handle_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            exercise.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            exercise.advancedPrescription.isEmpty
                                ? '${exercise.reps} • ${exercise.rest}'
                                : '${exercise.advancedPrescription.summary}\nToque para editar séries, semanas e técnicas',
                          ),
                          isThreeLine: !exercise.advancedPrescription.isEmpty,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                exercise.advancedPrescription.isEmpty
                                    ? Icons.tune_rounded
                                    : Icons.event_repeat_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              IconButton(
                                tooltip: 'Remover',
                                onPressed: () {
                                  setState(() => _exercises.removeAt(index));
                                },
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: _pickExercise,
                icon: const Icon(Icons.add_rounded),
                label: const Text('ADICIONAR EXERCÍCIO'),
              ),
            ],
            if (_type.includesCardio) ...<Widget>[
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'CARDIO',
                subtitle:
                    '${_cardio.length} etapa${_cardio.length == 1 ? '' : 's'}',
              ),
              const SizedBox(height: 10),
              if (_cardio.isEmpty)
                const _EmptyBlock(
                  icon: Icons.directions_run_rounded,
                  title: 'Nenhum cardio adicionado',
                  message:
                      'Adicione esteira, bicicleta, corrida ou outra modalidade.',
                )
              else
                ..._cardio.asMap().entries.map((entry) {
                  final index = entry.key;
                  final cardio = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: AppColors.border),
                        ),
                        onTap: () => _editCardio(existing: cardio),
                        leading: Icon(
                          Icons.directions_run_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          cardio.modality.label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${cardio.plannedDurationMinutes} min planejados',
                        ),
                        trailing: IconButton(
                          tooltip: 'Remover',
                          onPressed: () {
                            setState(() => _cardio.removeAt(index));
                          },
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: () => _editCardio(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('ADICIONAR CARDIO'),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded),
            label: const Text('SALVAR FICHA'),
          ),
        ),
      ),
    );
  }
}

class _ExercisePickerSheet extends StatefulWidget {
  const _ExercisePickerSheet({
    required this.exercises,
    required this.alreadyAddedIds,
  });

  final List<Exercise> exercises;
  final Set<String> alreadyAddedIds;

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalized = _query.trim().toLowerCase();
    final filtered = widget.exercises
        .where((exercise) {
          if (normalized.isEmpty) {
            return true;
          }
          return exercise.name.toLowerCase().contains(normalized) ||
              exercise.muscle.toLowerCase().contains(normalized);
        })
        .toList(growable: false);

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Adicionar exercício',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Buscar por exercício ou músculo',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                20,
                4,
                20,
                MediaQuery.paddingOf(context).bottom + 24,
              ),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final exercise = filtered[index];
                final alreadyAdded = widget.alreadyAddedIds.contains(
                  exercise.id,
                );

                return Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: AppColors.border),
                    ),
                    enabled: !alreadyAdded,
                    leading: Icon(
                      alreadyAdded
                          ? Icons.check_circle_rounded
                          : Icons.fitness_center_rounded,
                      color: alreadyAdded
                          ? AppColors.textMuted
                          : Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      exercise.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(exercise.muscle),
                    trailing: alreadyAdded
                        ? const Text('Adicionado')
                        : const Icon(Icons.add_rounded),
                    onTap: alreadyAdded
                        ? null
                        : () => Navigator.pop(context, exercise),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineCardioEditorSheet extends StatefulWidget {
  const _RoutineCardioEditorSheet({this.existing});

  final RoutineCardio? existing;

  @override
  State<_RoutineCardioEditorSheet> createState() =>
      _RoutineCardioEditorSheetState();
}

class _RoutineCardioEditorSheetState extends State<_RoutineCardioEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _durationController;
  late final TextEditingController _notesController;
  late CardioModality _modality;

  @override
  void initState() {
    super.initState();
    _modality = widget.existing?.modality ?? CardioModality.treadmill;
    _durationController = TextEditingController(
      text: widget.existing?.plannedDurationMinutes.toString() ?? '20',
    );
    _notesController = TextEditingController(
      text: widget.existing?.notes ?? '',
    );
  }

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.pop(
      context,
      RoutineCardio(
        id:
            widget.existing?.id ??
            'routine_cardio_${DateTime.now().microsecondsSinceEpoch}',
        modality: _modality,
        plannedDurationMinutes: int.parse(_durationController.text.trim()),
        notes: _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom +
            20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      widget.existing == null
                          ? 'Adicionar cardio'
                          : 'Editar cardio',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CardioModality>(
                initialValue: _modality,
                decoration: const InputDecoration(
                  labelText: 'Modalidade',
                  prefixIcon: Icon(Icons.directions_run_rounded),
                ),
                items: CardioModality.values
                    .map(
                      (item) => DropdownMenuItem<CardioModality>(
                        value: item,
                        child: Text(item.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _modality = value);
                  }
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duração planejada',
                  suffixText: 'min',
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
                validator: (value) {
                  final minutes = int.tryParse(value?.trim() ?? '');
                  if (minutes == null || minutes <= 0) {
                    return 'Informe uma duração maior que zero.';
                  }
                  if (minutes > 600) {
                    return 'Use uma duração de até 600 minutos.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Orientação opcional',
                  hintText: 'Ex.: ritmo moderado após a musculação',
                  prefixIcon: Icon(Icons.sticky_note_2_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('SALVAR CARDIO'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
