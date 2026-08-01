import '../../../../models/exercise.dart';
import '../../../exercises/domain/exercise_catalog.dart';

class PersonalExerciseMatch {
  const PersonalExerciseMatch({
    required this.selectedExerciseId,
    required this.suggestedExerciseIds,
    required this.needsReview,
  });

  final String? selectedExerciseId;
  final List<String> suggestedExerciseIds;
  final bool needsReview;
}

class PersonalExerciseMatcher {
  const PersonalExerciseMatcher();

  static const Map<String, String> _knownAliases = <String, String>{
    'crucifixo maquina': 'p9',
    'voador maquina': 'p9',
    'elevacao frontal com corda': 'o9',
    'pulley triceps barra': 'tr1',
    'pulley triceps barra reta': 'tr1',
    'pulley triceps testa com barra': 'tr4',
    'pulley frente com barra longa': 'c1',
    'puxador frente com barra longa': 'c1',
    'remada baixa com triangulo': 'c5',
    'rosca direta com barra w': 'b1',
    'agachamento barra guiada': 'pe2',
    'leg press 45': 'pe4',
    'stiff': 'pe10',
    'gemeos maquina': 'pe16',
    'banco soleo': 'pe17',
    'triceps frances com halter': 'tr5',
  };

  PersonalExerciseMatch match(String rawName) {
    final normalized = ExerciseCatalog.normalize(_cleanName(rawName));
    if (normalized.isEmpty) {
      return const PersonalExerciseMatch(
        selectedExerciseId: null,
        suggestedExerciseIds: <String>[],
        needsReview: true,
      );
    }

    final knownId = _knownAliases[normalized];
    if (knownId != null) {
      return PersonalExerciseMatch(
        selectedExerciseId: knownId,
        suggestedExerciseIds: <String>[knownId],
        needsReview: _isKnownAliasAmbiguous(normalized),
      );
    }

    final scored = <_ScoredExercise>[];

    for (final exercise in exerciseDatabase) {
      final candidates = <String>[
        exercise.name,
        ...ExerciseCatalog.aliasesFor(exercise),
      ];

      var bestScore = 0.0;
      for (final candidate in candidates) {
        final normalizedCandidate = ExerciseCatalog.normalize(candidate);
        if (normalizedCandidate == normalized) {
          return PersonalExerciseMatch(
            selectedExerciseId: exercise.id,
            suggestedExerciseIds: <String>[exercise.id],
            needsReview: false,
          );
        }

        final score = _similarity(normalized, normalizedCandidate);
        if (score > bestScore) {
          bestScore = score;
        }
      }

      if (bestScore >= 0.34) {
        scored.add(_ScoredExercise(exercise.id, bestScore));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    final suggestions = scored
        .take(5)
        .map((item) => item.exerciseId)
        .toList(growable: false);

    if (scored.isEmpty || scored.first.score < 0.72) {
      return PersonalExerciseMatch(
        selectedExerciseId: null,
        suggestedExerciseIds: suggestions,
        needsReview: true,
      );
    }

    final top = scored.first;
    final second = scored.length > 1 ? scored[1] : null;
    final isAmbiguous = second != null && top.score - second.score < 0.10;

    return PersonalExerciseMatch(
      selectedExerciseId: top.exerciseId,
      suggestedExerciseIds: suggestions,
      needsReview: isAmbiguous || top.score < 0.84,
    );
  }

  static String _cleanName(String rawName) {
    return rawName
        .replaceAll(RegExp(r'\([^)]*\)'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _isKnownAliasAmbiguous(String normalized) {
    return normalized == 'gemeos maquina';
  }

  static double _similarity(String left, String right) {
    if (left == right) {
      return 1;
    }
    if (left.contains(right) || right.contains(left)) {
      final shorter = left.length < right.length ? left.length : right.length;
      final longer = left.length > right.length ? left.length : right.length;
      return 0.72 + (0.20 * shorter / longer);
    }

    final leftTokens = _tokens(left);
    final rightTokens = _tokens(right);
    if (leftTokens.isEmpty || rightTokens.isEmpty) {
      return 0;
    }

    final intersection = leftTokens.intersection(rightTokens).length;
    final union = leftTokens.union(rightTokens).length;
    final jaccard = intersection / union;

    final prefixBonus = leftTokens.first == rightTokens.first ? 0.10 : 0.0;
    return (jaccard + prefixBonus).clamp(0.0, 1.0).toDouble();
  }

  static Set<String> _tokens(String value) {
    const ignored = <String>{
      'com',
      'de',
      'do',
      'da',
      'dos',
      'das',
      'na',
      'no',
      'em',
      'e',
    };

    return value
        .split(' ')
        .where((token) => token.length > 1 && !ignored.contains(token))
        .toSet();
  }
}

class _ScoredExercise {
  const _ScoredExercise(this.exerciseId, this.score);

  final String exerciseId;
  final double score;
}
