import 'dart:convert';
import 'dart:io';

class PlainTextPersonalWorkoutReader {
  const PlainTextPersonalWorkoutReader();

  Future<String> readFile(String path) async {
    final bytes = await File(path).readAsBytes();
    if (bytes.isEmpty) {
      throw const FormatException('O arquivo de texto está vazio.');
    }

    try {
      return utf8.decode(bytes);
    } on FormatException {
      return latin1.decode(bytes);
    }
  }
}
