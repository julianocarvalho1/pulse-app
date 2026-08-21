import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../../models/exercise.dart';
import '../../../workouts/data/mappers/legacy_workout_mapper.dart';
import '../../../workouts/domain/models/advanced_workout_prescription.dart';
import '../../../workouts/domain/models/cardio_log.dart';

enum PersonalImportIssueSeverity { info, warning, error }

enum PersonalImportDocumentKind {
  workoutPlan,
  periodizedPlan,
  emptyTemplate,
  educationalMaterial,
  unknown;

  String get label {
    return switch (this) {
      PersonalImportDocumentKind.workoutPlan => 'Ficha de treino',
      PersonalImportDocumentKind.periodizedPlan => 'Planejamento por semanas',
      PersonalImportDocumentKind.emptyTemplate => 'Modelo não preenchido',
      PersonalImportDocumentKind.educationalMaterial => 'Material informativo',
      PersonalImportDocumentKind.unknown => 'Formato não classificado',
    };
  }
}

enum PersonalImportPrescriptionKind {
  repetitions,
  perSet,
  time,
  steps,
  maximum,
  mixed;

  String get label {
    return switch (this) {
      PersonalImportPrescriptionKind.repetitions => 'Repetições',
      PersonalImportPrescriptionKind.perSet => 'Prescrição por série',
      PersonalImportPrescriptionKind.time => 'Tempo',
      PersonalImportPrescriptionKind.steps => 'Passos',
      PersonalImportPrescriptionKind.maximum => 'Máximo',
      PersonalImportPrescriptionKind.mixed => 'Prescrição especial',
    };
  }
}

@immutable
class PersonalImportIssue {
  const PersonalImportIssue({
    required this.message,
    this.severity = PersonalImportIssueSeverity.warning,
    this.routineName,
    this.exerciseName,
  });

  final String message;
  final PersonalImportIssueSeverity severity;
  final String? routineName;
  final String? exerciseName;
}

@immutable
class PersonalImportExerciseDraft {
  const PersonalImportExerciseDraft({
    required this.rawName,
    required this.seriesCount,
    required this.repetitions,
    required this.rest,
    required this.note,
    required this.suggestedExerciseIds,
    this.selectedExerciseId,
    this.isSupersetLead = false,
    this.needsReview = false,
    this.originalPrescription = '',
    this.prescriptionKind = PersonalImportPrescriptionKind.repetitions,
    this.techniques = const <String>[],
    this.alternatives = const <String>[],
    this.intensity = '',
    this.cadence = '',
  });

  final String rawName;
  final int seriesCount;
  final String repetitions;
  final String rest;
  final String note;
  final String? selectedExerciseId;
  final List<String> suggestedExerciseIds;
  final bool isSupersetLead;
  final bool needsReview;
  final String originalPrescription;
  final PersonalImportPrescriptionKind prescriptionKind;
  final List<String> techniques;
  final List<String> alternatives;
  final String intensity;
  final String cadence;

  bool get isCatalogExercise => selectedExerciseId != null;
  bool get hasAlternatives => alternatives.length > 1;
  bool get hasMissingRepetitions => repetitions.trim().isEmpty;
  bool get hasInvalidSeries => seriesCount <= 0;
  bool get hasRequiredProblem =>
      rawName.trim().isEmpty || hasMissingRepetitions || hasInvalidSeries;
  bool get hasPendingReview => needsReview || hasRequiredProblem;

  List<String> get pendingReasons {
    final reasons = <String>[];
    if (rawName.trim().isEmpty) {
      reasons.add('Nome ausente');
    }
    if (hasMissingRepetitions) {
      reasons.add('Repetições ausentes');
    }
    if (hasInvalidSeries) {
      reasons.add('Séries inválidas');
    }
    if (needsReview && selectedExerciseId == null) {
      reasons.add('Exercício não identificado pelo PULSE');
    } else if (needsReview) {
      reasons.add('Associação precisa ser confirmada');
    }
    return reasons;
  }

  String get displayPrescription {
    final original = originalPrescription.trim();
    if (original.isNotEmpty) {
      return original;
    }
    return '${seriesCount}x ${repetitions.trim()}';
  }

  String get advancedSummary {
    final parts = <String>[
      ...techniques,
      if (intensity.trim().isNotEmpty) intensity.trim(),
      if (cadence.trim().isNotEmpty) 'Cadência: ${cadence.trim()}',
    ];
    return parts.join(' • ');
  }

