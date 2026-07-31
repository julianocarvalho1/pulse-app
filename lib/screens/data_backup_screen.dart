import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../features/auth/presentation/providers/auth_controller.dart';
import '../features/backup/domain/pulse_backup.dart';
import '../features/backup/presentation/providers/backup_providers.dart';
import '../features/onboarding/presentation/providers/onboarding_controller.dart';
import '../features/progress/presentation/providers/progress_controller.dart';
import '../features/settings/presentation/providers/settings_controller.dart';
import '../features/workouts/presentation/providers/workout_controller.dart';
import '../theme/app_theme.dart';

class DataBackupScreen extends ConsumerStatefulWidget {
  const DataBackupScreen({super.key});

  @override
  ConsumerState<DataBackupScreen> createState() => _DataBackupScreenState();
}

class _DataBackupScreenState extends ConsumerState<DataBackupScreen> {
  String? _busyAction;

  bool get _isBusy => _busyAction != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Dados e backup',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        children: [
          _informationCard(context),
          const SizedBox(height: 28),
          _sectionTitle('BACKUP LOCAL'),
          const SizedBox(height: 12),
          _sectionCard(
            context,
            children: [
              ListTile(
                enabled: !_isBusy,
                leading: _actionIcon(context, Icons.file_download_outlined),
                title: const Text(
                  'Exportar backup',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Escolha onde salvar uma cópia dos seus dados.',
                ),
                trailing: _busyAction == 'export'
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: _exportBackup,
              ),
              Divider(color: AppColors.border, height: 1),
              ListTile(
                enabled: !_isBusy,
                leading: _actionIcon(
                  context,
                  Icons.settings_backup_restore_outlined,
                ),
                title: const Text(
                  'Importar backup',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Substitui os dados atuais pelos dados de um arquivo do PULSE.',
                ),
                trailing: _busyAction == 'import'
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: _importBackup,
              ),
            ],
          ),
          const SizedBox(height: 28),
          _sectionTitle('HISTÓRICO DE MEDIDAS'),
          const SizedBox(height: 12),
          _sectionCard(
            context,
            children: [
              ListTile(
                enabled: !_isBusy,
                leading: const Icon(
                  Icons.delete_sweep_outlined,
                  color: Colors.orangeAccent,
                ),
                title: const Text(
                  'Apagar histórico de medidas',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Remove somente pesagens e avaliações corporais.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _confirmClearMeasurements,
              ),
            ],
          ),
          const SizedBox(height: 28),
          _sectionTitle('ZONA DE PERIGO'),
          const SizedBox(height: 12),
          _sectionCard(
            context,
            children: [
              ListTile(
                enabled: !_isBusy,
                leading: const Icon(
                  Icons.delete_forever,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Apagar todos os dados',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.redAccent,
                  ),
                ),
                subtitle: const Text(
                  'Remove perfil, fichas, histórico e preferências deste aparelho.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _confirmFactoryReset,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _informationCard(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: primary),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'O backup inclui perfil, preferências, fichas, histórico, medidas e treino em andamento. O arquivo não é criptografado; guarde-o em um local seguro. A proteção por biometria ou senha do aparelho não é restaurada automaticamente.',
              style: TextStyle(height: 1.45, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup() async {
    if (_isBusy) {
      return;
    }

    setState(() => _busyAction = 'export');

    try {
      final service = ref.read(pulseBackupServiceProvider);
      final bytes = await service.exportBytes();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Salvar backup do PULSE',
        fileName: 'PULSE_backup_$timestamp.json',
        type: FileType.custom,
        allowedExtensions: const <String>['json'],
        bytes: bytes,
      );

      if (savedPath != null && mounted) {
        _showMessage('Backup salvo com sucesso.');
      }
    } on PulseBackupException catch (error) {
      if (mounted) {
        _showMessage(error.message, isError: true);
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Não foi possível criar o backup. Tente novamente.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyAction = null);
      }
    }
  }

  Future<void> _importBackup() async {
    if (_isBusy) {
      return;
    }

    setState(() => _busyAction = 'import');

    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Selecionar backup do PULSE',
        type: FileType.custom,
        allowedExtensions: const <String>['json'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final bytes = await _readPickedFile(result.files.single);
      final service = ref.read(pulseBackupServiceProvider);
      final preview = service.inspectBytes(bytes);

      if (!mounted) {
        return;
      }

      final confirmed = await _confirmImport(preview);
      if (confirmed != true || !mounted) {
        return;
      }

      await ref
          .read(workoutSessionControllerProvider.notifier)
          .prepareForFactoryReset();

      try {
        await service.importBytes(bytes);
      } catch (error) {
        await ref.read(workoutControllerProvider.notifier).reload();
        rethrow;
      }

      await _reloadApplicationState();

      if (mounted) {
        _showMessage('Backup restaurado com sucesso.');
      }
    } on PulseBackupException catch (error) {
      if (mounted) {
        _showMessage(error.message, isError: true);
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Não foi possível importar esse backup.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _busyAction = null);
      }
    }
  }

  Future<Uint8List> _readPickedFile(PlatformFile file) async {
    final bytes = file.bytes;
    if (bytes != null) {
      return bytes;
    }

    final path = file.path;
    if (path == null) {
      throw const PulseBackupException(
        'Não foi possível ler o arquivo selecionado.',
      );
    }

    return File(path).readAsBytes();
  }

  Future<bool?> _confirmImport(PulseBackupPreview preview) {
    final date = DateFormat('dd/MM/yyyy HH:mm').format(preview.createdAt);

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restaurar este backup?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Criado em: $date'),
            const SizedBox(height: 14),
            Text('${preview.routineCount} fichas de treino'),
            Text('${preview.workoutCount} treinos no histórico'),
            Text('${preview.measurementCount} registros de medidas'),
            Text('${preview.customExerciseCount} exercícios personalizados'),
            const SizedBox(height: 14),
            const Text(
              'Os dados atuais serão substituídos. Essa ação não pode ser desfeita sem outro backup.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearMeasurements() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Apagar histórico de medidas?'),
        content: const Text(
          'Todas as pesagens e avaliações corporais serão removidas. O peso atual do Perfil também será limpo. Fichas e treinos não serão afetados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Apagar medidas'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _busyAction = 'clear-measurements');

    try {
      await ref.read(bodyMeasurementsControllerProvider.notifier).clearAll();
      if (mounted) {
        _showMessage('Histórico de medidas apagado.');
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Não foi possível apagar o histórico de medidas.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyAction = null);
      }
    }
  }

  Future<void> _confirmFactoryReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Apagar todos os dados?'),
        content: const Text(
          'Essa ação apagará perfil, fichas, histórico, medidas e preferências salvas neste aparelho. Não será possível desfazer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Apagar tudo'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _busyAction = 'factory-reset');

    try {
      await ref.read(workoutControllerProvider.notifier).factoryReset();
      await ref.read(bodyMeasurementsControllerProvider.notifier).clearAll();
      await ref
          .read(settingsControllerProvider.notifier)
          .resetToDefaults(clearStorage: false);
      await ref.read(authControllerProvider.notifier).resetAfterFactoryReset();
      ref.read(onboardingControllerProvider.notifier).resetAfterFactoryReset();

      if (!mounted) {
        return;
      }

      Navigator.of(context).popUntil((route) => route.isFirst);
      _showMessage('Os dados locais do PULSE foram apagados.');
    } catch (error) {
      if (mounted) {
        _showMessage('Não foi possível apagar todos os dados.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _busyAction = null);
      }
    }
  }

  Future<void> _reloadApplicationState() async {
    await ref.read(settingsControllerProvider.notifier).reload();
    await ref.read(onboardingControllerProvider.notifier).reload();
    await ref.read(authControllerProvider.notifier).reload();
    await ref.read(workoutControllerProvider.notifier).reload();
    await ref.read(bodyMeasurementsControllerProvider.notifier).reload();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : null,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 1,
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required List<Widget> children}) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _actionIcon(BuildContext context, IconData icon) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: primary),
    );
  }
}
