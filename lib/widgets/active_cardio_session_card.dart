import 'package:flutter/material.dart';

import '../features/workouts/domain/models/active_workout_session.dart';
import '../features/workouts/domain/models/cardio_log.dart';
import '../theme/app_theme.dart';
import 'cardio_guided_player.dart';

class ActiveCardioSessionCard extends StatelessWidget {
  const ActiveCardioSessionCard({
    super.key,
    required this.entry,
    required this.index,
    required this.onChanged,
  });

  final ActiveCardioEntry entry;
  final int index;
  final ValueChanged<ActiveCardioEntry> onChanged;

  Future<void> _openEditor(
    BuildContext context, {
    ActiveCardioEntry? initial,
  }) async {
    final result = await showModalBottomSheet<ActiveCardioEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ActiveCardioEditorSheet(entry: initial ?? entry),
    );

    if (result != null && context.mounted) {
      onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final statusColor = entry.isCompleted ? primary : AppColors.warning;
    final plannedGoals = _plannedGoalLabels(entry.plan);

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openEditor(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: statusColor.withValues(
                alpha: entry.isCompleted ? 0.45 : 0.28,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(_iconFor(entry.modality), color: statusColor),
                  ),
                  const SizedBox(width: 12),
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
                          entry.isCompleted
                              ? '${entry.actualDurationMinutes} min realizados • meta ${entry.plannedDurationMinutes} min'
                              : '${entry.plannedDurationMinutes} min planejados',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      entry.isCompleted ? 'CONCLUÍDO' : 'PENDENTE',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                '${entry.plan.purpose.label} • ${entry.plan.format.label} • ${entry.plan.intensity.label}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (plannedGoals.isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  'Metas: ${plannedGoals.join(' • ')}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
              if (entry.plan.intervals case final intervals?) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  '${intervals.warmUpMinutes} min aquecimento • ${intervals.cycles}x ${intervals.effortSeconds}s esforço / ${intervals.recoverySeconds}s recuperação • ${intervals.coolDownMinutes} min desaceleração',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
              if (entry.notes.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  entry.notes,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Icon(Icons.touch_app_outlined, size: 15, color: statusColor),
                  const SizedBox(width: 6),
                  Text(
                    entry.isCompleted
                        ? 'Toque para revisar as métricas'
                        : 'Toque para registrar e concluir',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (!entry.isCompleted) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('INICIAR CARDIO GUIADO'),
                  onPressed: () async {
                    final seconds = await Navigator.push<int>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CardioGuidedPlayer(
                          plan: entry.plan,
                          minutes: entry.plannedDurationMinutes,
                          modality: entry.modality,
                        ),
                      ),
                    );
                    if (seconds != null && context.mounted) {
                      await _openEditor(
                        context,
                        initial: entry.copyWith(
                          actualDurationMinutes: seconds ~/ 60,
                          notes:
                              '${entry.notes}${entry.notes.isEmpty ? '' : '\n'}Guia: ${seconds ~/ 60} min ${seconds % 60} s realizados. Revise o tempo antes de salvar.',
                        ),
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveCardioEditorSheet extends StatefulWidget {
  const _ActiveCardioEditorSheet({required this.entry});

  final ActiveCardioEntry entry;

  @override
  State<_ActiveCardioEditorSheet> createState() =>
      _ActiveCardioEditorSheetState();
}

class _ActiveCardioEditorSheetState extends State<_ActiveCardioEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _durationController;
  late final TextEditingController _distanceController;
  late final TextEditingController _speedController;
  late final TextEditingController _inclineController;
  late final TextEditingController _resistanceController;
  late final TextEditingController _effortController;
  late final TextEditingController _heartRateController;
  late final TextEditingController _notesController;
  late bool _isCompleted;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _durationController = TextEditingController(
      text: entry.actualDurationMinutes > 0
          ? entry.actualDurationMinutes.toString()
          : '',
    );
    _distanceController = TextEditingController(
      text: entry.distanceKm == null ? '' : _formatNumber(entry.distanceKm!),
    );
    _speedController = TextEditingController(
      text: entry.averageSpeedKmh == null
          ? ''
          : _formatNumber(entry.averageSpeedKmh!),
    );
    _inclineController = TextEditingController(
      text: entry.inclinePercent == null
          ? ''
          : _formatNumber(entry.inclinePercent!),
    );
    _resistanceController = TextEditingController(
      text: entry.resistanceLevel == null
          ? ''
          : _formatNumber(entry.resistanceLevel!),
    );
    _effortController = TextEditingController(
      text: entry.perceivedEffort?.toString() ?? '',
    );
    _heartRateController = TextEditingController(
      text: entry.averageHeartRateBpm?.toString() ?? '',
    );
    _notesController = TextEditingController(text: entry.notes);
    _isCompleted = entry.isCompleted;
  }

  @override
  void dispose() {
    _durationController.dispose();
    _distanceController.dispose();
    _speedController.dispose();
    _inclineController.dispose();
    _resistanceController.dispose();
    _effortController.dispose();
    _heartRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    final entry = widget.entry;
    Navigator.of(context).pop(
      entry.copyWith(
        actualDurationMinutes:
            int.tryParse(_durationController.text.trim()) ?? 0,
        distanceKm: _readDouble(_distanceController.text),
        clearDistance: _distanceController.text.trim().isEmpty,
        averageSpeedKmh: _readDouble(_speedController.text),
        clearAverageSpeed: _speedController.text.trim().isEmpty,
        inclinePercent: _readDouble(_inclineController.text),
        clearIncline: _inclineController.text.trim().isEmpty,
        resistanceLevel: _readDouble(_resistanceController.text),
        clearResistance: _resistanceController.text.trim().isEmpty,
        perceivedEffort: int.tryParse(_effortController.text.trim()),
        clearPerceivedEffort: _effortController.text.trim().isEmpty,
        averageHeartRateBpm: int.tryParse(_heartRateController.text.trim()),
        clearAverageHeartRate: _heartRateController.text.trim().isEmpty,
        notes: _notesController.text.trim(),
        isCompleted: _isCompleted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final plannedGoals = _plannedGoalLabels(entry.plan);

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
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      _iconFor(entry.modality),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          entry.modality.label,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${entry.plannedDurationMinutes} min planejados',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${entry.plan.purpose.label} • ${entry.plan.format.label} • ${entry.plan.intensity.label}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Teste da fala: ${entry.plan.intensity.talkTestDescription}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                    if (entry.plan.intervals case final intervals?) ...<Widget>[
                      const SizedBox(height: 5),
                      Text(
                        '${intervals.warmUpMinutes} min aquecimento • ${intervals.cycles}x ${intervals.effortSeconds}s esforço / ${intervals.recoverySeconds}s recuperação • ${intervals.coolDownMinutes} min desaceleração',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (plannedGoals.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 5),
                      Text(
                        'Metas: ${plannedGoals.join(' • ')}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duração realizada',
                  suffixText: 'min',
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
                validator: (value) {
                  final minutes = int.tryParse(value?.trim() ?? '');
                  if (_isCompleted && (minutes == null || minutes <= 0)) {
                    return 'Informe a duração para concluir o cardio.';
                  }
                  if (minutes != null && minutes > 600) {
                    return 'Use uma duração de até 600 minutos.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _distanceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Distância',
                        suffixText: 'km',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _speedController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Velocidade média',
                        suffixText: 'km/h',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _inclineController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Inclinação',
                        suffixText: '%',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _resistanceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Resistência',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _effortController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Esforço',
                        suffixText: '/10',
                      ),
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return null;
                        }
                        final effort = int.tryParse(value!.trim());
                        if (effort == null || effort < 1 || effort > 10) {
                          return 'Use 1 a 10.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _heartRateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'FC média',
                        suffixText: 'bpm',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                child: CheckboxListTile(
                  value: _isCompleted,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'Cardio concluído',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text(
                    'Apenas atividades concluídas entram no histórico.',
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onChanged: (value) {
                    setState(() => _isCompleted = value ?? false);
                  },
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('SALVAR CARDIO'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

String _formatNumber(num value) {
  final decimal = value.toDouble();
  return decimal == decimal.roundToDouble()
      ? decimal.toStringAsFixed(0)
      : decimal.toStringAsFixed(1);
}

double? _readDouble(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  if (normalized.isEmpty) {
    return null;
  }
  return double.tryParse(normalized);
}

List<String> _plannedGoalLabels(CardioPlan plan) {
  return <String>[
    if (plan.plannedDistanceKm != null)
      '${_formatNumber(plan.plannedDistanceKm!)} km',
    if (plan.plannedSpeedKmh != null)
      '${_formatNumber(plan.plannedSpeedKmh!)} km/h',
    if (plan.plannedInclinePercent != null)
      '${_formatNumber(plan.plannedInclinePercent!)}% inclinação',
    if (plan.plannedResistanceLevel != null)
      'resistência ${_formatNumber(plan.plannedResistanceLevel!)}',
  ];
}