  PersonalImportExerciseDraft copyWith({
    String? rawName,
    int? seriesCount,
    String? repetitions,
    String? rest,
    String? note,
    String? selectedExerciseId,
    bool clearSelectedExercise = false,
    List<String>? suggestedExerciseIds,
    bool? isSupersetLead,
    bool? needsReview,
    String? originalPrescription,
    PersonalImportPrescriptionKind? prescriptionKind,
    List<String>? techniques,
    List<String>? alternatives,
    String? intensity,
    String? cadence,
  }) {
    return PersonalImportExerciseDraft(
      rawName: rawName ?? this.rawName,
      seriesCount: seriesCount ?? this.seriesCount,
      repetitions: repetitions ?? this.repetitions,
      rest: rest ?? this.rest,
      note: note ?? this.note,
      selectedExerciseId: clearSelectedExercise
          ? null
          : selectedExerciseId ?? this.selectedExerciseId,
      suggestedExerciseIds: suggestedExerciseIds ?? this.suggestedExerciseIds,
      isSupersetLead: isSupersetLead ?? this.isSupersetLead,
      needsReview: needsReview ?? this.needsReview,
      originalPrescription: originalPrescription ?? this.originalPrescription,
      prescriptionKind: prescriptionKind ?? this.prescriptionKind,
      techniques: techniques ?? this.techniques,
      alternatives: alternatives ?? this.alternatives,
      intensity: intensity ?? this.intensity,
      cadence: cadence ?? this.cadence,
    );
  }

  Exercise toExercise({
    required int stamp,
    required int routineIndex,
    required int exerciseIndex,
    String? customExerciseId,
  }) {
    final matched = selectedExerciseId == null
        ? null
        : exerciseDatabase
              .where((exercise) => exercise.id == selectedExerciseId)
              .firstOrNull;

    final repsText = '${seriesCount}x ${repetitions.trim()}';
    final noteParts = <String>[
      if (note.trim().isNotEmpty) note.trim(),
      if (originalPrescription.trim().isNotEmpty &&
          originalPrescription.trim() != repsText)
        'Prescrição original: ${originalPrescription.trim()}',
      if (techniques.isNotEmpty) 'Técnica: ${techniques.join(', ')}',
      if (intensity.trim().isNotEmpty) 'Intensidade: ${intensity.trim()}',
      if (cadence.trim().isNotEmpty) 'Cadência: ${cadence.trim()}',
      if (alternatives.length > 1)
        'Alternativas informadas: ${alternatives.join(' ou ')}',
    ];
    final importedNote = noteParts.join(' • ');
    final advancedPrescription = _buildAdvancedPrescription(repsText);

    if (matched != null) {
      return matched.copyWith(
        reps: repsText,
        rest: rest.trim().isEmpty ? 'Não informado' : rest.trim(),
        isSuperset: isSupersetLead,
        customNote: importedNote,
        advancedPrescription: advancedPrescription,
      );
    }

    return Exercise(
      id:
          customExerciseId ??
          'custom_import_${stamp}_${routineIndex}_$exerciseIndex',
      name: rawName.trim(),
      muscle: 'Outros',
      description: 'Exercício importado de uma ficha externa.',
      reps: repsText,
      rest: rest.trim().isEmpty ? 'Não informado' : rest.trim(),
      isSuperset: isSupersetLead,
      customNote: importedNote,
      advancedPrescription: advancedPrescription,
    );
  }

