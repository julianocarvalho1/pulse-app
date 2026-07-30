import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../providers/workout_provider.dart';
import '../theme/app_theme.dart';

// ============================================================
//  TELA: CONSTRUTOR DO PROGRAMA (PASSO 2)
// ============================================================

class ProgramBuilderScreen extends StatefulWidget {
  final String programName;
  final String programFocus;
  final String splitType;

  const ProgramBuilderScreen({
    super.key,
    required this.programName,
    required this.programFocus,
    required this.splitType,
  });

  @override
  State<ProgramBuilderScreen> createState() => _ProgramBuilderScreenState();
}

class _ProgramBuilderScreenState extends State<ProgramBuilderScreen> {
  final List<WorkoutRoutine> _draftRoutines = [];

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

    for (var name in routineNames) {
      _draftRoutines.add(
        WorkoutRoutine(
          id: DateTime.now().millisecondsSinceEpoch.toString() + name,
          name: name,
          focus: widget.programFocus,
          groupName: widget.programName,
          exercises: [],
        ),
      );
    }
  }

  void _showCustomExerciseDialog(int routineIndex) {
    final customNameCtrl = TextEditingController();
    final customMuscleCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Criar Novo Exercício',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: customNameCtrl,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nome do exercício/aparelho',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                enabledBorder: const UnderlineInputBorder(
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
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Foco (ex: Costas, LPO, Cardio)',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                enabledBorder: const UnderlineInputBorder(
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
              if (customNameCtrl.text.trim().isNotEmpty) {
                String name = customNameCtrl.text.trim();
                String muscle = customMuscleCtrl.text.trim().isEmpty
                    ? 'Geral'
                    : customMuscleCtrl.text.trim();

                context.read<WorkoutProvider>().createCustomExercise(
                  name,
                  muscle,
                );
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
    bool isBiset = ex.reps.toUpperCase().contains('BISET');

    // Só podemos fazer bi-set se já existir um exercício antes dele
    bool canBiset =
        (editIndex != null && editIndex > 0) ||
        (editIndex == null &&
            _draftRoutines[routineIndex].exercises.isNotEmpty);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              title: Text(
                editIndex == null
                    ? 'Configurar Exercício'
                    : 'Editar Configuração',
                style: const TextStyle(
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
                        fontSize: 16,
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
                        labelText: 'Séries e Reps (ex: 4x 15-12-10)',
                        labelStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
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
                        labelText: 'Descanso (ex: 60 seg)',
                        labelStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
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
                      controller: obsCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Observações (ex: Falha nas últimas)',
                        labelStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
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

                    // SWITCH DE BI-SET (UNIR EXERCÍCIOS)
                    if (canBiset)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orangeAccent.withOpacity(0.5),
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
                          subtitle: const Text(
                            'Unir com o exercício de cima',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          activeColor: Colors.orangeAccent,
                          value: isBiset,
                          onChanged: (val) {
                            setStateDialog(() {
                              isBiset = val;
                              if (val)
                                isDropset =
                                    false; // Se for bi-set, desmarca dropset pra não confundir
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
                        title: const Text(
                          'Dropset',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: const Text(
                          'Reduzir carga na última série',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        activeColor: Theme.of(context).colorScheme.primary,
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
                    String finalReps = repsCtrl.text.trim().isEmpty
                        ? ex.reps
                        : repsCtrl.text.trim();
                    if (isDropset &&
                        !finalReps.toUpperCase().contains('DROPSET')) {
                      finalReps += ' + DROPSET';
                    }
                    if (isBiset && !finalReps.toUpperCase().contains('BISET')) {
                      finalReps += ' + BISET';
                    }

                    final customizedEx = Exercise(
                      id: ex.id,
                      name: ex.name,
                      muscle: ex.muscle,
                      description: obsCtrl.text.trim(),
                      reps: finalReps,
                      rest: restCtrl.text.trim().isEmpty
                          ? ex.rest
                          : restCtrl.text.trim(),
                    );

                    setState(() {
                      final routine = _draftRoutines[routineIndex];

                      final updatedExercises = List<Exercise>.from(
                        routine.exercises,
                      );

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
            final allExercises = context
                .watch<WorkoutProvider>()
                .allExercises
                .where((ex) {
                  return ex.name.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      ) ||
                      ex.muscle.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      );
                })
                .toList();

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
                      decoration: const BoxDecoration(
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
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Buscar exercício...',
                          hintStyle: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                          prefixIcon: const Icon(
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
                          ? const Center(
                              child: Text(
                                'Nenhum exercício encontrado.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: allExercises.length,
                              separatorBuilder: (_, __) =>
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  subtitle: Text(
                                    ex.muscle,
                                    style: const TextStyle(
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

  void _saveProgram() {
    final provider = context.read<WorkoutProvider>();

    for (var routine in _draftRoutines) {
      provider.createRoutine(
        routine.name,
        routine.focus,
        routine.groupName,
        routine.exercises,
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
        padding: const EdgeInsets.all(20),
        itemCount: _draftRoutines.length,
        separatorBuilder: (_, __) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          final routine = _draftRoutines[index];

          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CABEÇALHO DO TREINO (Sem Lápis, mas arrumado visualmente)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.view_day,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          routine.name,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (routine.exercises.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Nenhum exercício adicionado.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: routine.exercises.length,
                    itemBuilder: (ctx, i) {
                      final ex = routine.exercises[i];
                      bool isDropset = ex.reps.toUpperCase().contains(
                        'DROPSET',
                      );
                      bool isBiset = ex.reps.toUpperCase().contains('BISET');

                      return Container(
                        // Lógica visual do Bi-set (Gruda no de cima)
                        decoration: BoxDecoration(
                          border: isBiset
                              ? Border(
                                  left: BorderSide(
                                    color: Colors.orangeAccent,
                                    width: 4,
                                  ),
                                )
                              : null,
                          color: isBiset
                              ? Colors.orangeAccent.withOpacity(0.05)
                              : Colors.transparent,
                        ),
                        child: ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  ex.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (isDropset)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'DROPSET',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              if (isBiset)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orangeAccent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'BI-SET',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${ex.muscle} • ${ex.reps.replaceAll(RegExp(r'\s*\+\s*DROPSET', caseSensitive: false), '').replaceAll(RegExp(r'\s*\+\s*BISET', caseSensitive: false), '')} • ${ex.rest}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              if (ex.description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Obs: ${ex.description}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // AQUI ESTÁ O LÁPIS DIRETO NO EXERCÍCIO
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () => _showExerciseConfigDialog(
                                  index,
                                  ex,
                                  editIndex: i,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    final updatedExercises =
                                        List<Exercise>.from(routine.exercises)
                                          ..removeAt(i);

                                    _draftRoutines[index] = routine.copyWith(
                                      exercises: updatedExercises,
                                    );
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _showExerciseSelector(index),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('INSERIR EXERCÍCIO'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.black,
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
