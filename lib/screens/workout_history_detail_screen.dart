import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../features/exercises/domain/exercise_catalog.dart';
import '../features/workouts/domain/models/cardio_log.dart';
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
    final statusLabel = workout.isCardioOnly
        ? 'CARDIO'
        : isIncomplete
        ? 'INCOMPLETO'
        : 'CONCLUÍDO';
    final statusIcon = workout.isCardioOnly
        ? Icons.directions_run_rounded
        : isIncomplete
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
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          workout.isCardioOnly ? 'Detalhes do cardio' : 'Detalhes do treino',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
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
              if (workout.cardio.isNotEmpty) ...[
                const SizedBox(height: 26),
                Row(
                  children: <Widget>[
                    const Expanded(child: _SectionTitle('CARDIO REALIZADO')),
                    Text(
                      '${workout.totalCardioActivities}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: workout.cardio.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _CardioHistoryCard(
                    entry: workout.cardio[index],
                    index: index,
                  ),
                ),
              ],
              if (workout.exercises.isNotEmpty) ...[
                const SizedBox(height: 26),
                Row(
                  children: <Widget>[
                    const Expanded(
                      child: _SectionTitle('EXERCÍCIOS REALIZADOS'),
                    ),
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
              if (workout.exercises.isEmpty && workout.cardio.isEmpty) ...[
                const SizedBox(height: 26),
                const _EmptyExerciseDetails(),
              ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
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
              children: workout.isCardioOnly
                  ? <Widget>[
                      Expanded(
                        child: _SummaryMetric(
                          icon: Icons.timer_outlined,
                          value: '${workout.totalCardioMinutes} min',
                          label: 'Duração',
                        ),
                      ),
                      const _MetricDivider(),
                      Expanded(
                        child: _SummaryMetric(
                          icon: Icons.directions_run_rounded,
                          value: '${workout.totalCardioActivities}',
                          label: 'Atividades',
                        ),
                      ),
                      const _MetricDivider(),
                      Expanded(
                        child: _SummaryMetric(
                          icon: Icons.route_outlined,
                          value: workout.totalCardioDistanceKm > 0
                              ? '${_formatDecimal(workout.totalCardioDistanceKm)} km'
                              : '—',
                          label: 'Distância',
                        ),
                      ),
                    ]
                  : <Widget>[
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
                          icon: workout.cardio.isEmpty
                              ? Icons.format_list_numbered_rounded
                              : Icons.directions_run_rounded,
                          value: workout.cardio.isEmpty
                              ? '${workout.totalSets}'
                              : '${workout.totalCardioMinutes} min',
                          label: workout.cardio.isEmpty ? 'Séries' : 'Cardio',
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

class _CardioHistoryCard extends StatelessWidget {
  const _CardioHistoryCard({required this.entry, required this.index});

  final CardioLog entry;
  final int index;

  IconData get _icon {
    return switch (entry.modality) {
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

  @override
  Widget build(BuildContext context) {
    final metrics = <Widget>[
      _CardioMetricChip(
        icon: Icons.timer_outlined,
        label: '${entry.actualDurationMinutes} min realizados',
      ),
      if (entry.plannedDurationMinutes > 0)
        _CardioMetricChip(
          icon: Icons.flag_outlined,
          label: '${entry.plannedDurationMinutes} min planejados',
        ),
      if (entry.distanceKm != null && entry.distanceKm! > 0)
        _CardioMetricChip(
          icon: Icons.route_outlined,
          label: '${_formatDecimal(entry.distanceKm!)} km',
        ),
      if (entry.averageSpeedKmh != null && entry.averageSpeedKmh! > 0)
        _CardioMetricChip(
          icon: Icons.speed_rounded,
          label: '${_formatDecimal(entry.averageSpeedKmh!)} km/h',
        ),
      if (entry.inclinePercent != null)
        _CardioMetricChip(
          icon: Icons.trending_up_rounded,
          label: '${_formatDecimal(entry.inclinePercent!)}% inclinação',
        ),
      if (entry.resistanceLevel != null)
        _CardioMetricChip(
          icon: Icons.tune_rounded,
          label: 'Resistência ${_formatDecimal(entry.resistanceLevel!)}',
        ),
      if (entry.perceivedEffort != null)
        _CardioMetricChip(
          icon: Icons.bolt_rounded,
          label: 'Esforço ${entry.perceivedEffort}/10',
        ),
      if (entry.averageHeartRateBpm != null)
        _CardioMetricChip(
          icon: Icons.favorite_rounded,
          label: '${entry.averageHeartRateBpm} bpm',
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      entry.modality.label,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Cardio ${index + 1}',
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
          const SizedBox(height: 14),
          Wrap(spacing: 7, runSpacing: 7, children: metrics),
          if (entry.notes.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 13),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                entry.notes,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CardioMetricChip extends StatelessWidget {
  const _CardioMetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
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

String _formatDecimal(double value) {
  final hasDecimals = value != value.roundToDouble();
  return value.toStringAsFixed(hasDecimals ? 1 : 0).replaceAll('.', ',');
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
