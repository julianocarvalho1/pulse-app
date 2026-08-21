import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../features/progress/domain/models/workout_progress_summary.dart';
import '../features/progress/presentation/providers/progress_providers.dart';
import '../features/workouts/domain/models/workout_history_item.dart';
import '../theme/app_theme.dart';
import 'workout_history_detail_screen.dart';

/// Calendário completo exibido diretamente na aba Consistência.
///
/// Ele substitui a antiga tela separada de calendário para manter mês,
/// seleção de dia e histórico diário no mesmo fluxo de progresso.
class ConsistencyCalendarSection extends ConsumerStatefulWidget {
  const ConsistencyCalendarSection({super.key});

  @override
  ConsumerState<ConsistencyCalendarSection> createState() =>
      _ConsistencyCalendarSectionState();
}

class _ConsistencyCalendarSectionState
    extends ConsumerState<ConsistencyCalendarSection> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final days = ref.watch(workoutCalendarProvider(_currentMonth));
    final selectedDate = _effectiveSelectedDate(days);
    final selectedDay = selectedDate == null ? null : days[selectedDate];
    final completed = days.values.fold<int>(
      0,
      (total, day) => total + day.completedCount,
    );
    final incomplete = days.values.fold<int>(
      0,
      (total, day) => total + day.incompleteCount,
    );
    final freeActivities = days.values.fold<int>(
      0,
      (total, day) => total + day.freeActivityCount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    tooltip: 'Mês anterior',
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      _monthYearLabel(_currentMonth),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Próximo mês',
                    onPressed: _canGoNext ? () => _changeMonth(1) : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 7,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    _legend(
                      Theme.of(context).colorScheme.primary,
                      '$completed concluído${completed == 1 ? '' : 's'}',
                    ),
                    _legend(
                      Colors.orangeAccent,
                      '$incomplete incompleto${incomplete == 1 ? '' : 's'}',
                    ),
                    if (freeActivities > 0)
                      _legend(
                        AppColors.info,
                        '$freeActivities atividade${freeActivities == 1 ? '' : 's'} livre${freeActivities == 1 ? '' : 's'}',
                      ),
                    Text(
                      '${days.length} dia${days.length == 1 ? '' : 's'} ativo${days.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  _WeekdayLabel('D'),
                  _WeekdayLabel('S'),
                  _WeekdayLabel('T'),
                  _WeekdayLabel('Q'),
                  _WeekdayLabel('Q'),
                  _WeekdayLabel('S'),
                  _WeekdayLabel('S'),
                ],
              ),
              const SizedBox(height: 8),
              _calendarGrid(context, days: days, selectedDate: selectedDate),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _selectedDaySection(
          context,
          selectedDate: selectedDate,
          selectedDay: selectedDay,
        ),
      ],
    );
  }

  Widget _calendarGrid(
    BuildContext context, {
    required Map<DateTime, WorkoutDaySummary> days,
    required DateTime? selectedDate,
  }) {
    final daysInMonth = DateUtils.getDaysInMonth(
      _currentMonth.year,
      _currentMonth.month,
    );
    final firstWeekday = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    ).weekday;
    final offset = firstWeekday == DateTime.sunday ? 0 : firstWeekday;
    final cells = ((daysInMonth + offset) / 7).ceil() * 7;

    return GridView.builder(
      itemCount: cells,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 7,
        crossAxisSpacing: 7,
      ),
      itemBuilder: (context, index) {
        if (index < offset || index >= offset + daysInMonth) {
          return const SizedBox.shrink();
        }

        final dayNumber = index - offset + 1;
        final date = DateTime(
          _currentMonth.year,
          _currentMonth.month,
          dayNumber,
        );
        final summary = days[date];
        final selected =
            selectedDate != null && DateUtils.isSameDay(selectedDate, date);

        return _dayCell(
          context,
          date: date,
          summary: summary,
          selected: selected,
        );
      },
    );
  }

  Widget _dayCell(
    BuildContext context, {
    required DateTime date,
    required WorkoutDaySummary? summary,
    required bool selected,
  }) {
    final hasCompleted = summary?.hasCompleted ?? false;
    final hasIncomplete = summary?.hasIncomplete ?? false;
    final hasFreeActivity = summary?.hasFreeActivity ?? false;
    final onlyFreeActivity =
        summary != null && summary.total == summary.freeActivityCount;
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final primary = Theme.of(context).colorScheme.primary;
    final background = onlyFreeActivity
        ? AppColors.info
        : hasCompleted
        ? primary
        : hasIncomplete
        ? Colors.orangeAccent
        : Colors.transparent;
    final contentColor = summary == null
        ? AppColors.textPrimary
        : hasCompleted || onlyFreeActivity
        ? AppColors.onPrimary
        : Colors.black87;

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDate = date;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? primary
                  : isToday
                  ? primary.withValues(alpha: 0.75)
                  : Colors.transparent,
              width: selected ? 2.5 : 1.5,
            ),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: primary.withValues(alpha: 0.22),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Text(
                '${date.day}',
                style: TextStyle(
                  color: contentColor,
                  fontWeight: summary == null && !selected && !isToday
                      ? FontWeight.w400
                      : FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              if (hasCompleted && hasIncomplete)
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.orangeAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              if (hasFreeActivity && !onlyFreeActivity)
                Positioned(
                  left: 1,
                  bottom: 1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.info,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectedDaySection(
    BuildContext context, {
    required DateTime? selectedDate,
    required WorkoutDaySummary? selectedDay,
  }) {
    final effectiveDate = selectedDate ?? _currentMonth;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${effectiveDate.day}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _fullDateLabel(effectiveDate),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedDay == null
                          ? 'Nenhuma atividade registrada'
                          : '${selectedDay.total} atividade${selectedDay.total == 1 ? '' : 's'} registrada${selectedDay.total == 1 ? '' : 's'}',
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
          if (selectedDay == null)
            _emptySelectedDay()
          else
            ...selectedDay.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _workoutItem(context, item),
              ),
            ),
        ],
      ),
    );
  }

  Widget _workoutItem(BuildContext context, WorkoutHistoryItem item) {
    final incomplete = item.isIncomplete;
    final isFreeActivity = item.isFreeActivityOnly;
    final isCardio = item.isCardioOnly;
    final color = isFreeActivity
        ? AppColors.info
        : incomplete
        ? Colors.orangeAccent
        : Theme.of(context).colorScheme.primary;

    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(13),
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
          padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isFreeActivity
                      ? Icons.sports_gymnastics_rounded
                      : isCardio
                      ? Icons.directions_run_rounded
                      : incomplete
                      ? Icons.pending_actions_rounded
                      : Icons.check_circle_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.routineName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _workoutSubtitle(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isFreeActivity
                      ? 'ATIVIDADE'
                      : incomplete
                      ? 'INCOMPLETO'
                      : 'CONCLUÍDO',
                  style: TextStyle(
                    color: color,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptySelectedDay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.event_available_outlined,
            color: AppColors.textMuted,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            'Toque em outro dia para consultar o histórico.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  DateTime? _effectiveSelectedDate(Map<DateTime, WorkoutDaySummary> days) {
    final selected = _selectedDate;
    if (selected != null &&
        selected.year == _currentMonth.year &&
        selected.month == _currentMonth.month) {
      return DateTime(selected.year, selected.month, selected.day);
    }

    if (days.isNotEmpty) {
      final dates = days.keys.toList()..sort();
      return dates.last;
    }

    final now = DateTime.now();
    if (_currentMonth.year == now.year && _currentMonth.month == now.month) {
      return DateTime(now.year, now.month, now.day);
    }

    return DateTime(_currentMonth.year, _currentMonth.month, 1);
  }

  bool get _canGoNext {
    final now = DateTime.now();
    return _currentMonth.year < now.year ||
        (_currentMonth.year == now.year && _currentMonth.month < now.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta);
      _selectedDate = null;
    });
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _workoutSubtitle(WorkoutHistoryItem item) {
    final time = DateFormat('HH:mm').format(item.date);
    if (item.isFreeActivityOnly && item.freeActivities.isNotEmpty) {
      final activity = item.freeActivities.first;
      final replacement = activity.replacedPlannedWorkout
          ? ' • substituiu o treino'
          : '';
      return '$time • ${activity.durationMinutes} min • ${activity.intensity.label}$replacement';
    }

    if (item.isCardioOnly && item.cardio.isNotEmpty) {
      return '$time • ${item.totalCardioMinutes} min • ${item.cardio.first.modality.label}';
    }

    if (item.cardio.isNotEmpty) {
      return '$time • ${item.totalSets} séries • ${item.totalCardioMinutes} min de cardio';
    }

    return '$time • ${item.duration} • ${item.totalSets} séries';
  }

  String _monthYearLabel(DateTime date) {
    const months = <String>[
      'JANEIRO',
      'FEVEREIRO',
      'MARÇO',
      'ABRIL',
      'MAIO',
      'JUNHO',
      'JULHO',
      'AGOSTO',
      'SETEMBRO',
      'OUTUBRO',
      'NOVEMBRO',
      'DEZEMBRO',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _fullDateLabel(DateTime date) {
    const weekdays = <String>[
      'segunda-feira',
      'terça-feira',
      'quarta-feira',
      'quinta-feira',
      'sexta-feira',
      'sábado',
      'domingo',
    ];
    const months = <String>[
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} de ${months[date.month - 1]}';
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
