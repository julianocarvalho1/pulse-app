import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../features/progress/domain/models/body_measurement_entry.dart';
import '../features/settings/domain/pulse_settings.dart';
import '../theme/app_theme.dart';

class BodyMeasurementEditorScreen extends StatefulWidget {
  const BodyMeasurementEditorScreen({
    super.key,
    required this.history,
    required this.measurementSystem,
  });

  final List<BodyMeasurementEntry> history;
  final MeasurementSystem measurementSystem;

  @override
  State<BodyMeasurementEditorScreen> createState() =>
      _BodyMeasurementEditorScreenState();
}

class _BodyMeasurementEditorScreenState
    extends State<BodyMeasurementEditorScreen> {
  static const List<BodyMeasurementType> _mainTypes = <BodyMeasurementType>[
    BodyMeasurementType.weight,
    BodyMeasurementType.shoulders,
    BodyMeasurementType.chest,
    BodyMeasurementType.waist,
    BodyMeasurementType.hips,
  ];
  static const List<BodyMeasurementType> _armTypes = <BodyMeasurementType>[
    BodyMeasurementType.leftArm,
    BodyMeasurementType.rightArm,
    BodyMeasurementType.leftForearm,
    BodyMeasurementType.rightForearm,
  ];
  static const List<BodyMeasurementType> _legTypes = <BodyMeasurementType>[
    BodyMeasurementType.leftThigh,
    BodyMeasurementType.rightThigh,
    BodyMeasurementType.leftCalf,
    BodyMeasurementType.rightCalf,
  ];

  late final Map<BodyMeasurementType, TextEditingController> _controllers;
  late DateTime _recordedAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _recordedAt = DateTime.now();
    _controllers = <BodyMeasurementType, TextEditingController>{
      for (final type in BodyMeasurementType.values)
        type: TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova avaliação corporal')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: <Widget>[
            Text(
              'Preencha somente o que foi medido hoje. Os valores anteriores aparecem apenas como referência.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            _dateCard(),
            const SizedBox(height: 16),
            _measurementSection(
              title: 'MEDIDAS PRINCIPAIS',
              icon: Icons.straighten,
              types: _mainTypes,
              initiallyExpanded: true,
            ),
            const SizedBox(height: 10),
            _measurementSection(
              title: 'BRAÇOS',
              icon: Icons.fitness_center,
              types: _armTypes,
            ),
            const SizedBox(height: 10),
            _measurementSection(
              title: 'PERNAS',
              icon: Icons.directions_walk,
              types: _legTypes,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('SALVAR AVALIAÇÃO'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateCard() {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        leading: const Icon(Icons.calendar_today_outlined),
        title: const Text('Data da avaliação'),
        subtitle: Text(DateFormat("dd/MM/yyyy 'às' HH:mm").format(_recordedAt)),
        trailing: const Icon(Icons.chevron_right),
        onTap: _selectDate,
      ),
    );
  }

  Widget _measurementSection({
    required String title,
    required IconData icon,
    required List<BodyMeasurementType> types,
    bool initiallyExpanded = false,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        children: types.map(_field).toList(),
      ),
    );
  }

  Widget _field(BodyMeasurementType type) {
    final previous = _latestEntryFor(type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _controllers[type],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: type.label,
          suffixText: _unitFor(type),
          helperText: previous == null
              ? 'Sem registro anterior'
              : 'Último: ${_displayValue(previous.valueFor(type)!, type)} ${_unitFor(type)} em ${DateFormat('dd/MM/yyyy').format(previous.recordedAt)}',
          helperMaxLines: 2,
        ),
      ),
    );
  }

  BodyMeasurementEntry? _latestEntryFor(BodyMeasurementType type) {
    for (final entry in widget.history) {
      if (entry.valueFor(type) != null) {
        return entry;
      }
    }
    return null;
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_recordedAt),
    );
    if (!mounted) {
      return;
    }

    final selectedTime = time ?? TimeOfDay.fromDateTime(_recordedAt);
    setState(() {
      _recordedAt = DateTime(
        date.year,
        date.month,
        date.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    final values = <BodyMeasurementType, double?>{
      for (final type in BodyMeasurementType.values)
        type: _toStorageValue(_parse(_controllers[type]!.text), type),
    };

    if (values.values.every((value) => value == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe pelo menos uma medida válida.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    Navigator.pop(
      context,
      BodyMeasurementEntry(
        id: 'measurement_${DateTime.now().microsecondsSinceEpoch}',
        recordedAt: _recordedAt,
        weightKg: values[BodyMeasurementType.weight],
        shouldersCm: values[BodyMeasurementType.shoulders],
        chestCm: values[BodyMeasurementType.chest],
        waistCm: values[BodyMeasurementType.waist],
        hipsCm: values[BodyMeasurementType.hips],
        leftArmCm: values[BodyMeasurementType.leftArm],
        rightArmCm: values[BodyMeasurementType.rightArm],
        leftForearmCm: values[BodyMeasurementType.leftForearm],
        rightForearmCm: values[BodyMeasurementType.rightForearm],
        leftThighCm: values[BodyMeasurementType.leftThigh],
        rightThighCm: values[BodyMeasurementType.rightThigh],
        leftCalfCm: values[BodyMeasurementType.leftCalf],
        rightCalfCm: values[BodyMeasurementType.rightCalf],
      ),
    );
  }

  String _unitFor(BodyMeasurementType type) {
    if (widget.measurementSystem == MeasurementSystem.metric) {
      return type.isWeight ? 'kg' : 'cm';
    }
    return type.isWeight ? 'lbs' : 'in';
  }

  String _displayValue(double value, BodyMeasurementType type) {
    final displayed = widget.measurementSystem == MeasurementSystem.metric
        ? value
        : type.isWeight
        ? value * 2.2046226218
        : value / 2.54;
    return displayed.toStringAsFixed(1).replaceAll('.', ',');
  }

  double? _toStorageValue(double? value, BodyMeasurementType type) {
    if (value == null || widget.measurementSystem == MeasurementSystem.metric) {
      return value;
    }
    return type.isWeight ? value / 2.2046226218 : value * 2.54;
  }

  double? _parse(String text) {
    final value = double.tryParse(text.trim().replaceAll(',', '.'));
    if (value == null || value <= 0) {
      return null;
    }
    return value;
  }
}
