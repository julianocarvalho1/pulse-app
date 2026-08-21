import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../../domain/models/personal_workout_import.dart';

class DocxPersonalWorkoutReader {
  const DocxPersonalWorkoutReader();

  Future<List<PersonalImportDocumentBlock>> readFile(String path) async {
    final bytes = await File(path).readAsBytes();
    return readBytes(bytes);
  }

  List<PersonalImportDocumentBlock> readBytes(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    final documentFile = archive.findFile('word/document.xml');

    if (documentFile == null) {
      throw const FormatException(
        'O arquivo DOCX não possui o conteúdo principal esperado.',
      );
    }

    final xmlBytes = documentFile.readBytes();
    if (xmlBytes == null) {
      throw const FormatException(
        'O arquivo DOCX possui o conteúdo principal vazio ou ilegível.',
      );
    }

    final document = XmlDocument.parse(utf8.decode(xmlBytes));
    final body = document.descendants.whereType<XmlElement>().firstWhere(
      (element) => element.name.local == 'body',
      orElse: () => throw const FormatException(
        'O documento não possui uma seção de conteúdo reconhecível.',
      ),
    );

    final blocks = <PersonalImportDocumentBlock>[];

    for (final child in body.childElements) {
      switch (child.name.local) {
        case 'p':
          final text = _paragraphText(child);
          if (text.isNotEmpty) {
            blocks.add(PersonalImportParagraph(text));
          }
        case 'tbl':
          final rows = _tableRows(child);
          if (rows.isNotEmpty) {
            blocks.add(PersonalImportTable(rows));
          }
      }
    }

    return blocks;
  }

  static List<List<String>> _tableRows(XmlElement table) {
    final rows = <List<String>>[];

    for (final row in table.childElements.where(
      (element) => element.name.local == 'tr',
    )) {
      final cells = <String>[];

      for (final cell in row.childElements.where(
        (element) => element.name.local == 'tc',
      )) {
        final paragraphs = cell.descendants
            .whereType<XmlElement>()
            .where((element) => element.name.local == 'p')
            .map(_paragraphText)
            .where((text) => text.isNotEmpty)
            .toList(growable: false);
        cells.add(paragraphs.join('\n'));
      }

      if (cells.any((cell) => cell.trim().isNotEmpty)) {
        rows.add(cells);
      }
    }

    return rows;
  }

  static String _paragraphText(XmlElement paragraph) {
    return paragraph.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local == 't')
        .map((element) => element.innerText)
        .join()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
