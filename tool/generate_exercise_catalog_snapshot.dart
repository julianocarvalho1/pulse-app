import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/exercises/domain/exercise_catalog.dart';
import 'package:pulse/models/exercise.dart';

void main() {
  test('gera o snapshot da versão atual do catálogo', () {
    final outputPath =
        'test/fixtures/exercises/exercise_catalog_v${ExerciseCatalog.version}.snapshot';
    final entries = exerciseDatabase
        .map((exercise) {
          final definition = ExerciseCatalog.definitionFor(exercise);
          if (definition == null) {
            throw StateError(
              'Exercício sem definição canônica: ${exercise.id}',
            );
          }

          return <String>[
            exercise.id,
            exercise.name,
            exercise.muscle,
            definition.mediaAssetId,
          ].join('|');
        })
        .toList(growable: false);
    final content = exerciseDatabase
        .map(
          (exercise) => jsonEncode(<String, Object?>{
            ...exercise.toMap(),
            'mediaAssetId': ExerciseCatalog.definitionFor(
              exercise,
            )!.mediaAssetId,
          }),
        )
        .join('\n');
    final media = exerciseDatabase
        .map(
          (exercise) =>
              '${exercise.id}|${ExerciseCatalog.mediaPathFor(exercise)}',
        )
        .join('\n');
    final snapshot = <String>[
      'catalog_version=${ExerciseCatalog.version}',
      'exercise_count=${exerciseDatabase.length}',
      'identity_hash=${_fnv1a32(entries.join('\n'))}',
      'content_hash=${_fnv1a32(content)}',
      'media_hash=${_fnv1a32(media)}',
      '---',
      ...entries,
      '',
    ].join('\n');

    File(outputPath)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(snapshot);
    stdout.writeln('Snapshot gerado: $outputPath');
  });
}

String _fnv1a32(String value) {
  var hash = 0x811c9dc5;

  for (final byte in utf8.encode(value)) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xffffffff;
  }

  return hash.toRadixString(16).padLeft(8, '0');
}
