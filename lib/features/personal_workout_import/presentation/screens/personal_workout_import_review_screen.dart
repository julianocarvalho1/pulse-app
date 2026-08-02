import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/exercise.dart';
import '../../../../theme/app_theme.dart';
import '../../../exercises/domain/exercise_catalog.dart';
import '../../../workouts/domain/models/cardio_log.dart';
import '../../../workouts/presentation/providers/workout_library_controller.dart';
import '../../domain/models/personal_workout_import.dart';

class PersonalWorkoutImportReviewScreen extends ConsumerStatefulWidget {
  const PersonalWorkoutImportReviewScreen({super.key, required this.draft});

  final PersonalWorkoutImportDraft draft;

  @override
  ConsumerState<PersonalWorkoutImportReviewScreen> createState() =>
      _PersonalWorkoutImportReviewScreenState();
}

class _PersonalWorkoutImportReviewScreenState
    extends ConsumerState<PersonalWorkoutImportReviewScreen> {
  late PersonalWorkoutImportDraft _draft;
  late final TextEditingController _programNameController;
  late final TextEditingController _focusController;
  bool _isSaving = false;
  bool _showOnlyPending = false;

  List<_PendingExerciseLocation> get _pendingLocations {
    final pending = <_PendingExerciseLocation>[];
    for (
      var routineIndex = 0;
      routineIndex < _draft.routines.length;
      routineIndex++
    ) {
      final routine = _draft.routines[routineIndex];
      for (
        var exerciseIndex = 0;
        exerciseIndex < routine.exercises.length;
        exerciseIndex++
      ) {
        final exercise = routine.exercises[exerciseIndex];
        if (exercise.hasPendingReview) {
          pending.add(
            _PendingExerciseLocation(
              routineIndex: routineIndex,
              exerciseIndex: exerciseIndex,
            ),
          );
        }
      }
    }
    return pending;
  }

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _programNameController = TextEditingController(text: _draft.programName);
    _focusController = TextEditingController(text: _draft.focus);
  }

  @override
  void dispose() {
    _programNameController.dispose();
    _focusController.dispose();
    super.dispose();
  }

  Future<void> _editExercise(int routineIndex, int exerciseIndex) async {
    final current = _draft.routines[routineIndex].exercises[exerciseIndex];
    final updated = await showModalBottomSheet<PersonalImportExerciseDraft>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _ExerciseImportEditorSheet(draft: current),
    );

    if (updated == null || !mounted) {
      return;
    }

    final routines = List<PersonalImportRoutineDraft>.from(_draft.routines);
    final exercises = List<PersonalImportExerciseDraft>.from(
      routines[routineIndex].exercises,
    );
    exercises[exerciseIndex] = updated;
    routines[routineIndex] = routines[routineIndex].copyWith(
      exercises: exercises,
    );
    setState(() {
      _draft = _draft.resolveExerciseReview(
        routineName: routines[routineIndex].name,
        exerciseNames: <String>{current.rawName, updated.rawName},
        routines: routines,
      );
    });
  }

  Future<void> _editRoutineCardio(int routineIndex, int cardioIndex) async {
    final current = _draft.routines[routineIndex].cardio[cardioIndex];
    final updated = await showModalBottomSheet<RoutineCardio>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _GeneralCardioEditorSheet(cardio: current),
    );

    if (updated == null || !mounted) {
      return;
    }
    final routines = List<PersonalImportRoutineDraft>.from(_draft.routines);
    final cardio = List<RoutineCardio>.from(routines[routineIndex].cardio);
    cardio[cardioIndex] = updated;
    routines[routineIndex] = routines[routineIndex].copyWith(cardio: cardio);
    setState(() => _draft = _draft.copyWith(routines: routines));
  }

  void _removeRoutineCardio(int routineIndex, int cardioIndex) {
    final routines = List<PersonalImportRoutineDraft>.from(_draft.routines);
    final cardio = List<RoutineCardio>.from(routines[routineIndex].cardio)
      ..removeAt(cardioIndex);
    routines[routineIndex] = routines[routineIndex].copyWith(cardio: cardio);
    setState(() => _draft = _draft.copyWith(routines: routines));
  }

  Future<void> _editCardio() async {
    final current =
        _draft.generalCardio ??
        const RoutineCardio(
          id: 'import_general_cardio',
          modality: CardioModality.other,
          plannedDurationMinutes: 30,
        );
    final updated = await showModalBottomSheet<RoutineCardio>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _GeneralCardioEditorSheet(cardio: current),
    );

    if (updated == null || !mounted) {
      return;
    }
    setState(() => _draft = _draft.copyWith(generalCardio: updated));
  }

  Future<void> _applyBulkRest() async {
    final rest = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (_) => const _BulkRestSheet(),
    );

    if (rest == null || !mounted) {
      return;
    }
    setState(() => _draft = _draft.applyRestToMissing(rest));
  }

  Future<void> _reviewFirstPending() async {
    final pending = _pendingLocations;
    if (pending.isEmpty) {
      _showMessage('Não há exercícios pendentes para revisar.');
      return;
    }
    final first = pending.first;
    await _editExercise(first.routineIndex, first.exerciseIndex);
  }

  void _togglePendingFilter() {
    setState(() => _showOnlyPending = !_showOnlyPending);
  }

  Future<bool> _showBlockingIssues(
    PersonalImportSaveValidation validation,
  ) async {
    final reviewNow = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Não foi possível salvar'),
        content: _ImportValidationMessageList(
          intro: 'Preencha os campos obrigatórios antes de continuar:',
          messages: validation.blockingMessages,
          color: AppColors.danger,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Fechar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ir para a primeira pendência'),
          ),
        ],
      ),
    );
    return reviewNow == true;
  }

  Future<bool> _confirmWarnings(PersonalImportSaveValidation validation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Salvar programa com pendências?'),
        content: _ImportValidationMessageList(
          intro:
              'O programa pode ser salvo, mas ainda encontramos estes pontos:',
          messages: validation.warningMessages,
          color: AppColors.warning,
          footer:
              'Você poderá editar tudo depois. Para maior segurança, revise antes de iniciar os treinos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Voltar e revisar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Salvar mesmo assim'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();

    final preparedDraft = _draft.copyWith(
      programName: _programNameController.text.trim(),
      focus: _focusController.text.trim(),
    );
    final validation = preparedDraft.validateForSave();
    if (validation.hasBlockingIssues) {
      final reviewNow = await _showBlockingIssues(validation);
      if (reviewNow && mounted) {
        setState(() => _showOnlyPending = true);
        await _reviewFirstPending();
      }
      return;
    }
    if (validation.hasWarnings && !await _confirmWarnings(validation)) {
      return;
    }
    if (!mounted) {
      return;
    }

    setState(() => _isSaving = true);
    final program = preparedDraft.toProgram();

    ref
        .read(workoutLibraryControllerProvider.notifier)
        .addImportedProgram(program);

    if (!mounted) {
      return;
    }
    _showMessage('Programa importado e salvo nas suas fichas.');
    Navigator.pop(context, true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routineEntries = _draft.routines
        .asMap()
        .entries
        .where(
          (entry) =>
              !_showOnlyPending ||
              entry.value.exercises.any((item) => item.hasPendingReview),
        )
        .toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Revisar importação',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  _ImportSummaryCard(draft: _draft),
                  if (_draft.pendingExerciseCount > 0) ...[
                    const SizedBox(height: 12),
                    _PendingReviewCard(
                      draft: _draft,
                      showOnlyPending: _showOnlyPending,
                      onReviewFirst: _reviewFirstPending,
                      onToggleFilter: _togglePendingFilter,
                    ),
                  ],
                  if (_draft.missingRestCount > 0) ...[
                    const SizedBox(height: 12),
                    _MissingRestCard(
                      count: _draft.missingRestCount,
                      onApply: _applyBulkRest,
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: _programNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do programa',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _focusController,
                    decoration: const InputDecoration(
                      labelText: 'Objetivo ou observação geral',
                    ),
                  ),
                  const SizedBox(height: 20),
                  _GeneralCardioCard(
                    cardio: _draft.generalCardio,
                    onEdit: _editCardio,
                    onRemove: _draft.generalCardio == null
                        ? null
                        : () {
                            setState(
                              () => _draft = _draft.copyWith(
                                clearGeneralCardio: true,
                              ),
                            );
                          },
                  ),
                  if (_draft.issues.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _IssuesCard(issues: _draft.issues),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'FICHAS ENCONTRADAS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        '${_draft.routines.length}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...routineEntries.map((routineEntry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RoutineImportCard(
                        routine: routineEntry.value,
                        showOnlyPending: _showOnlyPending,
                        onEditExercise: (exerciseIndex) =>
                            _editExercise(routineEntry.key, exerciseIndex),
                        onEditCardio: (cardioIndex) =>
                            _editRoutineCardio(routineEntry.key, cardioIndex),
                        onRemoveCardio: (cardioIndex) =>
                            _removeRoutineCardio(routineEntry.key, cardioIndex),
                      ),
                    );
                  }),
                  if (_showOnlyPending && routineEntries.isEmpty)
                    _NoPendingExercisesCard(onShowAll: _togglePendingFilter),
                  Text(
                    'Exercícios sem associação permanecem como personalizados. Você poderá editar as fichas normalmente depois de salvar.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.viewPaddingOf(context).bottom + 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _isSaving ? 'Salvando...' : 'Salvar programa',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingExerciseLocation {
  const _PendingExerciseLocation({
    required this.routineIndex,
    required this.exerciseIndex,
  });

  final int routineIndex;
  final int exerciseIndex;
}

class _PendingReviewCard extends StatelessWidget {
  const _PendingReviewCard({
    required this.draft,
    required this.showOnlyPending,
    required this.onReviewFirst,
    required this.onToggleFilter,
  });

  final PersonalWorkoutImportDraft draft;
  final bool showOnlyPending;
  final VoidCallback onReviewFirst;
  final VoidCallback onToggleFilter;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (draft.reviewCount > 0)
        '${draft.reviewCount} ${draft.reviewCount == 1 ? 'associação' : 'associações'} para confirmar',
      if (draft.missingRepetitionsCount > 0)
        '${draft.missingRepetitionsCount} sem repetições',
      if (draft.invalidSeriesCount > 0)
        '${draft.invalidSeriesCount} com séries inválidas',
    ];

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.rule_folder_outlined,
                  color: AppColors.warning,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${draft.pendingExerciseCount} exercício${draft.pendingExerciseCount == 1 ? '' : 's'} com pendência',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${draft.routinesWithPendingCount} ficha${draft.routinesWithPendingCount == 1 ? '' : 's'} precisam de conferência',
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
          if (parts.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              parts.join(' • '),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onToggleFilter,
                  icon: Icon(
                    showOnlyPending
                        ? Icons.list_alt_rounded
                        : Icons.filter_alt_outlined,
                    size: 18,
                  ),
                  label: Text(
                    showOnlyPending
                        ? 'Mostrar todas as fichas'
                        : 'Ver só pendências',
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onReviewFirst,
                  icon: const Icon(Icons.navigate_next_rounded, size: 19),
                  label: const Text('Revisar primeira'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoPendingExercisesCard extends StatelessWidget {
  const _NoPendingExercisesCard({required this.onShowAll});

  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.task_alt_rounded, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Todos os exercícios obrigatórios foram revisados.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: onShowAll, child: const Text('Mostrar fichas')),
        ],
      ),
    );
  }
}

class _ImportSummaryCard extends StatelessWidget {
  const _ImportSummaryCard({required this.draft});

  final PersonalWorkoutImportDraft draft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.fact_check_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Documento analisado',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (draft.sourceLabel.isNotEmpty)
                      Text(
                        draft.sourceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryChip(
                label: draft.documentKind.label,
                color:
                    draft.documentKind ==
                        PersonalImportDocumentKind.periodizedPlan
                    ? AppColors.warning
                    : AppColors.info,
              ),
              _SummaryChip(
                label: '${draft.routines.length} fichas',
                color: AppColors.info,
              ),
              _SummaryChip(
                label: '${draft.exerciseCount} exercícios',
                color: AppColors.success,
              ),
              _SummaryChip(
                label: '${draft.reviewedExerciseCount} revisados',
                color: AppColors.success,
              ),
              _SummaryChip(
                label: '${draft.reviewCount} para revisar',
                color: draft.reviewCount == 0
                    ? AppColors.success
                    : AppColors.warning,
              ),
              if (draft.cardioCount > 0)
                _SummaryChip(
                  label: '${draft.cardioCount} cardio',
                  color: AppColors.info,
                ),
              if (draft.advancedTechniqueCount > 0)
                _SummaryChip(
                  label: '${draft.advancedTechniqueCount} com técnica',
                  color: AppColors.info,
                ),
              if (draft.customExerciseCount > 0)
                _SummaryChip(
                  label: '${draft.customExerciseCount} personalizados',
                  color: AppColors.warning,
                ),
            ],
          ),
          if (draft.classificationMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              draft.classificationMessage,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MissingRestCard extends StatelessWidget {
  const _MissingRestCard({required this.count, required this.onApply});

  final int count;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_off_outlined, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Descanso não informado em $count exercício(s)',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Você pode definir um valor para todos os campos vazios ou manter como não informado.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(onPressed: onApply, child: const Text('Definir em lote')),
        ],
      ),
    );
  }
}

