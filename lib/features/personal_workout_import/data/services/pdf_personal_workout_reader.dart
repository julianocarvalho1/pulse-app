import 'dart:io';

import 'package:flutter/services.dart';

class PdfPersonalWorkoutReader {
  const PdfPersonalWorkoutReader();

  static const MethodChannel _channel = MethodChannel('pulse/pdf_text');

  Future<String> readFile(String path) async {
    if (!Platform.isAndroid) {
      throw const FormatException(
        'A importação de PDF está disponível no Android nesta versão.',
      );
    }

    final extracted = await _channel.invokeMethod<String>(
      'extractText',
      <String, Object?>{'path': path},
    );
    return normalizeAndValidateExtractedText(extracted);
  }

  static String normalizeAndValidateExtractedText(String? extracted) {
    final normalized = (extracted ?? '')
        .replaceAll('\u0000', ' ')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    if (normalized.length < 20) {
      throw const FormatException(
        'Não foi possível extrair o texto deste PDF. Ele pode ser uma digitalização, usar fontes incorporadas incompatíveis ou ter o conteúdo convertido em imagem. Tente enviar o DOCX original, copiar e colar o texto, exportar novamente pelo Word ou salvar como TXT/CSV. A leitura por OCR ficará para uma próxima versão.',
      );
    }

    return normalized;
  }
}
