import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../theme/app_theme.dart';
import '../../data/services/pulse_workout_file_service.dart';
import '../../domain/models/pulse_workout_file.dart';
import '../../domain/services/pulse_workout_qr_codec.dart';

class PulseWorkoutQrScreen extends StatefulWidget {
  const PulseWorkoutQrScreen({super.key, required this.document});

  final PulseWorkoutDocument document;

  @override
  State<PulseWorkoutQrScreen> createState() => _PulseWorkoutQrScreenState();
}

class _PulseWorkoutQrScreenState extends State<PulseWorkoutQrScreen> {
  String? _qrData;
  String? _error;
  bool _isSharingFile = false;

  @override
  void initState() {
    super.initState();
    try {
      _qrData = const PulseWorkoutQrCodec().encode(widget.document);
    } on PulseWorkoutFileException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Não foi possível gerar o QR Code deste conteúdo.';
    }
  }

  Future<void> _shareFile() async {
    if (_isSharingFile) {
      return;
    }
    setState(() => _isSharingFile = true);
    try {
      await const PulseWorkoutFileService().shareDocument(widget.document);
    } on PulseWorkoutFileException catch (error) {
      if (mounted) {
        _showError(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showError('Não foi possível compartilhar o arquivo. Tente novamente.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSharingFile = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document;
    final qrData = _qrData;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'QR Code do PULSE',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.paddingOf(context).bottom + 28,
        ),
        children: <Widget>[
          _summaryCard(context, document),
          const SizedBox(height: 18),
          if (qrData != null)
            _qrCard(context, qrData)
          else
            _errorCard(context, _error ?? 'Não foi possível gerar o QR Code.'),
        ],
      ),
    );
  }

  Widget _summaryCard(BuildContext context, PulseWorkoutDocument document) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              document.contentType == PulseWorkoutContentType.program
                  ? Icons.folder_copy_outlined
                  : Icons.assignment_outlined,
              color: primary,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${document.contentType.label} • ${document.routines.length} ficha${document.routines.length == 1 ? '' : 's'}',
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

  Widget _qrCard(BuildContext context, String data) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          const Text(
            'Aponte a câmera do outro aparelho',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'No outro PULSE, abra Criar treino e escolha “Ler QR Code”.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final qrSize = (constraints.maxWidth - 24)
                  .clamp(210.0, 270.0)
                  .toDouble();
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: qrSize,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                  errorStateBuilder: (context, error) => const SizedBox(
                    height: 220,
                    child: Center(
                      child: Text(
                        'Não foi possível desenhar este QR Code.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'O outro aparelho sempre mostrará uma revisão antes de adicionar. Fichas duplicadas continuam bloqueadas.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _errorCard(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.36)),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.qr_code_2_rounded,
            size: 44,
            color: Colors.orangeAccent,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isSharingFile ? null : _shareFile,
            icon: _isSharingFile
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_outlined),
            label: const Text('Compartilhar arquivo .pulse'),
          ),
        ],
      ),
    );
  }
}
