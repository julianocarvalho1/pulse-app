import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/exercises/domain/exercise_catalog.dart';
import 'package:pulse/features/exercises/domain/repdb_exercise_mapping.dart';
import 'package:pulse/models/exercise.dart';

void main() {
  group('RepDbExerciseMapping', () {
    test('classifica todos os 75 exercícios legados uma única vez', () {
      final catalogIds = exerciseDatabase
          .map((exercise) => exercise.id)
          .toSet();
      final mappedIds = RepDbExerciseMapping.legacyMatches.keys.toSet();
      final statusCounts = <RepDbMatchStatus, int>{};

      for (final match in RepDbExerciseMapping.legacyMatches.values) {
        statusCounts.update(
          match.status,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }

      expect(mappedIds, hasLength(75));
      expect(catalogIds, containsAll(mappedIds));
      expect(statusCounts, <RepDbMatchStatus, int>{RepDbMatchStatus.exact: 75});
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

    test('não deixa correspondências legadas pendentes para o lançamento', () {
      expect(
        RepDbExerciseMapping.legacyMatches.values.every(
          (match) => match.isApproved && match.reviewNote.isEmpty,
        ),
        isTrue,
      );
    });

    test('nomes oficiais aprovados também funcionam como aliases', () {
      for (final exercise in exerciseDatabase) {
        final match = RepDbExerciseMapping.matchFor(exercise.id)!;

        expect(match.isApproved, isTrue);
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

    test('fornece mídia oficial para os 104 exercícios do catálogo', () {
      final approvedMedia = exerciseDatabase
          .map(
            (exercise) => RepDbExerciseMapping.approvedMediaFor(exercise.id)!,
          )
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

      expect(approvedMedia, hasLength(104));
      expect(paired, hasLength(102));
      expect(single, hasLength(2));
      expect(assetPaths, hasLength(206));
      expect(assetPaths.toSet(), hasLength(assetPaths.length));
      expect(assetPaths.every((path) => File(path).existsSync()), isTrue);
      expect(assetPaths.every((path) => path.endsWith('.webp')), isTrue);

      final manifest = File(
        'third_party/repdb/ASSET-MANIFEST.sha256',
      ).readAsStringSync();
      expect(assetPaths.every(manifest.contains), isTrue);
    });

    test('inclui 29 adições úteis sem reutilizar mídias já mapeadas', () {
      final additions = RepDbExerciseMapping.catalogAdditions;
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

      expect(additions, hasLength(29));
      expect(
        additions.every(
          (item) =>
              exerciseDatabase.any((exercise) => exercise.id == item.pulseId),
        ),
        isTrue,
      );
      expect(sourceIds, hasLength(additions.length));
      expect(names, hasLength(additions.length));
      expect(sourceIds.intersection(mappedSourceIds), isEmpty);
      expect(
        additions.every(
          (item) =>
              item.namePtBr.isNotEmpty &&
              item.sourceName.isNotEmpty &&
              supportedMuscles.contains(item.primaryMuscle) &&
              item.aliases.isNotEmpty,
        ),
        isTrue,
      );
    });

    test('mantém a atribuição gratuita em um único contrato', () {
      expect(RepDbExerciseMapping.version, 3);
      expect(
        RepDbExerciseMapping.attributionText,
        'Exercise data by RepDB (repdb.co)',
      );
      expect(RepDbExerciseMapping.attributionUrl, 'https://repdb.co');
    });

    test('preserva os nomes substituídos como aliases de compatibilidade', () {
      const oldNamesById = <String, String>{
        'p5': 'Supino Inclinado Articulado',
        'p11': 'Crossover na Polia Baixa',
        'c5': 'Remada Baixa Sentada',
        'c6': 'Remada Articulada',
        'c10': 'Voador Inverso na Máquina',
        'b2': 'Rosca Alternada com Halteres',
        'b8': 'Flexão de Punho',
        'tr1': 'Tríceps na Polia com Barra Reta',
        'tr2': 'Tríceps na Polia com Corda',
        'tr4': 'Tríceps Testa na Polia',
        'tr6': 'Tríceps Francês na Polia',
        'pe9': 'Flexora Unilateral em Pé',
        'pe15': 'Afundo ou Passada',
        'pe18': 'Panturrilha no Leg Press',
        'pe19': 'Stiff com Halteres',
        'ab3': 'Abdominal na Máquina',
      };

      for (final entry in oldNamesById.entries) {
        final exercise = exerciseDatabase.firstWhere(
          (item) => item.id == entry.key,
        );
        expect(ExerciseCatalog.aliasesFor(exercise), contains(entry.value));
        expect(
          ExerciseCatalog.canonicalIdFor('', exerciseName: entry.value),
          entry.key,
        );
      }
    });
  });
}
