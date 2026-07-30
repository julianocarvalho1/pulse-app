import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../features/workouts/presentation/providers/workout_controller.dart';
import '../theme/app_theme.dart';

class ProgressCalendarScreen extends ConsumerStatefulWidget {
  const ProgressCalendarScreen({super.key});

  @override
  ConsumerState<ProgressCalendarScreen> createState() =>
      _ProgressCalendarScreenState();
}

class _ProgressCalendarScreenState
    extends ConsumerState<ProgressCalendarScreen> {
  DateTime _currentMonth = DateTime.now();

  void _mudarMes(int delta) {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + delta,
        1,
      );
    });
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  int _getFirstWeekday(int year, int month) {
    return DateTime(year, month, 1).weekday; // 1 = Seg, 7 = Dom
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(workoutControllerProvider);
    final history = provider.history;

    int daysInMonth = _getDaysInMonth(_currentMonth.year, _currentMonth.month);
    int firstWeekday = _getFirstWeekday(
      _currentMonth.year,
      _currentMonth.month,
    );
    int startOffset = firstWeekday == 7
        ? 0
        : firstWeekday; // Ajusta pra Domingo ser 0

    // Conta total de treinos do mês atual para exibir no cabeçalho
    int treinosDoMes = history
        .where(
          (h) =>
              h.date.year == _currentMonth.year &&
              h.date.month == _currentMonth.month,
        )
        .length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: const Text(
          'Calendário de Treinos',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                        ),
                        onPressed: () => _mudarMes(-1),
                      ),
                      Text(
                        DateFormat(
                          'MMMM yyyy',
                          'pt_BR',
                        ).format(_currentMonth).toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                        ),
                        onPressed: () => _mudarMes(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Cabeçalho dos dias da semana
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb']
                        .map((dia) {
                          return SizedBox(
                            width: 32,
                            child: Center(
                              child: Text(
                                dia,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        })
                        .toList(),
                  ),
                  const SizedBox(height: 12),

                  // GRID DO CALENDÁRIO MANUAL
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                    itemCount: daysInMonth + startOffset,
                    itemBuilder: (context, index) {
                      if (index < startOffset) {
                        return const SizedBox.shrink(); // Espaços vazios do início do mês
                      }

                      int day = index - startOffset + 1;
                      DateTime currentDay = DateTime(
                        _currentMonth.year,
                        _currentMonth.month,
                        day,
                      );

                      // Verifica se treinou neste dia exato
                      bool hasWorkout = history.any(
                        (h) =>
                            h.date.year == currentDay.year &&
                            h.date.month == currentDay.month &&
                            h.date.day == currentDay.day,
                      );
                      bool isToday =
                          DateTime.now().year == currentDay.year &&
                          DateTime.now().month == currentDay.month &&
                          DateTime.now().day == currentDay.day;

                      return Container(
                        decoration: BoxDecoration(
                          color: hasWorkout
                              ? Theme.of(context).colorScheme.primary
                              : (isToday
                                    ? AppColors.border
                                    : Colors.transparent),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isToday
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              color: hasWorkout ? Colors.black : Colors.white,
                              fontWeight: hasWorkout || isToday
                                  ? FontWeight.w800
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'VOCÊ TREINOU $treinosDoMes DIAS NESTE MÊS!',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
