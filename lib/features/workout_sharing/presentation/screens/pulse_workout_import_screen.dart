import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../models/exercise.dart';
import '../../../../theme/app_theme.dart';
import '../../../workouts/presentation/providers/workout_controller.dart';
import '../../data/services/pulse_workout_file_service.dart';
import '../../domain/models/pulse_workout_file.dart';

class PulseWorkoutImportScreen extends ConsumerStatefulWidget {
  const PulseWorkoutImportScreen({
    super.key,
    this.initialDocument,
    this.sourceLabel = 'arquivo',
  });

  final PulseWorkoutDocument? initialDocument;
  final String sourceLabel;

  @override
  ConsumerState<PulseWorkoutImportScreen> createState() =>
      _PulseWorkoutImportScreenState();
}

class _PulseWorkoutImportScreenState
    extends ConsumerState<PulseWorkoutImportScreen> {
  final _nameController = TextEditingController();
  final _fileService = const PulseWorkoutFileService();
  PulseWorkoutImportPreview? _preview;
  String? _error;
  bool _isPicking = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    final initialDocument = widget.initialDocument;
    if (initialDocument != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadDocument(initialDocument);
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    if (_isPicking || _isImporting) {
      return;
    }

    setState(() {
      _isPicking = true;
      _error = null;
    });

    try {
      final bytes = await _fileService.pickFile();
      if (bytes == null) {
        return;
      }
      _loadPreview(bytes);
    } on PulseWorkoutFileException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Não foi possível abrir esse arquivo do PULSE.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  void _loadPreview(Uint8List bytes) {
    _loadDocument(_fileService.codec.decode(bytes));
  }

  void _loadDocument(PulseWorkoutDocument document) {
    final state = ref.read(workoutControllerProvider);
    final preview = _fileService.codec.prepareImport(
      document: document,
      localExercises: state.allExercises,
      currentRoutines: state.myRoutines,
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _preview = preview;
      _nameController.text = preview.suggestedName;
      _error = null;
    });
  }

  void _import() {
    final preview = _preview;
    if (preview == null || preview.isExactDuplicate || _isImporting) {
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Informe um nome para continuar.');
      return;
    }

    final latestState = ref.read(workoutControllerProvider);
    final checkedPreview = _fileService.codec.prepareImport(
      document: preview.document,
      localExercises: latestState.allExercises,
      currentRoutines: latestState.myRoutines,
    );

    if (checkedPreview.isExactDuplicate) {
      setState(() {
        _preview = checkedPreview;
        _nameController.text = checkedPreview.suggestedName;
        _error = null;
      });
      return;
    }

    setState(() {
      _isImporting = true;
      _error = null;
    });

    final bundle = checkedPreview.buildBundle(name);
    ref
        .read(workoutControllerProvider.notifier)
        .addSharedContent(
          routines: bundle.routines,
          customExercises: bundle.customExercises,
          activeProgramName: bundle.activeProgramName,
        );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.initialDocument == null
              ? 'Importar arquivo PULSE'
              : 'Revisar QR Code do PULSE',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          MediaQuery.paddingOf(context).bottom + 110,
        ),
        children: <Widget>[
          _introCard(context),
          const SizedBox(height: 16),
          if (widget.initialDocument == null)
            OutlinedButton.icon(
              onPressed: _isPicking ? null : _pickFile,
              icon: _isPicking
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.folder_open_outlined),
              label: Text(
                preview == null
                    ? 'Selecionar arquivo .pulse'
                    : 'Escolher outro arquivo',
              ),
            ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 12),
            _messageCard(
              context,
              icon: Icons.error_outline_rounded,
              message: _error!,
              color: Colors.redAccent,
            ),
          ],
          if (preview != null) ...<Widget>[
            const SizedBox(height: 20),
            _fileSummary(context, preview),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              enabled: !preview.isExactDuplicate,
              decoration: InputDecoration(
                labelText:
                    preview.document.contentType ==
                        PulseWorkoutContentType.program
                    ? 'Nome do programa'
                    : 'Nome da ficha',
                prefixIcon: const Icon(Icons.edit_outlined),
              ),
            ),
            if (preview.unmatchedExerciseCount > 0) ...<Widget>[
              const SizedBox(height: 12),
              _messageCard(
                context,
                icon: Icons.extension_outlined,
                message:
                    '${preview.unmatchedExerciseCount} exercício${preview.unmatchedExerciseCount == 1 ? '' : 's'} não encontrado${preview.unmatchedExerciseCount == 1 ? '' : 's'} na biblioteca. O PULSE vai mantê-${preview.unmatchedExerciseCount == 1 ? 'lo' : 'los'} como personalizado${preview.unmatchedExerciseCount == 1 ? '' : 's'}.',
                color: Colors.orangeAccent,
              ),
            ],
            if (preview.isExactDuplicate) ...<Widget>[
              const SizedBox(height: 12),
              _messageCard(
                context,
                icon: Icons.content_copy_rounded,
                message:
                    'Esse conteúdo já existe no aparelho. Nada será adicionado para evitar uma duplicação acidental.',
                color: Colors.orangeAccent,
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'CONTEÚDO DO ARQUIVO',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            ...preview.resolvedRoutines.map(
              (routine) => _routinePreview(context, routine),
            ),
          ],
        ],
      ),
      bottomNavigationBar: preview == null
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: FilledButton.icon(
                  onPressed: preview.isExactDuplicate || _isImporting
                      ? null
                      : _import,
                  icon: _isImporting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_done_rounded),
                  label: Text(
                    preview.isExactDuplicate
                        ? 'Já está no aparelho'
                        : 'Importar e adicionar',
                  ),
                ),
              ),
            ),
    );
  }

  Widget _introCard(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.ios_share_rounded, color: primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.initialDocument == null
                  ? 'Arquivos .pulse podem conter uma ficha ou um programa completo. Confira tudo antes de adicionar ao aplicativo.'
                  : 'O QR Code pode conter uma ficha ou um programa completo. Confira tudo antes de adicionar ao aplicativo.',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fileSummary(BuildContext context, PulseWorkoutImportPreview preview) {
    final document = preview.document;
    final createdAt = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(document.createdAt.toLocal());
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  document.contentType == PulseWorkoutContentType.program
                      ? Icons.folder_copy_outlined
                      : Icons.assignment_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      document.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.initialDocument == null
                          ? '${document.contentType.label} • criado em $createdAt'
                          : '${document.contentType.label} • recebido por ${widget.sourceLabel}',
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
            children: <Widget>[
              _countChip(
                context,
                Icons.list_alt_rounded,
                '${preview.resolvedRoutines.length} ficha${preview.resolvedRoutines.length == 1 ? '' : 's'}',
              ),
              _countChip(
                context,
                Icons.fitness_center_rounded,
                '${preview.exerciseCount} exercícios',
              ),
              if (preview.cardioCount > 0)
                _countChip(
                  context,
                  Icons.directions_run_rounded,
                  '${preview.cardioCount} cardio',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _countChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _messageCard(
    BuildContext context, {
    required IconData icon,
    required String message,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _routinePreview(BuildContext context, WorkoutRoutine routine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          routine.name,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        subtitle: Text(
          '${routine.activitySummary} • ${routine.focus}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: <Widget>[
          for (var index = 0; index < routine.exercises.length; index++)
            _exerciseRow(routine.exercises[index], index),
          for (final cardio in routine.cardio)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.directions_run_rounded, size: 17),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      '${cardio.modality.label} • ${cardio.plannedDurationMinutes} min',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _exerciseRow(Exercise exercise, int index) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 22,
            child: Text(
              '${index + 1}.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  exercise.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  exercise.advancedPrescription.isEmpty
                      ? '${exercise.reps} • ${exercise.rest}'
                      : '${exercise.reps} • ${exercise.rest}\n${exercise.advancedPrescription.summary}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
