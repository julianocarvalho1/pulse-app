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
  late int _storedActiveWeek;

  @override
  void initState() {
    super.initState();
    final existing = widget.exercise.advancedPrescription;
    if (existing.weeks.isEmpty) {
      _weeks = <WorkoutWeekPrescription>[_legacyWeek(widget.exercise)];
      _storedActiveWeek = 1;
    } else {
      _weeks = List<WorkoutWeekPrescription>.from(existing.weeks)
        ..sort((a, b) => a.weekNumber.compareTo(b.weekNumber));
      _storedActiveWeek = existing.activeWeek;
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

  WorkoutWeekPrescription get _currentWeek => _weeks.first;

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
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: targetController,
                  decoration: const InputDecoration(
                    labelText: 'Alvo da série',
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
                          labelText: 'Esforço (RIR)',
                          hintText: '0–5',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'RIR é quantas repetições ainda sobrariam antes da falha. Ex.: RIR 2 = você conseguiria fazer mais 2.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cadenceController,
                  decoration: const InputDecoration(
                    labelText: 'Cadência (opcional)',
                    hintText: 'Ex.: 3-1-1-0',
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Cadência descreve o tempo de cada fase do movimento. Ex.: 3-1-1-0.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<WorkoutTechnique>(
                  initialValue: technique,
                  decoration: const InputDecoration(
                    labelText: 'Técnica (opcional)',
                  ),
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
              child: const Text('Cancelar'),
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
              child: const Text('Salvar'),
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
    final searchController = TextEditingController();
    var query = '';

    final result = await showModalBottomSheet<List<ExerciseAlternative>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        final selection = Set<String>.from(selectedIds);
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final normalizedQuery = query.trim().toLowerCase();
            final filtered = candidates
                .where((exercise) {
                  if (normalizedQuery.isEmpty) {
                    return true;
                  }
                  return exercise.name.toLowerCase().contains(
                        normalizedQuery,
                      ) ||
                      exercise.muscle.toLowerCase().contains(normalizedQuery);
                })
                .toList(growable: false);

            return SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.86,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                    child: Row(
                      children: <Widget>[
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Alternativas permitidas',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Escolha exercícios que podem substituir o atual.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Fechar',
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                    child: TextField(
                      controller: searchController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Buscar por exercício ou músculo',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Limpar busca',
                                onPressed: () {
                                  searchController.clear();
                                  setSheetState(() => query = '');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                      onChanged: (value) => setSheetState(() => query = value),
                    ),
                  ),
                  if (selection.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${selection.length} selecionada${selection.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 42,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Nenhum exercício encontrado',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tente outro nome ou grupo muscular.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final exercise = filtered[index];
                              final selected = selection.contains(exercise.id);
                              return CheckboxListTile(
                                value: selected,
                                controlAffinity:
                                    ListTileControlAffinity.trailing,
                                title: Text(
                                  exercise.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
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
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
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
                          label: const Text('Confirmar alternativas'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    searchController.dispose();
    if (result != null && mounted) {
      setState(() => _alternatives = result);
    }
  }

  void _save() {
    final prescription = AdvancedExercisePrescription(
      activeWeek: _storedActiveWeek,
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
              'Os detalhes por série, RIR, cadência, técnicas e alternativas serão removidos. Séries e repetições simples continuarão preservadas.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Remover detalhes'),
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
          'Detalhes da prescrição',
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
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                Text(
                  'Configure cada série com alvo, descanso, RIR, cadência e técnica. Você também pode indicar exercícios alternativos.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
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
                label: const Text('Adicionar'),
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
                label: const Text('Escolher'),
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
                'Nenhuma alternativa definida. O exercício original será usado no treino.',
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
            label: const Text('Salvar prescrição'),
          ),
        ),
      ),
    );
  }
}
