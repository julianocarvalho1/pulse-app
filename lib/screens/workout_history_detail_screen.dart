import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../features/exercises/domain/exercise_catalog.dart';
import '../features/workouts/domain/models/exercise_log.dart';
import '../features/workouts/domain/models/workout_history_item.dart';
import '../features/workouts/domain/models/workout_set.dart';
import '../theme/app_theme.dart';

class WorkoutHistoryDetailScreen extends StatelessWidget {
  const WorkoutHistoryDetailScreen({super.key, required this.workout});

  final WorkoutHistoryItem workout;

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      "dd/MM/yyyy 'às' HH:mm",
    ).format(workout.date);
    final isIncomplete = workout.isIncomplete;
    final statusColor = isIncomplete
        ? AppColors.warning
        : Theme.of(context).colorScheme.primary;
    final statusLabel = isIncomplete ? 'INCOMPLETO' : 'CONCLUÍDO';
    final statusIcon = isIncomplete
        ? Icons.pending_actions_rounded
        : Icons.check_circle_rounded;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Voltar',
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detalhes do treino',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.paddingOf(context).bottom + 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WorkoutSummaryCard(
                workout: workout,
                formattedDate: formattedDate,
                statusColor: statusColor,
                statusIcon: statusIcon,
                statusLabel: statusLabel,
                isIncomplete: isIncomplete,
              ),
              if (workout.notes.trim().isNotEmpty) ...[
                const SizedBox(height: 22),
                const _SectionTitle('ANOTAÇÕES'),
                const SizedBox(height: 10),
                _NotesCard(notes: workout.notes),
              ],
              const SizedBox(height: 26),
              Row(
                children: [
                  const Expanded(child: _SectionTitle('EXERCÍCIOS REALIZADOS')),
                  Text(
                    '${workout.totalExercises}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (workout.exercises.isEmpty)
                const _EmptyExerciseDetails()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: workout.exercises.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _ExerciseHistoryCard(
                      exercise: workout.exercises[index],
                      index: index,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutSummaryCard extends StatelessWidget {
  const _WorkoutSummaryCard({
    required this.workout,
    required this.formattedDate,
    required this.statusColor,
    required this.statusIcon,
    required this.statusLabel,
    required this.isIncomplete,
  });

  final WorkoutHistoryItem workout;
  final String formattedDate;
  final Color statusColor;
  final IconData statusIcon;
  final String statusLabel;
  final bool isIncomplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(statusIcon, color: statusColor, size: 25),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.routineName,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (isIncomplete) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: statusColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Treino encerrado antes do fim.',
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryMetric(
                    icon: Icons.timer_outlined,
                    value: workout.duration,
                    label: 'Duração',
                  ),
                ),
                const _MetricDivider(),
                Expanded(
                  child: _SummaryMetric(
                    icon: Icons.fitness_center_outlined,
                    value: '${workout.totalExercises}',
                    label: 'Exercícios',
                  ),
                ),
                const _MetricDivider(),
                Expanded(
                  child: _SummaryMetric(
                    icon: Icons.format_list_numbered_rounded,
                    value: '${workout.totalSets}',
                    label: 'Séries',
                  ),
                ),
              ],
            ),
          ),
          if (isIncomplete) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: statusColor.withValues(alpha: 0.18)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: statusColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Histórico parcial salvo',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Somente exercícios e séries concluídos foram registrados neste treino.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 19),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 38, color: AppColors.border);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.edit_note_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              notes,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseHistoryCard extends StatelessWidget {
  const _ExerciseHistoryCard({required this.exercise, required this.index});

  final ExerciseLog exercise;
  final int index;

  @override
  Widget build(BuildContext context) {
    final definition = ExerciseCatalog.definitionForId(
      exercise.exerciseId,
      exerciseName: exercise.exerciseName,
    );
    final muscle = definition?.primaryMuscle.trim() ?? '';
    final setCount = exercise.sets.length;
    final totalReps = exercise.totalReps;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.exerciseName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (muscle.isNotEmpty) muscle,
                          '$setCount série${setCount == 1 ? '' : 's'}',
                          '$totalReps rep${totalReps == 1 ? '' : 's'}',
                        ].join(' • '),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: exercise.sets
                  .asMap()
                  .entries
                  .map((entry) {
                    return Padding(
                      padding: EdgeInsets.only(top: entry.key == 0 ? 0 : 7),
                      child: _SetHistoryRow(
                        setNumber: entry.key + 1,
                        set: entry.value,
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetHistoryRow extends StatelessWidget {
  const _SetHistoryRow({required this.setNumber, required this.set});

  final int setNumber;
  final ExerciseSet set;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Série $setNumber',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${set.reps} rep${set.reps == 1 ? '' : 's'}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _weightLabel(set.weight),
              textAlign: TextAlign.end,
              style: TextStyle(
                color: set.weight > 0
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _weightLabel(double weight) {
    if (weight <= 0) {
      return '—';
    }

    final hasDecimals = weight != weight.roundToDouble();
    return '${weight.toStringAsFixed(hasDecimals ? 1 : 0)} kg';
  }
}

class _EmptyExerciseDetails extends StatelessWidget {
  const _EmptyExerciseDetails();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.format_list_bulleted_rounded,
            color: AppColors.textMuted,
            size: 30,
          ),
          const SizedBox(height: 10),
          Text(
            'Nenhum detalhe de exercício foi salvo neste treino.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
