import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../features/exercises/domain/exercise_catalog.dart';
import '../features/workouts/domain/models/cardio_log.dart';
import '../features/workouts/presentation/providers/workout_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/routine_type_selector.dart';

// ============================================================
//  TELA: CONSTRUTOR DO PROGRAMA (PASSO 2)
// ============================================================

class ProgramBuilderScreen extends ConsumerStatefulWidget {
  final String programName;
  final String programFocus;
  final String splitType;
  final RoutineType defaultRoutineType;

  const ProgramBuilderScreen({
    super.key,
    required this.programName,
    required this.programFocus,
    required this.splitType,
    this.defaultRoutineType = RoutineType.strength,
  });

  @override
  ConsumerState<ProgramBuilderScreen> createState() =>
      _ProgramBuilderScreenState();
}

class _ProgramBuilderScreenState extends ConsumerState<ProgramBuilderScreen> {
  final List<WorkoutRoutine> _draftRoutines = [];
  final Map<String, RoutineType> _draftTypes = <String, RoutineType>{};

  @override
  void initState() {
    super.initState();
    _generateDraftRoutines();
  }

  void _generateDraftRoutines() {
    List<String> routineNames = [];
    if (widget.splitType == 'Full Body') {
      routineNames = ['Treino Único'];
    } else if (widget.splitType == 'AB') {
      routineNames = ['Treino A', 'Treino B'];
    } else if (widget.splitType == 'ABC') {
      routineNames = ['Treino A', 'Treino B', 'Treino C'];
    } else if (widget.splitType == 'ABCD') {
      routineNames = ['Treino A', 'Treino B', 'Treino C', 'Treino D'];
    } else if (widget.splitType == 'ABCDE') {
      routineNames = [
        'Treino A',
        'Treino B',
        'Treino C',
        'Treino D',
        'Treino E',
      ];
    }

    for (var index = 0; index < routineNames.length; index++) {
      final name = routineNames[index];
      final id =
          '${DateTime.now().microsecondsSinceEpoch}_${index}_${name.hashCode}';
      _draftRoutines.add(
        WorkoutRoutine(
          id: id,
          name: name,
          focus: widget.programFocus,
          groupName: widget.programName,
          exercises: const <Exercise>[],
        ),
      );
      _draftTypes[id] = widget.defaultRoutineType;
    }
  }

