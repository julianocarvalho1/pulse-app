import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../features/exercises/domain/exercise_catalog.dart';
import '../features/pulse_ai/presentation/screens/pulse_ai_assistant_screen.dart';
import '../features/workouts/domain/models/cardio_log.dart';
import '../features/workouts/presentation/providers/workout_controller.dart';
import '../features/workout_sharing/domain/services/pulse_workout_codec.dart';
import '../features/workout_sharing/presentation/widgets/pulse_workout_share_sheet.dart';
import '../theme/app_theme.dart';
import 'routine_editor_screen.dart';
import 'workout_session_screen.dart';

class RoutineDetailScreen extends ConsumerStatefulWidget {
  final WorkoutRoutine routine;

  const RoutineDetailScreen({super.key, required this.routine});

  @override
  ConsumerState<RoutineDetailScreen> createState() =>
      _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends ConsumerState<RoutineDetailScreen> {
  String _startLabel(WorkoutRoutine routine, bool isActive) {
    if (isActive) {
      return 'CONTINUAR TREINO INICIADO';
    }
    return switch (routine.type) {
      RoutineType.strength => 'INICIAR ESTE TREINO',
      RoutineType.cardio => 'INICIAR ESTE CARDIO',
      RoutineType.mixed => 'INICIAR TREINO MISTO',
    };
  }

  Future<void> _openEditor(WorkoutRoutine routine) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => RoutineEditorScreen(routine: routine),
      ),
    );

    if ((updated ?? false) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ficha atualizada com sucesso.')),
      );
    }
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
                      ExerciseCatalog.mediaPathFor(exercise),
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
                      if (!exercise.advancedPrescription.isEmpty) ...<Widget>[
                        const SizedBox(height: 6),
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.tune_rounded,
                              size: 14,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                exercise.advancedPrescription.summary,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  IconData _cardioIcon(CardioModality modality) {
    return switch (modality) {
      CardioModality.treadmill => Icons.directions_run_rounded,
      CardioModality.stationaryBike => Icons.pedal_bike_rounded,
      CardioModality.elliptical => Icons.sync_alt_rounded,
      CardioModality.stairClimber => Icons.stairs_rounded,
      CardioModality.rowing => Icons.rowing_rounded,
      CardioModality.walking => Icons.directions_walk_rounded,
      CardioModality.running => Icons.directions_run_rounded,
      CardioModality.other => Icons.favorite_outline_rounded,
    };
  }

  Widget _buildRoutineCardioCard(
    BuildContext context,
    RoutineCardio cardio,
    int index,
  ) {
    return Container(
      key: ValueKey<String>(cardio.id),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              _cardioIcon(cardio.modality),
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  cardio.modality.label,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${cardio.plannedDurationMinutes} min planejados',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (cardio.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    cardio.notes,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            routineIndexLabel(index),
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String routineIndexLabel(int index) => 'C${index + 1}';

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
          title: Text(
            'Trocar Treino?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Você tem um treino ("${provider.activeRoutineName}") em andamento. Deseja substituí-lo por este?',
            style: TextStyle(color: AppColors.textSecondary),
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
                provider.startRoutine(routine, replaceActive: true);
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

  IconData _routineTypeIcon(RoutineType type) {
    return switch (type) {
      RoutineType.strength => Icons.fitness_center_rounded,
      RoutineType.cardio => Icons.directions_run_rounded,
      RoutineType.mixed => Icons.sports_gymnastics_rounded,
    };
  }

  Widget _buildRoutineInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge(BuildContext context, int count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Future<void> _openPulseAiAssistant(WorkoutRoutine routine) async {
    final applied = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => PulseAiAssistantScreen(routine: routine),
      ),
    );

    if ((applied ?? false) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Substituição aplicada à ficha com sucesso.'),
        ),
      );
    }
  }

  Widget _buildPulseAiEntry(BuildContext context, WorkoutRoutine routine) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () => _openPulseAiAssistant(routine),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: AppColors.primaryBorder),
            gradient: LinearGradient(
              colors: <Color>[
                primary.withValues(alpha: 0.14),
                AppColors.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.auto_awesome_rounded, color: primary),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Assistente PULSE',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Explique, revise ou encontre alternativas para esta ficha.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'PILOTO',
                  style: TextStyle(
                    color: primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
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
          'Detalhes da ficha',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Compartilhar ficha',
            icon: Icon(
              Icons.ios_share_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => showPulseWorkoutShareSheet(
              context,
              const PulseWorkoutCodec().routineDocument(routine),
            ),
          ),
          IconButton(
            tooltip: 'Editar ficha',
            icon: Icon(
              Icons.edit_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => _openEditor(routine),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.paddingOf(context).bottom + 120,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
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
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
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
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildRoutineInfoChip(
                        context,
                        icon: _routineTypeIcon(routine.type),
                        label: routine.typeLabel,
                      ),
                      _buildRoutineInfoChip(
                        context,
                        icon: Icons.format_list_numbered_rounded,
                        label: routine.activitySummary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildPulseAiEntry(context, routine),
            const SizedBox(height: 24),
            if (routine.exercises.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'EXERCÍCIOS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  _buildCountBadge(
                    context,
                    routine.exercises.length,
                    routine.exercises.length == 1 ? 'exercício' : 'exercícios',
                  ),
                ],
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
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'CARDIO DA FICHA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _openEditor(routine),
                  icon: Icon(
                    routine.cardio.isEmpty
                        ? Icons.add_rounded
                        : Icons.edit_rounded,
                    size: 18,
                  ),
                  label: Text(
                    routine.cardio.isEmpty ? 'Adicionar' : 'Gerenciar',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (routine.cardio.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.directions_run_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Nenhum cardio planejado. Você pode adicionar um quando quiser.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: routine.cardio.length,
                itemBuilder: (context, index) => _buildRoutineCardioCard(
                  context,
                  routine.cardio[index],
                  index,
                ),
              ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: AppColors.onPrimary,
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
                _startLabel(
                  routine,
                  workoutState.isWorkoutActive &&
                      workoutState.activeRoutineName == routine.name,
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
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
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
