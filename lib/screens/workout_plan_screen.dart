import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../features/personal_workout_import/presentation/screens/personal_workout_import_screen.dart';
import '../features/workout_generator/presentation/screens/workout_generator_screen.dart';
import '../features/workouts/data/catalogs/core_extra_session_catalog.dart';
import '../features/workouts/domain/models/cardio_log.dart';
import '../features/workouts/presentation/providers/workout_controller.dart';
import '../features/workout_sharing/domain/services/pulse_workout_codec.dart';
import '../features/workout_sharing/presentation/screens/pulse_workout_import_screen.dart';
import '../features/workout_sharing/presentation/screens/pulse_workout_qr_scanner_screen.dart';
import '../features/workout_sharing/presentation/widgets/pulse_workout_share_sheet.dart';
import '../theme/app_theme.dart';
import 'create_routine_screen.dart';
import 'exercises_screen.dart';
import 'routine_detail_screen.dart';
import 'routine_editor_screen.dart';

class WorkoutPlanScreen extends ConsumerWidget {
  const WorkoutPlanScreen({super.key, this.onBackToHome});

  final VoidCallback? onBackToHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(workoutControllerProvider);
    final provider = ref.read(workoutControllerProvider.notifier);
    final myRoutines = workoutState.myRoutines;
    final preMadePrograms = workoutState.preMadePrograms;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          primary: true,
          toolbarHeight: 54,
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: onBackToHome == null,
          leading: onBackToHome == null
              ? null
              : IconButton(
                  tooltip: 'Voltar para o início',
                  onPressed: onBackToHome,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
          titleSpacing: onBackToHome == null ? 20 : 0,
          title: const Text(
            'Treinos',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
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
              Tab(text: 'Extras'),
              Tab(text: 'Exercícios'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _buildMyRoutinesTab(context, provider, myRoutines),
            _buildCatalogTab(context, provider, preMadePrograms),
            _buildExtraSessionsTab(context, provider, myRoutines),
            const ExercisesScreen(embedded: true),
          ],
        ),
        floatingActionButton: SizedBox(
          height: 40,
          child: FilledButton.icon(
            onPressed: () => _showCreateOptions(context),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 0,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 17),
            label: const Text(
              'Criar treino',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
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
                'Gere, importe do personal ou monte uma ficha manualmente.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 10),
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
                icon: Icons.assignment_ind_outlined,
                title: 'Importar ficha do personal',
                subtitle:
                    'Importe DOCX, TXT, CSV ou cole o texto para revisar.',
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PersonalWorkoutImportScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _CreateOptionTile(
                icon: Icons.swap_horiz_rounded,
                title: 'Importar arquivo do PULSE',
                subtitle: 'Receba uma ficha ou programa compartilhado.',
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final imported = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute<bool>(
                      builder: (_) => const PulseWorkoutImportScreen(),
                    ),
                  );
                  if ((imported ?? false) && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Conteúdo do PULSE adicionado.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 10),
              _CreateOptionTile(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Ler QR Code do PULSE',
                subtitle: 'Aponte a câmera para receber uma ficha ou programa.',
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final allowed = await _confirmCameraUse(context);
                  if (!allowed || !context.mounted) {
                    return;
                  }
                  final imported = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute<bool>(
                      builder: (_) => const PulseWorkoutQrScannerScreen(),
                    ),
                  );
                  if ((imported ?? false) && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Conteúdo do QR Code adicionado.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _confirmCameraUse(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.qr_code_scanner_rounded),
        title: const Text('Uso da câmera'),
        content: const Text(
          'O PULSE usará a câmera somente enquanto esta tela estiver aberta '
          'para reconhecer um QR Code de treino. Imagens e vídeos não são '
          'salvos nem enviados pela internet.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Agora não'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Usar câmera'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
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
      final primary = Theme.of(context).colorScheme.primary;
      final isActiveProgram = provider.activeProgramName == groupName;

      listItems.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: isActiveProgram
                    ? AppColors.primaryBorder
                    : AppColors.border,
                width: isActiveProgram ? 1.5 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                childrenPadding: const EdgeInsets.only(
                  left: 12,
                  right: 12,
                  bottom: 12,
                ),
                collapsedIconColor: AppColors.textSecondary,
                iconColor: primary,
                leading: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        primary.withValues(alpha: 0.22),
                        primary.withValues(alpha: 0.09),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: primary.withValues(alpha: 0.12)),
                  ),
                  child: Icon(Icons.folder_rounded, color: primary, size: 22),
                ),
                title: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        groupName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          height: 1.15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isActiveProgram) ...<Widget>[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'ATIVO',
                          style: TextStyle(
                            color: primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.45,
                          ),
                        ),
                      ),
                    ],
                    PopupMenuButton<String>(
                      tooltip: 'Opções do programa',
                      color: AppColors.surface,
                      onSelected: (value) {
                        if (value == 'share_program') {
                          showPulseWorkoutShareSheet(
                            context,
                            const PulseWorkoutCodec().programDocument(
                              name: groupName,
                              routines: groupRoutines,
                            ),
                          );
                        } else if (value == 'delete_program') {
                          _confirmDeleteProgram(
                            context,
                            provider,
                            groupName,
                            groupRoutines.length,
                          );
                        }
                      },
                      itemBuilder: (_) => const <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'share_program',
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.ios_share_rounded),
                              SizedBox(width: 10),
                              Text('Compartilhar programa'),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete_program',
                          child: Row(
                            children: <Widget>[
                              Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Excluir programa inteiro',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.view_agenda_outlined,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${groupRoutines.length} fichas neste programa',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
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
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
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
    final primary = Theme.of(context).colorScheme.primary;

    return Dismissible(
      key: Key(routine.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmRoutineDeletion(context, routine),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(isInsideGroup ? 15 : 0),
        ),
        child: const Icon(
          Icons.delete_sweep_rounded,
          color: Colors.white,
          size: 28,
        ),
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
        padding: EdgeInsets.only(top: isInsideGroup ? 8 : 0),
        child: Container(
          decoration: BoxDecoration(
            gradient: isInsideGroup
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      AppColors.surfaceLight,
                      Color.alphaBlend(
                        primary.withValues(alpha: 0.035),
                        AppColors.surface,
                      ),
                    ],
                  )
                : null,
            color: isInsideGroup ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isInsideGroup
                  ? AppColors.primaryBorder.withValues(alpha: 0.72)
                  : AppColors.border,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              minVerticalPadding: 8,
              contentPadding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _routineIcon(routine.type),
                  color: primary,
                  size: 21,
                ),
              ),
              title: Text(
                routine.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  height: 1.15,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: <Widget>[
                        _buildRoutineMetaChip(routine.typeLabel),
                        _buildRoutineMetaChip(routine.activitySummary),
                      ],
                    ),
                    if (routine.focus.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Icon(
                                Icons.center_focus_strong_outlined,
                                size: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                routine.focus,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11.5,
                                  height: 1.18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              trailing: PopupMenuButton<String>(
                tooltip: 'Opções da ficha',
                icon: Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
                color: AppColors.surface,
                onSelected: (value) async {
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
                    final confirmed = await _confirmRoutineDeletion(
                      context,
                      routine,
                    );
                    if (confirmed && context.mounted) {
                      provider.deleteRoutine(routine.id);
                      _showRoutineDeletedMessage(context, routine);
                    }
                  }
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'view',
                    child: Text(
                      'Ver detalhes',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Text(
                      'Editar',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                  const PopupMenuItem<String>(
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
        ),
      ),
    );
  }

  Future<bool> _confirmRoutineDeletion(
    BuildContext context,
    WorkoutRoutine routine,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir esta ficha?'),
        content: Text(
          '“${routine.name}” será removida dos seus treinos. O histórico já registrado será mantido. Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirmDeleteRoutineButton'),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir ficha'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  void _showRoutineDeletedMessage(
    BuildContext context,
    WorkoutRoutine routine,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${routine.name} foi apagada.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildRoutineMetaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.70)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteProgram(
    BuildContext context,
    WorkoutController provider,
    String groupName,
    int routineCount,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Excluir programa inteiro?'),
        content: Text(
          '“$groupName” possui $routineCount ficha${routineCount == 1 ? '' : 's'}. Todas serão removidas de uma vez. O histórico dos treinos já realizados será mantido.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir programa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    provider.deleteProgram(groupName);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Programa “$groupName” excluído.'),
        behavior: SnackBarBehavior.floating,
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

  Widget _buildExtraSessionsTab(
    BuildContext context,
    WorkoutController provider,
    List<WorkoutRoutine> savedRoutines,
  ) {
    final primary = Theme.of(context).colorScheme.primary;
    final routines = CoreExtraSessionCatalog.routines;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: primary.withValues(alpha: 0.45)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.add_circle_outline_rounded, color: primary, size: 20),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Faça uma sessão extra sem alterar a sequência do seu programa atual. Você também pode salvar uma cópia para personalizar.',
                  style: TextStyle(
                    color: primary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final routine in routines) ...<Widget>[
          Container(
            key: Key('extra-session-${routine.id}'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.sports_gymnastics_rounded,
                        color: primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            routine.name,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            routine.focus,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    _buildRoutineMetaChip(routine.activitySummary),
                    _buildRoutineMetaChip(_extraSessionDuration(routine.id)),
                    _buildRoutineMetaChip(_extraSessionEquipment(routine.id)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  routine.exercises
                      .map((exercise) => exercise.name)
                      .join(' • '),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        key: Key('view-${routine.id}'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => RoutineDetailScreen(
                                routine: routine,
                                allowEditing: false,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: const Text('Ver e iniciar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        key: Key('copy-${routine.id}'),
                        onPressed: () => _copyExtraSession(
                          context,
                          provider,
                          routine,
                          savedRoutines,
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 17),
                        label: const Text('Salvar cópia'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  String _extraSessionDuration(String id) {
    return switch (id) {
      'extra_core_express' => '≈ 10 min',
      'extra_core_complete' => '≈ 20 min',
      'extra_core_circuit' => '≈ 15 min',
      _ => 'Sessão curta',
    };
  }

  String _extraSessionEquipment(String id) {
    return switch (id) {
      'extra_core_complete' => 'Colchonete + polia',
      _ => 'Sem equipamento',
    };
  }

  void _copyExtraSession(
    BuildContext context,
    WorkoutController provider,
    WorkoutRoutine routine,
    List<WorkoutRoutine> savedRoutines,
  ) {
    final existingNames = savedRoutines
        .map((item) => item.name.trim().toLowerCase())
        .toSet();
    var copyName = routine.name;
    var copyNumber = 1;

    while (existingNames.contains(copyName.toLowerCase())) {
      copyNumber++;
      copyName = copyNumber == 2
          ? '${routine.name} (cópia)'
          : '${routine.name} (cópia $copyNumber)';
    }

    provider.createRoutine(
      copyName,
      routine.focus,
      '',
      List<Exercise>.from(routine.exercises),
      cardio: List<RoutineCardio>.from(routine.cardio),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$copyName foi salva em Fichas.'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'VER',
          onPressed: () => DefaultTabController.maybeOf(context)?.animateTo(0),
        ),
      ),
    );
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Escolha um programa, confira todas as fichas e adapte exercícios, séries e descansos depois de adicionar.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 54),
              itemCount: programs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final prog = programs[index];
                final isImported = provider.isProgramImported(prog);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _programIcon(prog),
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prog.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${prog.routines.length} fichas • ${prog.frequencyPerWeek}x por semana',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isImported)
                            Icon(
                              Icons.check_circle_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 22,
                            ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _programBadge(
                            context,
                            icon: Icons.signal_cellular_alt_rounded,
                            label: prog.level,
                          ),
                          _programBadge(
                            context,
                            icon: Icons.flag_rounded,
                            label: prog.objective,
                          ),
                          _programBadge(
                            context,
                            icon: Icons.schedule_rounded,
                            label: prog.estimatedDuration,
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          prog.focus,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              onPressed: () {
                                _showProgramDetails(context, provider, prog);
                              },
                              icon: const Icon(
                                Icons.visibility_outlined,
                                size: 18,
                              ),
                              label: const Text(
                                'Ver estrutura',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
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
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              onPressed: isImported
                                  ? null
                                  : () {
                                      _importCatalogProgram(
                                        context,
                                        provider,
                                        prog,
                                      );
                                    },
                              icon: Icon(
                                isImported
                                    ? Icons.check_circle
                                    : Icons.add_rounded,
                                size: 18,
                              ),
                              label: Text(
                                isImported ? 'Adicionado' : 'Adicionar',
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

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.6,
        maxChildSize: 0.96,
        builder: (sheetContext, scrollController) => Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _programIcon(prog),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prog.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${prog.routines.length} fichas • ${prog.frequencyPerWeek}x por semana',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _programBadge(
                        context,
                        icon: Icons.signal_cellular_alt_rounded,
                        label: prog.level,
                      ),
                      _programBadge(
                        context,
                        icon: Icons.flag_rounded,
                        label: prog.objective,
                      ),
                      _programBadge(
                        context,
                        icon: Icons.schedule_rounded,
                        label: prog.estimatedDuration,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      prog.focus,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'FICHAS E EXERCÍCIOS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...prog.routines.map(
                    (routine) => _programRoutinePreview(context, routine),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.edit_note_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Depois de adicionar, todas as fichas ficam editáveis em Minhas Fichas.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.paddingOf(ctx).bottom + 12,
              ),
              child: SizedBox(
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
                          Navigator.pop(ctx);
                          _importCatalogProgram(context, provider, prog);
                        },
                  icon: Icon(
                    isImported ? Icons.check_circle : Icons.add_rounded,
                  ),
                  label: Text(
                    isImported
                        ? 'Programa já adicionado'
                        : 'Adicionar programa',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _programRoutinePreview(BuildContext context, WorkoutRoutine routine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Text(
            routine.name,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${routine.activitySummary} • ${routine.focus}',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
          children: [
            ...routine.exercises.map(
              (exercise) => Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.fitness_center_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${exercise.reps} • descanso ${exercise.rest}',
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
              ),
            ),
            ...routine.cardio.map(
              (cardio) => Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.directions_run_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cardio.modality.label,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${cardio.plannedDurationMinutes} min${cardio.notes.isEmpty ? '' : ' • ${cardio.notes}'}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _programBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
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

  IconData _programIcon(WorkoutProgram program) {
    final objective = program.objective.toLowerCase();
    if (objective.contains('adapta')) {
      return Icons.school_rounded;
    }
    if (objective.contains('condicion')) {
      return Icons.directions_run_rounded;
    }
    return Icons.fitness_center_rounded;
  }

  void _importCatalogProgram(
    BuildContext context,
    WorkoutController provider,
    WorkoutProgram program,
  ) {
    final imported = provider.importProgram(program);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          imported
              ? '${program.name} foi adicionado a Minhas Fichas.'
              : 'Este programa já está em Minhas Fichas.',
        ),
        backgroundColor: imported
            ? Theme.of(context).colorScheme.primary
            : AppColors.surfaceLight,
        behavior: SnackBarBehavior.floating,
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
