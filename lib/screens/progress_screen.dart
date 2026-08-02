import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../features/progress/domain/models/body_measurement_entry.dart';
import '../features/progress/domain/models/progress_period.dart';
import '../features/progress/domain/models/workout_progress_summary.dart';
import '../features/progress/presentation/providers/progress_controller.dart';
import '../features/progress/presentation/providers/progress_providers.dart';
import '../features/settings/domain/pulse_settings.dart';
import '../features/settings/presentation/providers/settings_controller.dart';
import '../features/workouts/domain/models/workout_history_item.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_line_chart.dart';
import 'body_measurement_editor_screen.dart';
import 'progress_calendar_screen.dart';
import 'workout_history_detail_screen.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key, this.onBackToHome});

  final VoidCallback? onBackToHome;

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  static const List<String> _tabs = <String>[
    'Consistência',
    'Treinos',
    'Medidas',
    'Desempenho',
  ];

  int _tab = 0;
  ProgressPeriod _period = ProgressPeriod.threeMonths;
  BodyMeasurementType _measurementType = BodyMeasurementType.weight;
  String? _selectedExerciseKey;

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(workoutProgressSummaryProvider(_period));

    return ColoredBox(
      color: AppColors.background,
      child: CustomScrollView(
        key: const PageStorageKey<String>('progress-scroll'),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: <Widget>[
          SliverAppBar(
            primary: true,
            pinned: true,
            floating: true,
            snap: true,
            toolbarHeight: 56,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: widget.onBackToHome == null,
            leading: widget.onBackToHome == null
                ? null
                : IconButton(
                    tooltip: 'Voltar para o início',
                    onPressed: widget.onBackToHome,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
            titleSpacing: widget.onBackToHome == null ? 20 : 0,
            title: const Text(
              'Progresso',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _ProgressTabsHeaderDelegate(
              backgroundColor: AppColors.background,
              borderColor: AppColors.border,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          Expanded(child: _tabItem(_tabs[0], 0)),
                          const SizedBox(width: 8),
                          Expanded(child: _tabItem(_tabs[1], 1)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          Expanded(child: _tabItem(_tabs[2], 2)),
                          const SizedBox(width: 8),
                          Expanded(child: _tabItem(_tabs[3], 3)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.paddingOf(context).bottom + 32,
            ),
            sliver: SliverToBoxAdapter(
              child: _buildTabContent(context, summary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    WorkoutProgressSummary summary,
  ) {
    return switch (_tab) {
      1 => _buildWorkouts(context, summary),
      2 => _buildMeasurements(context),
      3 => _buildPerformance(context, summary),
      _ => _buildConsistency(context, summary),
    };
  }

  Widget _buildConsistency(
    BuildContext context,
    WorkoutProgressSummary summary,
  ) {
    final stats = summary.current;
    final weeklyVolume = summary.weeklyPoints
        .map((point) => point.volume)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _progressSectionHeader(
          title: 'CALENDÁRIO DE TREINOS',
          subtitle: 'Toque em um dia para consultar as atividades registradas.',
        ),
        const SizedBox(height: 10),
        const ConsistencyCalendarSection(),
        const SizedBox(height: 20),
        _progressSectionHeader(
          title: 'RESUMO DO PERÍODO',
          subtitle: 'Frequência, tempo e evolução dos seus treinos.',
          trailing: _periodDropdown(),
        ),
        const SizedBox(height: 10),
        if (stats.isEmpty)
          _emptyState(
            icon: Icons.insights_outlined,
            title: 'Ainda não há dados neste período',
            message:
                'Conclua ou salve um treino incompleto para começar a acompanhar sua evolução real.',
          )
        else ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _metricCard(
                  context,
                  icon: Icons.fitness_center,
                  value: '${stats.workouts}',
                  label: 'Treinos',
                  detail:
                      '${stats.completedWorkouts} completos • ${stats.incompleteWorkouts} incompletos',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricCard(
                  context,
                  icon: Icons.calendar_month,
                  value: '${stats.activeDays}',
                  label: 'Dias ativos',
                  detail:
                      '${stats.weeklyFrequency.toStringAsFixed(1)} dias/semana',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _metricCard(
                  context,
                  icon: Icons.timer_outlined,
                  value: _formatDuration(stats.durationSeconds),
                  label: 'Tempo treinado',
                  detail: '${stats.totalSets} séries registradas',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricCard(
                  context,
                  icon: Icons.monitor_weight_outlined,
                  value: _formatVolume(stats.totalVolume),
                  label: 'Volume',
                  detail: '${stats.totalReps} repetições',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _streakCard(context, summary),
          const SizedBox(height: 16),
          if (summary.comparison != null)
            _comparisonCard(context, summary.comparison!),
          if (summary.comparison != null) const SizedBox(height: 16),
          _chartCard(
            context,
            title: 'VOLUME POR SEMANA',
            subtitle: 'Somente cargas e repetições registradas nos treinos',
            values: weeklyVolume,
            emptyMessage:
                'São necessárias pelo menos duas semanas com dados para formar a linha de evolução.',
            trailing: _formatVolume(stats.totalVolume),
          ),
        ],
      ],
    );
  }

  Widget _buildWorkouts(BuildContext context, WorkoutProgressSummary summary) {
    final workouts = summary.workouts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _periodSelector(),
        const SizedBox(height: 16),
        if (workouts.isEmpty)
          _emptyState(
            icon: Icons.history,
            title: 'Nenhum treino no período',
            message:
                'Altere o período ou conclua um treino para visualizar o histórico.',
          )
        else ...<Widget>[
          Row(
            children: <Widget>[
              _statusCounter(
                context,
                label: 'CONCLUÍDOS',
                value: summary.current.completedWorkouts,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              _statusCounter(
                context,
                label: 'INCOMPLETOS',
                value: summary.current.incompleteWorkouts,
                color: Colors.orangeAccent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...workouts.map((item) => _workoutCard(context, item)),
        ],
      ],
    );
  }

  Widget _buildMeasurements(BuildContext context) {
    final measurementsAsync = ref.watch(bodyMeasurementsControllerProvider);
    final settingsAsync = ref.watch(settingsControllerProvider);
    final settings = switch (settingsAsync) {
      AsyncData<PulseSettings>(:final value) => value,
      _ => PulseSettings.defaults(),
    };

    return measurementsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => _emptyState(
        icon: Icons.error_outline,
        title: 'Não foi possível carregar as medidas',
        message: 'Tente novamente para consultar os registros locais.',
        actionLabel: 'TENTAR NOVAMENTE',
        onAction: () {
          ref.read(bodyMeasurementsControllerProvider.notifier).reload();
        },
      ),
      data: (entries) {
        final latest = entries.isEmpty ? null : entries.first;
        final selectedPoints =
            entries
                .where((entry) => entry.valueFor(_measurementType) != null)
                .toList()
              ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
        final values = selectedPoints
            .map(
              (entry) => _displayMeasurement(
                entry.valueFor(_measurementType)!,
                _measurementType,
                settings,
              ),
            )
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'MEDIDAS CORPORAIS',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        latest == null
                            ? 'Nenhuma medida registrada'
                            : '${latest.isWeightOnly ? 'Última pesagem' : 'Última avaliação'} em ${DateFormat('dd/MM/yyyy').format(latest.recordedAt)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openMeasurementActionPicker(
                    context,
                    settings: settings,
                    entries: entries,
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('REGISTRAR'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (latest == null)
              _profileWeightCard(context, settings)
            else
              _measurementOverview(context, latest, settings),
            const SizedBox(height: 16),
            _sectionCard(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'EVOLUÇÃO REAL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      _measurementTypeSelector(context),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (values.length >= 2) ...<Widget>[
                    Text(
                      '${values.last.toStringAsFixed(1)} ${_measurementUnit(_measurementType, settings)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    MiniLineChart(values: values, height: 130, showDots: true),
                    const SizedBox(height: 8),
                    Text(
                      '${DateFormat('dd/MM').format(selectedPoints.first.recordedAt)} → ${DateFormat('dd/MM').format(selectedPoints.last.recordedAt)}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ] else
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 26),
                      child: Text(
                        'Registre pelo menos dois valores desta medida para visualizar a evolução.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (entries.isNotEmpty) ...<Widget>[
              const SizedBox(height: 20),
              Text(
                'HISTÓRICO DE MEDIDAS',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 10),
              ...entries
                  .take(5)
                  .map(
                    (entry) =>
                        _measurementHistoryCard(context, entry, settings),
                  ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPerformance(
    BuildContext context,
    WorkoutProgressSummary summary,
  ) {
    final exercises = summary.exerciseProgress;
    final selected = exercises.isEmpty
        ? null
        : exercises.firstWhere(
            (item) => item.exerciseKey == _selectedExerciseKey,
            orElse: () => exercises.first,
          );

    final weightPoints =
        selected?.points.where((point) => point.maxWeight > 0).toList() ??
        const <ExerciseProgressPoint>[];
    final weightValues = weightPoints.map((point) => point.maxWeight).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _progressSectionHeader(
          title: 'EVOLUÇÃO POR EXERCÍCIO',
          subtitle: 'Compare cargas e sessões no período selecionado.',
          trailing: _periodDropdown(),
        ),
        const SizedBox(height: 10),
        if (selected == null)
          _emptyState(
            icon: Icons.emoji_events_outlined,
            title: 'Desempenho ainda sem dados',
            message:
                'Registre cargas e repetições durante os treinos para acompanhar recordes e evolução.',
          )
        else ...<Widget>[
          _sectionCard(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DropdownButtonFormField<String>(
                  key: ValueKey<String>(selected.exerciseKey),
                  initialValue: selected.exerciseKey,
                  dropdownColor: AppColors.surfaceLight,
                  isExpanded: true,
                  items: exercises.map((exercise) {
                    return DropdownMenuItem<String>(
                      value: exercise.exerciseKey,
                      child: Text(
                        exercise.exerciseName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (key) {
                    if (key != null) {
                      setState(() => _selectedExerciseKey = key);
                    }
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _smallMetric(
                        'CARGA RECENTE',
                        _formatWeight(selected.latestWeight),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _smallMetric(
                        'VOLUME RECENTE',
                        _formatExactVolume(selected.latestVolume),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _smallMetric(
                        'SESSÕES',
                        '${selected.points.length}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.info_outline,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Carga recente é a maior carga da última sessão. O gráfico compara a maior carga de cada sessão. Volume recente é a soma de carga × repetições da última sessão.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (weightValues.length >= 2) ...<Widget>[
                  MiniLineChart(
                    values: weightValues,
                    height: 140,
                    showDots: true,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        DateFormat('dd/MM').format(weightPoints.first.date),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM').format(weightPoints.last.date),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Column(
                        children: <Widget>[
                          Text(
                            'Primeiro registro: ${_formatWeight(selected.latestWeight)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Faça este exercício novamente para comparar sua evolução.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (selected.weightChange != null) ...<Widget>[
                  const SizedBox(height: 10),
                  _changeLabel(context, 'Última sessão', selected.weightChange),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'RECORDES PESSOAIS',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Melhores cargas de todo o histórico, independentemente do período selecionado.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          if (summary.personalRecords.isEmpty)
            _emptyState(
              icon: Icons.emoji_events_outlined,
              title: 'Nenhuma carga registrada',
              message:
                  'Os recordes aparecem quando pelo menos uma série possui carga maior que zero.',
            )
          else
            ...summary.personalRecords
                .take(10)
                .map((record) => _recordCard(context, record)),
        ],
      ],
    );
  }

  Widget _periodSelector() {
    return Align(alignment: Alignment.centerRight, child: _periodDropdown());
  }

  Widget _periodDropdown() {
    return Container(
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.only(left: 12, right: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ProgressPeriod>(
          value: _period,
          isDense: true,
          borderRadius: BorderRadius.circular(14),
          dropdownColor: AppColors.surfaceLight,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          items: ProgressPeriod.values.map((period) {
            return DropdownMenuItem<ProgressPeriod>(
              value: period,
              child: Text(period.label),
            );
          }).toList(),
          onChanged: (period) {
            if (period != null) {
              setState(() {
                _period = period;
                _selectedExerciseKey = null;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _progressSectionHeader({
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...<Widget>[const SizedBox(width: 12), trailing],
      ],
    );
  }

  Widget _metricCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required String detail,
  }) {
    return _sectionCard(
      context,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 21, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 5),
          Text(
            detail,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _streakCard(BuildContext context, WorkoutProgressSummary summary) {
    return _sectionCard(
      context,
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              Icons.local_fire_department,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'SEQUÊNCIA DE TREINOS',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${summary.currentStreak} dias atuais',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Recorde: ${summary.longestStreak}',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _comparisonCard(BuildContext context, ProgressComparison comparison) {
    return _sectionCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'COMPARAÇÃO COM O PERÍODO ANTERIOR',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _comparisonItem(
                  context,
                  'Treinos',
                  comparison.workoutsChange,
                ),
              ),
              Expanded(
                child: _comparisonItem(
                  context,
                  'Dias ativos',
                  comparison.activeDaysChange,
                ),
              ),
              Expanded(
                child: _comparisonItem(
                  context,
                  'Volume',
                  comparison.volumeChange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _comparisonItem(BuildContext context, String label, double? change) {
    final positive = change == null || change >= 0;
    final color = positive
        ? Theme.of(context).colorScheme.primary
        : Colors.orangeAccent;
    final value = change == null
        ? 'NOVO'
        : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(0)}%';

    return Column(
      children: <Widget>[
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }

  Widget _chartCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<double> values,
    required String emptyMessage,
    required String trailing,
  }) {
    return _sectionCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                trailing,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
          ),
          const SizedBox(height: 16),
          if (values.length >= 2)
            MiniLineChart(values: values, height: 130, showDots: true)
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _workoutCard(BuildContext context, WorkoutHistoryItem item) {
    final incomplete = item.isIncomplete;
    final isCardio = item.isCardioOnly;
    final color = incomplete
        ? Colors.orangeAccent
        : Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: color.withValues(alpha: 0.32)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => WorkoutHistoryDetailScreen(workout: item),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCardio
                        ? Icons.directions_run_rounded
                        : incomplete
                        ? Icons.pending_actions_rounded
                        : Icons.check_circle_rounded,
                    color: color,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.routineName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat("dd/MM/yyyy 'às' HH:mm").format(item.date),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 5,
                        children: isCardio
                            ? <Widget>[
                                _miniTag('${item.totalCardioMinutes} min'),
                                if (item.totalCardioDistanceKm > 0)
                                  _miniTag(
                                    '${_formatCardioNumber(item.totalCardioDistanceKm)} km',
                                  ),
                                _miniTag(
                                  item.cardio.length == 1
                                      ? item.cardio.first.modality.label
                                      : '${item.cardio.length} atividades',
                                ),
                              ]
                            : <Widget>[
                                _miniTag('${item.totalSets} séries'),
                                _miniTag(_formatVolume(item.totalVolume)),
                                _miniTag('${item.totalExercises} exercícios'),
                              ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      item.duration,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isCardio
                          ? 'CARDIO'
                          : incomplete
                          ? 'INCOMPLETO'
                          : 'CONCLUÍDO',
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCardioNumber(double value) {
    final hasDecimals = value != value.roundToDouble();
    return value.toStringAsFixed(hasDecimals ? 1 : 0).replaceAll('.', ',');
  }

  Widget _statusCounter(
    BuildContext context, {
    required String label,
    required int value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: <Widget>[
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _measurementOverview(
    BuildContext context,
    BodyMeasurementEntry entry,
    PulseSettings settings,
  ) {
    final visibleTypes = BodyMeasurementType.values
        .where((type) => entry.valueFor(type) != null)
        .toList();

    return _sectionCard(
      context,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: visibleTypes.map((type) {
          final value = entry.valueFor(type)!;
          return SizedBox(
            width: (MediaQuery.sizeOf(context).width - 94) / 2,
            child: _smallMetric(
              type.label.toUpperCase(),
              '${_displayMeasurement(value, type, settings)} ${_measurementUnit(type, settings)}',
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _profileWeightCard(BuildContext context, PulseSettings settings) {
    final weight = settings.profile.weightKg;

    return _sectionCard(
      context,
      child: Row(
        children: <Widget>[
          Icon(
            Icons.monitor_weight_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'PESO DO PERFIL',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  weight > 0
                      ? '${_displayMeasurement(weight, BodyMeasurementType.weight, settings)} ${_measurementUnit(BodyMeasurementType.weight, settings)}'
                      : 'Não informado',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Registre uma pesagem\npara criar o histórico.',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _measurementHistoryCard(
    BuildContext context,
    BodyMeasurementEntry entry,
    PulseSettings settings,
  ) {
    final values = BodyMeasurementType.values
        .where((type) => entry.valueFor(type) != null)
        .take(3)
        .map((type) {
          final value = entry.valueFor(type)!;
          return '${type.label}: ${_displayMeasurement(value, type, settings)} ${_measurementUnit(type, settings)}';
        })
        .join(' • ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        child: ListTile(
          title: Text(
            entry.isWeightOnly ? 'Pesagem' : 'Avaliação corporal',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          subtitle: Text(
            '${DateFormat("dd/MM/yyyy 'às' HH:mm").format(entry.recordedAt)}\n$values',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          isThreeLine: true,
          trailing: IconButton(
            tooltip: entry.isWeightOnly
                ? 'Excluir pesagem'
                : 'Excluir avaliação',
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _deleteMeasurement(context, entry),
          ),
        ),
      ),
    );
  }

  Widget _recordCard(BuildContext context, PersonalRecord record) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _sectionCard(
        context,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events, color: Colors.amber),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    record.exerciseName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${record.reps} repetições • ${DateFormat('dd/MM/yyyy').format(record.date)}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _formatWeight(record.weight),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 18,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _changeLabel(BuildContext context, String label, double? change) {
    final positive = change == null || change >= 0;
    final color = positive
        ? Theme.of(context).colorScheme.primary
        : Colors.orangeAccent;
    final value = change == null
        ? 'novo registro'
        : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%';

    return Row(
      children: <Widget>[
        Icon(
          positive ? Icons.trending_up : Icons.trending_down,
          color: color,
          size: 17,
        ),
        const SizedBox(width: 5),
        Text(
          '$value em relação à $label',
          style: TextStyle(color: color, fontSize: 11),
        ),
      ],
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(17),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 2),
          Icon(icon, size: 42, color: AppColors.textSecondary),
          const SizedBox(height: 13),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.4,
              fontSize: 12,
            ),
          ),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(height: 16),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ],
      ),
    );
  }

  Widget _miniTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 9),
      ),
    );
  }

  Widget _tabItem(String label, int index) {
    final active = _tab == index;
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 40,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: active ? primary.withValues(alpha: 0.12) : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active
                  ? primary.withValues(alpha: 0.65)
                  : AppColors.border,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              color: active ? primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _measurementTypeSelector(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Selecionar medida para o gráfico',
      value: _measurementType.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openMeasurementTypePicker(context),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 172),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: Text(
                  _measurementType.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 19),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openMeasurementTypePicker(BuildContext context) async {
    final selected = await showModalBottomSheet<BodyMeasurementType>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 8),
          child: FractionallySizedBox(
            heightFactor: 0.58,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Escolher medida',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Selecione o dado exibido no gráfico de evolução.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fechar',
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppColors.border),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    children: <Widget>[
                      _measurementTypeGroup(
                        sheetContext,
                        title: 'PRINCIPAIS',
                        types: const <BodyMeasurementType>[
                          BodyMeasurementType.weight,
                          BodyMeasurementType.shoulders,
                          BodyMeasurementType.chest,
                          BodyMeasurementType.waist,
                          BodyMeasurementType.hips,
                        ],
                      ),
                      const SizedBox(height: 20),
                      _measurementTypeGroup(
                        sheetContext,
                        title: 'BRAÇOS',
                        types: const <BodyMeasurementType>[
                          BodyMeasurementType.leftArm,
                          BodyMeasurementType.rightArm,
                          BodyMeasurementType.leftForearm,
                          BodyMeasurementType.rightForearm,
                        ],
                      ),
                      const SizedBox(height: 20),
                      _measurementTypeGroup(
                        sheetContext,
                        title: 'PERNAS',
                        types: const <BodyMeasurementType>[
                          BodyMeasurementType.leftThigh,
                          BodyMeasurementType.rightThigh,
                          BodyMeasurementType.leftCalf,
                          BodyMeasurementType.rightCalf,
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _measurementType = selected);
    }
  }

  Widget _measurementTypeGroup(
    BuildContext sheetContext, {
    required String title,
    required List<BodyMeasurementType> types,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: types.map((type) {
            final selected = type == _measurementType;
            final primary = Theme.of(sheetContext).colorScheme.primary;

            return Semantics(
              button: true,
              selected: selected,
              label: type.label,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(sheetContext, type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? primary.withValues(alpha: 0.14)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? primary : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (selected) ...<Widget>[
                        Icon(Icons.check_rounded, size: 16, color: primary),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        type.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: selected ? primary : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _openMeasurementActionPicker(
    BuildContext context, {
    required PulseSettings settings,
    required List<BodyMeasurementEntry> entries,
  }) async {
    final action = await showModalBottomSheet<_MeasurementAction>(
      context: context,
      backgroundColor: AppColors.surface,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: Icon(
                  Icons.monitor_weight_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Registrar peso'),
                subtitle: const Text(
                  'Para uma pesagem rápida, sem copiar outras medidas.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.pop(sheetContext, _MeasurementAction.weight),
              ),
              Divider(color: AppColors.border),
              ListTile(
                leading: Icon(
                  Icons.straighten,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Nova avaliação corporal'),
                subtitle: const Text(
                  'Registre apenas as regiões medidas hoje.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(
                  sheetContext,
                  _MeasurementAction.bodyAssessment,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (action == null || !context.mounted) {
      return;
    }

    BodyMeasurementEntry? entry;

    if (action == _MeasurementAction.weight) {
      BodyMeasurementEntry? latestWeight;
      for (final item in entries) {
        if (item.weightKg != null) {
          latestWeight = item;
          break;
        }
      }
      entry = await showModalBottomSheet<BodyMeasurementEntry>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        useSafeArea: true,
        builder: (_) => SafeArea(
          top: false,
          child: _WeightEntrySheet(
            latestWeight: latestWeight,
            measurementSystem: settings.measurementSystem,
          ),
        ),
      );
    } else {
      entry = await Navigator.of(context).push<BodyMeasurementEntry>(
        MaterialPageRoute<BodyMeasurementEntry>(
          builder: (_) => BodyMeasurementEditorScreen(
            history: entries,
            measurementSystem: settings.measurementSystem,
          ),
        ),
      );
    }

    if (entry == null || !context.mounted) {
      return;
    }

    await _saveMeasurement(context, entry);
  }

  Future<void> _saveMeasurement(
    BuildContext context,
    BodyMeasurementEntry entry,
  ) async {
    try {
      await ref.read(bodyMeasurementsControllerProvider.notifier).save(entry);

      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            entry.isWeightOnly ? 'Pesagem salva.' : 'Avaliação corporal salva.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            entry.isWeightOnly
                ? 'Não foi possível salvar a pesagem.'
                : 'Não foi possível salvar a avaliação.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteMeasurement(
    BuildContext context,
    BodyMeasurementEntry entry,
  ) async {
    final entryLabel = entry.isWeightOnly ? 'A pesagem' : 'A avaliação';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          entry.isWeightOnly ? 'Excluir pesagem?' : 'Excluir avaliação?',
        ),
        content: Text(
          '$entryLabel de ${DateFormat('dd/MM/yyyy').format(entry.recordedAt)} será removida.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await ref
        .read(bodyMeasurementsControllerProvider.notifier)
        .delete(entry.id);
  }

  double _displayMeasurement(
    double value,
    BodyMeasurementType type,
    PulseSettings settings,
  ) {
    if (settings.measurementSystem == MeasurementSystem.metric) {
      return value;
    }

    return type.isWeight ? value * 2.2046226218 : value / 2.54;
  }

  String _measurementUnit(BodyMeasurementType type, PulseSettings settings) {
    if (settings.measurementSystem == MeasurementSystem.metric) {
      return type.isWeight ? 'kg' : 'cm';
    }

    return type.isWeight ? 'lbs' : 'in';
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _formatVolume(double volume) {
    return '${NumberFormat('#,##0', 'pt_BR').format(volume)} kg';
  }

  String _formatExactVolume(double volume) {
    if (volume <= 0) {
      return '-- kg';
    }
    return '${NumberFormat('#,##0.##', 'pt_BR').format(volume)} kg';
  }

  String _formatWeight(double weight) {
    if (weight <= 0) {
      return '-- kg';
    }
    final value = weight % 1 == 0
        ? weight.toStringAsFixed(0)
        : weight.toStringAsFixed(1);
    return '$value kg';
  }
}

enum _MeasurementAction { weight, bodyAssessment }

class _WeightEntrySheet extends StatefulWidget {
  const _WeightEntrySheet({
    required this.latestWeight,
    required this.measurementSystem,
  });

  final BodyMeasurementEntry? latestWeight;
  final MeasurementSystem measurementSystem;

  @override
  State<_WeightEntrySheet> createState() => _WeightEntrySheetState();
}

class _WeightEntrySheetState extends State<_WeightEntrySheet> {
  final TextEditingController _weightController = TextEditingController();
  late DateTime _recordedAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _recordedAt = DateTime.now();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final latest = widget.latestWeight;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Registrar peso',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Cria uma pesagem independente. Nenhuma outra medida será copiada.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _weightController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Peso',
                suffixText: _unit,
                helperText: latest?.weightKg == null
                    ? 'Sem pesagem anterior'
                    : 'Último: ${_displayWeight(latest!.weightKg!)} $_unit em ${DateFormat('dd/MM/yyyy').format(latest.recordedAt)}',
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: 8),
            Material(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              child: ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Data da pesagem'),
                subtitle: Text(
                  DateFormat("dd/MM/yyyy 'às' HH:mm").format(_recordedAt),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectDate,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('SALVAR PESAGEM'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _unit {
    return widget.measurementSystem == MeasurementSystem.metric ? 'kg' : 'lbs';
  }

  String _displayWeight(double weightKg) {
    final displayed = widget.measurementSystem == MeasurementSystem.metric
        ? weightKg
        : weightKg * 2.2046226218;
    return displayed.toStringAsFixed(1).replaceAll('.', ',');
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_recordedAt),
    );
    if (!mounted) {
      return;
    }

    final selectedTime = time ?? TimeOfDay.fromDateTime(_recordedAt);
    setState(() {
      _recordedAt = DateTime(
        date.year,
        date.month,
        date.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    final entered = double.tryParse(
      _weightController.text.trim().replaceAll(',', '.'),
    );
    if (entered == null || entered <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um peso válido.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final weightKg = widget.measurementSystem == MeasurementSystem.metric
        ? entered
        : entered / 2.2046226218;

    setState(() => _saving = true);

    Navigator.pop(
      context,
      BodyMeasurementEntry(
        id: 'weight_${DateTime.now().microsecondsSinceEpoch}',
        recordedAt: _recordedAt,
        weightKg: weightKg,
      ),
    );
  }
}

class _ProgressTabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _ProgressTabsHeaderDelegate({
    required this.backgroundColor,
    required this.borderColor,
    required this.child,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Widget child;

  @override
  double get minExtent => 104;

  @override
  double get maxExtent => 104;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _ProgressTabsHeaderDelegate oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.child != child;
  }
}
