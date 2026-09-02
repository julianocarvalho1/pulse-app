import 'dart:convert';
import 'dart:io';

import '../../../../models/exercise.dart';
import '../../../workouts/domain/models/advanced_workout_prescription.dart';
import '../../../workouts/domain/models/cardio_log.dart';
import '../models/pulse_workout_file.dart';

class PulseWorkoutQrCodec {
  const PulseWorkoutQrCodec();

  static const int currentVersion = 2;
  static const int maxQrCharacters = 2200;
  static const int maxDecodedBytes = 512 * 1024;
  static const String _prefixRoot = 'PULSEQR';

  String encode(PulseWorkoutDocument document) {
    final compactJson = jsonEncode(_documentToCompactMap(document));
    final compressed = ZLibEncoder(level: 9).convert(utf8.encode(compactJson));
    final payload = base64UrlEncode(compressed).replaceAll('=', '');
    final encoded = '$_prefixRoot$currentVersion:$payload';

    if (encoded.length > maxQrCharacters) {
      throw const PulseWorkoutFileException(
        'Esse conteúdo é grande demais para um único QR Code. Compartilhe pelo arquivo .pulse.',
      );
    }
    return encoded;
  }

  PulseWorkoutDocument decode(String rawValue) {
    final value = rawValue.trim();
    final match = RegExp(r'^PULSEQR(\d+):(.+)$').firstMatch(value);
    if (match == null) {
      throw const PulseWorkoutFileException(
        'Este QR Code não contém uma ficha ou programa do PULSE.',
      );
    }

    final version = int.tryParse(match.group(1) ?? '');
    if (version == null || version < 1) {
      throw const PulseWorkoutFileException(
        'A versão do QR Code do PULSE é inválida.',
      );
    }
    if (version > currentVersion) {
      throw const PulseWorkoutFileException(
        'Este QR Code foi criado por uma versão mais nova do PULSE. Atualize o aplicativo para importá-lo.',
      );
    }

    final payload = match.group(2) ?? '';
    try {
      final padded = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');
      final compressed = base64Url.decode(padded);
      final decodedBytes = ZLibDecoder().convert(compressed);
      if (decodedBytes.length > maxDecodedBytes) {
        throw const PulseWorkoutFileException(
          'O conteúdo deste QR Code é grande demais para ser importado.',
        );
      }

      final decoded = jsonDecode(utf8.decode(decodedBytes));
      if (decoded is! Map) {
        throw const PulseWorkoutFileException(
          'O QR Code do PULSE possui conteúdo inválido.',
        );
      }
      return _documentFromCompactMap(Map<String, dynamic>.from(decoded));
    } on PulseWorkoutFileException {
      rethrow;
    } on Object {
      throw const PulseWorkoutFileException(
        'Não foi possível ler este QR Code do PULSE.',
      );
    }
  }

  Map<String, dynamic> _documentToCompactMap(PulseWorkoutDocument document) {
    return <String, dynamic>{
      'v': currentVersion,
      't': document.contentType == PulseWorkoutContentType.routine ? 'r' : 'p',
      'n': document.title,
      'c': document.createdAt.toUtc().millisecondsSinceEpoch,
      'd': document.contentType == PulseWorkoutContentType.routine
          ? _routineToCompactMap(document.routine!)
          : _programToCompactMap(document.program!),
    };
  }

  Map<String, dynamic> _programToCompactMap(WorkoutProgram program) {
    return <String, dynamic>{
      'n': program.name,
      if (program.focus.trim().isNotEmpty) 'f': program.focus,
      if (program.level.trim().isNotEmpty) 'l': program.level,
      if (program.objective.trim().isNotEmpty) 'o': program.objective,
      if (program.recommendedFrequency > 0) 'q': program.recommendedFrequency,
      if (program.estimatedDuration.trim().isNotEmpty)
        'd': program.estimatedDuration,
      'r': program.routines.map(_routineToCompactMap).toList(growable: false),
    };
  }

  Map<String, dynamic> _routineToCompactMap(WorkoutRoutine routine) {
    return <String, dynamic>{
      'n': routine.name,
      if (routine.focus.trim().isNotEmpty) 'f': routine.focus,
      if (routine.groupName.trim().isNotEmpty) 'g': routine.groupName,
      'e': routine.exercises.map(_exerciseToCompactMap).toList(growable: false),
      if (routine.cardio.isNotEmpty)
        'c': routine.cardio.map(_cardioToCompactMap).toList(growable: false),
    };
  }

  Map<String, dynamic> _exerciseToCompactMap(Exercise exercise) {
    final includeDescription = _isCustomExerciseId(exercise.id);
    return <String, dynamic>{
      if (exercise.id.trim().isNotEmpty) 'i': exercise.id,
      'n': exercise.name,
      if (exercise.muscle.trim().isNotEmpty) 'm': exercise.muscle,
      if (includeDescription && exercise.description.trim().isNotEmpty)
        'd': exercise.description,
      'r': exercise.reps,
      's': exercise.rest,
      if (exercise.isSuperset) 'u': 1,
      if (exercise.customNote.trim().isNotEmpty) 'o': exercise.customNote,
      if (!exercise.advancedPrescription.isEmpty)
        'a': exercise.advancedPrescription.toMap(),
    };
  }