  AdvancedExercisePrescription _buildAdvancedPrescription(String repsText) {
    final repValues = RegExp(r'\d+')
        .allMatches(repetitions)
        .map((match) => int.parse(match.group(0)!))
        .toList(growable: false);
    final normalizedRepetitions = repetitions.toLowerCase();
    final isWrittenAsRange =
        RegExp(
          r'\d+\s*(?:a|até)\s*\d+',
          caseSensitive: false,
        ).hasMatch(normalizedRepetitions) ||
        (seriesCount == 2 &&
            normalizedRepetitions.contains('-') &&
            !normalizedRepetitions.contains('/'));
    final hasExplicitPerSetSeparator =
        normalizedRepetitions.contains('/') ||
        normalizedRepetitions.contains('+');
    final hasPerSetTargets =
        seriesCount > 1 &&
        repValues.length == seriesCount &&
        !isWrittenAsRange &&
        (seriesCount >= 3 || hasExplicitPerSetSeparator);
    final technique = _structuredTechnique();
    final rir = RegExp(
      r'RIR\s*[:=-]?\s*(\d+)',
      caseSensitive: false,
    ).firstMatch(intensity)?.group(1);
    final targetRir = int.tryParse(rir ?? '');
    final hasAdvancedData =
        hasPerSetTargets ||
        techniques.isNotEmpty ||
        cadence.trim().isNotEmpty ||
        targetRir != null ||
        alternatives.length > 1;

    if (!hasAdvancedData) {
      return const AdvancedExercisePrescription();
    }

    final restSeconds = LegacyWorkoutMapper.parseExerciseConfig(
      reps: repsText,
      rest: rest,
    ).recommendedRestSeconds;
    final alternativesList = <ExerciseAlternative>[];
    final seen = <String>{};
    for (final alternativeName in alternatives) {
      final normalized = _normalizeAlternative(alternativeName);
      if (normalized.isEmpty ||
          normalized == _normalizeAlternative(rawName) ||
          !seen.add(normalized)) {
        continue;
      }
      Exercise? catalogMatch;
      for (final candidate in exerciseDatabase) {
        if (_normalizeAlternative(candidate.name) == normalized) {
          catalogMatch = candidate;
          break;
        }
      }
      alternativesList.add(
        ExerciseAlternative(
          exerciseId: catalogMatch?.id ?? '',
          name: alternativeName.trim(),
          muscle: catalogMatch?.muscle ?? '',
        ),
      );
    }

    return AdvancedExercisePrescription(
      activeWeek: 1,
      weeks: <WorkoutWeekPrescription>[
        WorkoutWeekPrescription(
          weekNumber: 1,
          label: 'Ficha importada',
          sets: <WorkoutSetPrescription>[
            for (var index = 0; index < seriesCount; index++)
              WorkoutSetPrescription(
                setNumber: index + 1,
                target: hasPerSetTargets
                    ? '${repValues[index]} reps'
                    : repetitions.trim(),
                restSeconds: restSeconds > 0 ? restSeconds : null,
                targetRir: targetRir,
                cadence: cadence.trim(),
                technique: technique,
              ),
          ],
        ),
      ],
      alternatives: alternativesList,
    );
  }

  WorkoutTechnique _structuredTechnique() {
    final normalized = techniques.join(' ').toLowerCase();
    if (normalized.contains('drop')) {
      return WorkoutTechnique.dropSet;
    }
    if (normalized.contains('rest') && normalized.contains('pause')) {
      return WorkoutTechnique.restPause;
    }
    if (normalized.contains('isometr')) {
      return WorkoutTechnique.isometry;
    }
    if (normalized.contains('parcial')) {
      return WorkoutTechnique.partialFailure;
    }
    if (normalized.contains('falha')) {
      return WorkoutTechnique.failure;
    }
    if (normalized.contains('dead') && normalized.contains('stop')) {
      return WorkoutTechnique.deadStop;
    }
    if (normalized.contains('cluster')) {
      return WorkoutTechnique.cluster;
    }
    if (normalized.contains('myo')) {
      return WorkoutTechnique.myoReps;
    }
    return WorkoutTechnique.none;
  }

  String _normalizeAlternative(String value) {
    const source = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const target = 'aaaaaeeeeiiiiooooouuuuc';
    var normalized = value.trim().toLowerCase();
    for (var index = 0; index < source.length; index++) {
      normalized = normalized.replaceAll(source[index], target[index]);
    }
    return normalized.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }
}

@immutable
class PersonalImportRoutineDraft {
  PersonalImportRoutineDraft({
    required this.name,
    required this.focus,
    required List<PersonalImportExerciseDraft> exercises,
    List<RoutineCardio> cardio = const <RoutineCardio>[],
    this.scheduleLabel = '',
    this.notes = '',
    this.isOptional = false,
  }) : exercises = UnmodifiableListView<PersonalImportExerciseDraft>(
         List<PersonalImportExerciseDraft>.from(exercises),
       ),
       cardio = UnmodifiableListView<RoutineCardio>(
         List<RoutineCardio>.from(cardio),
       );

  final String name;
  final String focus;
  final List<PersonalImportExerciseDraft> exercises;
  final List<RoutineCardio> cardio;
  final String scheduleLabel;
  final String notes;
  final bool isOptional;

  PersonalImportRoutineDraft copyWith({
    String? name,
    String? focus,
    List<PersonalImportExerciseDraft>? exercises,
    List<RoutineCardio>? cardio,
    String? scheduleLabel,
    String? notes,
    bool? isOptional,
  }) {
    return PersonalImportRoutineDraft(
      name: name ?? this.name,
      focus: focus ?? this.focus,
      exercises: exercises ?? this.exercises,
      cardio: cardio ?? this.cardio,
      scheduleLabel: scheduleLabel ?? this.scheduleLabel,
      notes: notes ?? this.notes,
      isOptional: isOptional ?? this.isOptional,
    );
  }
}

