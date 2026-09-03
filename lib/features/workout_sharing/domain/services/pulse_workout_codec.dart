import 'dart:convert';
import 'dart:typed_data';

import '../../../../models/exercise.dart';
import '../../../workouts/domain/models/advanced_workout_prescription.dart';
import '../models/pulse_workout_file.dart';

class PulseWorkoutCodec {
  const PulseWorkoutCodec();

  static const int maxFileBytes = 5 * 1024 * 1024;
  static const int maxRoutines = 30;
  static const int maxExercisesPerRoutine = 100;

  PulseWorkoutDocument routineDocument(WorkoutRoutine routine) {
    return PulseWorkoutDocument(
      contentType: PulseWorkoutContentType.routine,
      createdAt: DateTime.now(),
      title: routine.name,
      routine: routine,
    );
  }

  PulseWorkoutDocument programDocument({
    required String name,
    required List<WorkoutRoutine> routines,
  }) {
    final focus = routines
        .map((routine) => routine.focus.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .take(3)
        .join(' • ');

    return PulseWorkoutDocument(
      contentType: PulseWorkoutContentType.program,
      createdAt: DateTime.now(),
      title: name,
      program: WorkoutProgram(
        id: 'shared_program_${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        focus: focus.isEmpty ? 'Programa compartilhado pelo PULSE' : focus,
        routines: routines,
        recommendedFrequency: routines.length,
      ),
    );
  }

  Uint8List encode(PulseWorkoutDocument document) {
    final json = const JsonEncoder.withIndent('  ').convert(document.toMap());
    return Uint8List.fromList(utf8.encode(json));
  }

  PulseWorkoutDocument decode(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const PulseWorkoutFileException(
        'O arquivo selecionado está vazio.',
      );
    }
    if (bytes.length > maxFileBytes) {
      throw const PulseWorkoutFileException(
        'Esse arquivo é grande demais para ser uma ficha do PULSE.',
      );
    }

    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const PulseWorkoutFileException(
        'O arquivo não está em um formato válido do PULSE.',
      );
    }

    if (decoded is! Map) {
      throw const PulseWorkoutFileException(
        'O conteúdo do arquivo do PULSE é inválido.',
      );
    }

    final map = Map<String, dynamic>.from(decoded);
    if (map['format'] != PulseWorkoutDocument.format) {
      throw const PulseWorkoutFileException(
        'Este não é um arquivo de ficha ou programa do PULSE.',
      );
    }

    final version = _readInt(map['formatVersion']);
    if (version == null || version < 1) {
      throw const PulseWorkoutFileException(
        'A versão do arquivo do PULSE é inválida.',
      );
    }
    if (version > PulseWorkoutDocument.currentVersion) {
      throw const PulseWorkoutFileException(
        'Este arquivo foi criado por uma versão mais nova do PULSE. Atualize o aplicativo para importá-lo.',
      );
    }

    final type = PulseWorkoutContentType.fromStorage(map['contentType']);
    final payload = map['payload'];
    if (payload is! Map) {
      throw const PulseWorkoutFileException(
        'A ficha compartilhada não possui dados para importar.',
      );
    }

    final createdAt =
        DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final title = map['title']?.toString().trim() ?? '';
    final payloadMap = Map<String, dynamic>.from(payload);

    if (type == PulseWorkoutContentType.routine) {
      final routine = WorkoutRoutine.fromMap(payloadMap);
      _validateRoutines(<WorkoutRoutine>[routine]);
      return PulseWorkoutDocument(
        formatVersion: version,
        contentType: type,
        createdAt: createdAt,
        title: title.isEmpty ? routine.name : title,
        routine: routine,
      );
    }

