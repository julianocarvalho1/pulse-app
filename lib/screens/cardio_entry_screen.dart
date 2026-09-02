import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/workouts/domain/models/cardio_log.dart';
import '../features/workouts/presentation/providers/workout_controller.dart';
import '../theme/app_theme.dart';

class CardioEntryScreen extends ConsumerStatefulWidget {
  const CardioEntryScreen({super.key});

  @override
  ConsumerState<CardioEntryScreen> createState() => _CardioEntryScreenState();
}

class _CardioEntryScreenState extends ConsumerState<CardioEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plannedDurationController = TextEditingController(text: '30');
  final _actualDurationController = TextEditingController(text: '30');
  final _distanceController = TextEditingController();
  final _speedController = TextEditingController();
  final _inclineController = TextEditingController();
  final _resistanceController = TextEditingController();
  final _effortController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _notesController = TextEditingController();

  CardioModality _modality = CardioModality.treadmill;
  bool _showOptionalFields = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _plannedDurationController.dispose();
    _actualDurationController.dispose();
    _distanceController.dispose();
    _speedController.dispose();
    _inclineController.dispose();
    _resistanceController.dispose();
    _effortController.dispose();
    _heartRateController.dispose();
    _notesController.dispose();
    super.dispose();
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

  int? _parseInt(String value) {
    return int.tryParse(value.trim());
  }

  double? _parseDouble(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  String? _validateRequiredMinutes(String? value) {
    final minutes = _parseInt(value ?? '');
    if (minutes == null || minutes <= 0) {
      return 'Informe a duração realizada.';
    }
    if (minutes > 1440) {
      return 'Use um valor de até 1440 minutos.';
    }
    return null;
  }

  String? _validateOptionalMinutes(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    final minutes = _parseInt(text);
    if (minutes == null || minutes < 0 || minutes > 1440) {
      return 'Use um valor entre 0 e 1440.';
    }
    return null;
  }

  String? _validateOptionalDecimal(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    final parsed = _parseDouble(text);
    if (parsed == null || parsed < 0) {
      return 'Valor inválido.';
    }
    return null;
  }

  String? _validateEffort(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    final parsed = _parseInt(text);
    if (parsed == null || parsed < 1 || parsed > 10) {
      return 'Use uma escala de 1 a 10.';
    }
    return null;
  }

  String? _validateHeartRate(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    final parsed = _parseInt(text);
    if (parsed == null || parsed < 30 || parsed > 250) {
      return 'Use um valor entre 30 e 250 bpm.';
    }
    return null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _isSaving) {
      return;
    }

    setState(() => _isSaving = true);

    final log = CardioLog(
      modality: _modality,
      plan: const CardioPlan(purpose: CardioPurpose.standalone),
      plannedDurationMinutes: _parseInt(_plannedDurationController.text) ?? 0,
      actualDurationMinutes: _parseInt(_actualDurationController.text)!,
      distanceKm: _parseDouble(_distanceController.text),
      averageSpeedKmh: _parseDouble(_speedController.text),
      inclinePercent: _parseDouble(_inclineController.text),
      resistanceLevel: _parseDouble(_resistanceController.text),
      perceivedEffort: _parseInt(_effortController.text),
      averageHeartRateBpm: _parseInt(_heartRateController.text),
      notes: _notesController.text.trim(),
    );

    try {
      await ref
          .read(workoutControllerProvider.notifier)
          .addCardioSession(cardio: log);

      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar o cardio. Tente novamente.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Registrar cardio',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              20,
              10,
              20,
              MediaQuery.paddingOf(context).bottom + 120,
            ),
            children: <Widget>[
              _IntroCard(modality: _modality, icon: _iconFor(_modality)),
              const SizedBox(height: 24),
              const _SectionLabel('MODALIDADE'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CardioModality.values
                    .map((modality) {
                      final selected = modality == _modality;
                      return ChoiceChip(
                        avatar: Icon(
                          _iconFor(modality),
                          size: 17,
                          color: selected
                              ? AppColors.onPrimary
                              : AppColors.textSecondary,
                        ),
                        label: Text(modality.label),
                        selected: selected,
                        showCheckmark: false,
                        selectedColor: Theme.of(context).colorScheme.primary,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        side: BorderSide(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : AppColors.border,
                        ),
                        labelStyle: TextStyle(
                          color: selected
                              ? AppColors.onPrimary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (_) => setState(() => _modality = modality),
                      );
                    })
                    .toList(growable: false),
              ),
              const SizedBox(height: 26),
              const _SectionLabel('DURAÇÃO'),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: _NumberField(
                      controller: _plannedDurationController,
                      label: 'Planejada',
                      suffix: 'min',
                      validator: _validateOptionalMinutes,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NumberField(
                      controller: _actualDurationController,
                      label: 'Realizada *',
                      suffix: 'min',
                      validator: _validateRequiredMinutes,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Material(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => setState(
                    () => _showOptionalFields = !_showOptionalFields,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Detalhes opcionais',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Distância, velocidade, esforço e outros dados.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _showOptionalFields
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_showOptionalFields) ...<Widget>[
                const SizedBox(height: 14),
                _OptionalMetricsCard(
                  distanceController: _distanceController,
                  speedController: _speedController,
                  inclineController: _inclineController,
                  resistanceController: _resistanceController,
                  effortController: _effortController,
                  heartRateController: _heartRateController,
                  decimalValidator: _validateOptionalDecimal,
                  effortValidator: _validateEffort,
                  heartRateValidator: _validateHeartRate,
                ),
              ],
              const SizedBox(height: 24),
              const _SectionLabel('OBSERVAÇÕES'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesController,
                minLines: 3,
                maxLines: 5,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText:
                      'Ex.: ritmo leve, dor no joelho, treino em jejum...',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.primaryBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'O PULSE registra os dados informados por você. Nenhuma estimativa automática de calorias é criada.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
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
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(
              _isSaving ? 'SALVANDO...' : 'SALVAR CARDIO',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: AppColors.onPrimary,
              disabledBackgroundColor: AppColors.border,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.modality, required this.icon});

  final CardioModality modality;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[AppColors.primarySoft, AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: AppColors.onPrimary, size: 27),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  modality.label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Registre o que realmente foi realizado.',
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
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.55,
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.validator,
    this.integerOnly = true,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final FormFieldValidator<String> validator;
  final bool integerOnly;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: integerOnly
          ? TextInputType.number
          : const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}

class _OptionalMetricsCard extends StatelessWidget {
  const _OptionalMetricsCard({
    required this.distanceController,
    required this.speedController,
    required this.inclineController,
    required this.resistanceController,
    required this.effortController,
    required this.heartRateController,
    required this.decimalValidator,
    required this.effortValidator,
    required this.heartRateValidator,
  });

  final TextEditingController distanceController;
  final TextEditingController speedController;
  final TextEditingController inclineController;
  final TextEditingController resistanceController;
  final TextEditingController effortController;
  final TextEditingController heartRateController;
  final FormFieldValidator<String> decimalValidator;
  final FormFieldValidator<String> effortValidator;
  final FormFieldValidator<String> heartRateValidator;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _NumberField(
                  controller: distanceController,
                  label: 'Distância',
                  suffix: 'km',
                  integerOnly: false,
                  validator: decimalValidator,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NumberField(
                  controller: speedController,
                  label: 'Velocidade média',
                  suffix: 'km/h',
                  integerOnly: false,
                  validator: decimalValidator,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _NumberField(
                  controller: inclineController,
                  label: 'Inclinação',
                  suffix: '%',
                  integerOnly: false,
                  validator: decimalValidator,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NumberField(
                  controller: resistanceController,
                  label: 'Resistência',
                  suffix: 'nível',
                  integerOnly: false,
                  validator: decimalValidator,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _NumberField(
                  controller: effortController,
                  label: 'Esforço percebido',
                  suffix: '/10',
                  validator: effortValidator,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NumberField(
                  controller: heartRateController,
                  label: 'Frequência média',
                  suffix: 'bpm',
                  validator: heartRateValidator,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