@immutable
class PersonalWorkoutImportDraft {
  PersonalWorkoutImportDraft({
    required this.programName,
    required this.focus,
    required List<PersonalImportRoutineDraft> routines,
    required List<PersonalImportIssue> issues,
    this.generalCardio,
    this.sourceLabel = '',
    this.documentKind = PersonalImportDocumentKind.workoutPlan,
    this.classificationMessage = '',
    this.periodizationWeeks = 0,
  }) : routines = UnmodifiableListView<PersonalImportRoutineDraft>(
         List<PersonalImportRoutineDraft>.from(routines),
       ),
       issues = UnmodifiableListView<PersonalImportIssue>(
         List<PersonalImportIssue>.from(issues),
       );

  final String programName;
  final String focus;
  final List<PersonalImportRoutineDraft> routines;
  final List<PersonalImportIssue> issues;
  final RoutineCardio? generalCardio;
  final String sourceLabel;
  final PersonalImportDocumentKind documentKind;
  final String classificationMessage;
  final int periodizationWeeks;

  int get exerciseCount => routines.fold<int>(
    0,
    (total, routine) => total + routine.exercises.length,
  );

  int get recognizedExerciseCount => routines.fold<int>(
    0,
    (total, routine) =>
        total +
        routine.exercises.where((item) => item.isCatalogExercise).length,
  );

  int get customExerciseCount => exerciseCount - recognizedExerciseCount;

  int get reviewCount => routines.fold<int>(
    0,
    (total, routine) =>
        total + routine.exercises.where((item) => item.needsReview).length,
  );

  int get pendingExerciseCount => routines.fold<int>(
    0,
    (total, routine) =>
        total + routine.exercises.where((item) => item.hasPendingReview).length,
  );

  int get missingRepetitionsCount => routines.fold<int>(
    0,
    (total, routine) =>
        total +
        routine.exercises.where((item) => item.hasMissingRepetitions).length,
  );

  int get invalidSeriesCount => routines.fold<int>(
    0,
    (total, routine) =>
        total + routine.exercises.where((item) => item.hasInvalidSeries).length,
  );

  int get routinesWithPendingCount => routines
      .where(
        (routine) => routine.exercises.any((item) => item.hasPendingReview),
      )
      .length;

  int get reviewedExerciseCount => exerciseCount - reviewCount;

  int get cardioCount => routines.fold<int>(
    generalCardio == null ? 0 : routines.length,
    (total, routine) => total + routine.cardio.length,
  );

  int get alternativeExerciseCount => routines.fold<int>(
    0,
    (total, routine) =>
        total + routine.exercises.where((item) => item.hasAlternatives).length,
  );

  int get advancedTechniqueCount => routines.fold<int>(
    0,
    (total, routine) =>
        total +
        routine.exercises.where((item) => item.techniques.isNotEmpty).length,
  );

  int get missingRestCount => routines.fold<int>(
    0,
    (total, routine) =>
        total +
        routine.exercises.where((item) => item.rest.trim().isEmpty).length,
  );