class _ImportValidationMessageList extends StatelessWidget {
  const _ImportValidationMessageList({
    required this.intro,
    required this.messages,
    required this.color,
    this.footer,
  });

  final String intro;
  final List<String> messages;
  final Color color;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(intro, style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          ...messages.map(
            (message) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 7, color: color),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: 6),
            Text(
              footer!,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BulkRestSheet extends StatefulWidget {
  const _BulkRestSheet();

  @override
  State<_BulkRestSheet> createState() => _BulkRestSheetState();
}

class _BulkRestSheetState extends State<_BulkRestSheet> {
  static const _options = <String>['45 seg', '60 seg', '90 seg', '120 seg'];
  String _selected = '60 seg';
  String _custom = '';
  bool _useCustom = false;

  void _apply() {
    final value = _useCustom ? _custom.trim() : _selected;
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um tempo de descanso.')),
      );
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.viewPaddingOf(context).bottom +
            20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Definir descanso em lote',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'O valor será aplicado somente aos exercícios que ainda estão sem descanso.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _options
                .map((option) {
                  return ChoiceChip(
                    label: Text(option),
                    selected: !_useCustom && _selected == option,
                    onSelected: (_) => setState(() {
                      _useCustom = false;
                      _selected = option;
                    }),
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          TextField(
            onTap: () => setState(() => _useCustom = true),
            onChanged: (value) {
              _custom = value;
              if (!_useCustom) {
                setState(() => _useCustom = true);
              }
            },
            decoration: const InputDecoration(
              labelText: 'Outro valor',
              hintText: 'Ex.: 75 seg ou 2 min',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _apply,
              icon: const Icon(Icons.done_all_rounded),
              label: const Text('Aplicar nos campos vazios'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneralCardioCard extends StatelessWidget {
  const _GeneralCardioCard({
    required this.cardio,
    required this.onEdit,
    required this.onRemove,
  });

  final RoutineCardio? cardio;
  final VoidCallback onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.directions_run_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cardio == null
                      ? 'Cardio geral não encontrado'
                      : 'Cardio geral',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  cardio == null
                      ? 'Adicione cardio a todas as fichas importadas.'
                      : '${cardio!.modality.label} • ${cardio!.plannedDurationMinutes} min${cardio!.notes.isEmpty ? '' : '\n${cardio!.notes}'}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: cardio == null ? 'Adicionar cardio' : 'Editar cardio',
            onPressed: onEdit,
            icon: Icon(cardio == null ? Icons.add : Icons.edit_outlined),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: 'Remover cardio',
              onPressed: onRemove,
              icon: Icon(Icons.delete_outline, color: AppColors.danger),
            ),
        ],
      ),
    );
  }
}

class _IssuesCard extends StatelessWidget {
  const _IssuesCard({required this.issues});

  final List<PersonalImportIssue> issues;

  @override
  Widget build(BuildContext context) {
    final visibleIssues = issues.take(8).toList(growable: false);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Pontos para conferir',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...visibleIssues.map(
            (issue) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '• ${issue.message}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ),
          ),
          if (issues.length > visibleIssues.length)
            Text(
              '+ ${issues.length - visibleIssues.length} outros avisos',
              style: TextStyle(
                color: AppColors.warning,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _RoutineImportCard extends StatelessWidget {
  const _RoutineImportCard({
    required this.routine,
    required this.showOnlyPending,
    required this.onEditExercise,
    required this.onEditCardio,
    required this.onRemoveCardio,
  });

  final PersonalImportRoutineDraft routine;
  final bool showOnlyPending;
  final ValueChanged<int> onEditExercise;
  final ValueChanged<int> onEditCardio;
  final ValueChanged<int> onRemoveCardio;

  @override
  Widget build(BuildContext context) {
    final pendingCount = routine.exercises
        .where((exercise) => exercise.hasPendingReview)
        .length;
    final visibleExercises = routine.exercises
        .asMap()
        .entries
        .where((entry) => !showOnlyPending || entry.value.hasPendingReview)
        .toList(growable: false);

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: ValueKey('${routine.name}-$showOnlyPending'),
        initiallyExpanded: showOnlyPending,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Text(
          routine.name,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          '${routine.scheduleLabel.isEmpty ? '' : '${routine.scheduleLabel} • '}${routine.focus}${routine.focus.isEmpty ? '' : ' • '}${routine.exercises.length} exercícios${routine.cardio.isEmpty ? '' : ' • ${routine.cardio.length} cardio'}${routine.isOptional ? ' • opcional' : ''}${pendingCount == 0 ? '' : ' • $pendingCount pendência${pendingCount == 1 ? '' : 's'}'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        children: [
          ...visibleExercises.map((entry) {
            return Padding(
              padding: EdgeInsets.only(
                top: entry == visibleExercises.first ? 0 : 7,
              ),
              child: _ImportedExerciseRow(
                exercise: entry.value,
                onEdit: () => onEditExercise(entry.key),
              ),
            );
          }),
          ...routine.cardio.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(top: 7),
              child: _ImportedRoutineCardioRow(
                cardio: entry.value,
                onEdit: () => onEditCardio(entry.key),
                onRemove: () => onRemoveCardio(entry.key),
              ),
            ),
          ),
          if (routine.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  routine.notes,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImportedRoutineCardioRow extends StatelessWidget {
  const _ImportedRoutineCardioRow({
    required this.cardio,
    required this.onEdit,
    required this.onRemove,
  });

  final RoutineCardio cardio;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.directions_run_rounded, color: AppColors.info, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cardio.modality.label} • ${cardio.plannedDurationMinutes} min',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (cardio.notes.isNotEmpty)
                  Text(
                    cardio.notes,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      height: 1.35,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Editar cardio',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
          IconButton(
            tooltip: 'Remover cardio',
            onPressed: onRemove,
            icon: Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}

class _ImportedExerciseRow extends StatelessWidget {
  const _ImportedExerciseRow({required this.exercise, required this.onEdit});

  final PersonalImportExerciseDraft exercise;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final selected = exercise.selectedExerciseId == null
        ? null
        : exerciseDatabase
              .where((item) => item.id == exercise.selectedExerciseId)
              .firstOrNull;
    final color = exercise.hasPendingReview
        ? AppColors.warning
        : AppColors.success;
    final pendingReasons = exercise.pendingReasons;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: exercise.hasPendingReview
            ? AppColors.warning.withValues(alpha: 0.06)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: exercise.hasPendingReview
            ? Border.all(color: AppColors.warning.withValues(alpha: 0.28))
            : null,
      ),
      child: Row(
        children: [
          Icon(
            selected == null
                ? Icons.person_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: color,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selected?.name ?? exercise.rawName,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (selected != null &&
                    ExerciseCatalog.normalize(selected.name) !=
                        ExerciseCatalog.normalize(exercise.rawName))
                  Text(
                    'Documento: ${exercise.rawName}',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                  ),
                Text(
                  '${exercise.seriesCount}x ${exercise.repetitions.trim().isEmpty ? 'repetições ausentes' : exercise.repetitions} • ${exercise.rest.isEmpty ? 'descanso não informado' : exercise.rest}${exercise.isSupersetLead ? ' • início de bi-set' : ''}',
                  style: TextStyle(
                    color: exercise.hasMissingRepetitions
                        ? AppColors.danger
                        : AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: exercise.hasMissingRepetitions
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
                if (pendingReasons.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      pendingReasons.join(' • '),
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                if (exercise.originalPrescription.isNotEmpty &&
                    exercise.originalPrescription !=
                        '${exercise.seriesCount}x ${exercise.repetitions}')
                  Text(
                    'Original: ${exercise.originalPrescription}',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 9),
                  ),
                if (exercise.advancedSummary.isNotEmpty)
                  Text(
                    exercise.advancedSummary,
                    style: TextStyle(
                      color: AppColors.info,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (exercise.hasAlternatives)
                  Text(
                    'Alternativas: ${exercise.alternatives.join(' ou ')}',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Revisar exercício',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 19),
          ),
        ],
      ),
    );
  }
}

class _ExerciseImportEditorSheet extends StatefulWidget {
  const _ExerciseImportEditorSheet({required this.draft});

  final PersonalImportExerciseDraft draft;

  @override
  State<_ExerciseImportEditorSheet> createState() =>
      _ExerciseImportEditorSheetState();
}

class _ExerciseImportEditorSheetState
    extends State<_ExerciseImportEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _seriesController;
  late final TextEditingController _repetitionsController;
  late final TextEditingController _restController;
  late final TextEditingController _noteController;
  late final TextEditingController _searchController;
  String? _selectedExerciseId;
  late bool _isSupersetLead;
  String _search = '';

  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    _nameController = TextEditingController(text: draft.rawName);
    _seriesController = TextEditingController(text: '${draft.seriesCount}');
    _repetitionsController = TextEditingController(text: draft.repetitions);
    _restController = TextEditingController(text: draft.rest);
    _noteController = TextEditingController(text: draft.note);
    _searchController = TextEditingController(text: draft.rawName);
    _search = draft.rawName;
    _selectedExerciseId = draft.selectedExerciseId;
    _isSupersetLead = draft.isSupersetLead;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _seriesController.dispose();
    _repetitionsController.dispose();
    _restController.dispose();
    _noteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _save() {
    FocusManager.instance.primaryFocus?.unfocus();
    final series = int.tryParse(_seriesController.text.trim()) ?? 3;
    Navigator.pop(
      context,
      widget.draft.copyWith(
        rawName: _nameController.text.trim(),
        seriesCount: series.clamp(1, 20).toInt(),
        repetitions: _repetitionsController.text.trim(),
        rest: _restController.text.trim(),
        note: _noteController.text.trim(),
        selectedExerciseId: _selectedExerciseId,
        clearSelectedExercise: _selectedExerciseId == null,
        isSupersetLead: _isSupersetLead,
        needsReview: false,
        alternatives: <String>[_nameController.text.trim()],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = exerciseDatabase
        .where((exercise) {
          return ExerciseCatalog.matches(exercise, _search);
        })
        .take(30)
        .toList(growable: false);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.88,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Revisar exercício',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  if (widget.draft.hasAlternatives) ...[
                    Text(
                      'ESCOLHA UMA ALTERNATIVA',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.draft.alternatives
                          .map((alternative) {
                            return ChoiceChip(
                              label: Text(alternative),
                              selected: _nameController.text == alternative,
                              onSelected: (_) {
                                setState(() {
                                  _nameController.text = alternative;
                                  _searchController.text = alternative;
                                  _search = alternative;
                                  _selectedExerciseId = null;
                                });
                              },
                            );
                          })
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome no documento',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _seriesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Séries',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _repetitionsController,
                          decoration: const InputDecoration(
                            labelText: 'Repetições',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _restController,
                    decoration: const InputDecoration(
                      labelText: 'Descanso',
                      hintText: 'Ex.: 60 seg ou Não informado',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Observação do personal',
                    ),
                  ),
                  if (widget.draft.originalPrescription.isNotEmpty ||
                      widget.draft.advancedSummary.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Text(
                        [
                          if (widget.draft.originalPrescription.isNotEmpty)
                            'Prescrição original: ${widget.draft.originalPrescription}',
                          if (widget.draft.advancedSummary.isNotEmpty)
                            widget.draft.advancedSummary,
                        ].join('\n'),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Este exercício inicia um bi-set'),
                    value: _isSupersetLead,
                    onChanged: (value) =>
                        setState(() => _isSupersetLead = value),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ASSOCIAR À BIBLIOTECA',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _search = value),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Buscar exercício',
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ExerciseChoiceTile(
                    selected: _selectedExerciseId == null,
                    title: 'Manter como exercício personalizado',
                    subtitle: 'Não vincular a um exercício da biblioteca.',
                    onTap: () => setState(() => _selectedExerciseId = null),
                  ),
                  ...filtered.map(
                    (exercise) => _ExerciseChoiceTile(
                      selected: _selectedExerciseId == exercise.id,
                      title: exercise.name,
                      subtitle: exercise.muscle,
                      onTap: () =>
                          setState(() => _selectedExerciseId = exercise.id),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                10,
                20,
                MediaQuery.viewPaddingOf(context).bottom + 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: const Text('Aplicar revisão'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseChoiceTile extends StatelessWidget {
  const _ExerciseChoiceTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(
        selected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_off_rounded,
        color: selected
            ? Theme.of(context).colorScheme.primary
            : AppColors.textMuted,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class _GeneralCardioEditorSheet extends StatefulWidget {
  const _GeneralCardioEditorSheet({required this.cardio});

  final RoutineCardio cardio;

  @override
  State<_GeneralCardioEditorSheet> createState() =>
      _GeneralCardioEditorSheetState();
}

class _GeneralCardioEditorSheetState extends State<_GeneralCardioEditorSheet> {
  late CardioModality _modality;
  late final TextEditingController _durationController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _modality = widget.cardio.modality;
    _durationController = TextEditingController(
      text: '${widget.cardio.plannedDurationMinutes}',
    );
    _notesController = TextEditingController(text: widget.cardio.notes);
  }

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    FocusManager.instance.primaryFocus?.unfocus();
    final duration = int.tryParse(_durationController.text.trim()) ?? 0;
    Navigator.pop(
      context,
      widget.cardio.copyWith(
        modality: _modality,
        plannedDurationMinutes: duration.clamp(1, 600).toInt(),
        notes: _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.viewPaddingOf(context).bottom +
            18,
      ),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cardio aplicado às fichas',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CardioModality>(
              initialValue: _modality,
              decoration: const InputDecoration(labelText: 'Modalidade'),
              items: CardioModality.values
                  .map((modality) {
                    return DropdownMenuItem<CardioModality>(
                      value: modality,
                      child: Text(modality.label),
                    );
                  })
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _modality = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duração planejada em minutos',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Orientação',
                hintText: 'Ex.: intensidade leve a moderada, após o treino',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Aplicar cardio'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
