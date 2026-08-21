import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../domain/models/pulse_workout_file.dart';
import '../../domain/services/pulse_workout_qr_codec.dart';
import 'pulse_workout_import_screen.dart';

class PulseWorkoutQrScannerScreen extends StatefulWidget {
  const PulseWorkoutQrScannerScreen({super.key});

  @override
  State<PulseWorkoutQrScannerScreen> createState() =>
      _PulseWorkoutQrScannerScreenState();
}

class _PulseWorkoutQrScannerScreenState
    extends State<PulseWorkoutQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 500,
  );

  bool _isHandling = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleCapture(BarcodeCapture capture) async {
    if (_isHandling) {
      return;
    }
    final rawValue = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstWhere((value) => value.trim().isNotEmpty, orElse: () => '');
    if (rawValue.isEmpty) {
      return;
    }

    _isHandling = true;
    PulseWorkoutDocument document;
    try {
      document = const PulseWorkoutQrCodec().decode(rawValue);
    } on PulseWorkoutFileException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
      await Future<void>.delayed(const Duration(milliseconds: 900));
      _isHandling = false;
      return;
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível ler esse QR Code.');
      }
      await Future<void>.delayed(const Duration(milliseconds: 900));
      _isHandling = false;
      return;
    }

    await _controller.stop();
    if (!mounted) {
      return;
    }

    final imported = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => PulseWorkoutImportScreen(
          initialDocument: document,
          sourceLabel: 'QR Code',
        ),
      ),
    );

    if (!mounted) {
      return;
    }
    if (imported ?? false) {
      Navigator.pop(context, true);
      return;
    }

    setState(() => _error = null);
    _isHandling = false;
    await _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Ler QR Code do PULSE',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Lanterna',
            onPressed: () async {
              await _controller.toggleTorch();
            },
            icon: const Icon(Icons.flashlight_on_outlined),
          ),
          IconButton(
            tooltip: 'Trocar câmera',
            onPressed: () async {
              await _controller.switchCamera();
            },
            icon: const Icon(Icons.cameraswitch_outlined),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          MobileScanner(
            controller: _controller,
            onDetect: _handleCapture,
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  error.errorCode == MobileScannerErrorCode.permissionDenied
                      ? 'Permita o acesso à câmera para ler QR Codes do PULSE.'
                      : 'Não foi possível iniciar a câmera.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          const _ScannerShade(),
          SafeArea(
            child: Column(
              children: <Widget>[
                const Spacer(),
                Container(
                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        _error == null
                            ? Icons.qr_code_scanner_rounded
                            : Icons.error_outline_rounded,
                        color: _error == null
                            ? Theme.of(context).colorScheme.primary
                            : Colors.orangeAccent,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error ??
                              'Centralize o QR Code dentro do quadrado. A leitura acontece automaticamente.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
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

class _ScannerShade extends StatelessWidget {
  const _ScannerShade();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth.clamp(220.0, 290.0).toDouble();
        final rect = Rect.fromCenter(
          center: Offset(
            constraints.maxWidth / 2,
            constraints.maxHeight * 0.42,
          ),
          width: side,
          height: side,
        );
        return CustomPaint(
          painter: _ScannerShadePainter(
            scanRect: rect,
            borderColor: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }
}

class _ScannerShadePainter extends CustomPainter {
  const _ScannerShadePainter({
    required this.scanRect,
    required this.borderColor,
  });

  final Rect scanRect;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPath = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(22)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withValues(alpha: 0.48),
    );

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(22)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerShadePainter oldDelegate) {
    return oldDelegate.scanRect != scanRect ||
        oldDelegate.borderColor != borderColor;
  }
}