  PersonalImportSaveValidation validateForSave() {
    final blocking = <String>[];
    final warnings = <String>[];

    if (programName.trim().isEmpty) {
      blocking.add('Informe um nome para o programa.');
    }
    if (routines.isEmpty) {
      blocking.add('Nenhuma ficha foi reconhecida.');
    }

    var emptyRoutineNames = 0;
    var emptyRoutines = 0;
    var emptyExerciseNames = 0;
    var missingRepetitions = 0;
    var invalidSeries = 0;

    for (final routine in routines) {
      if (routine.name.trim().isEmpty) {
        emptyRoutineNames++;
      }
      if (routine.exercises.isEmpty &&
          routine.cardio.isEmpty &&
          generalCardio == null) {
        emptyRoutines++;
      }
      for (final exercise in routine.exercises) {
        if (exercise.rawName.trim().isEmpty) {
          emptyExerciseNames++;
        }
        if (exercise.seriesCount <= 0) {
          invalidSeries++;
        }
        if (exercise.repetitions.trim().isEmpty) {
          missingRepetitions++;
        }
      }
    }

    if (emptyRoutineNames > 0) {
      blocking.add('$emptyRoutineNames ficha(s) estão sem nome.');
    }
    if (emptyRoutines > 0) {
      blocking.add(
        '$emptyRoutines ficha(s) estão sem musculação e sem cardio.',
      );
    }
    if (emptyExerciseNames > 0) {
      blocking.add('$emptyExerciseNames exercício(s) estão sem nome.');
    }
    if (invalidSeries > 0) {
      blocking.add(
        '$invalidSeries exercício(s) têm número de séries inválido.',
      );
    }
    if (missingRepetitions > 0) {
      blocking.add('$missingRepetitions exercício(s) estão sem repetições.');
    }
    if (generalCardio != null && generalCardio!.plannedDurationMinutes <= 0) {
      blocking.add('O cardio geral precisa ter uma duração planejada válida.');
    }
    final parserErrors = issues
        .where((issue) => issue.severity == PersonalImportIssueSeverity.error)
        .length;
    if (parserErrors > 0 && routines.isEmpty) {
      blocking.add('$parserErrors erro(s) de leitura impedem o salvamento.');
    }

    if (reviewCount > 0) {
      warnings.add('$reviewCount exercício(s) ainda não foram revisados.');
    }
    if (customExerciseCount > 0) {
      warnings.add(
        '$customExerciseCount exercício(s) não estão associados à biblioteca do PULSE.',
      );
    }
    if (missingRestCount > 0) {
      warnings.add('Descanso não informado em $missingRestCount exercício(s).');
    }
    final remainingInterpretationIssues = issues
        .where((issue) => issue.severity != PersonalImportIssueSeverity.error)
        .length;
    if (remainingInterpretationIssues > 0) {
      warnings.add(
        '$remainingInterpretationIssues ponto(s) de interpretação continuam sinalizados.',
      );
    }
    if (generalCardio?.modality == CardioModality.other) {
      warnings.add('O cardio geral está com modalidade flexível.');
    }
    if (alternativeExerciseCount > 0) {
      warnings.add(
        '$alternativeExerciseCount exercício(s) possuem alternativas que precisam ser confirmadas.',
      );
    }
    if (documentKind == PersonalImportDocumentKind.periodizedPlan) {
      warnings.add(
        'Foi encontrada uma progressão de $periodizationWeeks semana(s). Nesta versão, a primeira semana será importada e o planejamento completo ficará preservado nas observações.',
      );
    }

    return PersonalImportSaveValidation(
      blockingMessages: blocking,
      warningMessages: warnings,
    );
  }

  PersonalWorkoutImportDraft applyRestToMissing(String rest) {
    final normalizedRest = rest.trim();
    if (normalizedRest.isEmpty) {
      return this;
    }

    final updatedRoutines = routines
        .map((routine) {
          final updatedExercises = routine.exercises
              .map((exercise) {
                if (exercise.rest.trim().isNotEmpty) {
                  return exercise;
                }
                return exercise.copyWith(rest: normalizedRest);
              })
              .toList(growable: false);
          return routine.copyWith(exercises: updatedExercises);
        })
        .toList(growable: false);

    return copyWith(routines: updatedRoutines);
  }

  PersonalWorkoutImportDraft resolveExerciseReview({
    required String routineName,
    required Iterable<String> exerciseNames,
    List<PersonalImportRoutineDraft>? routines,
  }) {
    final normalizedNames = exerciseNames
        .map(_normalizeIssueReference)
        .where((name) => name.isNotEmpty)
        .toSet();
    final normalizedRoutine = _normalizeIssueReference(routineName);
    final remainingIssues = issues
        .where((issue) {
          final issueRoutine = _normalizeIssueReference(
            issue.routineName ?? '',
          );
          final issueExercise = _normalizeIssueReference(
            issue.exerciseName ?? '',
          );
          final sameRoutine =
              issueRoutine.isEmpty || issueRoutine == normalizedRoutine;
          final referencesExercise = normalizedNames.contains(issueExercise);
          return !(sameRoutine && referencesExercise);
        })
        .toList(growable: false);

    return copyWith(routines: routines, issues: remainingIssues);
  }

