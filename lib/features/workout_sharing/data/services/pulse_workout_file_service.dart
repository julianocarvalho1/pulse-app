import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/models/pulse_workout_file.dart';
import '../../domain/services/pulse_workout_codec.dart';

class PulseWorkoutFileService {
  const PulseWorkoutFileService({this.codec = const PulseWorkoutCodec()});

  final PulseWorkoutCodec codec;

  Future<Uint8List?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Selecionar arquivo do PULSE',
      type: FileType.custom,
      allowedExtensions: const <String>['pulse'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    if (file.bytes != null) {
      return file.bytes!;
    }
    if (file.path == null) {
      throw const PulseWorkoutFileException(
        'Não foi possível ler o arquivo selecionado.',
      );
    }
    return File(file.path!).readAsBytes();
  }

  Future<bool> saveDocument(PulseWorkoutDocument document) async {
    final bytes = codec.encode(document);
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Salvar arquivo do PULSE',
      fileName: fileNameFor(document),
      type: FileType.custom,
      allowedExtensions: const <String>['pulse'],
      bytes: bytes,
    );
    return path != null;
  }

  Future<void> shareDocument(PulseWorkoutDocument document) async {
    final bytes = codec.encode(document);
    final fileName = fileNameFor(document);

    await SharePlus.instance.share(
      ShareParams(
        title: 'Compartilhar pelo PULSE',
        subject: document.title,
        text:
            '${document.contentType.label} “${document.title}” criada no PULSE.',
        files: <XFile>[
          XFile.fromData(bytes, mimeType: 'application/vnd.pulse.workout+json'),
        ],
        fileNameOverrides: <String>[fileName],
      ),
    );
  }

  String fileNameFor(PulseWorkoutDocument document) {
    final safeTitle = document.title
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9À-ÿ]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final fallback = document.contentType == PulseWorkoutContentType.program
        ? 'programa'
        : 'ficha';
    return 'PULSE_${safeTitle.isEmpty ? fallback : safeTitle}.pulse';
  }
}
