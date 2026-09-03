import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../features/exercises/domain/exercise_catalog.dart';
import '../features/workouts/domain/models/cardio_log.dart';
import '../features/workouts/domain/models/exercise_log.dart';
import '../features/workouts/domain/models/free_activity_log.dart';
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
    final statusColor = workout.isFreeActivityOnly
        ? AppColors.info
        : isIncomplete
        ? AppColors.warning
        : Theme.of(context).colorScheme.primary;
    final statusLabel = workout.isFreeActivityOnly
        ? 'ATIVIDADE'
        : workout.isCardioOnly
        ? 'CARDIO'
        : isIncomplete
        ? 'INCOMPLETO'
        : 'CONCLUÍDO';
    final statusIcon = workout.isFreeActivityOnly
        ? Icons.sports_gymnastics_rounded
        : workout.isCardioOnly
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
          workout.isFreeActivityOnly
              ? 'Detalhes da atividade'
              : workout.isCardioOnly
              ? 'Detalhes do cardio'
              : 'Detalhes do treino',
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
              if (workout.freeActivities.isNotEmpty) ...[
                const SizedBox(height: 26),
                Row(
                  children: <Widget>[
                    const Expanded(child: _SectionTitle('ATIVIDADE REALIZADA')),
                    Text(
                      '${workout.totalFreeActivities}',
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
                  itemCount: workout.freeActivities.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _FreeActivityHistoryCard(
                    entry: workout.freeActivities[index],
                  ),
                ),
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
              if (workout.exercises.isEmpty &&
                  workout.cardio.isEmpty &&
                  workout.freeActivities.isEmpty) ...[
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
              children: workout.isFreeActivityOnly
                  ? <Widget>[
                      Expanded(
                        child: _SummaryMetric(
                          icon: Icons.timer_outlined,
                          value: '${workout.totalFreeActivityMinutes} min',
                          label: 'Duração',
                        ),
                      ),
                      const _MetricDivider(),
                      Expanded(
                        child: _SummaryMetric(
                          icon: Icons.speed_rounded,
                          value: workout.freeActivities.first.intensity.label,
                          label: 'Intensidade',
                        ),
                      ),
                      const _MetricDivider(),
                      Expanded(
                        child: _SummaryMetric(
                          icon: workout.replacedPlannedWorkout
                              ? Icons.swap_horiz_rounded
                              : Icons.add_circle_outline_rounded,
                          value: workout.replacedPlannedWorkout ? 'Sim' : 'Não',
                          label: 'Substituiu ficha',
                        ),
                      ),
                    ]
                  : workout.isCardioOnly
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
                          label: workout.cardio.isEmpty ? 'Trabalho' : 'Cardio',
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

class _FreeActivityHistoryCard extends StatelessWidget {
  const _FreeActivityHistoryCard({required this.entry});

  final FreeActivityLog entry;

  IconData get _icon => switch (entry.type) {
    FreeActivityType.crossfit => Icons.sports_gymnastics_rounded,
    FreeActivityType.functional => Icons.fitness_center_rounded,
    FreeActivityType.pilates => Icons.self_improvement_rounded,
    FreeActivityType.dance => Icons.music_note_rounded,
    FreeActivityType.mobility => Icons.accessibility_new_rounded,
    FreeActivityType.sport => Icons.sports_soccer_rounded,
    FreeActivityType.yoga => Icons.spa_rounded,
    FreeActivityType.other => Icons.more_horiz_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.info;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(_icon, color: accent, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      entry.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${entry.durationMinutes} min • intensidade ${entry.intensity.label.toLowerCase()}',
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
          if (entry.replacedPlannedWorkout) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.swap_horiz_rounded, color: accent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta atividade substituiu o treino planejado do dia. A ficha não foi marcada como concluída.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (entry.notes.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              entry.notes,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
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
        icon: Icons.place_outlined,
        label: entry.plan.purpose.label,
      ),
      _CardioMetricChip(
        icon: Icons.view_timeline_outlined,
        label: entry.plan.format.label,
      ),
      if (entry.plan.intensity != CardioIntensity.selfSelected)
        _CardioMetricChip(
          icon: Icons.speed_outlined,
          label: 'Intensidade ${entry.plan.intensity.label.toLowerCase()}',
        ),
      _CardioMetricChip(
        icon: Icons.timer_outlined,
        label: '${entry.actualDurationMinutes} min realizados',
      ),
      if (entry.plannedDurationMinutes > 0)
        _CardioMetricChip(
          icon: Icons.flag_outlined,
          label: '${entry.plannedDurationMinutes} min planejados',
        ),
      if (entry.plan.plannedDistanceKm != null)
        _CardioMetricChip(
          icon: Icons.flag_outlined,
          label: 'Meta ${_formatDecimal(entry.plan.plannedDistanceKm!)} km',
        ),
      if (entry.plan.plannedSpeedKmh != null)
        _CardioMetricChip(
          icon: Icons.flag_outlined,
          label: 'Meta ${_formatDecimal(entry.plan.plannedSpeedKmh!)} km/h',
        ),
      if (entry.plan.plannedInclinePercent != null)
        _CardioMetricChip(
          icon: Icons.flag_outlined,
          label:
              'Meta ${_formatDecimal(entry.plan.plannedInclinePercent!)}% inclinação',
        ),
      if (entry.plan.plannedResistanceLevel != null)
        _CardioMetricChip(
          icon: Icons.flag_outlined,
          label:
              'Meta resistência ${_formatDecimal(entry.plan.plannedResistanceLevel!)}',
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
          if (entry.plan.intervals case final intervals?) ...<Widget>[
            const SizedBox(height: 11),
            Text(
              '${intervals.warmUpMinutes} min aquecimento • ${intervals.cycles}x ${intervals.effortSeconds}s esforço / ${intervals.recoverySeconds}s recuperação • ${intervals.coolDownMinutes} min desaceleração',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
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
    final setCount = exercise.workingSets.length;
    final warmUpCount = exercise.warmUpSets.length;
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
                          '$setCount série${setCount == 1 ? '' : 's'} de trabalho',
                          if (warmUpCount > 0)
                            '$warmUpCount aquecimento${warmUpCount == 1 ? '' : 's'}',
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
          if (exercise.notes.trim().isNotEmpty ||
              !exercise.isLoadComparable ||
              exercise.perceivedRir != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.sticky_note_2_outlined,
                          size: 15,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Anotações',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    if (exercise.notes.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 5),
                      Text(
                        exercise.notes.trim(),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (!exercise.isLoadComparable) ...<Widget>[
                      const SizedBox(height: 5),
                      Text(
                        'Carga não usada na comparação de progressão.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (exercise.perceivedRir != null) ...<Widget>[
                      const SizedBox(height: 5),
                      Text(
                        'RIR percebido na última série: ${exercise.perceivedRir}.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: () {
                var warmUpNumber = 0;
                var workingNumber = 0;
                return exercise.sets
                    .asMap()
                    .entries
                    .map((entry) {
                      final label = entry.value.kind == WorkoutSetKind.warmUp
                          ? 'Aquecimento ${++warmUpNumber}'
                          : 'Série ${++workingNumber}';
                      return Padding(
                        padding: EdgeInsets.only(top: entry.key == 0 ? 0 : 7),
                        child: _SetHistoryRow(label: label, set: entry.value),
                      );
                    })
                    .toList(growable: false);
              }(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetHistoryRow extends StatelessWidget {
  const _SetHistoryRow({required this.label, required this.set});

  final String label;
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
              label,
              style: TextStyle(
                color: set.kind == WorkoutSetKind.warmUp
                    ? AppColors.warning
                    : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (set.isTimed) ...<Widget>[
            Expanded(
              flex: 2,
              child: Text(
                _durationLabel(set.actualDurationSeconds),
                textAlign: TextAlign.center,
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
                'meta ${_durationLabel(set.plannedDurationSeconds)}',
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else ...<Widget>[
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

  static String _durationLabel(int totalSeconds) {
    final safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = safeSeconds ~/ 60;
    final seconds = safeSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
