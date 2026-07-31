import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../features/exercises/domain/exercise_catalog.dart';
import '../features/workouts/presentation/providers/workout_controller.dart';
import '../theme/app_theme.dart';
import 'exercise_detail_screen.dart';

class ExercisesScreen extends ConsumerStatefulWidget {
  const ExercisesScreen({
    super.key,
    this.isSelecting = false,
    this.embedded = false,
  });

  final bool isSelecting;
  final bool embedded;

  @override
  ConsumerState<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends ConsumerState<ExercisesScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  static const List<String> _muscleOrder = <String>[
    'Peito',
    'Costas',
    'Ombros',
    'Trapézio',
    'Bíceps',
    'Antebraço',
    'Tríceps',
    'Pernas',
    'Panturrilha',
    'Abdômen',
    'Outros',
  ];

  int _compareExercises(Exercise first, Exercise second) {
    final firstMuscle = ExerciseCatalog.standardizedMuscle(first.muscle);
    final secondMuscle = ExerciseCatalog.standardizedMuscle(second.muscle);
    final firstIndex = _muscleOrder.indexOf(firstMuscle);
    final secondIndex = _muscleOrder.indexOf(secondMuscle);
    final safeFirstIndex = firstIndex < 0 ? _muscleOrder.length : firstIndex;
    final safeSecondIndex = secondIndex < 0 ? _muscleOrder.length : secondIndex;

    final muscleComparison = safeFirstIndex.compareTo(safeSecondIndex);
    if (muscleComparison != 0) {
      return muscleComparison;
    }

    return first.name.toLowerCase().compareTo(second.name.toLowerCase());
  }