  void _showCustomExerciseDialog(int routineIndex) {
    final customNameCtrl = TextEditingController();
    final customMuscleCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Criar Novo Exercício',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: customNameCtrl,
              style: TextStyle(color: AppColors.textPrimary),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nome do exercício/aparelho',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: customMuscleCtrl,
              style: TextStyle(color: AppColors.textPrimary),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Foco (ex: Costas, LPO, Cardio)',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () {
              if (customNameCtrl.text.trim().isNotEmpty) {
                String name = customNameCtrl.text.trim();
                String muscle = customMuscleCtrl.text.trim().isEmpty
                    ? 'Geral'
                    : customMuscleCtrl.text.trim();

                ref
                    .read(workoutControllerProvider.notifier)
                    .createCustomExercise(name, muscle);
                Navigator.pop(ctx);

                final newEx = Exercise(
                  id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  muscle: muscle,
                  description: '',
                  reps: '3x 10-12',
                  rest: '60 seg',
                );

                _showExerciseConfigDialog(routineIndex, newEx);
              }
            },
            child: const Text(
              'Criar e Inserir',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  void _showExerciseConfigDialog(
    int routineIndex,
    Exercise ex, {
    int? editIndex,
  }) {
    String cleanReps = ex.reps
        .replaceAll(RegExp(r'\s*\+\s*DROPSET', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*\+\s*BISET', caseSensitive: false), '');

    final repsCtrl = TextEditingController(text: cleanReps);
    final restCtrl = TextEditingController(text: ex.rest);
    final obsCtrl = TextEditingController(
      text: editIndex != null ? ex.description : '',
    );

    bool isDropset = ex.reps.toUpperCase().contains('DROPSET');

    final draftExercises = _draftRoutines[routineIndex].exercises;
    final currentIndex = editIndex ?? draftExercises.length;
    final hasExerciseAbove = currentIndex > 0;
    final continuesExistingBiset =
        hasExerciseAbove && draftExercises[currentIndex - 1].isSuperset;
    final previousAlreadyContinuesBiset =
        currentIndex > 1 && draftExercises[currentIndex - 2].isSuperset;
    final currentStartsBiset = editIndex != null && ex.isSuperset;
    final hasLegacyBisetMarker = ex.reps.toUpperCase().contains('BISET');

    bool isBiset = continuesExistingBiset || hasLegacyBisetMarker;

    // Um bi-set é representado pelo exercício de cima apontando para este.
    // Evita que o mesmo exercício participe de dois bi-sets ao mesmo tempo.
    final bool canBiset =
        hasExerciseAbove &&
        (isBiset || (!previousAlreadyContinuesBiset && !currentStartsBiset));

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.border),
              ),
              title: Text(
                editIndex == null
                    ? 'Configurar Exercício'
                    : 'Editar Configuração',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              content: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex.name,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextField(
                      controller: repsCtrl,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Séries e Reps (ex: 4x 15-12-10)',
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.background,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: restCtrl,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Descanso (ex: 60 seg)',
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.background,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: obsCtrl,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Observações (ex: Falha nas últimas)',
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.background,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // SWITCH DE BI-SET (UNIR EXERCÍCIOS)
                    if (canBiset)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orangeAccent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: SwitchListTile(
                          title: const Text(
                            'Bi-set (Super-série)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orangeAccent,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            'Unir com o exercício de cima',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          activeThumbColor: Colors.orangeAccent,
                          value: isBiset,
                          onChanged: (val) {
                            setStateDialog(() {
                              isBiset = val;
                              if (val) {
                                // Evita combinar bi-set e dropset na mesma configuração.
                                isDropset = false;
                              }
                            });
                          },
                        ),
                      ),

                    // SWITCH DE DROPSET
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: SwitchListTile(
                        title: Text(
                          'Dropset',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'Reduzir carga na última série',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        activeThumbColor: Theme.of(context).colorScheme.primary,
                        value: isDropset,
                        onChanged: (val) {
                          setStateDialog(() {
                            isDropset = val;
                            if (val) isBiset = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: AppColors.onPrimary,
                  ),
                  onPressed: () {
                    String finalReps = repsCtrl.text.trim().isEmpty
                        ? ex.reps
                        : repsCtrl.text.trim();
                    if (isDropset &&
                        !finalReps.toUpperCase().contains('DROPSET')) {
                      finalReps += ' + DROPSET';
                    }
                    finalReps = finalReps
                        .replaceAll(
                          RegExp(r'\s*\+\s*BISET', caseSensitive: false),
                          '',
                        )
                        .trim();

                    final customizedEx = ex.copyWith(
                      description: obsCtrl.text.trim(),
                      reps: finalReps,
                      rest: restCtrl.text.trim().isEmpty
                          ? ex.rest
                          : restCtrl.text.trim(),
                      // Ao adicionar um exercício, ele começa sem apontar para
                      // o próximo. A ligação com o exercício de cima é salva
                      // no exercício anterior.
                      isSuperset: editIndex == null ? false : ex.isSuperset,
                    );

                    setState(() {
                      final routine = _draftRoutines[routineIndex];

                      final updatedExercises = List<Exercise>.from(
                        routine.exercises,
                      );
                      final targetIndex = editIndex ?? updatedExercises.length;

                      if (targetIndex > 0) {
                        final previousExercise =
                            updatedExercises[targetIndex - 1];
                        updatedExercises[targetIndex - 1] = previousExercise
                            .copyWith(isSuperset: isBiset);
                      }

                      if (editIndex == null) {
                        updatedExercises.add(customizedEx);
                      } else {
                        updatedExercises[editIndex] = customizedEx;
                      }

                      _draftRoutines[routineIndex] = routine.copyWith(
                        exercises: updatedExercises,
                      );
                    });

                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Salvar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showExerciseSelector(int routineIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String searchQuery = '';

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final allExercises =
                ref
                    .read(workoutControllerProvider)
                    .allExercises
                    .where(
                      (exercise) =>
                          ExerciseCatalog.matches(exercise, searchQuery),
                    )
                    .toList()
                  ..sort(
                    (first, second) => first.name.toLowerCase().compareTo(
                      second.name.toLowerCase(),
                    ),
                  );

            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.9,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Adicionar à ficha',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        style: TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Buscar exercício...',
                          hintStyle: TextStyle(color: AppColors.textSecondary),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setModalState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showCustomExerciseDialog(routineIndex);
                          },
                          icon: const Icon(Icons.add),
                          label: const Text(
                            'CRIAR EXERCÍCIO MANUAL',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Expanded(
                      child: allExercises.isEmpty
                          ? Center(
                              child: Text(
                                'Nenhum exercício encontrado.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          : ListView.separated(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: allExercises.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final ex = allExercises[index];
                                return ListTile(
                                  tileColor: AppColors.surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  title: Text(
                                    ex.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    ExerciseCatalog.standardizedMuscle(
                                      ex.muscle,
                                    ),
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.add_circle,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _showExerciseConfigDialog(routineIndex, ex);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _updateDraftIdentity(int routineIndex, {String? name, String? focus}) {
    final current = _draftRoutines[routineIndex];
    _draftRoutines[routineIndex] = current.copyWith(
      name: name ?? current.name,
      focus: focus ?? current.focus,
    );
  }

  Future<void> _changeDraftType(int routineIndex, RoutineType nextType) async {
    final routine = _draftRoutines[routineIndex];
    final currentType = _draftTypes[routine.id] ?? routine.type;
    if (currentType == nextType) {
      return;
    }

    if (nextType == RoutineType.cardio && routine.exercises.isNotEmpty) {
      final confirmed = await _confirmContentRemoval(
        title: 'Remover musculação desta ficha?',
        message:
            'Ao escolher Cardio, os exercícios de musculação desta ficha serão removidos.',
      );
      if (!confirmed || !mounted) {
        return;
      }
      setState(() {
        _draftTypes[routine.id] = nextType;
        _draftRoutines[routineIndex] = routine.copyWith(
          exercises: const <Exercise>[],
        );
      });
      return;
    }

    if (nextType == RoutineType.strength && routine.cardio.isNotEmpty) {
      final confirmed = await _confirmContentRemoval(
        title: 'Remover cardio desta ficha?',
        message:
            'Ao escolher Musculação, as etapas de cardio desta ficha serão removidas.',
      );
      if (!confirmed || !mounted) {
        return;
      }
      setState(() {
        _draftTypes[routine.id] = nextType;
        _draftRoutines[routineIndex] = routine.copyWith(
          cardio: const <RoutineCardio>[],
        );
      });
      return;
    }

    setState(() => _draftTypes[routine.id] = nextType);
  }

  Future<bool> _confirmContentRemoval({
    required String title,
    required String message,
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
                child: const Text('REMOVER'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _editDraftCardio(
    int routineIndex, {
    RoutineCardio? existing,
  }) async {
    var modality = existing?.modality ?? CardioModality.treadmill;
    final durationController = TextEditingController(
      text: existing?.plannedDurationMinutes.toString() ?? '20',
    );
    final notesController = TextEditingController(text: existing?.notes ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<RoutineCardio>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            MediaQuery.viewInsetsOf(context).bottom +
                MediaQuery.paddingOf(context).bottom +
                20,
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          existing == null
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
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<CardioModality>(
                    initialValue: modality,
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
                        setSheetState(() => modality = value);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: durationController,
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
                    controller: notesController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Orientação opcional',
                      hintText: 'Ex.: ritmo moderado após a musculação',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (!(formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        Navigator.pop(
                          sheetContext,
                          RoutineCardio(
                            id:
                                existing?.id ??
                                'routine_cardio_${DateTime.now().microsecondsSinceEpoch}',
                            modality: modality,
                            plannedDurationMinutes: int.parse(
                              durationController.text.trim(),
                            ),
                            notes: notesController.text.trim(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('SALVAR CARDIO'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    durationController.dispose();
    notesController.dispose();

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      final routine = _draftRoutines[routineIndex];
      final updated = List<RoutineCardio>.from(routine.cardio);
      final existingIndex = updated.indexWhere((item) => item.id == result.id);
      if (existingIndex >= 0) {
        updated[existingIndex] = result;
      } else {
        updated.add(result);
      }
      _draftRoutines[routineIndex] = routine.copyWith(cardio: updated);
    });
  }

  void _saveProgram() {
    for (final routine in _draftRoutines) {
      final type = _draftTypes[routine.id] ?? routine.type;
      if (routine.name.trim().isEmpty) {
        _showBuilderMessage('Todas as fichas precisam de um nome.');
        return;
      }
      if (type.includesStrength && routine.exercises.isEmpty) {
        _showBuilderMessage(
          'Adicione ao menos um exercício em ${routine.name}.',
        );
        return;
      }
      if (type.includesCardio && routine.cardio.isEmpty) {
        _showBuilderMessage(
          'Adicione ao menos uma etapa de cardio em ${routine.name}.',
        );
        return;
      }
    }

    final provider = ref.read(workoutControllerProvider.notifier);

    for (final routine in _draftRoutines) {
      final type = _draftTypes[routine.id] ?? routine.type;
      provider.createRoutine(
        routine.name.trim(),
        routine.focus.trim().isEmpty ? 'Geral' : routine.focus.trim(),
        routine.groupName,
        type.includesStrength ? routine.exercises : const <Exercise>[],
        cardio: type.includesCardio ? routine.cardio : const <RoutineCardio>[],
      );
    }

    Navigator.popUntil(context, (route) => route.isFirst);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Programa ${widget.programName} salvo com sucesso!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showBuilderMessage(String message) {
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
        elevation: 0,
        title: Text(
          widget.programName,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.paddingOf(context).bottom + 110,
        ),
        itemCount: _draftRoutines.length,
        separatorBuilder: (_, _) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          final routine = _draftRoutines[index];
          final type = _draftTypes[routine.id] ?? routine.type;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'FICHA ${index + 1}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            type.label,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: ValueKey<String>('name-${routine.id}'),
                  initialValue: routine.name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome da ficha',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                  onChanged: (value) {
                    _updateDraftIdentity(index, name: value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: ValueKey<String>('focus-${routine.id}'),
                  initialValue: routine.focus,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Foco ou objetivo',
                    prefixIcon: Icon(Icons.track_changes_rounded),
                  ),
                  onChanged: (value) {
                    _updateDraftIdentity(index, focus: value);
                  },
                ),
                const SizedBox(height: 20),
                RoutineTypeSelector(
                  value: type,
                  onChanged: (value) => _changeDraftType(index, value),
                ),
                if (type.includesStrength) ...<Widget>[
                  const SizedBox(height: 24),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'MUSCULAÇÃO',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      Text(
                        '${routine.exercises.length} exercício${routine.exercises.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (routine.exercises.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        'Adicione os exercícios de musculação desta ficha.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    )
                  else
                    ...routine.exercises.asMap().entries.map((entry) {
                      final exerciseIndex = entry.key;
                      final exercise = entry.value;
                      final isDropset = exercise.reps.toUpperCase().contains(
                        'DROPSET',
                      );
                      final isBiset =
                          exercise.isSuperset ||
                          (exerciseIndex > 0 &&
                              routine.exercises[exerciseIndex - 1].isSuperset);
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
                            title: Text(
                              exercise.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${ExerciseCatalog.standardizedMuscle(exercise.muscle)} • ${exercise.reps} • ${exercise.rest}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            leading: isBiset || isDropset
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDropset
                                          ? Colors.redAccent.withValues(
                                              alpha: 0.14,
                                            )
                                          : Colors.orangeAccent.withValues(
                                              alpha: 0.18,
                                            ),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Text(
                                      isDropset ? 'DROP' : 'BI',
                                      style: TextStyle(
                                        color: isDropset
                                            ? Colors.redAccent
                                            : Colors.orange.shade800,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.fitness_center_rounded,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                IconButton(
                                  tooltip: 'Editar exercício',
                                  onPressed: () => _showExerciseConfigDialog(
                                    index,
                                    exercise,
                                    editIndex: exerciseIndex,
                                  ),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Remover exercício',
                                  onPressed: () {
                                    setState(() {
                                      final current = _draftRoutines[index];
                                      final updated = List<Exercise>.from(
                                        current.exercises,
                                      );
                                      if (exerciseIndex > 0 &&
                                          updated[exerciseIndex - 1]
                                              .isSuperset) {
                                        updated[exerciseIndex -
                                            1] = updated[exerciseIndex - 1]
                                            .copyWith(isSuperset: false);
                                      }
                                      updated.removeAt(exerciseIndex);
                                      if (updated.isNotEmpty &&
                                          updated.last.isSuperset) {
                                        updated[updated.length - 1] = updated
                                            .last
                                            .copyWith(isSuperset: false);
                                      }
                                      _draftRoutines[index] = current.copyWith(
                                        exercises: updated,
                                      );
                                    });
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
                    }),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showExerciseSelector(index),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('ADICIONAR EXERCÍCIO'),
                    ),
                  ),
                ],
                if (type.includesCardio) ...<Widget>[
                  const SizedBox(height: 24),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'CARDIO',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      Text(
                        '${routine.cardio.length} etapa${routine.cardio.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (routine.cardio.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        type == RoutineType.mixed
                            ? 'Adicione o cardio que será feito após a musculação.'
                            : 'Adicione as atividades de cardio desta ficha.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    )
                  else
                    ...routine.cardio.asMap().entries.map((entry) {
                      final cardioIndex = entry.key;
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
                            onTap: () =>
                                _editDraftCardio(index, existing: cardio),
                            leading: Icon(
                              Icons.directions_run_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(
                              cardio.modality.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${cardio.plannedDurationMinutes} min planejados',
                            ),
                            trailing: IconButton(
                              tooltip: 'Remover cardio',
                              onPressed: () {
                                setState(() {
                                  final current = _draftRoutines[index];
                                  final updated = List<RoutineCardio>.from(
                                    current.cardio,
                                  )..removeAt(cardioIndex);
                                  _draftRoutines[index] = current.copyWith(
                                    cardio: updated,
                                  );
                                });
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
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _editDraftCardio(index),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('ADICIONAR CARDIO'),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.viewPaddingOf(context).bottom + 16,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: AppColors.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _saveProgram,
          child: const Text(
            'SALVAR PROGRAMA COMPLETO',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
      ),
    );
  }
}
