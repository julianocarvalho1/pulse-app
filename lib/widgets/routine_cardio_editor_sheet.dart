import 'package:flutter/material.dart';

import '../features/workouts/data/catalogs/cardio_plan_template_catalog.dart';
import '../features/workouts/domain/models/cardio_log.dart';
import '../theme/app_theme.dart';

Future<RoutineCardio?> showRoutineCardioEditorSheet(
  BuildContext context, {
  RoutineCardio? existing,
  CardioPurpose initialPurpose = CardioPurpose.postWorkout,
  String? cardioId,
}) {
  final initial =
      existing ??
      RoutineCardio(
        id:
            cardioId ??
            'routine_cardio_${DateTime.now().microsecondsSinceEpoch}',
        modality: CardioModality.treadmill,
        plannedDurationMinutes: 20,
        plan: CardioPlan(purpose: initialPurpose),
      );

  return showModalBottomSheet<RoutineCardio>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) =>
        RoutineCardioEditorSheet(initial: initial, isEditing: existing != null),
  );
}

class RoutineCardioEditorSheet extends StatefulWidget {
  const RoutineCardioEditorSheet({
    super.key,
    required this.initial,
    this.isEditing = false,
  });

  final RoutineCardio initial;
  final bool isEditing;

  @override
  State<RoutineCardioEditorSheet> createState() =>
      _RoutineCardioEditorSheetState();
}

class _RoutineCardioEditorSheetState extends State<RoutineCardioEditorSheet> {
  final _formKey = GlobalKey<FormState>();

  late CardioModality _modality;
  late CardioPurpose _purpose;
  late CardioFormat _format;
  late CardioIntensity _intensity;
  String? _selectedTemplateId;
  bool _showEquipmentDetails = false;

