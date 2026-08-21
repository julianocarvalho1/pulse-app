import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/workouts/domain/models/cardio_log.dart';
import '../features/workouts/presentation/providers/workout_controller.dart';
import '../models/exercise.dart';
import '../theme/app_theme.dart';

class RoutineCardioEditorScreen extends ConsumerWidget {
  const RoutineCardioEditorScreen({super.key, required this.routine});

  final WorkoutRoutine routine;

  IconData _iconFor(CardioModality modality) {
    return switch (modality) {
      CardioModality.treadmill => Icons.directions_run_rounded,
      CardioModality.stationaryBike => Icons.pedal_bike_rounded,
      CardioModality.elliptical => Icons.sync_alt_rounded,
      CardioModality.stairClimber => Icons.stairs_rounded,
      CardioModality.rowing => Icons.rowing_rounded,
      CardioModality.walking => Icons.directions_walk_rounded,
      CardioModality.running => Icons.directions_run_rounded,
      CardioModality.other => Icons.favorite_outline_rounded,
    };
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref,
    WorkoutRoutine currentRoutine, {
    RoutineCardio? existing,
  }) async {
    var modality = existing?.modality ?? CardioModality.treadmill;
    final durationController = TextEditingController(
      text: existing?.plannedDurationMinutes.toString() ?? '20',
    );
    final notesController = TextEditingController(text: existing?.notes ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<RoutineCardio>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              18,
              20,
              MediaQuery.viewInsetsOf(context).bottom +
                  MediaQuery.paddingOf(context).bottom +
                  20,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            existing == null
                                ? 'Adicionar cardio'
                                : 'Editar cardio',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Fechar',
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<CardioModality>(
                      initialValue: modality,
                      decoration: const InputDecoration(
                        labelText: 'Modalidade',
                        prefixIcon: Icon(Icons.directions_run_rounded),
                      ),
                      items: CardioModality.values
                          .map(
                            (item) => DropdownMenuItem<CardioModality>(
                              value: item,
                              child: Text(item.label),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => modality = value);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duração planejada',
                        suffixText: 'min',
                        prefixIcon: Icon(Icons.timer_outlined),
                      ),
                      validator: (value) {
                        final minutes = int.tryParse(value?.trim() ?? '');
                        if (minutes == null || minutes <= 0) {
                          return 'Informe uma duração maior que zero.';
                        }
                        if (minutes > 600) {
                          return 'Use uma duração de até 600 minutos.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: notesController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Orientação da ficha (opcional)',
                        hintText: 'Ex.: ritmo moderado, após a musculação',
                        prefixIcon: Icon(Icons.sticky_note_2_outlined),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }

                          Navigator.pop(
                            sheetContext,
                            RoutineCardio(
                              id:
                                  existing?.id ??
                                  'routine_cardio_${DateTime.now().microsecondsSinceEpoch}',
                              modality: modality,
                              plannedDurationMinutes: int.parse(
                                durationController.text.trim(),
                              ),
                              notes: notesController.text.trim(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('SALVAR CARDIO'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    durationController.dispose();
    notesController.dispose();

    if (result == null || !context.mounted) {
      return;
    }

    final updated = List<RoutineCardio>.from(currentRoutine.cardio);
    final existingIndex = updated.indexWhere((entry) => entry.id == result.id);
    if (existingIndex >= 0) {
      updated[existingIndex] = result;
    } else {
      updated.add(result);
    }

    ref
        .read(workoutControllerProvider.notifier)
        .updateRoutineCardio(currentRoutine.id, updated);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing == null
              ? 'Cardio adicionado à ficha.'
              : 'Cardio atualizado.',
        ),
      ),
    );
  }

  void _remove(
    BuildContext context,
    WidgetRef ref,
    WorkoutRoutine currentRoutine,
    RoutineCardio entry,
  ) {
    final updated = currentRoutine.cardio
        .where((item) => item.id != entry.id)
        .toList(growable: false);
    ref
        .read(workoutControllerProvider.notifier)
        .updateRoutineCardio(currentRoutine.id, updated);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${entry.modality.label} removido da ficha.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workoutControllerProvider);
    final currentRoutine = state.myRoutines.firstWhere(
      (item) => item.id == routine.id,
      orElse: () => routine,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Cardio da ficha',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: currentRoutine.cardio.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.directions_run_rounded,
                          size: 34,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Nenhum cardio nesta ficha',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Adicione uma modalidade e a duração planejada. Os dados realizados serão preenchidos durante o treino.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                itemCount: currentRoutine.cardio.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final entry = currentRoutine.cardio[index];
                  return Material(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _openEditor(
                        context,
                        ref,
                        currentRoutine,
                        existing: entry,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                _iconFor(entry.modality),
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    entry.modality.label,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${entry.plannedDurationMinutes} min planejados',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (entry.notes.trim().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      entry.notes,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remover',
                              onPressed: () =>
                                  _remove(context, ref, currentRoutine, entry),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _openEditor(context, ref, currentRoutine),
            icon: const Icon(Icons.add_rounded),
            label: const Text('ADICIONAR CARDIO'),
          ),
        ),
      ),
    );
  }
}