  Map<String, dynamic> _cardioToCompactMap(RoutineCardio cardio) {
    return <String, dynamic>{
      'm': cardio.modality.index,
      'd': cardio.plannedDurationMinutes,
      'p': _cardioPlanToCompactMap(cardio.plan),
      if (cardio.notes.trim().isNotEmpty) 'n': cardio.notes,
    };
  }

  Map<String, dynamic> _cardioPlanToCompactMap(CardioPlan plan) {
    final intervals = plan.intervals;
    return <String, dynamic>{
      'u': plan.purpose.index,
      'f': plan.format.index,
      'i': plan.intensity.index,
      if (plan.plannedDistanceKm != null) 'd': plan.plannedDistanceKm,
      if (plan.plannedSpeedKmh != null) 's': plan.plannedSpeedKmh,
      if (plan.plannedInclinePercent != null) 'n': plan.plannedInclinePercent,
      if (plan.plannedResistanceLevel != null) 'r': plan.plannedResistanceLevel,
      if (intervals != null)
        'x': <int>[
          intervals.warmUpMinutes,
          intervals.effortSeconds,
          intervals.recoverySeconds,
          intervals.cycles,
          intervals.coolDownMinutes,
        ],
    };
  }

  PulseWorkoutDocument _documentFromCompactMap(Map<String, dynamic> map) {
    final mapVersion = _readInt(map['v']);
    if (mapVersion == null || mapVersion < 1) {
      throw const PulseWorkoutFileException(
        'A versão interna do QR Code do PULSE é inválida.',
      );
    }
    if (mapVersion > currentVersion) {
      throw const PulseWorkoutFileException(
        'Este QR Code foi criado por uma versão mais nova do PULSE. Atualize o aplicativo para importá-lo.',
      );
    }

    final typeValue = map['t']?.toString();
    final contentType = switch (typeValue) {
      'r' => PulseWorkoutContentType.routine,
      'p' => PulseWorkoutContentType.program,
      _ => throw const PulseWorkoutFileException(
        'O QR Code não informa se contém uma ficha ou um programa.',
      ),
    };
    final title = map['n']?.toString().trim() ?? '';
    final createdAtMillis = _readInt(map['c']) ?? 0;
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      createdAtMillis,
      isUtc: true,
    );
    final rawData = map['d'];
    if (rawData is! Map) {
      throw const PulseWorkoutFileException(
        'O QR Code do PULSE não contém dados para importar.',
      );
    }
    final data = Map<String, dynamic>.from(rawData);

    if (contentType == PulseWorkoutContentType.routine) {
      final routine = _routineFromCompactMap(data, 0);
      _validateRoutines(<WorkoutRoutine>[routine]);
      return PulseWorkoutDocument(
        formatVersion: mapVersion,
        contentType: contentType,
        createdAt: createdAt,
        title: title.isEmpty ? routine.name : title,
        routine: routine,
      );
    }