  late final TextEditingController _durationController;
  late final TextEditingController _distanceController;
  late final TextEditingController _speedController;
  late final TextEditingController _inclineController;
  late final TextEditingController _resistanceController;
  late final TextEditingController _warmUpController;
  late final TextEditingController _effortController;
  late final TextEditingController _recoveryController;
  late final TextEditingController _cyclesController;
  late final TextEditingController _coolDownController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final cardio = widget.initial;
    final intervals = cardio.plan.intervals ?? const CardioIntervalPlan();
    _modality = cardio.modality;
    _purpose = cardio.plan.purpose;
    _format = cardio.plan.format;
    _intensity = cardio.plan.intensity;
    _durationController = TextEditingController(
      text: cardio.plannedDurationMinutes.toString(),
    );
    _distanceController = _decimalController(cardio.plan.plannedDistanceKm);
    _speedController = _decimalController(cardio.plan.plannedSpeedKmh);
    _inclineController = _decimalController(cardio.plan.plannedInclinePercent);
    _resistanceController = _decimalController(
      cardio.plan.plannedResistanceLevel,
    );
    _warmUpController = TextEditingController(
      text: intervals.warmUpMinutes.toString(),
    );
    _effortController = TextEditingController(
      text: intervals.effortSeconds.toString(),
    );
    _recoveryController = TextEditingController(
      text: intervals.recoverySeconds.toString(),
    );
    _cyclesController = TextEditingController(
      text: intervals.cycles.toString(),
    );
    _coolDownController = TextEditingController(
      text: intervals.coolDownMinutes.toString(),
    );
    _notesController = TextEditingController(text: cardio.notes);
    _showEquipmentDetails = <double?>[
      cardio.plan.plannedDistanceKm,
      cardio.plan.plannedSpeedKmh,
      cardio.plan.plannedInclinePercent,
      cardio.plan.plannedResistanceLevel,
    ].any((value) => value != null);
  }

  TextEditingController _decimalController(double? value) {
    return TextEditingController(
      text: value == null ? '' : _formatDecimal(value),
    );
  }

  @override
  void dispose() {
    _durationController.dispose();
    _distanceController.dispose();
    _speedController.dispose();
    _inclineController.dispose();
    _resistanceController.dispose();
    _warmUpController.dispose();
    _effortController.dispose();
    _recoveryController.dispose();
    _cyclesController.dispose();
    _coolDownController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _applyTemplate(CardioPlanTemplate template) {
    final plan = template.plan;
    final intervals = plan.intervals ?? const CardioIntervalPlan();
    setState(() {
      _selectedTemplateId = template.id;
      _format = plan.format;
      _intensity = plan.intensity;
      _durationController.text = template.durationMinutes.toString();
      _distanceController.text = _formatNullableDecimal(plan.plannedDistanceKm);
      _speedController.text = _formatNullableDecimal(plan.plannedSpeedKmh);
      _inclineController.text = _formatNullableDecimal(
        plan.plannedInclinePercent,
      );
      _resistanceController.text = _formatNullableDecimal(
        plan.plannedResistanceLevel,
      );
      _warmUpController.text = intervals.warmUpMinutes.toString();
      _effortController.text = intervals.effortSeconds.toString();
      _recoveryController.text = intervals.recoverySeconds.toString();
      _cyclesController.text = intervals.cycles.toString();
      _coolDownController.text = intervals.coolDownMinutes.toString();
    });
  }

  void _markCustomized() {
    setState(() => _selectedTemplateId = null);
  }

  CardioIntervalPlan _readIntervals() {
    return CardioIntervalPlan(
      warmUpMinutes: _parseInt(_warmUpController.text) ?? 0,
      effortSeconds: _parseInt(_effortController.text) ?? 0,
      recoverySeconds: _parseInt(_recoveryController.text) ?? 0,
      cycles: _parseInt(_cyclesController.text) ?? 0,
      coolDownMinutes: _parseInt(_coolDownController.text) ?? 0,
    );
  }

  String _formatCardioSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return remainder == 0 ? '$minutes min' : '$minutes min $remainder s';
  }

  String get _intervalCalculation {
    final plan = _readIntervals();
    final cycleSeconds =
        (plan.effortSeconds + plan.recoverySeconds) * plan.cycles;
    return '${plan.warmUpMinutes} min de aquecimento + '
        '${plan.cycles} × (${plan.effortSeconds} s de esforço + ${plan.recoverySeconds} s de recuperação) '
        '+ ${plan.coolDownMinutes} min de desaceleração.\n'
        'Trecho repetido: ${_formatCardioSeconds(cycleSeconds)}.';
  }

  int get _resolvedDurationMinutes {
    if (_format == CardioFormat.intervals) {
      return _readIntervals().totalDurationMinutes;
    }
    return _parseInt(_durationController.text) ?? 0;
  }

  String? _validateDuration(String? value) {
    final minutes = _parseInt(value);
    if (minutes == null || minutes <= 0) {
      return 'Informe uma duração maior que zero.';
    }
    if (minutes > 600) {
      return 'Use uma duração de até 600 minutos.';
    }
    return null;
  }

  String? _validateIntervalMinutes(String? value) {
    final minutes = _parseInt(value);
    if (minutes == null || minutes < 0 || minutes > 120) {
      return 'Use de 0 a 120.';
    }
    return null;
  }

  String? _validateIntervalSeconds(String? value) {
    final seconds = _parseInt(value);
    if (seconds == null || seconds <= 0 || seconds > 3600) {
      return 'Use de 1 a 3600.';
    }
    return null;
  }

  String? _validateCycles(String? value) {
    final cycles = _parseInt(value);
    if (cycles == null || cycles <= 0 || cycles > 100) {
      return 'Use de 1 a 100.';
    }
    return null;
  }

  String? _validateOptionalDecimal(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    final number = _parseDouble(text);
    if (number == null || number < 0) {
      return 'Use zero ou um valor positivo.';
    }
    return null;
  }

  void _save() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final intervals = _format == CardioFormat.intervals
        ? _readIntervals()
        : null;
    final duration =
        intervals?.totalDurationMinutes ??
        (_parseInt(_durationController.text) ?? 0);
    if (duration <= 0 || duration > 600) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A duração total precisa ficar entre 1 e 600 minutos.'),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      RoutineCardio(
        id: widget.initial.id,
        modality: _modality,
        plannedDurationMinutes: duration,
        plan: CardioPlan(
          purpose: _purpose,
          format: _format,
          intensity: _intensity,
          plannedDistanceKm: _parseDouble(_distanceController.text),
          plannedSpeedKmh: _parseDouble(_speedController.text),
          plannedInclinePercent: _parseDouble(_inclineController.text),
          plannedResistanceLevel: _parseDouble(_resistanceController.text),
          intervals: intervals,
        ),
        notes: _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final navigationInset = MediaQuery.viewPaddingOf(context).bottom;
    final bottomInset = keyboardInset > navigationInset
        ? keyboardInset
        : navigationInset;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 28),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      widget.isEditing ? 'Editar cardio' : 'Planejar cardio',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                'Escolha um modelo ou preencha conforme a sua ficha. Tudo pode ser editado.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              const _SectionTitle('MODELOS EDITÁVEIS'),
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CardioPlanTemplateCatalog.all
                    .map(
                      (template) => ChoiceChip(
                        key: Key('cardio-template-${template.id}'),
                        label: Text(template.name),
                        selected: _selectedTemplateId == template.id,
                        showCheckmark: false,
                        onSelected: (_) => _applyTemplate(template),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 8),
              Text(
                'Os modelos são pontos de partida, não uma prescrição individual.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 20),
              const _SectionTitle('ESTRUTURA'),
              const SizedBox(height: 10),
              DropdownButtonFormField<CardioModality>(
                key: const Key('cardio-modality'),
                initialValue: _modality,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Modalidade'),
                items: CardioModality.values
                    .map(
                      (value) => DropdownMenuItem<CardioModality>(
                        value: value,
                        child: Text(value.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _modality = value;
                      _selectedTemplateId = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CardioPurpose>(
                key: const Key('cardio-purpose'),
                initialValue: _purpose,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Finalidade'),
                items: CardioPurpose.values
                    .map(
                      (value) => DropdownMenuItem<CardioPurpose>(
                        value: value,
                        child: Text(value.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _purpose = value;
                      _selectedTemplateId = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CardioFormat>(
                key: ValueKey<String>('cardio-format-${_format.storageValue}'),
                initialValue: _format,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Formato'),
                items: CardioFormat.values
                    .map(
                      (value) => DropdownMenuItem<CardioFormat>(
                        value: value,
                        child: Text(value.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _format = value;
                      _selectedTemplateId = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CardioIntensity>(
                key: ValueKey<String>(
                  'cardio-intensity-${_intensity.storageValue}',
                ),
                initialValue: _intensity,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Intensidade relativa',
                ),
                items: CardioIntensity.values
                    .map(
                      (value) => DropdownMenuItem<CardioIntensity>(
                        value: value,
                        child: Text(
                          value.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _intensity = value;
                      _selectedTemplateId = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryBorder),
                ),
                child: Text(
                  'Teste da fala: ${_intensity.talkTestDescription}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_format == CardioFormat.continuous) ...<Widget>[
                const _SectionTitle('DURAÇÃO'),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('cardio-duration'),
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  validator: _validateDuration,
                  onChanged: (_) => _markCustomized(),
                  decoration: const InputDecoration(
                    labelText: 'Duração planejada',
                    suffixText: 'min',
                  ),
                ),
              ] else ...<Widget>[
                const _SectionTitle('BLOCOS DO INTERVALADO'),
                const SizedBox(height: 12),
                const _SectionTitle('1. INÍCIO · UMA VEZ'),
                const SizedBox(height: 8),
                _IntegerField(
                  key: const Key('cardio-warm-up'),
                  controller: _warmUpController,
                  label: 'Aquecimento',
                  suffix: 'min',
                  validator: _validateIntervalMinutes,
                  onChanged: (_) => _markCustomized(),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle('2. CICLO QUE SE REPETE'),
                      const SizedBox(height: 8),
                      const Text(
                        'Cada ciclo = esforço + recuperação. Só este trecho se repete.',
                      ),
                      const SizedBox(height: 12),
                      _IntegerField(
                        key: const Key('cardio-effort'),
                        controller: _effortController,
                        label: 'Esforço por ciclo',
                        suffix: 'segundos',
                        validator: _validateIntervalSeconds,
                        onChanged: (_) => _markCustomized(),
                      ),
                      const SizedBox(height: 10),
                      _IntegerField(
                        key: const Key('cardio-recovery'),
                        controller: _recoveryController,
                        label: 'Recuperação por ciclo',
                        suffix: 'segundos',
                        validator: _validateIntervalSeconds,
                        onChanged: (_) => _markCustomized(),
                      ),
                      const SizedBox(height: 10),
                      _IntegerField(
                        key: const Key('cardio-cycles'),
                        controller: _cyclesController,
                        label: 'Repetir este ciclo',
                        suffix: 'vezes',
                        validator: _validateCycles,
                        onChanged: (_) => _markCustomized(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const _SectionTitle('3. FINAL · UMA VEZ'),
                const SizedBox(height: 8),
                _IntegerField(
                  key: const Key('cardio-cool-down'),
                  controller: _coolDownController,
                  label: 'Desaceleração',
                  suffix: 'min',
                  validator: _validateIntervalMinutes,
                  onChanged: (_) => _markCustomized(),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Duração calculada: ${_formatCardioSeconds(_readIntervals().totalDurationSeconds)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(_intervalCalculation),
                      const SizedBox(height: 8),
                      const Text(
                        'Aquecimento e desaceleração não se repetem. A recuperação está incluída em cada ciclo, inclusive no último.',
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(
                    () => _showEquipmentDetails = !_showEquipmentDetails,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.tune_rounded),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Metas do aparelho (opcionais)',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Icon(
                          _showEquipmentDetails
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_showEquipmentDetails) ...<Widget>[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: _DecimalField(
                        controller: _distanceController,
                        label: 'Distância',
                        suffix: 'km',
                        validator: _validateOptionalDecimal,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DecimalField(
                        controller: _speedController,
                        label: 'Velocidade',
                        suffix: 'km/h',
                        validator: _validateOptionalDecimal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: _DecimalField(
                        controller: _inclineController,
                        label: 'Inclinação',
                        suffix: '%',
                        validator: _validateOptionalDecimal,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DecimalField(
                        controller: _resistanceController,
                        label: 'Resistência',
                        suffix: 'nível',
                        validator: _validateOptionalDecimal,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('cardio-notes'),
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Orientação da ficha (opcional)',
                  hintText: 'Ex.: manter o ritmo indicado pelo personal',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('save-cardio-plan'),
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('SALVAR CARDIO'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int? _parseInt(String? value) => int.tryParse(value?.trim() ?? '');

  double? _parseDouble(String? value) {
    final text = value?.trim().replaceAll(',', '.') ?? '';
    return text.isEmpty ? null : double.tryParse(text);
  }

  String _formatNullableDecimal(double? value) {
    return value == null ? '' : _formatDecimal(value);
  }

  String _formatDecimal(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1).replaceAll('.', ',');
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _IntegerField extends StatelessWidget {
  const _IntegerField({
    super.key,
    required this.controller,
    required this.label,
    required this.suffix,
    required this.validator,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final FormFieldValidator<String> validator;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label, suffixText: suffix),
    );
  }
}

class _DecimalField extends StatelessWidget {
  const _DecimalField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
      decoration: InputDecoration(labelText: label, suffixText: suffix),
    );
  }
}