  PersonalWorkoutImportDraft copyWith({
    String? programName,
    String? focus,
    List<PersonalImportRoutineDraft>? routines,
    List<PersonalImportIssue>? issues,
    RoutineCardio? generalCardio,
    bool clearGeneralCardio = false,
    String? sourceLabel,
    PersonalImportDocumentKind? documentKind,
    String? classificationMessage,
    int? periodizationWeeks,
  }) {
    return PersonalWorkoutImportDraft(
      programName: programName ?? this.programName,
      focus: focus ?? this.focus,
      routines: routines ?? this.routines,
      issues: issues ?? this.issues,
      generalCardio: clearGeneralCardio
          ? null
          : generalCardio ?? this.generalCardio,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      documentKind: documentKind ?? this.documentKind,
      classificationMessage:
          classificationMessage ?? this.classificationMessage,
      periodizationWeeks: periodizationWeeks ?? this.periodizationWeeks,
    );
  }

  WorkoutProgram toProgram() {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final programNameValue = programName.trim().isEmpty
        ? 'Programa importado'
        : programName.trim();

    final customIdsByName = <String, String>{};
    final convertedRoutines = routines
        .asMap()
        .entries
        .map((routineEntry) {
          final routine = routineEntry.value;
          final convertedExercises = routine.exercises
              .asMap()
              .entries
              .map((entry) {
                final normalizedCustomName = entry.value.rawName
                    .toLowerCase()
                    .replaceAll(
                      RegExp(r'[^a-z0-9áàâãäéèêëíìîïóòôõöúùûüç]+'),
                      '_',
                    )
                    .replaceAll(RegExp(r'_+'), '_')
                    .replaceAll(RegExp(r'^_|_$'), '');
                final customExerciseId = entry.value.isCatalogExercise
                    ? null
                    : customIdsByName.putIfAbsent(
                        normalizedCustomName,
                        () => 'custom_import_${stamp}_$normalizedCustomName',
                      );

                return entry.value.toExercise(
                  stamp: stamp,
                  routineIndex: routineEntry.key,
                  exerciseIndex: entry.key,
                  customExerciseId: customExerciseId,
                );
              })
              .toList(growable: false);

          final cardio = <RoutineCardio>[
            ...routine.cardio.asMap().entries.map(
              (entry) => entry.value.copyWith(
                id: 'import_cardio_${stamp}_${routineEntry.key}_${entry.key}',
              ),
            ),
            if (generalCardio != null)
              generalCardio!.copyWith(
                id: 'import_general_cardio_${stamp}_${routineEntry.key}',
              ),
          ];

          final routineFocus = <String>[
            if (routine.focus.trim().isNotEmpty) routine.focus.trim(),
            if (routine.scheduleLabel.trim().isNotEmpty)
              'Dia sugerido: ${routine.scheduleLabel.trim()}',
            if (routine.isOptional) 'Opcional',
            if (routine.notes.trim().isNotEmpty) routine.notes.trim(),
          ].join(' • ');

          return WorkoutRoutine(
            id: 'import_routine_${stamp}_${routineEntry.key}',
            name: routine.name.trim().isEmpty
                ? 'Treino ${routineEntry.key + 1}'
                : routine.name.trim(),
            focus: routineFocus,
            groupName: programNameValue,
            exercises: convertedExercises,
            cardio: cardio,
          );
        })
        .toList(growable: false);

    return WorkoutProgram(
      id: 'import_program_$stamp',
      name: programNameValue,
      focus: focus.trim().isEmpty
          ? 'Ficha importada do personal'
          : focus.trim(),
      routines: convertedRoutines,
    );
  }
}

@immutable
class PersonalImportSaveValidation {
  PersonalImportSaveValidation({
    required List<String> blockingMessages,
    required List<String> warningMessages,
  }) : blockingMessages = UnmodifiableListView<String>(
         List<String>.from(blockingMessages),
       ),
       warningMessages = UnmodifiableListView<String>(
         List<String>.from(warningMessages),
       );

  final List<String> blockingMessages;
  final List<String> warningMessages;

  bool get hasBlockingIssues => blockingMessages.isNotEmpty;
  bool get hasWarnings => warningMessages.isNotEmpty;
}

String _normalizeIssueReference(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9áàâãäéèêëíìîïóòôõöúùûüç]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}

@immutable
sealed class PersonalImportDocumentBlock {
  const PersonalImportDocumentBlock();
}

@immutable
class PersonalImportParagraph extends PersonalImportDocumentBlock {
  const PersonalImportParagraph(this.text);

  final String text;
}

@immutable
class PersonalImportTable extends PersonalImportDocumentBlock {
  PersonalImportTable(List<List<String>> rows)
    : rows = UnmodifiableListView<List<String>>(
        rows
            .map((row) => UnmodifiableListView<String>(List<String>.from(row)))
            .toList(growable: false),
      );

  final List<List<String>> rows;
}