    final program = _programFromCompactMap(data);
    _validateRoutines(program.routines);
    return PulseWorkoutDocument(
      formatVersion: mapVersion,
      contentType: contentType,
      createdAt: createdAt,
      title: title.isEmpty ? program.name : title,
      program: program,
    );
  }

  WorkoutProgram _programFromCompactMap(Map<String, dynamic> map) {
    final rawRoutines = map['r'];
    if (rawRoutines is! List) {
      throw const PulseWorkoutFileException(
        'O programa recebido não possui fichas válidas.',
      );
    }
    final name = map['n']?.toString().trim() ?? '';
    return WorkoutProgram(
      id: 'qr_program_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      focus: map['f']?.toString() ?? '',
      level: map['l']?.toString() ?? '',
      objective: map['o']?.toString() ?? '',
      recommendedFrequency: _readInt(map['q']) ?? 0,
      estimatedDuration: map['d']?.toString() ?? '',
      routines: <WorkoutRoutine>[
        for (var index = 0; index < rawRoutines.length; index++)
          if (rawRoutines[index] is Map)
            _routineFromCompactMap(
              Map<String, dynamic>.from(rawRoutines[index] as Map),
              index,
            ),
      ],
    );
  }

  WorkoutRoutine _routineFromCompactMap(
    Map<String, dynamic> map,
    int routineIndex,
  ) {
    final rawExercises = map['e'];
    final rawCardio = map['c'];
    return WorkoutRoutine(
      id: 'qr_routine_${DateTime.now().microsecondsSinceEpoch}_$routineIndex',
      name: map['n']?.toString() ?? '',
      focus: map['f']?.toString() ?? '',
      groupName: map['g']?.toString() ?? '',
      exercises: rawExercises is List
          ? <Exercise>[
              for (var index = 0; index < rawExercises.length; index++)
                if (rawExercises[index] is Map)
                  _exerciseFromCompactMap(
                    Map<String, dynamic>.from(rawExercises[index] as Map),
                  ),
            ]
          : const <Exercise>[],
      cardio: rawCardio is List
          ? <RoutineCardio>[
              for (var index = 0; index < rawCardio.length; index++)
                if (rawCardio[index] is Map)
                  _cardioFromCompactMap(
                    Map<String, dynamic>.from(rawCardio[index] as Map),
                    routineIndex,
                    index,
                  ),
            ]
          : const <RoutineCardio>[],
    );
  }

  Exercise _exerciseFromCompactMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['i']?.toString() ?? '',
      name: map['n']?.toString() ?? '',
      muscle: map['m']?.toString() ?? '',
      description: map['d']?.toString() ?? '',
      reps: map['r']?.toString() ?? '3x 10-12',
      rest: map['s']?.toString() ?? '60 seg',
      isSuperset: _readInt(map['u']) == 1,
      customNote: map['o']?.toString() ?? '',
      advancedPrescription: map['a'] is Map
          ? AdvancedExercisePrescription.fromMap(
              Map<String, dynamic>.from(map['a'] as Map),
            )
          : const AdvancedExercisePrescription(),
    );
  }

  RoutineCardio _cardioFromCompactMap(
    Map<String, dynamic> map,
    int routineIndex,
    int cardioIndex,
  ) {
    final modalityIndex = _readInt(map['m']);
    final modality =
        modalityIndex != null &&
            modalityIndex >= 0 &&
            modalityIndex < CardioModality.values.length
        ? CardioModality.values[modalityIndex]
        : CardioModality.other;
    return RoutineCardio(
      id: 'qr_cardio_${routineIndex}_$cardioIndex',
      modality: modality,
      plannedDurationMinutes: _readInt(map['d']) ?? 0,
      plan: map['p'] is Map
          ? _cardioPlanFromCompactMap(
              Map<String, dynamic>.from(map['p'] as Map),
            )
          : const CardioPlan(),
      notes: map['n']?.toString() ?? '',
    );
  }

  CardioPlan _cardioPlanFromCompactMap(Map<String, dynamic> map) {
    final purposeIndex = _readInt(map['u']);
    final formatIndex = _readInt(map['f']);
    final intensityIndex = _readInt(map['i']);
    final rawIntervals = map['x'];
    final intervalValues = rawIntervals is List
        ? rawIntervals.map(_readInt).toList(growable: false)
        : const <int?>[];

    return CardioPlan(
      purpose:
          purposeIndex != null &&
              purposeIndex >= 0 &&
              purposeIndex < CardioPurpose.values.length
          ? CardioPurpose.values[purposeIndex]
          : CardioPurpose.postWorkout,
      format:
          formatIndex != null &&
              formatIndex >= 0 &&
              formatIndex < CardioFormat.values.length
          ? CardioFormat.values[formatIndex]
          : CardioFormat.continuous,
      intensity:
          intensityIndex != null &&
              intensityIndex >= 0 &&
              intensityIndex < CardioIntensity.values.length
          ? CardioIntensity.values[intensityIndex]
          : CardioIntensity.selfSelected,
      plannedDistanceKm: _readDouble(map['d']),
      plannedSpeedKmh: _readDouble(map['s']),
      plannedInclinePercent: _readDouble(map['n']),
      plannedResistanceLevel: _readDouble(map['r']),
      intervals:
          intervalValues.length == 5 &&
              intervalValues.every((value) => value != null)
          ? CardioIntervalPlan(
              warmUpMinutes: intervalValues[0]!,
              effortSeconds: intervalValues[1]!,
              recoverySeconds: intervalValues[2]!,
              cycles: intervalValues[3]!,
              coolDownMinutes: intervalValues[4]!,
            )
          : null,
    );
  }

  void _validateRoutines(List<WorkoutRoutine> routines) {
    if (routines.isEmpty) {
      throw const PulseWorkoutFileException(
        'O QR Code não contém nenhuma ficha de treino.',
      );
    }
    if (routines.length > 30) {
      throw const PulseWorkoutFileException(
        'O QR Code contém fichas demais para uma única importação.',
      );
    }
    for (final routine in routines) {
      if (routine.name.trim().isEmpty) {
        throw const PulseWorkoutFileException(
          'Uma das fichas recebidas está sem nome.',
        );
      }
      if (routine.exercises.length > 100) {
        throw const PulseWorkoutFileException(
          'Uma das fichas recebidas contém exercícios demais.',
        );
      }
      if (routine.exercises.isEmpty && routine.cardio.isEmpty) {
        throw const PulseWorkoutFileException(
          'Uma das fichas recebidas não possui exercícios nem cardio.',
        );
      }
      if (routine.exercises.any((exercise) => exercise.name.trim().isEmpty)) {
        throw const PulseWorkoutFileException(
          'Um dos exercícios recebidos está sem nome.',
        );
      }
    }
  }

  bool _isCustomExerciseId(String id) {
    final normalized = id.trim().toLowerCase();
    return normalized.isEmpty ||
        normalized.startsWith('custom') ||
        normalized.startsWith('shared') ||
        normalized.startsWith('external') ||
        normalized.startsWith('personal');
  }

  int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  double? _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '');
  }
}
