import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../features/exercises/domain/exercise_catalog.dart';
import '../features/exercises/presentation/widgets/exercise_media_view.dart';
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
  String _selectedMuscle = 'Todos';
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

  Future<void> _showCreateCustomExerciseDialog(
    WorkoutController provider,
  ) async {
    _searchFocusNode.unfocus();

    final exercise = await showDialog<Exercise>(
      context: context,
      builder: (dialogContext) => _CreateCustomExerciseDialog(
        provider: provider,
        isSelecting: widget.isSelecting,
        muscles: _muscleOrder,
      ),
    );

    if (!mounted || exercise == null) {
      return;
    }

    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedMuscle = 'Personalizados';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${exercise.name} foi salvo na sua biblioteca.'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (widget.isSelecting) {
      _showExerciseConfigDialog(context, exercise, provider);
    }
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

  Widget _buildExerciseCard(
    BuildContext context,
    Exercise exercise,
    WorkoutController provider,
  ) {
    final muscle = ExerciseCatalog.standardizedMuscle(exercise.muscle);
    final isCustom = exercise.id.startsWith('custom_');
    final primary = Theme.of(context).colorScheme.primary;

    void openExercise() {
      _searchFocusNode.unfocus();
      FocusScope.of(context).unfocus();

      if (widget.isSelecting) {
        _showExerciseConfigDialog(context, exercise, provider);
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExerciseDetailScreen(exercise: exercise),
        ),
      );
    }

    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: openExercise,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
          child: Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: ExerciseMediaView(
                  exercise: exercise,
                  fit: BoxFit.cover,
                  placeholderBuilder: (context) => Center(
                    child: Icon(
                      Icons.fitness_center_rounded,
                      color: primary,
                      size: 23,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      exercise.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        isCustom ? 'Personalizado • $muscle' : muscle,
                        style: TextStyle(
                          color: primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (widget.isSelecting)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: AppColors.onPrimary,
                    size: 22,
                  ),
                )
              else
                IconButton.filledTonal(
                  tooltip: 'Adicionar à ficha',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    _searchFocusNode.unfocus();
                    _showRoutineSelector(context, exercise, provider);
                  },
                  icon: const Icon(Icons.add_rounded, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(
    BuildContext context,
    WorkoutController provider,
  ) {
    final primary = Theme.of(context).colorScheme.primary;
    final filters = <String>['Todos', 'Personalizados', ..._muscleOrder];

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            autofocus: false,
            textInputAction: TextInputAction.search,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Buscar exercício ou músculo',
              hintStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
                size: 21,
              ),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar busca',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        _searchController.clear();
                        _searchFocusNode.unfocus();
                        setState(() => _searchQuery = '');
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
              isDense: true,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide(color: primary, width: 1.4),
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('createCustomExerciseButton'),
              onPressed: () => _showCreateCustomExerciseDialog(provider),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Criar exercício personalizado'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 7),
              itemBuilder: (context, index) {
                final filter = filters[index];
                final selected = filter == _selectedMuscle;

                return FilterChip(
                  selected: selected,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 3),
                  side: BorderSide(
                    color: selected ? primary : AppColors.border,
                  ),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  selectedColor: primary.withValues(alpha: 0.14),
                  label: Text(
                    filter,
                    style: TextStyle(
                      color: selected ? primary : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  onSelected: (_) {
                    _searchFocusNode.unfocus();
                    setState(() => _selectedMuscle = filter);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(workoutControllerProvider);
    final provider = ref.read(workoutControllerProvider.notifier);

    final allExercises = workoutState.allExercises.where((exercise) {
      if (!ExerciseCatalog.matches(exercise, _searchQuery)) {
        return false;
      }

      if (_selectedMuscle == 'Todos') {
        return true;
      }

      if (_selectedMuscle == 'Personalizados') {
        return exercise.id.startsWith('custom_');
      }

      return ExerciseCatalog.standardizedMuscle(exercise.muscle) ==
          _selectedMuscle;
    }).toList()..sort(_compareExercises);

    final content = Column(
      children: <Widget>[
        _buildSearchAndFilters(context, provider),
        Divider(height: 1, color: AppColors.border),
        Expanded(
          child: allExercises.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.search_off_rounded,
                          size: 40,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Nenhum exercício encontrado',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tente outro nome ou escolha outro grupo muscular.',
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
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
                  itemCount: allExercises.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _buildExerciseCard(
                    context,
                    allExercises[index],
                    provider,
                  ),
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
              toolbarHeight: 54,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: !widget.isSelecting,
              leading: widget.isSelecting
                  ? IconButton(
                      tooltip: 'Voltar',
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  : null,
              titleSpacing: 0,
              title: Text(
                widget.isSelecting
                    ? 'Escolher exercício'
                    : 'Biblioteca de exercícios',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            ),
            body: content,
          );

    return GestureDetector(onTap: _searchFocusNode.unfocus, child: body);
  }
}

class _CreateCustomExerciseDialog extends StatefulWidget {
  const _CreateCustomExerciseDialog({
    required this.provider,
    required this.isSelecting,
    required this.muscles,
  });

  final WorkoutController provider;
  final bool isSelecting;
  final List<String> muscles;

  @override
  State<_CreateCustomExerciseDialog> createState() =>
      _CreateCustomExerciseDialogState();
}

class _CreateCustomExerciseDialogState
    extends State<_CreateCustomExerciseDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _repsController = TextEditingController(
    text: '3x 10-12',
  );
  final TextEditingController _restController = TextEditingController(
    text: '60 seg',
  );
  String _selectedMuscle = 'Outros';
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _repsController.dispose();
    _restController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Informe um nome para o exercício.');
      return;
    }

    final created = widget.provider.createCustomExercise(
      name,
      _selectedMuscle,
      description: _descriptionController.text,
      reps: _repsController.text,
      rest: _restController.text,
    );
    Navigator.pop(context, created);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Criar exercício personalizado'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              key: const Key('customExerciseNameField'),
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              maxLength: 80,
              decoration: InputDecoration(
                labelText: 'Nome do exercício *',
                hintText: 'Ex.: Remada no aparelho da academia',
                errorText: _nameError,
              ),
              onChanged: (_) {
                if (_nameError != null) {
                  setState(() => _nameError = null);
                }
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: const Key('customExerciseMuscleField'),
              initialValue: _selectedMuscle,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Grupo muscular'),
              items: widget.muscles
                  .map(
                    (muscle) => DropdownMenuItem<String>(
                      value: muscle,
                      child: Text(muscle),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedMuscle = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 240,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Como executar (opcional)',
                hintText: 'Uma instrução curta para você lembrar',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    maxLength: 30,
                    decoration: const InputDecoration(
                      labelText: 'Séries/repetições',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _restController,
                    maxLength: 30,
                    decoration: const InputDecoration(labelText: 'Descanso'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('saveCustomExerciseButton'),
          onPressed: _save,
          child: Text(widget.isSelecting ? 'Criar e usar' : 'Criar'),
        ),
      ],
    );
  }
}
