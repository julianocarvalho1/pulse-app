import '../../domain/models/workout_exercise_config.dart';

class LegacyWorkoutMapper {
  const LegacyWorkoutMapper._();

  static String targetForSet(String raw, int index) {
    final target = raw.trim().replaceFirst(
      RegExp(r'^\s*\d+\s*[x×]\s*', caseSensitive: false),
      '',
    );
    final parts = target.split(RegExp(r'\s*[-–]\s*'));
    if (parts.length >= 3 &&
        parts.every((part) => int.tryParse(part) != null)) {
      return parts[index.clamp(0, parts.length - 1)];
    }
    return target;
  }

  static WorkoutExerciseConfig parseExerciseConfig({
    required String reps,
    required String rest,
  }) {
    final seriesAndReps = _parseSeriesAndReps(reps);
    final restRange = _parseRestRange(rest);

    return WorkoutExerciseConfig(
      seriesCount: seriesAndReps.seriesCount,
      minimumReps: seriesAndReps.minimumReps,
      maximumReps: seriesAndReps.maximumReps,
      minimumRestSeconds: restRange.minimumSeconds,
      maximumRestSeconds: restRange.maximumSeconds,
      originalRepsText: reps,
      originalRestText: rest,
    );
  }

  static int parseRestSeconds(String rest) {
    return parseExerciseConfig(reps: '', rest: rest).recommendedRestSeconds;
  }

  static _SeriesAndReps _parseSeriesAndReps(String raw) {
    final normalized = raw.toLowerCase().replaceAll('×', 'x').trim();

    final split = normalized.split('x');

    final seriesCount = split.length > 1
        ? int.tryParse(
                RegExp(r'\d+').firstMatch(split.first)?.group(0) ?? '',
              ) ??
              3
        : 3;

    final repsPart = split.length > 1 ? split.sublist(1).join('x') : normalized;

    final values = RegExp(
      r'\d+',
    ).allMatches(repsPart).map((match) => int.parse(match.group(0)!)).toList();

    if (values.isEmpty) {
      return _SeriesAndReps(
        seriesCount: seriesCount,
        minimumReps: 10,
        maximumReps: 12,
      );
    }

    return _SeriesAndReps(
      seriesCount: seriesCount,
      minimumReps: values.reduce(
        (current, value) => value < current ? value : current,
      ),
      maximumReps: values.reduce(
        (current, value) => value > current ? value : current,
      ),
    );
  }

  static _RestRange _parseRestRange(String raw) {
    final normalized = raw.toLowerCase().trim();

    final values = RegExp(r'\d+(?:[.,]\d+)?')
        .allMatches(normalized)
        .map((match) => double.parse(match.group(0)!.replaceAll(',', '.')))
        .toList();

    if (values.isEmpty) {
      return const _RestRange(minimumSeconds: 0, maximumSeconds: 0);
    }

    final isMinutes = normalized.contains('min');

    int toSeconds(double value) {
      final seconds = isMinutes ? value * 60 : value;
      return seconds.round();
    }

    final converted = values.map(toSeconds).toList();

    final minimum = converted.reduce(
      (current, value) => value < current ? value : current,
    );

    final maximum = converted.reduce(
      (current, value) => value > current ? value : current,
    );

    return _RestRange(minimumSeconds: minimum, maximumSeconds: maximum);
  }
}

class _SeriesAndReps {
  const _SeriesAndReps({
    required this.seriesCount,
    required this.minimumReps,
    required this.maximumReps,
  });

  final int seriesCount;
  final int minimumReps;
  final int maximumReps;
}

class _RestRange {
  const _RestRange({
    required this.minimumSeconds,
    required this.maximumSeconds,
  });

  final int minimumSeconds;
  final int maximumSeconds;
}