  void _showExerciseConfigDialog(
    BuildContext context,
    Exercise ex,
    WorkoutController provider, {
    WorkoutRoutine? targetRoutine,
  }) {
    final repsCtrl = TextEditingController(text: ex.reps);
    final restCtrl = TextEditingController(text: ex.rest);

    String initialTechnique = 'Normal';
    if (ex.isSuperset) {
      initialTechnique = 'Bi-Set';
    } else if (ex.customNote.contains('Drop-Set')) {
      initialTechnique = 'Drop-Set';
    } else if (ex.customNote.contains('Rest-Pause')) {
      initialTechnique = 'Rest-Pause';
    } else if (ex.customNote.contains('Falha Muscular') ||
        ex.customNote.contains('Ir até a Falha')) {
      initialTechnique = 'Até a Falha';
    }

    String cleanNote = ex.customNote
        .replaceAll('Técnica: Drop-Set', '')
        .replaceAll('Drop-Set | ', '')
        .replaceAll('Técnica: Rest-Pause', '')
        .replaceAll('Rest-Pause | ', '')
        .replaceAll('Ir até a Falha Muscular', '')
        .replaceAll('Falha Muscular | ', '')
        .trim();

    final noteCtrl = TextEditingController(text: cleanNote);
    String selectedTechnique = initialTechnique;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.border),
            ),
            title: Text(
              'Configurar Exercício',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ex.name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
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
                      labelText: 'Séries e Repetições (ex: 3x 10-12)',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
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
                      labelText: 'Tempo de Descanso (ex: 60 seg)',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
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
                  const SizedBox(height: 24),

                  // TÍTULO DESTACADO PARA A OBSERVAÇÃO
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'TÉCNICA E OBSERVAÇÕES',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: selectedTechnique,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                    ),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Técnica / Método',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
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
                    items:
                        [
                          'Normal',
                          'Bi-Set',
                          'Drop-Set',
                          'Rest-Pause',
                          'Até a Falha',
                        ].map((String val) {
                          return DropdownMenuItem(
                            value: val,
                            child: Text(
                              val == 'Bi-Set'
                                  ? '🔗 Bi-Set (Ligar ao próximo)'
                                  : val,
                            ),
                          );
                        }).toList(),
                    onChanged: (val) {
                      setStateDialog(() {
                        selectedTechnique = val!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: noteCtrl,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Observação Livre (Ex: Banco no 4)',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
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
                  bool isSupersetFinal = selectedTechnique == 'Bi-Set';
                  String finalNote = noteCtrl.text.trim();

                  if (selectedTechnique == 'Drop-Set') {
                    finalNote = finalNote.isEmpty
                        ? 'Técnica: Drop-Set'
                        : 'Drop-Set | $finalNote';
                  } else if (selectedTechnique == 'Rest-Pause') {
                    finalNote = finalNote.isEmpty
                        ? 'Técnica: Rest-Pause'
                        : 'Rest-Pause | $finalNote';
                  } else if (selectedTechnique == 'Até a Falha') {
                    finalNote = finalNote.isEmpty
                        ? 'Ir até a Falha Muscular'
                        : 'Falha Muscular | $finalNote';
                  }

                  final customizedEx = Exercise(
                    id: ex.id,
                    name: ex.name,
                    muscle: ex.muscle,
                    description: ex.description,
                    reps: repsCtrl.text.trim().isEmpty
                        ? ex.reps
                        : repsCtrl.text.trim(),
                    rest: restCtrl.text.trim().isEmpty
                        ? ex.rest
                        : restCtrl.text.trim(),
                    isSuperset: isSupersetFinal,
                    customNote: finalNote,
                  );

                  if (targetRoutine != null) {
                    final updatedExercises = List<Exercise>.from(
                      targetRoutine.exercises,
                    )..add(customizedEx);
                    provider.updateRoutine(
                      targetRoutine.id,
                      targetRoutine.name,
                      targetRoutine.focus,
                      targetRoutine.groupName,
                      updatedExercises,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${ex.name} adicionado ao ${targetRoutine.name}!',
                        ),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else if (widget.isSelecting) {
                    Navigator.pop(ctx);
                    Navigator.pop(context, customizedEx);
                  }
                },
                child: const Text(
                  'Confirmar e Salvar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRoutineSelector(
    BuildContext context,
    Exercise ex,
    WorkoutController provider,
  ) {
    final routines = provider.myRoutines;

    if (routines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Você ainda não tem nenhuma ficha criada para receber este exercício.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Adicionar em qual ficha?',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.textPrimary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: routines.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final routine = routines[index];
                      final folderText = routine.groupName.isNotEmpty
                          ? 'Programa: ${routine.groupName}'
                          : 'Ficha Avulsa';

                      return ListTile(
                        tileColor: Theme.of(context).colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.border),
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.folder_open,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          routine.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          folderText,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Icon(
                          Icons.add_circle_outline,
                          color: AppColors.textSecondary,
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          _showExerciseConfigDialog(
                            context,
                            ex,
                            provider,
                            targetRoutine: routine,
                          );
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
  }

  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(workoutControllerProvider);
    final provider = ref.read(workoutControllerProvider.notifier);

    final allExercises =
        workoutState.allExercises
            .where(
              (exercise) => ExerciseCatalog.matches(exercise, _searchQuery),
            )
            .toList()
          ..sort(_compareExercises);

    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            autofocus: false,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Buscar por nome, alias ou músculo...',
              hintStyle: TextStyle(color: AppColors.textSecondary),
              prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),

              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: AppColors.textSecondary),
                      onPressed: () {
                        _searchController.clear();
                        _searchFocusNode.unfocus();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,

              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        Expanded(
          child: allExercises.isEmpty
              ? Center(
                  child: Text(
                    'Nenhum exercício encontrado.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                  itemCount: allExercises.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final ex = allExercises[index];
                    final muscle = ExerciseCatalog.standardizedMuscle(
                      ex.muscle,
                    );
                    final previousMuscle = index == 0
                        ? null
                        : ExerciseCatalog.standardizedMuscle(
                            allExercises[index - 1].muscle,
                          );
                    final showHeader = muscle != previousMuscle;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showHeader)
                          Padding(
                            padding: EdgeInsets.only(
                              left: 4,
                              top: index == 0 ? 0 : 10,
                              bottom: 8,
                            ),
                            child: Text(
                              muscle.toUpperCase(),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.9,
                              ),
                            ),
                          ),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: Image.asset(
                                  ExerciseCatalog.mediaPathFor(ex),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Center(
                                        child: Icon(
                                          Icons.fitness_center,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          size: 24,
                                        ),
                                      ),
                                ),
                              ),
                            ),
                            title: Text(
                              ex.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              ExerciseCatalog.standardizedMuscle(
                                ex.muscle,
                              ).toUpperCase(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            trailing: widget.isSelecting
                                ? Icon(
                                    Icons.add_circle,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.add_circle_outline,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                        onPressed: () {
                                          _searchFocusNode.unfocus();
                                          _showRoutineSelector(
                                            context,
                                            ex,
                                            provider,
                                          );
                                        },
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                            onTap: () {
                              _searchFocusNode.unfocus();
                              FocusScope.of(context).unfocus();

                              if (widget.isSelecting) {
                                _showExerciseConfigDialog(
                                  context,
                                  ex,
                                  provider,
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ExerciseDetailScreen(exercise: ex),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );

    final body = widget.embedded && !widget.isSelecting
        ? ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: content,
          )
        : Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              title: Text(
                widget.isSelecting
                    ? 'Adicionar ao Treino'
                    : 'Biblioteca de Exercícios',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
            body: content,
          );

    return GestureDetector(onTap: _searchFocusNode.unfocus, child: body);
  }
}
