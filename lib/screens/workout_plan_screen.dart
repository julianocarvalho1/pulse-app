import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../features/workout_generator/presentation/screens/workout_generator_screen.dart';
import '../features/workouts/presentation/providers/workout_controller.dart';
import '../theme/app_theme.dart';
import 'create_routine_screen.dart';
import 'exercises_screen.dart';
import 'routine_detail_screen.dart';
import 'routine_editor_screen.dart';

class WorkoutPlanScreen extends ConsumerWidget {
  const WorkoutPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(workoutControllerProvider);
    final provider = ref.read(workoutControllerProvider.notifier);
    final myRoutines = workoutState.myRoutines;
    final preMadePrograms = workoutState.preMadePrograms;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          primary: true,
          toolbarHeight: 60,
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 20,
          title: const Text(
            'Treinos',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
          ),
          bottom: TabBar(
            indicatorColor: Theme.of(context).colorScheme.primary,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            dividerColor: AppColors.border,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            tabs: const <Widget>[
              Tab(text: 'Fichas'),
              Tab(text: 'Programas'),
              Tab(text: 'Exercícios'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _buildMyRoutinesTab(context, provider, myRoutines),
            _buildCatalogTab(context, provider, preMadePrograms),
            const ExercisesScreen(embedded: true),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          onPressed: () => _showCreateOptions(context),
          icon: const Icon(Icons.add),
          label: const Text(
            'Criar treino',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            MediaQuery.viewPaddingOf(sheetContext).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Criar treino',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Gere um programa completo ou monte uma ficha manualmente.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              _CreateOptionTile(
                icon: Icons.auto_awesome_rounded,
                title: 'Gerar programa inteligente',
                subtitle: 'Objetivo, nível, dias, tempo e equipamentos.',
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WorkoutGeneratorScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _CreateOptionTile(
                icon: Icons.edit_note_rounded,
                title: 'Criar ficha manualmente',
                subtitle: 'Escolha cada exercício e etapa de cardio.',
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateRoutineScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================
  //  CONSTRUTOR DA ABA: MINHAS FICHAS
  // =========================================================
  Widget _buildMyRoutinesTab(
    BuildContext context,
    WorkoutController provider,
    List<WorkoutRoutine> routines,
  ) {
    if (routines.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 96),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: <Widget>[
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fitness_center_outlined,
                    size: 29,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Crie sua primeira ficha',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 7),
                Text(
                  'Use “Criar treino” para gerar um programa ou montar uma ficha manualmente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Builder(
                  builder: (tabContext) => OutlinedButton.icon(
                    onPressed: () {
                      DefaultTabController.of(tabContext).animateTo(1);
                    },
                    icon: const Icon(Icons.menu_book_outlined, size: 18),
                    label: const Text('Explorar programas'),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    Map<String, List<WorkoutRoutine>> groupedRoutines = {};
    List<WorkoutRoutine> looseRoutines = [];

    for (var r in routines) {
      if (r.groupName.isNotEmpty) {
        groupedRoutines.putIfAbsent(r.groupName, () => []).add(r);
      } else {
        looseRoutines.add(r);
      }
    }

    List<Widget> listItems = [];

    groupedRoutines.forEach((groupName, groupRoutines) {
      listItems.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                collapsedIconColor: AppColors.textSecondary,
                iconColor: Theme.of(context).colorScheme.primary,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.folder,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  groupName,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${groupRoutines.length} fichas neste programa',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                childrenPadding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                children: groupRoutines
                    .map(
                      (routine) => _buildRoutineTile(
                        context,
                        provider,
                        routine,
                        isInsideGroup: true,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      );
    });

    for (var routine in looseRoutines) {
      listItems.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: _buildRoutineTile(
            context,
            provider,
            routine,
            isInsideGroup: false,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      children: listItems,
    );
  }

  Widget _buildRoutineTile(
    BuildContext context,
    WorkoutController provider,
    WorkoutRoutine routine, {
    required bool isInsideGroup,
  }) {
    return Dismissible(
      key: Key(routine.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent,
        child: Icon(Icons.delete_sweep, color: AppColors.textPrimary, size: 28),
      ),
      onDismissed: (direction) {
        provider.deleteRoutine(routine.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${routine.name} foi apagada.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(top: isInsideGroup ? 8.0 : 0),
        child: ListTile(
          contentPadding: isInsideGroup
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isInsideGroup
                  ? AppColors.surfaceLight
                  : Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _routineIcon(routine.type),
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          title: Text(
            routine.name,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            '${routine.typeLabel} • ${routine.activitySummary} • ${routine.focus}',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
            color: AppColors.surface,
            onSelected: (value) {
              if (value == 'view') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RoutineDetailScreen(routine: routine),
                  ),
                );
              } else if (value == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute<bool>(
                    builder: (_) => RoutineEditorScreen(routine: routine),
                  ),
                );
              } else if (value == 'delete') {
                provider.deleteRoutine(routine.id);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'view',
                child: Text(
                  'Ver Detalhes',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Text(
                  'Editar',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Excluir',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RoutineDetailScreen(routine: routine),
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _routineIcon(RoutineType type) {
    return switch (type) {
      RoutineType.strength => Icons.fitness_center_rounded,
      RoutineType.cardio => Icons.directions_run_rounded,
      RoutineType.mixed => Icons.sports_gymnastics_rounded,
    };
  }

  // =========================================================
  //  CONSTRUTOR DA ABA: CATÁLOGO DE PROGRAMAS
  // =========================================================
  Widget _buildCatalogTab(
    BuildContext context,
    WorkoutController provider,
    List<WorkoutProgram> programs,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.menu_book,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Programas prontos para você importar e adaptar à sua rotina.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: programs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final prog = programs[index];
                final isImported = provider.isProgramImported(prog);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.bolt,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prog.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Contém ${prog.routines.length} fichas de treino',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MÉTODO E OBJETIVO:',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              prog.focus,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () {
                                _showProgramDetails(context, provider, prog);
                              },
                              child: const Text(
                                'Ver Fichas',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: AppColors.onPrimary,
                                disabledBackgroundColor: AppColors.surfaceLight,
                                disabledForegroundColor:
                                    AppColors.textSecondary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onPressed: isImported
                                  ? null
                                  : () {
                                      final imported = provider.importProgram(
                                        prog,
                                      );

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            imported
                                                ? 'Programa ${prog.name} importado para Minhas Fichas!'
                                                : 'Este programa já está em Minhas Fichas.',
                                          ),
                                          backgroundColor: imported
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : AppColors.surfaceLight,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                              icon: Icon(
                                isImported
                                    ? Icons.check_circle
                                    : Icons.download_rounded,
                                size: 18,
                              ),
                              label: Text(
                                isImported ? 'Já Importado' : 'Importar Grupo',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showProgramDetails(
    BuildContext context,
    WorkoutController provider,
    WorkoutProgram prog,
  ) {
    final isImported = provider.isProgramImported(prog);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              prog.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              prog.focus,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'FICHAS INCLUSAS NO PROGRAMA:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ...prog.routines.map(
              (r) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${r.exercises.length} exercícios estruturados.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: AppColors.onPrimary,
                  disabledBackgroundColor: AppColors.surfaceLight,
                  disabledForegroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isImported
                    ? null
                    : () {
                        final imported = provider.importProgram(prog);
                        Navigator.pop(ctx);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              imported
                                  ? 'Programa importado! Vá para "Minhas Fichas" para iniciar o treino.'
                                  : 'Este programa já está em Minhas Fichas.',
                            ),
                            backgroundColor: imported
                                ? Theme.of(context).colorScheme.primary
                                : AppColors.surfaceLight,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                icon: Icon(
                  isImported ? Icons.check_circle : Icons.download_rounded,
                ),
                label: Text(
                  isImported ? 'Programa já importado' : 'Importar Este Grupo',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateOptionTile extends StatelessWidget {
  const _CreateOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
