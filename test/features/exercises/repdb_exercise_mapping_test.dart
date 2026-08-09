import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/exercises/domain/exercise_catalog.dart';
import 'package:pulse/features/exercises/domain/repdb_exercise_mapping.dart';
import 'package:pulse/models/exercise.dart';

void main() {
  group('RepDbExerciseMapping', () {
    test('classifica todos os 75 exercícios legados uma única vez', () {
      final legacyIds = exerciseDatabase.map((exercise) => exercise.id).toSet();
      final mappedIds = RepDbExerciseMapping.legacyMatches.keys.toSet();
      final statusCounts = <RepDbMatchStatus, int>{};

      for (final match in RepDbExerciseMapping.legacyMatches.values) {
        statusCounts.update(
          match.status,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }

      expect(mappedIds, legacyIds);
      expect(statusCounts, <RepDbMatchStatus, int>{
        RepDbMatchStatus.exact: 57,
        RepDbMatchStatus.reviewRequired: 14,
        RepDbMatchStatus.unavailable: 4,
      });
    });

    test('aprova somente correspondências com fonte e execução definidas', () {
      final approved = RepDbExerciseMapping.legacyMatches.values
          .where((match) => match.isApproved)
          .toList(growable: false);
      final approvedSourceIds = approved.map((match) => match.repDbId).toSet();

      expect(approvedSourceIds, hasLength(approved.length));
      expect(
        approved.every(
          (match) =>
              match.repDbId?.isNotEmpty == true &&
              match.sourceName?.isNotEmpty == true &&
              match.reviewNote.isEmpty,
        ),
        isTrue,
      );
    });

    test('mantém casos duvidosos bloqueados e documentados', () {
      final pending = RepDbExerciseMapping.legacyMatches.values.where(
        (match) => !match.isApproved,
      );

      expect(pending.every((match) => match.reviewNote.isNotEmpty), isTrue);
      expect(
        pending
            .where((match) => match.status == RepDbMatchStatus.unavailable)
            .every(
              (match) => match.repDbId == null && match.sourceName == null,
            ),
        isTrue,
      );
    });

    test('nomes oficiais aprovados também funcionam como aliases', () {
      for (final exercise in exerciseDatabase) {
        final match = RepDbExerciseMapping.matchFor(exercise.id)!;
        if (!match.isApproved) {
          expect(match.approvedAliases, isEmpty);
          continue;
        }

        expect(
          ExerciseCatalog.aliasesFor(exercise),
          contains(match.sourceName),
        );
        expect(ExerciseCatalog.matches(exercise, match.sourceName!), isTrue);
        expect(
          ExerciseCatalog.canonicalIdFor('', exerciseName: match.sourceName!),
          exercise.id,
        );
      }
    });

    test('fornece 56 pares de poses e uma imagem estática oficiais', () {
      final approvedMedia = RepDbExerciseMapping.legacyMatches.entries
          .where((entry) => entry.value.isApproved)
          .map((entry) => RepDbExerciseMapping.approvedMediaFor(entry.key)!)
          .toList(growable: false);
      final paired = approvedMedia.where((media) => media.hasPosePair);
      final single = approvedMedia.where((media) => !media.hasPosePair);
      final assetPaths = <String>[
        for (final media in approvedMedia) ...<String>[
          if (media.startAssetPath != null) media.startAssetPath!,
          if (media.peakAssetPath != null) media.peakAssetPath!,
          if (media.mainAssetPath != null) media.mainAssetPath!,
        ],
      ];

      expect(approvedMedia, hasLength(57));
      expect(paired, hasLength(56));
      expect(single, hasLength(1));
      expect(assetPaths, hasLength(113));
      expect(assetPaths.every((path) => File(path).existsSync()), isTrue);
      expect(assetPaths.every((path) => path.endsWith('.webp')), isTrue);
    });

    test('planeja 26 adições úteis sem reutilizar mídias já mapeadas', () {
      final additions = RepDbExerciseMapping.plannedAdditions;
      final sourceIds = additions.map((item) => item.repDbId).toSet();
      final names = additions.map((item) => item.namePtBr).toSet();
      final mappedSourceIds = RepDbExerciseMapping.legacyMatches.values
          .map((match) => match.repDbId)
          .whereType<String>()
          .toSet();
      const supportedMuscles = <String>{
        'Abdômen',
        'Antebraço',
        'Bíceps',
        'Costas',
        'Ombros',
        'Panturrilha',
        'Peito',
        'Pernas',
        'Trapézio',
        'Tríceps',
      };

      expect(additions, hasLength(26));
      expect(sourceIds, hasLength(additions.length));
      expect(names, hasLength(additions.length));
      expect(sourceIds.intersection(mappedSourceIds), isEmpty);
      expect(
        additions.every(
          (item) =>
              item.namePtBr.isNotEmpty &&
              supportedMuscles.contains(item.primaryMuscle) &&
              item.aliases.isNotEmpty,
        ),
        isTrue,
      );
    });

    test('mantém a atribuição gratuita em um único contrato', () {
      expect(RepDbExerciseMapping.version, 1);
      expect(
        RepDbExerciseMapping.attributionText,
        'Exercise data by RepDB (repdb.co)',
      );
      expect(RepDbExerciseMapping.attributionUrl, 'https://repdb.co');
    });
  });
}
