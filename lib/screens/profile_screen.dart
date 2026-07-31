import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../features/settings/domain/pulse_settings.dart';
import '../features/settings/presentation/providers/settings_controller.dart';
import '../features/workouts/domain/models/workout_history_item.dart';
import '../features/workouts/presentation/providers/workout_controller.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';
import 'workout_history_detail_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.onOpenWorkouts, this.onOpenProgress});

  final VoidCallback? onOpenWorkouts;
  final VoidCallback? onOpenProgress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(workoutControllerProvider);
    final workoutController = ref.read(workoutControllerProvider.notifier);
    final settingsAsync = ref.watch(settingsControllerProvider);
    final settings = switch (settingsAsync) {
      AsyncData<PulseSettings>(:final value) => value,
      _ => PulseSettings.defaults(),
    };

    final history = workoutState.history;
    final recentHistory = history.take(5).toList(growable: false);
    final completedHistoryCount = history
        .where((item) => !item.isIncomplete)
        .length;
    final incompleteHistoryCount = history
        .where((item) => item.isIncomplete)
        .length;
    final profile = settings.profile;
    final activeRoutine =
        workoutState.nextRoutineToTrain ??
        (workoutState.myRoutines.isNotEmpty
            ? workoutState.myRoutines.first
            : null);
    final currentFocus = activeRoutine?.focus ?? 'Construa sua primeira rotina';
    final currentWeightLabel = profile.weightKg <= 0
        ? '—'
        : settings.measurementSystem == MeasurementSystem.metric
        ? '${profile.weightKg.toStringAsFixed(1)} kg'
        : '${(profile.weightKg * 2.2046226218).toStringAsFixed(1)} lbs';

    return ColoredBox(
      color: AppColors.background,
      child: CustomScrollView(
        key: const PageStorageKey<String>('profile-scroll'),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: <Widget>[
          SliverAppBar(
            primary: true,
            pinned: true,
            floating: true,
            snap: true,
            toolbarHeight: 60,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            titleSpacing: 20,
            automaticallyImplyLeading: false,
            title: const Text(
              'Perfil',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            actions: <Widget>[
              IconButton(
                tooltip: 'Abrir configurações',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
                icon: const Icon(Icons.settings_outlined),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              MediaQuery.paddingOf(context).bottom + 32,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _profileHeader(
                    context,
                    profile.displayName,
                    currentFocus,
                    completedHistoryCount,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _ProfileMetric(
                          value: '$completedHistoryCount',
                          label: 'Treinos',
                          icon: Icons.check_circle_outline,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ProfileMetric(
                          value: '${workoutState.myRoutines.length}',
                          label: 'Fichas',
                          icon: Icons.fitness_center_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ProfileMetric(
                          value: currentWeightLabel,
                          label: 'Peso atual',
                          icon: Icons.monitor_weight_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'TREINOS RECENTES',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (incompleteHistoryCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$incompleteHistoryCount incompleto${incompleteHistoryCount == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else if (history.isNotEmpty && onOpenProgress != null)
                        TextButton(
                          onPressed: onOpenProgress,
                          child: const Text('Ver todos'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (recentHistory.isEmpty)
                    _emptyHistory(context, onOpenWorkouts)
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentHistory.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _historyItem(
                        context,
                        workoutController,
                        recentHistory[index],
                      ),
                    ),
                  if (history.isNotEmpty &&
                      incompleteHistoryCount > 0 &&
                      onOpenProgress != null) ...<Widget>[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onOpenProgress,
                        icon: const Icon(Icons.insights_outlined),
                        label: const Text('Ver histórico completo'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyItem(
    BuildContext context,
    WorkoutController controller,
    WorkoutHistoryItem item,
  ) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(item.date);
    final isIncomplete = item.isIncomplete;
    final statusColor = isIncomplete ? AppColors.warning : AppColors.success;
    final statusIcon = isIncomplete
        ? Icons.pending_actions_rounded
        : Icons.check_circle;
    final statusLabel = isIncomplete ? 'INCOMPLETO' : 'CONCLUÍDO';

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) {
        controller.deleteHistoryItem(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Treino excluído do histórico.')),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WorkoutHistoryDetailScreen(workout: item),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.routineName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 7,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
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
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.totalExercises} exerc.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
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

  Widget _profileHeader(
    BuildContext context,
    String userName,
    String currentFocus,
    int completedWorkouts,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.primarySoft, AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryBorder),
            ),
            child: Icon(
              Icons.person_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  currentFocus,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    completedWorkouts == 0
                        ? 'Nenhum treino concluído'
                        : '$completedWorkouts treino${completedWorkouts == 1 ? '' : 's'} concluído${completedWorkouts == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: completedWorkouts == 0
                          ? AppColors.textSecondary
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyHistory(BuildContext context, VoidCallback? onOpenWorkouts) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.fitness_center_outlined,
              size: 27,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Seu histórico começa no primeiro treino',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ao concluir ou salvar uma sessão, ela aparecerá aqui com duração, exercícios e status.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          if (onOpenWorkouts != null) ...<Widget>[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onOpenWorkouts,
              icon: const Icon(Icons.fitness_center, size: 18),
              label: const Text('Abrir treinos'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 18,
            child: FittedBox(
              fit: BoxFit.scaleDown,
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
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
