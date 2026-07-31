import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../features/progress/domain/models/workout_progress_summary.dart';
import '../features/progress/presentation/providers/progress_providers.dart';
import '../theme/app_theme.dart';
import 'workout_history_detail_screen.dart';

class ProgressCalendarScreen extends ConsumerStatefulWidget {
  const ProgressCalendarScreen({super.key});

  @override
  ConsumerState<ProgressCalendarScreen> createState() =>
      _ProgressCalendarScreenState();
}

class _ProgressCalendarScreenState
    extends ConsumerState<ProgressCalendarScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final days = ref.watch(workoutCalendarProvider(_currentMonth));
    final daysInMonth = DateUtils.getDaysInMonth(
      _currentMonth.year,
      _currentMonth.month,
    );
    final firstWeekday = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    ).weekday;
    final offset = firstWeekday == 7 ? 0 : firstWeekday;
    final cells = ((daysInMonth + offset) / 7).ceil() * 7;
    final completed = days.values.fold<int>(
      0,
      (total, day) => total + day.completedCount,
    );
    final incomplete = days.values.fold<int>(
      0,
      (total, day) => total + day.incompleteCount,
    );
    final activeDays = days.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Calendário de Treinos',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      IconButton(
                        tooltip: 'Mês anterior',
                        onPressed: () => _changeMonth(-1),
                        icon: const Icon(Icons.chevron_left),
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
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      _legend(
                        Theme.of(context).colorScheme.primary,
                        'Concluído',
                      ),
                      const SizedBox(width: 14),
                      _legend(Colors.orangeAccent, 'Incompleto'),
                      const Spacer(),
                      Text(
                        '$activeDays dias ativos',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children:
                        const <String>[
                          'Dom',
                          'Seg',
                          'Ter',
                          'Qua',
                          'Qui',
                          'Sex',
                          'Sáb',
                        ].map((label) {
                          return SizedBox(
                            width: 34,
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
                        }).toList(),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    itemCount: cells,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
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
                      return _dayCell(context, date: date, summary: summary);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: _summaryCard(
                    context,
                    label: 'CONCLUÍDOS',
                    value: completed,
                    color: Theme.of(context).colorScheme.primary,
                    icon: Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryCard(
                    context,
                    label: 'INCOMPLETOS',
                    value: incomplete,
                    color: Colors.orangeAccent,
                    icon: Icons.pending_actions_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'TREINOS DO MÊS',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),
            if (days.isEmpty)
              _emptyMonth()
            else
              ..._orderedDays(days).map((day) => _dayHistoryCard(context, day)),
          ],
        ),
      ),
    );
  }

  bool get _canGoNext {
    final now = DateTime.now();
    return _currentMonth.year < now.year ||
        (_currentMonth.year == now.year && _currentMonth.month < now.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta);
    });
  }

  Widget _dayCell(
    BuildContext context, {
    required DateTime date,
    required WorkoutDaySummary? summary,
  }) {
    final hasCompleted = summary?.hasCompleted ?? false;
    final hasIncomplete = summary?.hasIncomplete ?? false;
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final primary = Theme.of(context).colorScheme.primary;
    final background = hasCompleted
        ? primary
        : hasIncomplete
        ? Colors.orangeAccent
        : Colors.transparent;

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: summary == null ? null : () => _showDay(context, summary),
        child: Container(
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: Border.all(
              color: isToday ? primary : Colors.transparent,
              width: 1.7,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Text(
                '${date.day}',
                style: TextStyle(
                  color: summary == null
                      ? AppColors.textPrimary
                      : hasCompleted
                      ? AppColors.onPrimary
                      : Colors.black87,
                  fontWeight: summary == null && !isToday
                      ? FontWeight.w400
                      : FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              if (hasCompleted && hasIncomplete)
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Colors.orangeAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(
    BuildContext context, {
    required String label,
    required int value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color, size: 25),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '$value',
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dayHistoryCard(BuildContext context, WorkoutDaySummary day) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(
                '${day.date.day}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          title: Text(
            _fullDateLabel(day.date),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          subtitle: Text(
            '${day.completedCount} concluídos • ${day.incompleteCount} incompletos',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          children: day.items.map((item) {
            final incomplete = item.isIncomplete;
            final color = incomplete
                ? Colors.orangeAccent
                : Theme.of(context).colorScheme.primary;

            return ListTile(
              contentPadding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
              leading: Icon(
                incomplete
                    ? Icons.pending_actions_rounded
                    : Icons.check_circle_rounded,
                color: color,
              ),
              title: Text(
                item.routineName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${DateFormat('HH:mm').format(item.date)} • ${item.duration} • ${item.totalSets} séries',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => WorkoutHistoryDetailScreen(workout: item),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _emptyMonth() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.calendar_month_outlined,
            color: AppColors.textSecondary,
            size: 40,
          ),
          SizedBox(height: 12),
          Text(
            'Nenhum treino neste mês',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Os dias treinados aparecerão aqui após o registro no histórico.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
    );
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

  List<WorkoutDaySummary> _orderedDays(Map<DateTime, WorkoutDaySummary> days) {
    final result = days.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  Future<void> _showDay(BuildContext context, WorkoutDaySummary day) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      useSafeArea: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _fullDateLabel(day.date),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                ...day.items.map((item) {
                  final incomplete = item.isIncomplete;
                  final color = incomplete
                      ? Colors.orangeAccent
                      : Theme.of(context).colorScheme.primary;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      incomplete
                          ? Icons.pending_actions_rounded
                          : Icons.check_circle_rounded,
                      color: color,
                    ),
                    title: Text(item.routineName),
                    subtitle: Text(
                      '${DateFormat('HH:mm').format(item.date)} • ${item.duration}',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              WorkoutHistoryDetailScreen(workout: item),
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