    final program = WorkoutProgram.fromMap(payloadMap);
    _validateRoutines(program.routines);
    return PulseWorkoutDocument(
      formatVersion: version,
      contentType: type,
      createdAt: createdAt,
      title: title.isEmpty ? program.name : title,
      program: program,
    );
  }

  PulseWorkoutImportPreview prepareImport({
    required PulseWorkoutDocument document,
    required List<Exercise> localExercises,
    required List<WorkoutRoutine> currentRoutines,
  }) {
    final byId = <String, Exercise>{
      for (final exercise in localExercises)
        if (exercise.id.trim().isNotEmpty) exercise.id: exercise,
    };
    final byName = <String, Exercise>{
      for (final exercise in localExercises)
        _normalize(exercise.name): exercise,
    };
    final customExercises = <Exercise>[];
    var unmatchedCount = 0;
    var customIndex = 0;
    final stamp = DateTime.now().microsecondsSinceEpoch;

    final resolvedRoutines = document.routines
        .map((routine) {
          final resolvedExercises = routine.exercises
              .map((incoming) {
                final local =
                    byId[incoming.id] ?? byName[_normalize(incoming.name)];
                final resolvedAdvanced = _resolveAdvancedPrescription(
                  incoming.advancedPrescription,
                  byId: byId,
                  byName: byName,
                );
                if (local != null) {
                  return local.copyWith(
                    reps: incoming.reps,
                    rest: incoming.rest,
                    isSuperset: incoming.isSuperset,
                    customNote: incoming.customNote,
                    advancedPrescription: resolvedAdvanced,
                  );
                }

                unmatchedCount++;
                final custom = incoming.copyWith(
                  id: 'custom_shared_${stamp}_${customIndex++}',
                  description: incoming.description.trim().isEmpty
                      ? 'Exercício recebido em um arquivo do PULSE.'
                      : incoming.description,
                  advancedPrescription: resolvedAdvanced,
                );
                customExercises.add(custom);
                return custom;
              })
              .toList(growable: false);

          return routine.copyWith(exercises: resolvedExercises);
        })
        .toList(growable: false);

    final baseName = document.title.trim().isEmpty
        ? document.contentType.label
        : document.title.trim();
    final suggestedName = _uniqueName(
      baseName,
      document.contentType,
      currentRoutines,
    );
    final duplicate = _containsExactDuplicate(
      document.contentType,
      resolvedRoutines,
      currentRoutines,
    );

    return PulseWorkoutImportPreview(
      document: document,
      resolvedRoutines: resolvedRoutines,
      customExercises: customExercises,
      suggestedName: suggestedName,
      unmatchedExerciseCount: unmatchedCount,
      isExactDuplicate: duplicate,
    );
  }

  void _validateRoutines(List<WorkoutRoutine> routines) {
    if (routines.isEmpty) {
      throw const PulseWorkoutFileException(
        'O arquivo não contém nenhuma ficha de treino.',
      );
    }
    if (routines.length > maxRoutines) {
      throw const PulseWorkoutFileException(
        'O arquivo contém fichas demais para uma única importação.',
      );
    }

    for (final routine in routines) {
      if (routine.name.trim().isEmpty) {
        throw const PulseWorkoutFileException('Uma das fichas está sem nome.');
      }
      if (routine.exercises.length > maxExercisesPerRoutine) {
        throw const PulseWorkoutFileException(
          'Uma das fichas contém exercícios demais.',
        );
      }
      if (routine.exercises.isEmpty && routine.cardio.isEmpty) {
        throw const PulseWorkoutFileException(
          'Uma das fichas não possui exercícios nem cardio.',
        );
      }
    }
  }

  String _uniqueName(
    String baseName,
    PulseWorkoutContentType type,
    List<WorkoutRoutine> current,
  ) {
    final usedNames = type == PulseWorkoutContentType.program
        ? current
              .map((routine) => routine.groupName.trim())
              .where((name) => name.isNotEmpty)
              .map(_normalize)
              .toSet()
        : current.map((routine) => _normalize(routine.name)).toSet();

    if (!usedNames.contains(_normalize(baseName))) {
      return baseName;
    }

    var suffix = 2;
    while (usedNames.contains(_normalize('$baseName ($suffix)'))) {
      suffix++;
    }
    return '$baseName ($suffix)';
  }

  bool _containsExactDuplicate(
    PulseWorkoutContentType type,
    List<WorkoutRoutine> incoming,
    List<WorkoutRoutine> current,
  ) {
    if (type == PulseWorkoutContentType.routine) {
      final signature = _routineSignature(incoming.single);
      return current.any((routine) => _routineSignature(routine) == signature);
    }

    final incomingSignatures = incoming.map(_routineSignature).toList()..sort();
    final groupNames = current
        .map((routine) => routine.groupName)
        .where((name) => name.trim().isNotEmpty)
        .toSet();
    for (final group in groupNames) {
      final signatures =
          current
              .where((routine) => routine.groupName == group)
              .map(_routineSignature)
              .toList()
            ..sort();
      if (_listEquals(incomingSignatures, signatures)) {
        return true;
      }
    }
    return false;
  }

  String _routineSignature(WorkoutRoutine routine) {
    final exercises = routine.exercises
        .map((exercise) {
          return <String>[
            _normalize(exercise.name),
            _normalize(exercise.muscle),
            _normalize(exercise.reps),
            _normalize(exercise.rest),
            exercise.isSuperset ? '1' : '0',
            _normalize(exercise.customNote),
            _advancedPrescriptionSignature(exercise.advancedPrescription),
          ].join('|');
        })
        .join('||');
    final cardio = routine.cardio
        .map((entry) {
          return '${entry.modality.storageValue}|${entry.plannedDurationMinutes}|${jsonEncode(entry.plan.toMap())}|${_normalize(entry.notes)}';
        })
        .join('||');

    // Nome, grupo, ids e datas são dados mutáveis. A assinatura representa
    // somente o conteúdo prescrito, para que uma ficha renomeada continue
    // sendo reconhecida ao tentar importar o mesmo arquivo novamente.
    return '$exercises###$cardio';
  }

  AdvancedExercisePrescription _resolveAdvancedPrescription(
    AdvancedExercisePrescription incoming, {
    required Map<String, Exercise> byId,
    required Map<String, Exercise> byName,
  }) {
    if (incoming.isEmpty) {
      return incoming;
    }

    return incoming.copyWith(
      alternatives: <ExerciseAlternative>[
        for (final alternative in incoming.alternatives)
          () {
            final local =
                byId[alternative.exerciseId] ??
                byName[_normalize(alternative.name)];
            if (local == null) {
              return alternative;
            }
            return ExerciseAlternative(
              exerciseId: local.id,
              name: local.name,
              muscle: local.muscle,
            );
          }(),
      ],
    );
  }

  String _advancedPrescriptionSignature(
    AdvancedExercisePrescription prescription,
  ) {
    if (prescription.isEmpty) {
      return '';
    }
    final weeks = prescription.weeks
        .map((week) {
          final sets = week.sets
              .map((set) {
                return <String>[
                  '${set.setNumber}',
                  set.kind.storageValue,
                  _normalize(set.target),
                  '${set.restSeconds ?? ''}',
                  '${set.targetRir ?? ''}',
                  _normalize(set.cadence),
                  set.technique.storageValue,
                  _normalize(set.notes),
                ].join('~');
              })
              .join('^');
          return '${week.weekNumber}:${_normalize(week.label)}:$sets:${_normalize(week.notes)}';
        })
        .join('||');
    final alternatives =
        prescription.alternatives
            .map(
              (alternative) =>
                  '${_normalize(alternative.name)}:${_normalize(alternative.muscle)}',
            )
            .toList()
          ..sort();
    return '${prescription.activeWeek}##$weeks##${alternatives.join('|')}';
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }

  String _normalize(String value) {
    const source = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const target = 'aaaaaeeeeiiiiooooouuuuc';
    var normalized = value.trim().toLowerCase();
    for (var index = 0; index < source.length; index++) {
      normalized = normalized.replaceAll(source[index], target[index]);
    }
    return normalized.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
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
}
