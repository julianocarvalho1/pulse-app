import 'package:flutter/material.dart';

import '../features/workouts/data/mappers/legacy_workout_mapper.dart';
import '../features/workouts/domain/models/advanced_workout_prescription.dart';
import '../models/exercise.dart';
import '../theme/app_theme.dart';

class ExercisePrescriptionEditorScreen extends StatefulWidget {
  const ExercisePrescriptionEditorScreen({
    super.key,
    required this.exercise,
    required this.availableExercises,
  });

  final Exercise exercise;
  final List<Exercise> availableExercises;

  @override
  State<ExercisePrescriptionEditorScreen> createState() =>
      _ExercisePrescriptionEditorScreenState();
}

class _ExercisePrescriptionEditorScreenState
    extends State<ExercisePrescriptionEditorScreen> {
  late List<WorkoutWeekPrescription> _weeks;
  late List<ExerciseAlternative> _alternatives;
  late int _activeWeek;
  late int _selectedWeek;

  @override
  void initState() {
    super.initState();
    final existing = widget.exercise.advancedPrescription;
    if (existing.weeks.isEmpty) {
      _weeks = <WorkoutWeekPrescription>[_legacyWeek(widget.exercise)];
      _activeWeek = 1;
      _selectedWeek = 1;
    } else {
      _weeks = List<WorkoutWeekPrescription>.from(existing.weeks);
      _activeWeek = existing.activeWeek.clamp(1, _weeks.length).toInt();
      _selectedWeek = _activeWeek;
    }
    _alternatives = List<ExerciseAlternative>.from(existing.alternatives);
  }

  WorkoutWeekPrescription _legacyWeek(Exercise exercise) {
    final config = LegacyWorkoutMapper.parseExerciseConfig(
      reps: exercise.reps,
      rest: exercise.rest,
    );
    final target = _legacyTarget(exercise.reps);
    return WorkoutWeekPrescription(
      weekNumber: 1,
      label: 'Base atual',
      sets: <WorkoutSetPrescription>[
        for (var index = 0; index < config.seriesCount; index++)
          WorkoutSetPrescription(
            setNumber: index + 1,
            target: target,
            restSeconds: config.recommendedRestSeconds > 0
                ? config.recommendedRestSeconds
                : null,
          ),
      ],
    );
  }

  String _legacyTarget(String raw) {
    final normalized = raw.replaceAll('×', 'x').trim();
    final index = normalized.toLowerCase().indexOf('x');
    if (index >= 0 && index < normalized.length - 1) {
      return normalized.substring(index + 1).trim();
    }
    return normalized;
  }

  WorkoutWeekPrescription get _currentWeek => _weeks.firstWhere(
    (week) => week.weekNumber == _selectedWeek,
    orElse: () => _weeks.first,
  );

  void _replaceCurrentWeek(WorkoutWeekPrescription updated) {
    setState(() {
      final index = _weeks.indexWhere(
        (week) => week.weekNumber == updated.weekNumber,
      );
      if (index >= 0) {
        _weeks[index] = updated;
      }
    });
  }

  void _changeWeekCount(int nextCount) {
    final safeCount = nextCount.clamp(1, 12).toInt();
    setState(() {
      if (safeCount > _weeks.length) {
        final template = _weeks.last;
        for (var number = _weeks.length + 1; number <= safeCount; number++) {
          _weeks.add(
            template.copyWith(
              weekNumber: number,
              label: '',
              sets: <WorkoutSetPrescription>[
                for (var index = 0; index < template.sets.length; index++)
                  template.sets[index].copyWith(setNumber: index + 1),
              ],
            ),
          );
        }
      } else if (safeCount < _weeks.length) {
        _weeks = _weeks.take(safeCount).toList();
        if (_selectedWeek > safeCount) {
          _selectedWeek = safeCount;
        }
        if (_activeWeek > safeCount) {
          _activeWeek = safeCount;
        }
      }
    });
  }

  Future<void> _editWeekDetails() async {
    final week = _currentWeek;
    final labelController = TextEditingController(text: week.label);
    final notesController = TextEditingController(text: week.notes);
    final result = await showDialog<WorkoutWeekPrescription>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Semana ${week.weekNumber}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: 'Nome opcional',
                  hintText: 'Ex.: Acúmulo, Deload, Intensificação',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: notesController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Orientações da semana',
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              week.copyWith(
                label: labelController.text.trim(),
                notes: notesController.text.trim(),
              ),
            ),
            child: const Text('SALVAR'),
          ),
        ],
      ),
    );
    labelController.dispose();
    notesController.dispose();
    if (result != null && mounted) {
      _replaceCurrentWeek(result);
    }
  }

  Future<void> _editSet(int index) async {
    final week = _currentWeek;
    final existing = week.sets[index];
    final result = await _showSetEditor(existing);
    if (result == null || !mounted) {
      return;
    }
    final updatedSets = List<WorkoutSetPrescription>.from(week.sets);
    updatedSets[index] = result.copyWith(setNumber: index + 1);
    _replaceCurrentWeek(week.copyWith(sets: updatedSets));
  }

  Future<WorkoutSetPrescription?> _showSetEditor(
    WorkoutSetPrescription existing,
  ) async {
    final targetController = TextEditingController(text: existing.target);
    final restController = TextEditingController(
      text: existing.restSeconds?.toString() ?? '',
    );
    final rirController = TextEditingController(
      text: existing.targetRir?.toString() ?? '',
    );
    final cadenceController = TextEditingController(text: existing.cadence);
    final notesController = TextEditingController(text: existing.notes);
    var technique = existing.technique;

    final result = await showDialog<WorkoutSetPrescription>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Série ${existing.setNumber}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: targetController,
                  decoration: const InputDecoration(
                    labelText: 'Alvo',
                    hintText: 'Ex.: 8–12 reps, 30s, máximo',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: restController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Descanso (s)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: rirController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'RIR',
                          hintText: '0–5',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cadenceController,
                  decoration: const InputDecoration(
                    labelText: 'Cadência',
                    hintText: 'Ex.: 3-1-1-0',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<WorkoutTechnique>(
                  initialValue: technique,
                  decoration: const InputDecoration(labelText: 'Técnica'),
                  items: WorkoutTechnique.values
                      .map(
                        (item) => DropdownMenuItem<WorkoutTechnique>(
                          value: item,
                          child: Text(item.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => technique = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Observação desta série',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCELAR'),
            ),
            FilledButton(
              onPressed: () {
                final rir = int.tryParse(rirController.text.trim());
                Navigator.pop(
                  dialogContext,
                  existing.copyWith(
                    target: targetController.text.trim(),
                    restSeconds: int.tryParse(restController.text.trim()),
                    clearRestSeconds: restController.text.trim().isEmpty,
                    targetRir: rir?.clamp(0, 10).toInt(),
                    clearTargetRir: rirController.text.trim().isEmpty,
                    cadence: cadenceController.text.trim(),
                    technique: technique,
                    notes: notesController.text.trim(),
                  ),
                );
              },
              child: const Text('SALVAR'),
            ),
          ],
        ),
      ),
    );

    targetController.dispose();
    restController.dispose();
    rirController.dispose();
    cadenceController.dispose();
    notesController.dispose();
    return result;
  }

  void _addSet() {
    final week = _currentWeek;
    final template = week.sets.isEmpty
        ? const WorkoutSetPrescription(setNumber: 1, target: '8–12 reps')
        : week.sets.last;
    _replaceCurrentWeek(
      week.copyWith(
        sets: <WorkoutSetPrescription>[
          ...week.sets,
          template.copyWith(setNumber: week.sets.length + 1),
        ],
      ),
    );
  }

  void _removeSet(int index) {
    final week = _currentWeek;
    if (week.sets.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mantenha ao menos uma série.')),
      );
      return;
    }
    final updated = List<WorkoutSetPrescription>.from(week.sets)
      ..removeAt(index);
    _replaceCurrentWeek(
      week.copyWith(
        sets: <WorkoutSetPrescription>[
          for (var i = 0; i < updated.length; i++)
            updated[i].copyWith(setNumber: i + 1),
        ],
      ),
    );
  }

  Future<void> _chooseAlternatives() async {
    final selectedIds = _alternatives
        .map((alternative) => alternative.exerciseId)
        .toSet();
    final candidates = widget.availableExercises
        .where((exercise) => exercise.id != widget.exercise.id)
        .toList(growable: false);
    final result = await showModalBottomSheet<List<ExerciseAlternative>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        final selection = Set<String>.from(selectedIds);
        return StatefulBuilder(
          builder: (context, setSheetState) => SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.82,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
                  child: Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Alternativas permitidas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: candidates.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final exercise = candidates[index];
                      final selected = selection.contains(exercise.id);
                      return CheckboxListTile(
                        value: selected,
                        title: Text(
                          exercise.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(exercise.muscle),
                        onChanged: (value) {
                          setSheetState(() {
                            if (value == true) {
                              selection.add(exercise.id);
                            } else {
                              selection.remove(exercise.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext, <ExerciseAlternative>[
                          for (final exercise in candidates)
                            if (selection.contains(exercise.id))
                              ExerciseAlternative(
                                exerciseId: exercise.id,
                                name: exercise.name,
                                muscle: exercise.muscle,
                              ),
                        ]);
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('CONFIRMAR ALTERNATIVAS'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (result != null && mounted) {
      setState(() => _alternatives = result);
    }
  }

  void _save() {
    final prescription = AdvancedExercisePrescription(
      activeWeek: _activeWeek,
      weeks: _weeks,
      alternatives: _alternatives,
    );
    Navigator.pop(
      context,
      widget.exercise.copyWith(advancedPrescription: prescription),
    );
  }

  Future<void> _clearAdvancedPrescription() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Usar prescrição simples?'),
            content: const Text(
              'A periodização, os detalhes por série e as alternativas serão removidos. Séries e repetições simples continuarão preservadas.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('CANCELAR'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('REMOVER AVANÇADO'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed && mounted) {
      Navigator.pop(
        context,
        widget.exercise.copyWith(
          advancedPrescription: const AdvancedExercisePrescription(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final week = _currentWeek;
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Prescrição avançada',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Remover prescrição avançada',
            onPressed: _clearAdvancedPrescription,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.paddingOf(context).bottom + 110,
        ),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.exercise.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.exercise.reps} • ${widget.exercise.rest}',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Quantidade de semanas',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _weeks.length > 1
                          ? () => _changeWeekCount(_weeks.length - 1)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                    ),
                    Text(
                      '${_weeks.length}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      onPressed: _weeks.length < 12
                          ? () => _changeWeekCount(_weeks.length + 1)
                          : null,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'SEMANA EM EDIÇÃO',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final item in _weeks)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: item.weekNumber == _selectedWeek,
                      label: Text('${item.weekNumber}'),
                      onSelected: (_) {
                        setState(() => _selectedWeek = item.weekNumber);
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primary.withValues(alpha: 0.28)),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  week.weekNumber == _activeWeek
                      ? Icons.calendar_month_rounded
                      : Icons.edit_calendar_rounded,
                  color: primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        week.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        week.weekNumber == _activeWeek
                            ? 'Semana ativa atual. A troca é feita na tela da ficha.'
                            : 'Edite a prescrição aqui e escolha a semana ativa na tela da ficha.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Editar nome e orientações',
                  onPressed: _editWeekDetails,
                  icon: const Icon(Icons.edit_note_rounded),
                ),
              ],
            ),
          ),
          if (week.notes.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              week.notes,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'SÉRIES',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton.icon(
                onPressed: _addSet,
                icon: const Icon(Icons.add_rounded),
                label: const Text('ADICIONAR'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...week.sets.asMap().entries.map((entry) {
            final index = entry.key;
            final set = entry.value;
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
                  onTap: () => _editSet(index),
                  leading: CircleAvatar(
                    backgroundColor: primary.withValues(alpha: 0.12),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  title: Text(
                    set.target.trim().isEmpty
                        ? 'Alvo não informado'
                        : set.target,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(set.summary),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.edit_rounded, size: 20),
                      IconButton(
                        tooltip: 'Remover série',
                        onPressed: () => _removeSet(index),
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
          }),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'ALTERNATIVAS',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton.icon(
                onPressed: _chooseAlternatives,
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('ESCOLHER'),
              ),
            ],
          ),
          if (_alternatives.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Nenhuma alternativa definida. Durante esta fase o exercício será mantido como prescrito.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _alternatives
                  .map(
                    (alternative) => InputChip(
                      label: Text(alternative.name),
                      onDeleted: () {
                        setState(() {
                          _alternatives.removeWhere(
                            (item) => item.exerciseId == alternative.exerciseId,
                          );
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded),
            label: const Text('SALVAR PRESCRIÇÃO'),
          ),
        ),
      ),
    );
  }
}
