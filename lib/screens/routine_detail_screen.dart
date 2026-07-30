import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../features/workouts/presentation/providers/workout_controller.dart';
import '../theme/app_theme.dart';
import 'workout_session_screen.dart';

class RoutineDetailScreen extends ConsumerStatefulWidget {
  final WorkoutRoutine routine;

  const RoutineDetailScreen({super.key, required this.routine});

  @override
  ConsumerState<RoutineDetailScreen> createState() =>
      _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends ConsumerState<RoutineDetailScreen> {
  String _getImagePath(String exerciseName) {
    String cleanName = exerciseName.toLowerCase().trim();

    final Map<String, String> aliases = {
      'puxada na frente': 'puxada_frontal_aberta',
      'remada curvada': 'remada_curvada_com_barra',
      'rosca direta': 'rosca_direta_com_barra',
      'agachamento': 'agachamento_livre',
      'leg press': 'leg_press_45',
      'cadeira extensora': 'cadeira_extensora',
      'crunch abdominal': 'abdominal_supra',
      'tríceps na polia': 'triceps_pulley_reta_v',
      'triceps na polia': 'triceps_pulley_reta_v',
      'rosca scott': 'rosca_scott_maquina_livre',
      'desenvolvimento militar': 'desenvolvimento_com_barra',
      'chest press': 'supino_reto_com_barra',
      'remada sentada': 'remada_baixa_sentada',
      'remada baixa': 'remada_baixa_sentada',
    };

    if (aliases.containsKey(cleanName)) {
      return 'assets/images/${aliases[cleanName]}.gif';
    }

    cleanName = cleanName.replaceAll('/', ' ');
    cleanName = cleanName.replaceAll('-', ' ');
    cleanName = cleanName.replaceAll(RegExp(r'[áàâã]'), 'a');
    cleanName = cleanName.replaceAll(RegExp(r'[éèê]'), 'e');
    cleanName = cleanName.replaceAll(RegExp(r'[íìî]'), 'i');
    cleanName = cleanName.replaceAll(RegExp(r'[óòôõ]'), 'o');
    cleanName = cleanName.replaceAll(RegExp(r'[úùû]'), 'u');
    cleanName = cleanName.replaceAll('ç', 'c');
    cleanName = cleanName.replaceAll(RegExp(r'[^a-z0-9\s]'), '');
    cleanName = cleanName.trim().replaceAll(RegExp(r'\s+'), '_');

    return 'assets/images/$cleanName.gif';
  }

  void _openEditRoutineModal(
    BuildContext context,
    WorkoutController provider,
    WorkoutRoutine routine,
  ) {
    final nameCtrl = TextEditingController(text: routine.name);
    final focusCtrl = TextEditingController(text: routine.focus);
    List<Exercise> currentExercises = List.from(routine.exercises);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Editar Ficha de Treino',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Nome da Ficha (Ex: Treino A)',
                        labelStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: focusCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Foco/Objetivo (Ex: Peito e Tríceps)',
                        labelStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'GERENCIAR EXERCÍCIOS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: currentExercises.length,
                      onReorderItem: (oldIndex, newIndex) {
                        setStateModal(() {
                          final item = currentExercises.removeAt(oldIndex);
                          currentExercises.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final ex = currentExercises[index];
                        return Container(
                          key: ValueKey('${ex.id}_$index'),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.drag_handle,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(
                              ex.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              '${ex.reps} • ${ex.rest}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              onPressed: () {
                                setStateModal(() {
                                  currentExercises.removeAt(index);
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          provider.updateRoutine(
                            routine.id,
                            nameCtrl.text.trim().isEmpty
                                ? routine.name
                                : nameCtrl.text.trim(),
                            focusCtrl.text.trim().isEmpty
                                ? routine.focus
                                : focusCtrl.text.trim(),
                            routine.groupName,
                            currentExercises,
                          );
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Ficha atualizada com sucesso!',
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                            ),
                          );
                        },
                        child: const Text(
                          'SALVAR ALTERAÇÕES',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoutineExerciseCard(
    BuildContext context,
    WorkoutRoutine routine,
    int index,
  ) {
    final exercise = routine.exercises[index];
    final startsBiSet =
        exercise.isSuperset && index < routine.exercises.length - 1;
    final continuesBiSet = index > 0 && routine.exercises[index - 1].isSuperset;
    final isBiSet = startsBiSet || continuesBiSet;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      key: ValueKey<String>('${routine.id}-${exercise.id}-$index'),
      margin: EdgeInsets.only(bottom: startsBiSet ? 2 : 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(continuesBiSet ? 4 : 12),
          bottom: Radius.circular(startsBiSet ? 4 : 12),
        ),
        border: Border.all(
          color: isBiSet
              ? primaryColor.withValues(alpha: 0.55)
              : AppColors.border,
          width: isBiSet ? 1.25 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBiSet)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(continuesBiSet ? 3 : 11),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.link, size: 15, color: primaryColor),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      startsBiSet
                          ? 'BI-SET 1/2 — FAÇA COM O PRÓXIMO'
                          : 'BI-SET 2/2 — CONTINUAÇÃO SEM PAUSA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset(
                      _getImagePath(exercise.name),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (exercise.customNote.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.push_pin,
                                size: 10,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  exercise.customNote,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        'MÚSCULO: ${exercise.muscle.toUpperCase()}',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          _ExerciseMetric(
                            icon: Icons.repeat,
                            label: exercise.reps,
                          ),
                          _ExerciseMetric(
                            icon: Icons.timer_outlined,
                            label: exercise.rest,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleStartRoutine(
    BuildContext context,
    WorkoutController provider,
    WorkoutRoutine routine,
  ) {
    if (provider.isWorkoutActive &&
        provider.activeRoutineName != routine.name) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text(
            'Trocar Treino?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Você tem um treino ("${provider.activeRoutineName}") em andamento. Deseja substituí-lo por este?',
            style: const TextStyle(color: AppColors.textSecondary),
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
                provider.startRoutine(routine);
                Navigator.pop(ctx);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WorkoutSessionScreen(),
                  ),
                );
              },
              child: const Text(
                'Trocar',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
    } else {
      if (!provider.isWorkoutActive) {
        provider.startRoutine(routine);
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WorkoutSessionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(workoutControllerProvider);
    final provider = ref.read(workoutControllerProvider.notifier);
    final routine = workoutState.myRoutines.firstWhere(
      (item) => item.id == widget.routine.id,
      orElse: () => widget.routine,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: const Text(
          'Detalhes da Ficha',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => _openEditRoutineModal(context, provider, routine),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routine.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'OBJETIVO / FOCO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    routine.focus,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.format_list_numbered,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${routine.exercises.length} Exercícios nesta ficha',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'LISTA DE EXERCÍCIOS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: routine.exercises.length,
              itemBuilder: (context, index) {
                return _buildRoutineExerciseCard(context, routine, index);
              },
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
            ),
            onPressed: () => _handleStartRoutine(context, provider, routine),
            icon: Icon(
              workoutState.isWorkoutActive &&
                      workoutState.activeRoutineName == routine.name
                  ? Icons.play_circle_filled
                  : Icons.play_arrow,
            ),
            label: Text(
              workoutState.isWorkoutActive &&
                      workoutState.activeRoutineName == routine.name
                  ? 'CONTINUAR TREINO INICIADO'
                  : 'INICIAR ESTE TREINO',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExerciseMetric extends StatelessWidget {
  const _ExerciseMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
