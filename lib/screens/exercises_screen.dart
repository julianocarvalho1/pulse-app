import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../providers/workout_provider.dart';
import '../theme/app_theme.dart';
import 'exercise_detail_screen.dart';

class ExercisesScreen extends StatefulWidget {
  final bool isSelecting;

  const ExercisesScreen({super.key, this.isSelecting = false});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String _getImagePath(String exerciseName) {
    String cleanName = exerciseName.toLowerCase().trim();

    final Map<String, String> aliases = {
      'crucifixo com halteres': 'crucifixo_reto',
      'crucifixo maquina': 'peck_deck_voador',
      'encolhimento no smith': 'encolhimento_na_barra_smith',
      'elevacao frontal com barra': 'elevacao_frontal_com_barra_anilha',
      'pull-down na polia': 'pull_down_na_polia',
      'passada / afundo': 'passada_afundo',
      'puxada na frente': 'puxada_frontal_aberta',
      'remada curvada': 'remada_curvada_com_barra',
      'rosca direta': 'rosca_direta_com_barra',
      'agachamento': 'agachamento_livre',
      'leg press': 'leg_press_45',
      'cadeira extensora': 'cadeira_extensora',
      'crunch abdominal': 'abdominal_supra',
      'rosca scott': 'rosca_scott_maquina_livre',
      'desenvolvimento militar': 'desenvolvimento_com_barra',
      'chest press': 'supino_reto_com_barra',
      'remada sentada': 'remada_baixa_sentada',
      'remada baixa': 'remada_baixa_sentada',
    };

    String nameForAlias = cleanName
        .replaceAll(RegExp(r'[áàâã]'), 'a')
        .replaceAll(RegExp(r'[éèê]'), 'e')
        .replaceAll(RegExp(r'[íìî]'), 'i')
        .replaceAll(RegExp(r'[óòôõ]'), 'o')
        .replaceAll(RegExp(r'[úùû]'), 'u')
        .replaceAll('ç', 'c');

    if (aliases.containsKey(nameForAlias)) {
      return 'assets/images/${aliases[nameForAlias]}.gif';
    }

    cleanName = cleanName.replaceAll('-', '_');
    cleanName = cleanName.replaceAll('/', '_');
    cleanName = cleanName.replaceAll(RegExp(r'[áàâã]'), 'a');
    cleanName = cleanName.replaceAll(RegExp(r'[éèê]'), 'e');
    cleanName = cleanName.replaceAll(RegExp(r'[íìî]'), 'i');
    cleanName = cleanName.replaceAll(RegExp(r'[óòôõ]'), 'o');
    cleanName = cleanName.replaceAll(RegExp(r'[úùû]'), 'u');
    cleanName = cleanName.replaceAll('ç', 'c');
    cleanName = cleanName.replaceAll(RegExp(r'[^a-z0-9_\s]'), '');
    cleanName = cleanName.trim().replaceAll(RegExp(r'\s+'), '_');
    cleanName = cleanName.replaceAll('__', '_');

    return 'assets/images/$cleanName.gif';
  }

  void _showExerciseConfigDialog(
    BuildContext context,
    Exercise ex,
    WorkoutProvider provider, {
    WorkoutRoutine? targetRoutine,
  }) {
    final repsCtrl = TextEditingController(text: ex.reps);
    final restCtrl = TextEditingController(text: ex.rest);

    String initialTechnique = 'Normal';
    if (ex.isSuperset)
      initialTechnique = 'Bi-Set';
    else if (ex.customNote.contains('Drop-Set'))
      initialTechnique = 'Drop-Set';
    else if (ex.customNote.contains('Rest-Pause'))
      initialTechnique = 'Rest-Pause';
    else if (ex.customNote.contains('Falha Muscular') ||
        ex.customNote.contains('Ir até a Falha'))
      initialTechnique = 'Até a Falha';

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
              side: const BorderSide(color: AppColors.border),
            ),
            title: const Text(
              'Configurar Exercício',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Séries e Repetições (ex: 3x 10-12)',
                      labelStyle: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Tempo de Descanso (ex: 60 seg)',
                      labelStyle: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
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
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: selectedTechnique,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Técnica / Método',
                      labelStyle: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
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
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Observação Livre (Ex: Banco no 4)',
                      labelStyle: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
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
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.black,
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
    WorkoutProvider provider,
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
                      const Text(
                        'Adicionar em qual ficha?',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
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
                          side: const BorderSide(color: AppColors.border),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          folderText,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(
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
    final provider = context.watch<WorkoutProvider>();

    final allExercises = provider.allExercises.where((ex) {
      return ex.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ex.muscle.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return GestureDetector(
      onTap: () {
        _searchFocusNode.unfocus();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          title: Text(
            widget.isSelecting
                ? 'Adicionar ao Treino'
                : 'Biblioteca de Exercícios',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: false,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar por nome ou músculo...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                  ),

                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: AppColors.textSecondary,
                          ),
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
                    borderSide: const BorderSide(color: AppColors.border),
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
                  ? const Center(
                      child: Text(
                        'Nenhum exercício encontrado.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      itemCount: allExercises.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ex = allExercises[index];
                        return Container(
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
                                  _getImagePath(ex.name),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              ex.muscle.toUpperCase(),
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
                                      const Icon(
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
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
