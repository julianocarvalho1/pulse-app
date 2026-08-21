import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/progress/domain/models/body_measurement_entry.dart';
import '../features/progress/presentation/providers/progress_controller.dart';
import '../features/settings/domain/pulse_settings.dart';
import '../features/settings/presentation/providers/settings_controller.dart';
import '../theme/app_theme.dart';

Future<void> showPersonalDataSheet(
  BuildContext context,
  PulseSettings settings,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return PersonalDataSheet(initialSettings: settings);
    },
  );
}

class PersonalDataSheet extends ConsumerStatefulWidget {
  const PersonalDataSheet({required this.initialSettings, super.key});

  final PulseSettings initialSettings;

  @override
  ConsumerState<PersonalDataSheet> createState() => _PersonalDataSheetState();
}

class _PersonalDataSheetState extends ConsumerState<PersonalDataSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _ageController;

  bool _isSaving = false;

  bool get _isMetric =>
      widget.initialSettings.measurementSystem == MeasurementSystem.metric;

  @override
  void initState() {
    super.initState();

    final profile = widget.initialSettings.profile;

    final displayedWeight = profile.weightKg <= 0
        ? ''
        : _isMetric
        ? profile.weightKg.toStringAsFixed(1)
        : (profile.weightKg * 2.2046226218).toStringAsFixed(1);

    final displayedHeight = profile.heightCm <= 0
        ? ''
        : _isMetric
        ? profile.heightCm.toStringAsFixed(0)
        : (profile.heightCm / 2.54).toStringAsFixed(1);

    _nameController = TextEditingController(
      text: profile.displayName == 'Atleta' ? '' : profile.displayName,
    );
    _weightController = TextEditingController(text: displayedWeight);
    _heightController = TextEditingController(text: displayedHeight);
    _ageController = TextEditingController(
      text: profile.age > 0 ? profile.age.toString() : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'EDITAR DADOS PESSOAIS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSaving
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();
                            Navigator.of(context).pop();
                          },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nome ou apelido'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _weightController,
                enabled: !_isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Peso atual (${_isMetric ? 'kg' : 'lbs'})',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _heightController,
                enabled: !_isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Altura (${_isMetric ? 'cm' : 'in'})',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ageController,
                enabled: !_isSaving,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                decoration: const InputDecoration(labelText: 'Idade'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: AppColors.onPrimary,
                    disabledBackgroundColor: primaryColor.withValues(
                      alpha: 0.55,
                    ),
                    disabledForegroundColor: AppColors.onPrimary.withValues(
                      alpha: 0.55,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : const Text(
                          'SALVAR ALTERAÇÕES',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      final enteredWeight = _parseDouble(_weightController.text);
      final enteredHeight = _parseDouble(_heightController.text);

      final weightKg = _isMetric ? enteredWeight : enteredWeight / 2.2046226218;
      final heightCm = _isMetric ? enteredHeight : enteredHeight * 2.54;

      final previousWeightKg = widget.initialSettings.profile.weightKg;
      final weightChanged = (previousWeightKg - weightKg).abs() >= 0.0001;

      if (weightChanged) {
        await ref.read(bodyMeasurementsControllerProvider.future);
        final measurementsController = ref.read(
          bodyMeasurementsControllerProvider.notifier,
        );

        await measurementsController.ensureWeightBaseline(previousWeightKg);

        if (weightKg > 0) {
          await measurementsController.save(
            BodyMeasurementEntry(
              id: 'profile_weight_${DateTime.now().microsecondsSinceEpoch}',
              recordedAt: DateTime.now(),
              weightKg: weightKg,
            ),
          );
        }
      }

      await ref
          .read(settingsControllerProvider.notifier)
          .updateProfile(
            UserProfile(
              name: _nameController.text,
              weightKg: weightKg,
              heightCm: heightCm,
              age: int.tryParse(_ageController.text.trim()) ?? 0,
            ),
          );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } catch (error, stackTrace) {
      debugPrint('Erro ao salvar perfil: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar os dados. Tente novamente.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() => _isSaving = false);
    }
  }

  double _parseDouble(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
  }
}
