import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../providers/workout_provider.dart';
import '../theme/app_theme.dart';
import 'create_routine_screen.dart';
import 'routine_detail_screen.dart';

class WorkoutPlanScreen extends StatelessWidget {
  const WorkoutPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final myRoutines = provider.myRoutines;
    final preMadePrograms = provider.preMadePrograms;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Fichas de Treino', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          backgroundColor: AppColors.background,
          elevation: 0,
          automaticallyImplyLeading: false,
          bottom: TabBar(
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            tabs: const [
              Tab(text: 'MINHAS FICHAS'),
              Tab(text: 'CATÁLOGO OFICIAL'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMyRoutinesTab(context, provider, myRoutines),
            _buildCatalogTab(context, provider, preMadePrograms),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.black,
          elevation: 0,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateRoutineScreen()),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Nova Ficha', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  // =========================================================
  //  CONSTRUTOR DA ABA: MINHAS FICHAS
  // =========================================================
  Widget _buildMyRoutinesTab(BuildContext context, WorkoutProvider provider, List<WorkoutRoutine> routines) {
    if (routines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fitness_center_outlined, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'Você não possui fichas ativas.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (ctx) => ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  DefaultTabController.of(ctx).animateTo(1);
                },
                child: const Text('Explorar Catálogo', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
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

    // 1. Constrói os Acordeões (Pastas) com os programas do Catálogo
    groupedRoutines.forEach((groupName, groupRoutines) {
      listItems.add(
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            clipBehavior: Clip.antiAlias, // Evita vazamento visual do Swipe
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                collapsedIconColor: AppColors.textSecondary,
                iconColor: Theme.of(context).colorScheme.primary,
                leading: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.folder, color: Theme.of(context).colorScheme.primary, size: 20),
                ),
                title: Text(groupName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
                subtitle: Text('${groupRoutines.length} fichas neste programa', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                children: groupRoutines.map((routine) => _buildRoutineTile(context, provider, routine, isInsideGroup: true)).toList(),
              ),
            ),
          )
      );
    });

    // 2. Constrói as fichas avulsas embaixo
    for (var routine in looseRoutines) {
      listItems.add(
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            clipBehavior: Clip.antiAlias, // Evita vazamento visual da cor vermelha da lixeira
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: _buildRoutineTile(context, provider, routine, isInsideGroup: false),
          )
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      children: listItems,
    );
  }

  // =========================================================
  //  MÁGICA DO DISMISSIBLE APLICADA AQUI (Arrastar p/ Apagar)
  // =========================================================
  Widget _buildRoutineTile(BuildContext context, WorkoutProvider provider, WorkoutRoutine routine, {required bool isInsideGroup}) {
    return Dismissible(
      key: Key(routine.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent,
        child: const Icon(Icons.delete_sweep, color: Colors.white, size: 28),
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
          contentPadding: isInsideGroup ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isInsideGroup ? AppColors.surfaceLight : Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.fitness_center, color: Theme.of(context).colorScheme.primary, size: 20),
          ),
          title: Text(routine.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
          subtitle: Text(
            '${routine.exercises.length} exercício(s) • Foco: ${routine.focus}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            color: AppColors.surface,
            onSelected: (value) {
              if (value == 'view') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RoutineDetailScreen(routine: routine)),
                );
              } else if (value == 'edit') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('O painel de edição está sendo remodelado para o novo formato de Programas!'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else if (value == 'delete') {
                provider.deleteRoutine(routine.id);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view',
                child: Text('Ver Detalhes', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Text('Editar', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Excluir', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => RoutineDetailScreen(routine: routine)));
          },
        ),
      ),
    );
  }

  // =========================================================
  //  CONSTRUTOR DA ABA: CATÁLOGO DE PROGRAMAS
  // =========================================================
  Widget _buildCatalogTab(BuildContext context, WorkoutProvider provider, List programs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5))
            ),
            child: Row(
              children: [
                Icon(Icons.menu_book, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Programas de hipertrofia baseados nas metodologias do Guia Oficial.',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: programs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final prog = programs[index];
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
                              child: Icon(Icons.bolt, color: Theme.of(context).colorScheme.primary, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prog.name,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Contém ${prog.routines.length} fichas de treino',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
                              const Text('MÉTODO E OBJETIVO:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Text(
                                prog.focus,
                                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
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
                                  foregroundColor: Theme.of(context).colorScheme.primary,
                                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () {
                                  _showProgramDetails(context, provider, prog);
                                },
                                child: const Text('Ver Fichas', style: TextStyle(fontWeight: FontWeight.w800)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () {
                                  provider.importProgram(prog);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Programa ${prog.name} importado para Minhas Fichas!'),
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: const Text('Importar Grupo', style: TextStyle(fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ],
                        )
                      ],
                    )
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showProgramDetails(BuildContext context, WorkoutProvider provider, dynamic prog) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(prog.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(prog.focus, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 14)),
            const SizedBox(height: 24),
            const Text('FICHAS INCLUSAS NO PROGRAMA:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            ...prog.routines.map((r) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${r.exercises.length} exercícios estruturados.', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  provider.importProgram(prog);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Programa importado! Vá para "Minhas Fichas" para iniciar o treino.'),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        behavior: SnackBarBehavior.floating,
                      )
                  );
                },
                child: const Text('Importar Este Grupo', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}