import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../features/workouts/domain/models/free_activity_log.dart';
import '../features/workouts/presentation/providers/workout_controller.dart';
import '../theme/app_theme.dart';

class FreeActivityEntryScreen extends ConsumerStatefulWidget {
  const FreeActivityEntryScreen({super.key});

  @override
  ConsumerState<FreeActivityEntryScreen> createState() =>
      _FreeActivityEntryScreenState();
}

class _FreeActivityEntryScreenState
    extends ConsumerState<FreeActivityEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController(text: '45');
  final _customNameController = TextEditingController();
  final _notesController = TextEditingController();

  FreeActivityType _type = FreeActivityType.crossfit;
  FreeActivityIntensity _intensity = FreeActivityIntensity.moderate;
  DateTime _date = DateTime.now();
  bool _replacedPlannedWorkout = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _durationController.dispose();
    _customNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  IconData _typeIcon(FreeActivityType type) => switch (type) {
    FreeActivityType.crossfit => Icons.sports_gymnastics_rounded,
    FreeActivityType.functional => Icons.fitness_center_rounded,
    FreeActivityType.pilates => Icons.self_improvement_rounded,
    FreeActivityType.dance => Icons.music_note_rounded,
    FreeActivityType.mobility => Icons.accessibility_new_rounded,
    FreeActivityType.sport => Icons.sports_soccer_rounded,
    FreeActivityType.yoga => Icons.spa_rounded,
    FreeActivityType.other => Icons.more_horiz_rounded,
  };

  bool get _showsCustomName =>
      _type == FreeActivityType.other || _type == FreeActivityType.sport;

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'DATA DA ATIVIDADE',
      cancelText: 'CANCELAR',
      confirmText: 'CONFIRMAR',
    );

    if (selected != null && mounted) {
      setState(() {
        _date = selected;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) {
      return;
    }

    final duration = int.parse(_durationController.text.trim());
    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(workoutControllerProvider.notifier)
          .addFreeActivity(
            activity: FreeActivityLog(
              type: _type,
              durationMinutes: duration,
              intensity: _intensity,
              replacedPlannedWorkout: _replacedPlannedWorkout,
              customName: _customNameController.text.trim(),
              notes: _notesController.text.trim(),
            ),
            date: _date,
          );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar a atividade.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Registrar atividade',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MediaQuery.paddingOf(context).bottom + 24,
            ),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.sports_gymnastics_rounded,
                        color: primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Atividade fora da ficha',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Registre CrossFit, pilates, dança, mobilidade ou outro treino sem fingir que uma ficha de musculação foi concluída.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const _SectionTitle('QUAL ATIVIDADE VOCÊ FEZ?'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: FreeActivityType.values
                    .map((type) {
                      final selected = _type == type;
                      return ChoiceChip(
                        selected: selected,
                        showCheckmark: false,
                        avatar: Icon(
                          _typeIcon(type),
                          size: 17,
                          color: selected ? AppColors.onPrimary : primary,
                        ),
                        label: Text(type.label),
                        labelStyle: TextStyle(
                          color: selected
                              ? AppColors.onPrimary
                              : AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        selectedColor: primary,
                        backgroundColor: AppColors.surface,
                        side: BorderSide(
                          color: selected ? primary : AppColors.border,
                        ),
                        onSelected: (_) {
                          setState(() {
                            _type = type;
                          });
                        },
                      );
                    })
                    .toList(growable: false),
              ),
              if (_showsCustomName) ...<Widget>[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _customNameController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: _type == FreeActivityType.sport
                        ? 'Qual esporte?'
                        : 'Nome da atividade',
                    hintText: _type == FreeActivityType.sport
                        ? 'Ex.: Vôlei'
                        : 'Ex.: Aula de circo',
                    prefixIcon: const Icon(Icons.edit_outlined),
                  ),
                  validator: (value) {
                    if (_showsCustomName && value!.trim().isEmpty) {
                      return 'Informe o nome da atividade.';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 22),
              const _SectionTitle('DETALHES'),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Duração',
                        suffixText: 'min',
                        prefixIcon: Icon(Icons.timer_outlined),
                      ),
                      validator: (value) {
                        final duration = int.tryParse(value?.trim() ?? '');
                        if (duration == null || duration <= 0) {
                          return 'Informe a duração.';
                        }
                        if (duration > 600) {
                          return 'Máximo de 600 min.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(_date),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Intensidade percebida',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: FreeActivityIntensity.values
                    .map((intensity) {
                      final selected = _intensity == intensity;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: intensity == FreeActivityIntensity.intense
                                ? 0
                                : 8,
                          ),
                          child: ChoiceChip(
                            selected: selected,
                            showCheckmark: false,
                            label: SizedBox(
                              width: double.infinity,
                              child: Text(
                                intensity.label,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            labelStyle: TextStyle(
                              color: selected
                                  ? AppColors.onPrimary
                                  : AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                            selectedColor: primary,
                            backgroundColor: AppColors.surface,
                            side: BorderSide(
                              color: selected ? primary : AppColors.border,
                            ),
                            onSelected: (_) {
                              setState(() {
                                _intensity = intensity;
                              });
                            },
                          ),
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _replacedPlannedWorkout
                        ? primary.withValues(alpha: 0.55)
                        : AppColors.border,
                  ),
                ),
                child: SwitchListTile.adaptive(
                  value: _replacedPlannedWorkout,
                  activeTrackColor: primary,
                  title: const Text(
                    'Substituiu o treino planejado?',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    'O dia contará como ativo, mas nenhuma ficha será marcada como concluída.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _replacedPlannedWorkout = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                minLines: 3,
                maxLines: 5,
                maxLength: 300,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Observação (opcional)',
                  hintText: 'Ex.: Aula experimental com as amigas',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
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
                    _isSaving ? 'SALVANDO...' : 'SALVAR ATIVIDADE',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.45,
      ),
    );
  }
}
