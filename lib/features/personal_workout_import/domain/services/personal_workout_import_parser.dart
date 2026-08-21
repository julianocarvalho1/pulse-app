import '../../../../models/exercise.dart';
import '../../../workouts/domain/models/cardio_log.dart';
import '../models/personal_workout_import.dart';
import 'personal_exercise_matcher.dart';

class PersonalWorkoutImportParser {
  const PersonalWorkoutImportParser({
    this._matcher = const PersonalExerciseMatcher(),
  });

  final PersonalExerciseMatcher _matcher;

  PersonalWorkoutImportDraft parseDocument({
    required List<PersonalImportDocumentBlock> blocks,
    required String sourceLabel,
  }) {
    final classification = _classifyDocument(_blocksToText(blocks));
    final blocked = _blockedClassificationDraft(
      classification: classification,
      sourceLabel: sourceLabel,
    );
    if (blocked != null) {
      return blocked;
    }

    final issues = <PersonalImportIssue>[];
    final routines = <PersonalImportRoutineDraft>[];
    var programName = 'Programa importado';
    var focus = 'Ficha importada do personal';
    _MutableRoutine? currentRoutine;
    String? cardioText;

    void flushRoutine() {
      final routine = currentRoutine;
      if (routine == null) {
        return;
      }
      if (routine.exercises.isEmpty && routine.cardio.isEmpty) {
        issues.add(
          PersonalImportIssue(
            message: 'Nenhuma atividade foi encontrada em ${routine.name}.',
            routineName: routine.name,
          ),
        );
      }
      routines.add(routine.toDraft());
      currentRoutine = null;
    }

    for (final block in blocks) {
      switch (block) {
        case PersonalImportParagraph(:final text):
          final normalized = text.trim();
          if (normalized.isEmpty) {
            continue;
          }

          if (_looksLikeProgramTitle(normalized) &&
              programName == 'Programa importado') {
            programName = _cleanProgramName(normalized);
            continue;
          }

          final heading = _parseRoutineHeading(normalized);
          if (heading != null) {
            flushRoutine();
            if (heading.isRestDay) {
              issues.add(
                PersonalImportIssue(
                  message:
                      '${heading.name} foi identificado como dia de descanso e não será criado como ficha.',
                  severity: PersonalImportIssueSeverity.info,
                ),
              );
              currentRoutine = null;
              continue;
            }
            currentRoutine = _MutableRoutine(
              name: heading.name,
              focus: heading.focus,
              scheduleLabel: heading.scheduleLabel,
              isOptional: heading.isOptional,
            );
            continue;
          }

          if (_isCardioIntro(normalized)) {
            cardioText = normalized;
            continue;
          }

          if (cardioText != null && _isCardioInstruction(normalized)) {
            cardioText = '$cardioText $normalized';
            continue;
          }

          if (currentRoutine != null) {
            final localCardio = _parseCardioText(
              normalized,
              id: 'import_cardio_${routines.length}_${currentRoutine!.cardio.length}',
            );
            if (localCardio != null) {
              currentRoutine!.cardio.add(localCardio);
              continue;
            }
          }

          final inlineExercise = _parseInlineExercise(normalized);
          if (inlineExercise != null) {
            currentRoutine ??= _MutableRoutine(name: 'Treino 1', focus: '');
            currentRoutine!.exercises.add(
              _buildExerciseDraft(
                rawName: inlineExercise.name,
                seriesText: inlineExercise.series,
                repetitions: inlineExercise.repetitions,
                rest: inlineExercise.rest,
                note: inlineExercise.note,
                routineName: currentRoutine!.name,
                issues: issues,
              ),
            );
          }

        case PersonalImportTable(:final rows):
          currentRoutine ??= _MutableRoutine(
            name: 'Treino ${routines.length + 1}',
            focus: '',
          );
          _parseTableRows(rows: rows, routine: currentRoutine!, issues: issues);
      }
    }

    flushRoutine();

    if (routines.isEmpty) {
      issues.add(
        const PersonalImportIssue(
          message:
              'Nenhuma ficha foi reconhecida. Revise o documento ou use a opção de colar texto.',
          severity: PersonalImportIssueSeverity.error,
        ),
      );
    }

    final cardio = _parseGeneralCardio(cardioText, issues);

    if (cardio != null) {
      focus = 'Musculação com cardio após o treino';
    }

    return PersonalWorkoutImportDraft(
      programName: programName,
      focus: focus,
      routines: routines,
      issues: issues,
      generalCardio: cardio,
      sourceLabel: sourceLabel,
      documentKind: classification.kind,
      classificationMessage: classification.message,
      periodizationWeeks: classification.periodizationWeeks,
    );
  }

  PersonalWorkoutImportDraft parseText({
    required String text,
    String sourceLabel = 'Texto colado',
  }) {
    final normalizedText = _normalizeCopiedText(text);
    final classification = _classifyDocument(normalizedText);
    final blocked = _blockedClassificationDraft(
      classification: classification,
      sourceLabel: sourceLabel,
    );
    if (blocked != null) {
      return blocked;
    }

    final structuredDraft = _parseStructuredDelimitedText(
      text: normalizedText,
      sourceLabel: sourceLabel,
      classification: classification,
    );
    if (structuredDraft != null &&
        (structuredDraft.exerciseCount > 0 ||
            structuredDraft.cardioCount > 0)) {
      return structuredDraft;
    }

    final sectionedDraft = _parseSectionedText(
      text: normalizedText,
      sourceLabel: sourceLabel,
      classification: classification,
    );

    if (sectionedDraft != null &&
        (sectionedDraft.exerciseCount > 0 || sectionedDraft.cardioCount > 0)) {
      return sectionedDraft;
    }

    final regularBlocks = _buildTextBlocks(normalizedText);
    final regularDraft =
        parseDocument(blocks: regularBlocks, sourceLabel: sourceLabel).copyWith(
          documentKind: classification.kind,
          classificationMessage: classification.message,
          periodizationWeeks: classification.periodizationWeeks,
        );

    if (regularDraft.exerciseCount > 0 || regularDraft.cardioCount > 0) {
      return regularDraft;
    }

    final looseBlocks = _buildLooseTextBlocks(normalizedText);
    final looseDraft =
        parseDocument(blocks: looseBlocks, sourceLabel: sourceLabel).copyWith(
          documentKind: classification.kind,
          classificationMessage: classification.message,
          periodizationWeeks: classification.periodizationWeeks,
        );

    return looseDraft.exerciseCount > 0 || looseDraft.cardioCount > 0
        ? looseDraft
        : regularDraft;
  }

  PersonalWorkoutImportDraft? _parseStructuredDelimitedText({
    required String text,
    required String sourceLabel,
    required _DocumentClassification classification,
  }) {
    final rawLines = text
        .split('\n')
        .map((line) => line.trimRight())
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
    if (rawLines.length < 2) {
      return null;
    }

    final headerCells = _splitDelimitedColumns(
      rawLines.first,
      preserveEmpty: true,
    );
    if (headerCells.length < 4) {
      return null;
    }
    final header = _TableColumnMap.fromHeader(headerCells);
    if (header.exerciseIndex == null || header.routineIndex == null) {
      return null;
    }

    final groupedRows = <String, List<List<String>>>{};
    final order = <String>[];
    for (final line in rawLines.skip(1)) {
      final cells = _splitDelimitedColumns(line, preserveEmpty: true);
      if (cells.length <= header.exerciseIndex!) {
        continue;
      }
      final routineName = _cellAt(cells, header.routineIndex!).trim();
      final exerciseName = _cellAt(cells, header.exerciseIndex!).trim();
      if (routineName.isEmpty || exerciseName.isEmpty) {
        continue;
      }
      groupedRows
          .putIfAbsent(routineName, () {
            order.add(routineName);
            return <List<String>>[];
          })
          .add(cells);
    }

    if (groupedRows.isEmpty) {
      return null;
    }

    final issues = <PersonalImportIssue>[];
    final routines = <PersonalImportRoutineDraft>[];
    for (final routineName in order) {
      final rows = groupedRows[routineName]!;
      rows.sort((first, second) {
        final firstOrder =
            int.tryParse(_cellAt(first, header.orderIndex ?? -1)) ?? 999;
        final secondOrder =
            int.tryParse(_cellAt(second, header.orderIndex ?? -1)) ?? 999;
        return firstOrder.compareTo(secondOrder);
      });

      final exercises = <PersonalImportExerciseDraft>[];
      final cardio = <RoutineCardio>[];
      final focusValues = <String>{};
      var scheduleLabel = '';
      for (final cells in rows) {
        final rawName = _cellAt(cells, header.exerciseIndex!).trim();
        final series = _cellAt(cells, header.seriesIndex ?? -1).trim();
        final repetitions = _cellAt(
          cells,
          header.repetitionsIndex ?? -1,
        ).trim();
        final restRaw = _cellAt(cells, header.restIndex ?? -1).trim();
        final rest = restRaw.isEmpty
            ? ''
            : RegExp(r'^[0-9]+$').hasMatch(restRaw)
            ? '$restRaw seg'
            : restRaw;
        final intensity = _cellAt(cells, header.intensityIndex ?? -1).trim();
        final observation = _cellAt(cells, header.notesIndex ?? -1).trim();
        final muscle = _cellAt(cells, header.muscleIndex ?? -1).trim();
        final technique = _cellAt(cells, header.techniqueIndex ?? -1).trim();
        final cadence = _cellAt(cells, header.cadenceIndex ?? -1).trim();
        final day = _cellAt(cells, header.dayIndex ?? -1).trim();
        if (day.isNotEmpty) {
          scheduleLabel = day;
        }
        if (muscle.isNotEmpty) {
          focusValues.add(muscle);
        }
        final noteParts = <String>[
          if (observation.isNotEmpty) observation,
          if (muscle.isNotEmpty) 'Grupo informado: $muscle',
        ];
        final cardioDraft = _parseCardioText(
          '$rawName $series $repetitions $observation',
          id: 'import_cardio_${_slug(routineName)}_${cardio.length}',
        );
        if (cardioDraft != null) {
          cardio.add(cardioDraft);
          continue;
        }
        final techniques = _extractTechniques('$technique $observation');
        final prescription = _normalizePrescription(
          seriesText: series,
          repetitionsText: repetitions,
        );
        exercises.add(
          _buildExerciseDraft(
            rawName: rawName,
            seriesText: prescription.seriesText,
            repetitions: prescription.repetitions,
            rest: rest,
            note: noteParts.join(' • '),
            routineName: routineName,
            issues: issues,
            originalPrescription: prescription.original,
            prescriptionKind: prescription.kind,
            techniques: <String>{
              ...techniques,
              if (technique.isNotEmpty) technique,
            }.toList(),
            intensity: intensity,
            cadence: cadence,
          ),
        );
      }

      routines.add(
        PersonalImportRoutineDraft(
          name: routineName,
          focus: focusValues.take(3).join(', '),
          exercises: exercises,
          cardio: cardio,
          scheduleLabel: scheduleLabel,
        ),
      );
    }

    return PersonalWorkoutImportDraft(
      programName: 'Programa importado',
      focus: 'Ficha importada do personal',
      routines: routines,
      issues: issues,
      sourceLabel: sourceLabel,
      documentKind: classification.kind,
      classificationMessage: classification.message,
      periodizationWeeks: classification.periodizationWeeks,
    );
  }

  _DocumentClassification _classifyDocument(String rawText) {
    final text = _normalizeCopiedText(rawText);
    final normalized = _normalizeForDetection(text);
    final compactPrescriptionCount = RegExp(
      r'\b\d{1,2}\s*[x×]\s*(?:\d{1,3}|m[aá]x)',
      caseSensitive: false,
    ).allMatches(text).length;
    final separatePrescriptionCount = RegExp(
      r'(?:\t|;)0?\d{1,2}(?:\t|;)\s*(?:\d{1,3}|m[aá]x)',
      caseSensitive: false,
    ).allMatches(text).length;
    final prescriptionCount =
        compactPrescriptionCount + separatePrescriptionCount;
    final routineHeadingCount = text
        .split('\n')
        .where((line) => _parseRoutineHeading(line.trim()) != null)
        .length;
    final weekNumbers = RegExp(r'\bsemana\s*(\d{1,2})\b', caseSensitive: false)
        .allMatches(text)
        .map((match) => int.tryParse(match.group(1) ?? ''))
        .whereType<int>()
        .toSet();
    final maxWeek = weekNumbers.isEmpty
        ? 0
        : weekNumbers.reduce(
            (first, second) => first > second ? first : second,
          );
    final educationalMarkers = <String>[
      'sumario',
      'capitulo',
      'objetivos de aprendizagem',
      'referencias bibliograficas',
      'introducao',
    ].where(normalized.contains).length;
    final templateMarkers =
        normalized.contains('ficha de treinamento') ||
        normalized.contains('validade da ficha') ||
        normalized.contains('nome objetivo prof');

    if (educationalMarkers >= 2 &&
        (text.length > 10000 || prescriptionCount < 8)) {
      return const _DocumentClassification(
        kind: PersonalImportDocumentKind.educationalMaterial,
        message:
            'O arquivo parece ser material informativo ou didático, não uma ficha individual preenchida.',
      );
    }

    if (templateMarkers && prescriptionCount < 2) {
      return const _DocumentClassification(
        kind: PersonalImportDocumentKind.emptyTemplate,
        message:
            'O arquivo parece ser um modelo de ficha ainda não preenchido. Preencha séries e repetições antes de importar.',
      );
    }

    if ((maxWeek >= 3 || weekNumbers.length >= 3) && prescriptionCount >= 3) {
      return _DocumentClassification(
        kind: PersonalImportDocumentKind.periodizedPlan,
        message:
            'O PULSE encontrou uma progressão distribuída por várias semanas. A primeira semana será usada agora e o restante será preservado para revisão.',
        periodizationWeeks: maxWeek == 0 ? weekNumbers.length : maxWeek,
      );
    }

    if (routineHeadingCount > 0 && prescriptionCount > 0) {
      return const _DocumentClassification(
        kind: PersonalImportDocumentKind.workoutPlan,
        message: 'Estrutura de ficha de treino reconhecida.',
      );
    }

    if (prescriptionCount > 1 ||
        (normalized.contains('exercicio') &&
            normalized.contains('serie') &&
            (normalized.contains('repet') || normalized.contains('reps')))) {
      return const _DocumentClassification(
        kind: PersonalImportDocumentKind.workoutPlan,
        message:
            'Prescrições de treino foram encontradas, mas alguns títulos podem precisar de revisão.',
      );
    }

    return const _DocumentClassification(
      kind: PersonalImportDocumentKind.unknown,
      message:
          'Não foi possível confirmar a estrutura do documento. Revise atentamente o conteúdo reconhecido.',
    );
  }

  PersonalWorkoutImportDraft? _blockedClassificationDraft({
    required _DocumentClassification classification,
    required String sourceLabel,
  }) {
    if (classification.kind != PersonalImportDocumentKind.emptyTemplate &&
        classification.kind != PersonalImportDocumentKind.educationalMaterial) {
      return null;
    }
    return PersonalWorkoutImportDraft(
      programName: 'Programa importado',
      focus: '',
      routines: const <PersonalImportRoutineDraft>[],
      issues: <PersonalImportIssue>[
        PersonalImportIssue(
          message: classification.message,
          severity: PersonalImportIssueSeverity.error,
        ),
      ],
      sourceLabel: sourceLabel,
      documentKind: classification.kind,
      classificationMessage: classification.message,
      periodizationWeeks: classification.periodizationWeeks,
    );
  }

  static String _blocksToText(List<PersonalImportDocumentBlock> blocks) {
    return blocks
        .map((block) {
          return switch (block) {
            PersonalImportParagraph(:final text) => text,
            PersonalImportTable(:final rows) =>
              rows.map((row) => row.join('\t')).join('\n'),
          };
        })
        .join('\n');
  }

  PersonalWorkoutImportDraft? _parseSectionedText({
    required String text,
    required String sourceLabel,
    required _DocumentClassification classification,
  }) {
    final lines = text.split('\n').map((line) => line.trimRight()).toList();
    final headings = <_RoutineSectionHeading>[];
    var programName = 'Programa importado';
    final cardioIntroLines = <String>[];

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index].trim();
      if (line.isEmpty) {
        continue;
      }

      if (_looksLikeProgramTitle(line)) {
        if (programName == 'Programa importado') {
          programName = _cleanProgramName(line);
        }
        continue;
      }

      final heading = _parseRoutineHeading(line);
      if (heading != null) {
        headings.add(_RoutineSectionHeading(index: index, heading: heading));
        continue;
      }

      if (headings.isEmpty &&
          (_isCardioIntro(line) ||
              (cardioIntroLines.isNotEmpty && _isCardioInstruction(line)))) {
        cardioIntroLines.add(line);
      }
    }

    if (headings.isEmpty) {
      return null;
    }

    final issues = <PersonalImportIssue>[];
    final routines = <PersonalImportRoutineDraft>[];
    var recognizedHeadings = 0;

    for (var headingIndex = 0; headingIndex < headings.length; headingIndex++) {
      final sectionHeading = headings[headingIndex];
      final heading = sectionHeading.heading;
      final endIndex = headingIndex + 1 < headings.length
          ? headings[headingIndex + 1].index
          : lines.length;
      final sectionLines = lines.sublist(sectionHeading.index + 1, endIndex);

      if (heading.isRestDay) {
        issues.add(
          PersonalImportIssue(
            message:
                '${heading.name} foi identificado como descanso e não será criado como ficha.',
            severity: PersonalImportIssueSeverity.info,
          ),
        );
        continue;
      }

      recognizedHeadings++;
      final detectedFocus = heading.focus.isNotEmpty
          ? heading.focus
          : _extractSectionFocus(sectionLines);
      final content = _parseRoutineTextLines(
        lines: sectionLines,
        routineName: heading.name,
        issues: issues,
        fallbackFocus: detectedFocus,
      );

      if (content.exercises.isEmpty && content.cardio.isEmpty) {
        issues.add(
          PersonalImportIssue(
            message: 'Nenhuma atividade foi encontrada em ${heading.name}.',
            routineName: heading.name,
          ),
        );
      }

      routines.add(
        PersonalImportRoutineDraft(
          name: heading.name,
          focus: detectedFocus,
          exercises: content.exercises,
          cardio: content.cardio,
          scheduleLabel: heading.scheduleLabel,
          notes: content.notes,
          isOptional: heading.isOptional,
        ),
      );
    }

    final headingExercises = routines
        .expand((routine) => routine.exercises)
        .where(
          (exercise) => _parseRoutineHeading(exercise.rawName.trim()) != null,
        )
        .toList(growable: false);

    if (headingExercises.isNotEmpty) {
      issues.add(
        const PersonalImportIssue(
          message:
              'Um título de treino foi interpretado como exercício. Revise o texto reconhecido antes de salvar.',
          severity: PersonalImportIssueSeverity.error,
        ),
      );
    }

    if (routines.length != recognizedHeadings) {
      issues.add(
        PersonalImportIssue(
          message:
              'Foram encontrados $recognizedHeadings títulos de treino, mas apenas ${routines.length} fichas foram interpretadas.',
          severity: PersonalImportIssueSeverity.error,
        ),
      );
    }

    final cardio = _parseGeneralCardio(
      cardioIntroLines.isEmpty ? null : cardioIntroLines.join(' '),
      issues,
    );

    if (classification.kind == PersonalImportDocumentKind.periodizedPlan) {
      issues.add(
        PersonalImportIssue(
          message:
              'Planejamento de ${classification.periodizationWeeks} semanas reconhecido. A primeira semana será usada na ficha e a progressão completa ficará nas observações.',
          severity: PersonalImportIssueSeverity.info,
        ),
      );
    }

    return PersonalWorkoutImportDraft(
      programName: programName,
      focus: cardio == null
          ? 'Ficha importada do personal'
          : 'Musculação com cardio após o treino',
      routines: routines,
      issues: issues,
      generalCardio: cardio,
      sourceLabel: sourceLabel,
      documentKind: classification.kind,
      classificationMessage: classification.message,
      periodizationWeeks: classification.periodizationWeeks,
    );
  }

  _ParsedRoutineContent _parseRoutineTextLines({
    required List<String> lines,
    required String routineName,
    required List<PersonalImportIssue> issues,
    required String fallbackFocus,
  }) {
    final exercises = <PersonalImportExerciseDraft>[];
    final cardio = <RoutineCardio>[];
    final defaultRest = _findDefaultSeriesRest(lines);
    final betweenExercisesRest = _findBetweenExercisesRest(lines);
    final routineCardio = _parseRoutineCardioFromLines(
      lines,
      id: 'import_cardio_${_slug(routineName)}',
      focus: fallbackFocus,
    );
    if (routineCardio != null) {
      cardio.add(routineCardio);
    }

    var index = 0;
    while (index < lines.length) {
      final rawLine = lines[index];
      final line = rawLine.trim();

      if (line.isEmpty ||
          _isTextHeader(line) ||
          _isRoutineMetadataLine(line) ||
          _looksLikeFocusLine(line, fallbackFocus) ||
          _isCardioOnlyLine(line)) {
        index++;
        continue;
      }

      if (line == '+' && exercises.isNotEmpty) {
        final previous = exercises.removeLast();
        exercises.add(previous.copyWith(isSupersetLead: true));
        index++;
        continue;
      }

      if (_parseRoutineHeading(line) != null) {
        index++;
        continue;
      }

      final standaloneTechniques = _extractTechniques(line);
      final standaloneIntensity = _extractIntensity(line);
      final standaloneCadence = _extractCadence(line);
      if (exercises.isNotEmpty &&
          !RegExp(r'\d+\s*[x×]').hasMatch(line) &&
          (standaloneTechniques.isNotEmpty ||
              standaloneIntensity.isNotEmpty ||
              standaloneCadence.isNotEmpty)) {
        final previous = exercises.removeLast();
        exercises.add(
          previous.copyWith(
            note: previous.note.isEmpty ? line : '${previous.note} • $line',
            techniques: <String>{
              ...previous.techniques,
              ...standaloneTechniques,
            }.toList(growable: false),
            intensity: standaloneIntensity.isEmpty
                ? previous.intensity
                : standaloneIntensity,
            cadence: standaloneCadence.isEmpty
                ? previous.cadence
                : standaloneCadence,
          ),
        );
        index++;
        continue;
      }

      final inline = _parseInlineExercise(line);
      if (inline != null) {
        exercises.add(
          _buildExerciseDraft(
            rawName: inline.name,
            seriesText: inline.series,
            repetitions: inline.repetitions,
            rest: inline.rest.isEmpty ? defaultRest : inline.rest,
            note: inline.note,
            routineName: routineName,
            issues: issues,
            originalPrescription: inline.originalPrescription,
            prescriptionKind: inline.prescriptionKind,
            techniques: inline.techniques,
            intensity: inline.intensity,
            cadence: inline.cadence,
          ),
        );
        index++;
        continue;
      }

      final cells = _splitTextCells(rawLine);
      if (cells.length >= 3 && _isPotentialLooseExerciseName(cells.first)) {
        final parsed = _parseCellsAsExercise(cells, defaultRest: defaultRest);
        if (parsed != null) {
          exercises.add(
            _buildExerciseDraft(
              rawName: parsed.name,
              seriesText: parsed.series,
              repetitions: parsed.repetitions,
              rest: parsed.rest,
              note: parsed.note,
              routineName: routineName,
              issues: issues,
              originalPrescription: parsed.originalPrescription,
              prescriptionKind: parsed.prescriptionKind,
              techniques: parsed.techniques,
              intensity: parsed.intensity,
              cadence: parsed.cadence,
            ),
          );
          index++;
          continue;
        }
      }

      if (!_isPotentialLooseExerciseName(cells.firstOrNull ?? line)) {
        index++;
        continue;
      }

      final group = _parseExerciseGroupAt(lines, index);
      if (group == null) {
        index++;
        continue;
      }

      for (
        var exerciseIndex = 0;
        exerciseIndex < group.names.length;
        exerciseIndex++
      ) {
        final seriesText = _valueAtOrLast(
          group.series,
          exerciseIndex,
          fallback: '3',
        );
        final repsText = _valueAtOrLast(
          group.repetitions,
          exerciseIndex,
          fallback: '10-12',
        );
        final originalPrescription = '$seriesText x $repsText';
        exercises.add(
          _buildExerciseDraft(
            rawName: group.names[exerciseIndex],
            seriesText: seriesText,
            repetitions: repsText,
            rest: defaultRest,
            note: group.notes.isEmpty
                ? ''
                : group.notes.length == group.names.length
                ? group.notes[exerciseIndex]
                : group.notes.join(' '),
            isSupersetLead:
                group.names.length > 1 &&
                exerciseIndex < group.names.length - 1,
            routineName: routineName,
            issues: issues,
            originalPrescription: originalPrescription,
          ),
        );
      }

      index = group.nextIndex;
    }

    return _ParsedRoutineContent(
      exercises: exercises,
      cardio: cardio,
      notes: betweenExercisesRest.isEmpty
          ? ''
          : 'Intervalo entre exercícios: $betweenExercisesRest',
    );
  }

  _ParsedExerciseGroup? _parseExerciseGroupAt(
    List<String> lines,
    int startIndex,
  ) {
    final firstCells = _splitTextCells(lines[startIndex]);
    final firstName = firstCells.firstOrNull?.trim() ?? '';
    if (!_isPotentialLooseExerciseName(firstName)) {
      return null;
    }

    final names = <String>[firstName];
    final notes = <String>[];
    final series = <String>[];
    final repetitions = <String>[];

    _collectPrescriptionCells(
      firstCells.skip(1),
      names: names,
      notes: notes,
      series: series,
      repetitions: repetitions,
      allowNames: false,
    );

    var cursor = startIndex + 1;
    var isSuperset = false;

    while (cursor < lines.length) {
      final line = lines[cursor].trim();
      if (line.isEmpty) {
        if (series.length >= names.length &&
            repetitions.length >= names.length) {
          cursor++;
          break;
        }
        cursor++;
        continue;
      }

      if (_isTextHeader(line) || _parseRoutineHeading(line) != null) {
        break;
      }

      if (line == '+') {
        isSuperset = true;
        cursor++;
        continue;
      }

      final cells = _splitTextCells(lines[cursor]);
      final firstCell = cells.firstOrNull?.trim() ?? '';
      final canAcceptAnotherName =
          isSuperset &&
          series.length < names.length &&
          repetitions.length < names.length;

      if (_isPotentialLooseExerciseName(firstCell) &&
          !_isObservation(firstCell)) {
        if (!canAcceptAnotherName) {
          break;
        }
        names.add(firstCell);
        _collectPrescriptionCells(
          cells.skip(1),
          names: names,
          notes: notes,
          series: series,
          repetitions: repetitions,
          allowNames: false,
        );
        cursor++;
        continue;
      }

      _collectPrescriptionCells(
        cells,
        names: names,
        notes: notes,
        series: series,
        repetitions: repetitions,
        allowNames: isSuperset,
      );
      cursor++;

      if (series.length >= names.length && repetitions.length >= names.length) {
        break;
      }
    }

    if (series.isEmpty || repetitions.isEmpty) {
      return null;
    }

    return _ParsedExerciseGroup(
      names: names,
      notes: notes,
      series: series,
      repetitions: repetitions,
      nextIndex: cursor,
    );
  }

  void _collectPrescriptionCells(
    Iterable<String> cells, {
    required List<String> names,
    required List<String> notes,
    required List<String> series,
    required List<String> repetitions,
    required bool allowNames,
  }) {
    for (final rawCell in cells) {
      final cell = rawCell.trim();
      if (cell.isEmpty || cell == '+') {
        continue;
      }

      if (_isObservation(cell)) {
        notes.add(_stripParentheses(cell));
        continue;
      }

      if (_isStandaloneSeries(cell) && series.length < names.length) {
        series.add(cell);
        continue;
      }

      if (_isLooseRepetitionValue(cell) && repetitions.length < names.length) {
        repetitions.add(cell);
        continue;
      }

      if (allowNames && _isPotentialLooseExerciseName(cell)) {
        names.add(cell);
      }
    }
  }

  static List<String> _splitTextCells(String rawLine) {
    if (rawLine.contains('\t')) {
      return rawLine
          .split(RegExp(r'\t+'))
          .map((cell) => cell.trim())
          .where((cell) => cell.isNotEmpty)
          .toList(growable: false);
    }

    final delimited = _splitDelimitedColumns(rawLine);
    if (delimited.isNotEmpty) {
      return delimited;
    }

    return <String>[rawLine.trim()];
  }

  static bool _isTextHeader(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll('º', '°')
        .replaceAll(RegExp(r'\s+'), ' ');
    return normalized.contains('exercício') &&
        (normalized.contains('série') || normalized.contains('repet'));
  }

  static String _normalizeCopiedText(String value) {
    return value
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\u00A0', ' ')
        .replaceAll('\u200B', '')
        .replaceAll('\uFEFF', '')
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'[ ]+$'), ''))
        .join('\n')
        .trim();
  }

  List<PersonalImportDocumentBlock> _buildTextBlocks(String text) {
    final blocks = <PersonalImportDocumentBlock>[];
    final pendingRows = <List<String>>[];

    void flushRows() {
      if (pendingRows.isEmpty) {
        return;
      }
      blocks.add(PersonalImportTable(List<List<String>>.from(pendingRows)));
      pendingRows.clear();
    }

    for (final rawLine in text.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        flushRows();
        continue;
      }

      final columns = _splitDelimitedColumns(rawLine);
      if (columns.length >= 3) {
        pendingRows.add(columns);
        continue;
      }

      flushRows();
      blocks.add(PersonalImportParagraph(line));
    }

    flushRows();
    return blocks;
  }

  List<PersonalImportDocumentBlock> _buildLooseTextBlocks(String text) {
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    final blocks = <PersonalImportDocumentBlock>[];

    var index = 0;
    while (index < lines.length) {
      final line = lines[index];

      if (_shouldKeepLooseParagraph(line)) {
        blocks.add(PersonalImportParagraph(line));
        index++;
        continue;
      }

      if (!_isPotentialLooseExerciseName(line)) {
        index++;
        continue;
      }

      final names = <String>[line];
      final notes = <String>[];
      var cursor = index + 1;

      while (cursor < lines.length && _isObservation(lines[cursor])) {
        notes.add(_stripParentheses(lines[cursor]));
        cursor++;
      }

      while (cursor + 1 < lines.length && lines[cursor] == '+') {
        final nextName = lines[cursor + 1];
        if (!_isPotentialLooseExerciseName(nextName)) {
          break;
        }
        names.add(nextName);
        cursor += 2;
        while (cursor < lines.length && _isObservation(lines[cursor])) {
          notes.add(_stripParentheses(lines[cursor]));
          cursor++;
        }
      }

      final series = <String>[];
      while (cursor < lines.length && series.length < names.length) {
        final candidate = lines[cursor];
        if (candidate == '+') {
          cursor++;
          continue;
        }
        if (!_isStandaloneSeries(candidate)) {
          break;
        }
        series.add(candidate);
        cursor++;
      }

      final repetitions = <String>[];
      while (cursor < lines.length && repetitions.length < names.length) {
        final candidate = lines[cursor];
        if (candidate == '+') {
          cursor++;
          continue;
        }
        if (!_isLooseRepetitionValue(candidate)) {
          break;
        }
        repetitions.add(candidate);
        cursor++;
      }

      if (series.isEmpty || repetitions.isEmpty) {
        final compact = _parseLooseInlineColumns(line);
        if (compact != null) {
          blocks.add(
            PersonalImportParagraph(
              '${compact.name} - ${compact.series}x${compact.repetitions}${compact.rest.isEmpty ? '' : ' - ${compact.rest}'}${compact.note.isEmpty ? '' : ' - ${compact.note}'}',
            ),
          );
        }
        index++;
        continue;
      }

      final nameCellParts = <String>[];
      for (var nameIndex = 0; nameIndex < names.length; nameIndex++) {
        if (nameIndex > 0) {
          nameCellParts.add('+');
        }
        nameCellParts.add(names[nameIndex]);
        if (notes.isNotEmpty) {
          final note = notes.length == names.length
              ? notes[nameIndex]
              : notes.join(' ');
          nameCellParts.add('($note)');
        }
      }

      blocks.add(
        PersonalImportTable(<List<String>>[
          <String>[
            nameCellParts.join('\n'),
            series.join('\n+\n'),
            repetitions.join('\n+\n'),
          ],
        ]),
      );
      index = cursor;
    }

    return blocks;
  }

  static List<String> _splitDelimitedColumns(
    String rawLine, {
    bool preserveEmpty = false,
  }) {
    final commaCount = ','.allMatches(rawLine).length;
    final delimiter = rawLine.contains('\t')
        ? '\t'
        : rawLine.contains(';')
        ? ';'
        : commaCount >= 2
        ? ','
        : null;
    if (delimiter == null) {
      return const <String>[];
    }

    final columns = rawLine
        .split(delimiter)
        .map((column) => column.trim().replaceAll(RegExp(r'^"|"$'), ''))
        .toList(growable: false);
    return preserveEmpty
        ? columns
        : columns.where((column) => column.isNotEmpty).toList(growable: false);
  }

  bool _shouldKeepLooseParagraph(String line) {
    return _looksLikeProgramTitle(line) ||
        _parseRoutineHeading(line) != null ||
        _isCardioIntro(line) ||
        _isCardioInstruction(line);
  }

  bool _isPotentialLooseExerciseName(String line) {
    final normalized = line.toLowerCase().trim();
    if (_isStandaloneSeries(normalized) ||
        _isLooseRepetitionValue(normalized)) {
      return false;
    }
    if (!RegExp(r'[a-záàâãäéèêëíìîïóòôõöúùûüç]').hasMatch(normalized)) {
      return false;
    }
    if (_shouldKeepLooseParagraph(line) ||
        _isRoutineMetadataLine(line) ||
        _isObservation(line) ||
        line == '+' ||
        normalized.contains('exercícios') ||
        normalized.contains('exercicios') ||
        normalized.contains('n° séries') ||
        normalized.contains('nº séries') ||
        normalized.contains('repetições') ||
        normalized.contains('repeticoes') ||
        normalized.contains('consultoria') ||
        normalized.contains('exercícios anaeróbicos') ||
        normalized.contains('exercicios anaerobicos') ||
        normalized.startsWith('email') ||
        normalized.startsWith('whatsap') ||
        normalized.startsWith('whatsapp')) {
      return false;
    }
    return true;
  }

  static bool _isStandaloneSeries(String value) {
    return RegExp(r'^0?([1-9]|1[0-9]|20)$').hasMatch(value.trim());
  }

  static bool _isLooseRepetitionValue(String value) {
    final normalized = value.trim();
    return RegExp(
      r'^(?:\d{1,3}(?:\s*(?:[Aa]|-|–|—|\+)\s*\d{1,3})*(?:\s*\(?\s*(?:passos|s|seg|min)\s*\)?)?|m[aá]x\.?)$',
      caseSensitive: false,
    ).hasMatch(normalized);
  }

  _InlineExercise? _parseLooseInlineColumns(String line) {
    final match = RegExp(
      r'^(.+?)\s+(\d{1,2})\s+(\d{1,3}(?:\s*(?:[Aa]|-|–|—)\s*\d{1,3})*)(?:\s+(\d+\s*(?:s|seg|min)))?(?:\s+(.*))?$',
      caseSensitive: false,
    ).firstMatch(line.trim());
    if (match == null) {
      return null;
    }
    return _InlineExercise(
      name: match.group(1)!.trim(),
      series: match.group(2)!.trim(),
      repetitions: match.group(3)!.trim(),
      rest: match.group(4)?.trim() ?? '',
      note: match.group(5)?.trim() ?? '',
    );
  }

  _InlineExercise? _parseCellsAsExercise(
    List<String> cells, {
    required String defaultRest,
  }) {
    if (cells.isEmpty) {
      return null;
    }
    final name = cells.first.trim();
    if (!_isPotentialLooseExerciseName(name)) {
      return null;
    }
    final second = cells.length > 1 ? cells[1].trim() : '';
    final third = cells.length > 2 ? cells[2].trim() : '';
    final fourth = cells.length > 3 ? cells[3].trim() : '';
    final remaining = cells.length > 4 ? cells.sublist(4).join(' • ') : '';
    final prescription = _normalizePrescription(
      seriesText: second,
      repetitionsText: third,
    );
    if (prescription.original.isEmpty) {
      return null;
    }
    final rest = _looksLikeRest(fourth) ? fourth : defaultRest;
    final noteParts = <String>[
      if (fourth.isNotEmpty && !_looksLikeRest(fourth)) fourth,
      if (remaining.isNotEmpty) remaining,
    ];
    final note = noteParts.join(' • ');
    return _InlineExercise(
      name: name,
      series: prescription.seriesText,
      repetitions: prescription.repetitions,
      rest: rest,
      note: note,
      originalPrescription: prescription.original,
      prescriptionKind: prescription.kind,
      techniques: _extractTechniques(note),
      intensity: _extractIntensity(note),
      cadence: _extractCadence(note),
    );
  }

  _NormalizedPrescription _normalizePrescription({
    required String seriesText,
    required String repetitionsText,
  }) {
    final cleanSeries = seriesText.trim().replaceAll('×', 'x');
    final cleanReps = repetitionsText.trim().replaceAll('×', 'x');
    final combined = cleanReps.isEmpty
        ? cleanSeries
        : '$cleanSeries x $cleanReps';
    if (combined.trim().isEmpty) {
      return const _NormalizedPrescription(
        seriesText: '3',
        repetitions: '',
        original: '',
        kind: PersonalImportPrescriptionKind.repetitions,
      );
    }

    if (cleanReps.isNotEmpty && RegExp(r'^\d+$').hasMatch(cleanSeries)) {
      final repetitions = _cleanRepetitions(cleanReps);
      return _NormalizedPrescription(
        seriesText: cleanSeries,
        repetitions: repetitions,
        original: '$cleanSeries x $cleanReps',
        kind: _prescriptionKindFor(repetitions),
      );
    }

    final groupMatches = RegExp(
      r'(\d{1,2})\s*x\s*(m[aá]x\.?|\d{1,3}(?:\s*(?:a|-|–|—|\+)\s*\d{1,3})*)(?:\s*\(?\s*(passos|s|seg|min)\s*\)?)?',
      caseSensitive: false,
    ).allMatches(combined).toList(growable: false);

    if (groupMatches.isEmpty) {
      final series = _parseSeries(cleanSeries).toString();
      final repetitions = _cleanRepetitions(cleanReps);
      return _NormalizedPrescription(
        seriesText: series,
        repetitions: repetitions,
        original: cleanReps.isEmpty ? cleanSeries : '$cleanSeries x $cleanReps',
        kind: _prescriptionKindFor(repetitions),
      );
    }

    final totalSeries = groupMatches.fold<int>(
      0,
      (total, match) => total + (int.tryParse(match.group(1) ?? '') ?? 0),
    );
    final rawTargets = groupMatches
        .map((match) => match.group(2)!.trim())
        .toList(growable: false);
    final units = groupMatches
        .map((match) => (match.group(3) ?? '').toLowerCase())
        .where((unit) => unit.isNotEmpty)
        .toSet();
    final original = combined.trim();

    PersonalImportPrescriptionKind kind;
    if (units.contains('passos')) {
      kind = PersonalImportPrescriptionKind.steps;
    } else if (units.any(
      (unit) => unit == 's' || unit == 'seg' || unit == 'min',
    )) {
      kind = PersonalImportPrescriptionKind.time;
    } else if (rawTargets.any(
      (target) => _normalizeForDetection(target).contains('max'),
    )) {
      kind = PersonalImportPrescriptionKind.maximum;
    } else if (groupMatches.length > 1) {
      kind = PersonalImportPrescriptionKind.perSet;
    } else if (rawTargets.single.contains('+')) {
      kind = PersonalImportPrescriptionKind.mixed;
    } else {
      kind = PersonalImportPrescriptionKind.repetitions;
    }

    String repetitions;
    if (kind == PersonalImportPrescriptionKind.perSet) {
      final values = rawTargets
          .expand((target) => RegExp(r'\d+').allMatches(target))
          .map((match) => int.parse(match.group(0)!))
          .toList(growable: false);
      if (values.isEmpty) {
        repetitions = rawTargets.first;
      } else {
        final minimum = values.reduce((a, b) => a < b ? a : b);
        final maximum = values.reduce((a, b) => a > b ? a : b);
        repetitions = minimum == maximum ? '$minimum' : '$minimum-$maximum';
      }
    } else {
      repetitions = rawTargets.first;
      if (units.isNotEmpty) {
        repetitions = '$repetitions ${units.first}';
      }
    }

    return _NormalizedPrescription(
      seriesText: totalSeries <= 0 ? '3' : '$totalSeries',
      repetitions: _cleanRepetitions(repetitions),
      original: original,
      kind: kind,
    );
  }

  static PersonalImportPrescriptionKind _prescriptionKindFor(String value) {
    final normalized = _normalizeForDetection(value);
    if (normalized.contains('passos')) {
      return PersonalImportPrescriptionKind.steps;
    }
    if (RegExp(r'\b(?:s|seg|min)\b').hasMatch(normalized)) {
      return PersonalImportPrescriptionKind.time;
    }
    if (normalized.contains('max')) {
      return PersonalImportPrescriptionKind.maximum;
    }
    if (normalized.contains('+')) {
      return PersonalImportPrescriptionKind.mixed;
    }
    return PersonalImportPrescriptionKind.repetitions;
  }

  static List<String> _extractAlternatives(String rawName) {
    final source = rawName.trim();
    final hasCompactSlashAlternative =
        source.contains('/') &&
        !RegExp(r'\b[cs]/', caseSensitive: false).hasMatch(source) &&
        !RegExp(r'\d\s*/\s*\d').hasMatch(source);
    final separator = source.contains('\\')
        ? RegExp(r'\s*\\\s*')
        : hasCompactSlashAlternative
        ? RegExp(r'\s*/\s*')
        : RegExp(r'\s+ou\s+', caseSensitive: false);
    final parts = source
        .split(separator)
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    return parts.length > 1 ? parts : <String>[source];
  }

  static List<String> _extractTechniques(String text) {
    final normalized = _normalizeForDetection(text);
    final techniques = <String>[];
    void addIf(String needle, String label) {
      if (normalized.contains(needle) && !techniques.contains(label)) {
        techniques.add(label);
      }
    }

    addIf('drop set', 'Drop-set');
    addIf('drop-set', 'Drop-set');
    addIf('drop na', 'Drop-set');
    if (RegExp(r'\bdrop\b').hasMatch(normalized) &&
        !techniques.contains('Drop-set')) {
      techniques.add('Drop-set');
    }
    addIf('rest pause', 'Rest-pause');
    addIf('dead stop', 'Dead stop');
    addIf('falha concentrica', 'Falha concêntrica');
    addIf('falha parcial', 'Falha parcial');
    addIf('falha excentrica', 'Falha excêntrica');
    addIf('isometria', 'Isometria');
    addIf('piramide', 'Pirâmide');
    addIf('bi set', 'Bi-set');
    addIf('biset', 'Bi-set');
    addIf('tri set', 'Tri-set');
    addIf('triset', 'Tri-set');
    addIf('movimento controlado', 'Movimento controlado');
    addIf('progressao de cargas', 'Progressão de cargas');
    addIf('pause no pico', 'Pausa no pico de contração');
    addIf('alongamento apos cada serie', 'Alongamento após cada série');
    return techniques;
  }

  static String _extractIntensity(String text) {
    final rir = RegExp(
      r'\bRIR\s*\d+(?:\s*[-–—]\s*\d+)?',
      caseSensitive: false,
    ).firstMatch(text);
    if (rir != null) {
      return rir.group(0)!;
    }
    final rpe = RegExp(
      r'\bRPE\s*\d+(?:[.,]\d+)?',
      caseSensitive: false,
    ).firstMatch(text);
    if (rpe != null) {
      return rpe.group(0)!;
    }
    final percent = RegExp(r'\b\d{1,3}\s*%').firstMatch(text);
    return percent?.group(0) ?? '';
  }

  static String _extractCadence(String text) {
    final explicit = RegExp(
      r'(?:cad[eê]ncia|vel\.?\s*c/e)\s*[:=-]?\s*([0-9]+\s*(?:por|/|-|:)\s*[0-9]+(?:\s*(?:/|-|:)\s*[0-9]+)*)',
      caseSensitive: false,
    ).firstMatch(text);
    if (explicit != null) {
      return explicit.group(1)!.trim();
    }
    final simple = RegExp(
      r'\b\d+\s+por\s+\d+\b',
      caseSensitive: false,
    ).firstMatch(text);
    return simple?.group(0) ?? '';
  }

  static String _findDefaultSeriesRest(List<String> lines) {
    for (final line in lines) {
      final normalized = _normalizeForDetection(line);
      if (normalized.contains('entre') &&
          normalized.contains('serie') &&
          !normalized.contains('exercicio')) {
        final value = RegExp(
          r'(\d+(?:\s*(?:a|-|–|—)\s*\d+)?)\s*(s|seg|min)',
          caseSensitive: false,
        ).firstMatch(line);
        if (value != null) {
          return '${value.group(1)} ${value.group(2)}';
        }
      }
    }
    return '';
  }

  static String _findBetweenExercisesRest(List<String> lines) {
    for (final line in lines) {
      final normalized = _normalizeForDetection(line);
      if (normalized.contains('entre') && normalized.contains('exercicio')) {
        final value = RegExp(
          r'(\d+(?:\s*(?:a|-|–|—)\s*\d+)?)\s*(s|seg|min)',
          caseSensitive: false,
        ).firstMatch(line);
        if (value != null) {
          return '${value.group(1)} ${value.group(2)}';
        }
      }
    }
    return '';
  }

  static String _extractSectionFocus(List<String> lines) {
    for (final rawLine in lines.take(5)) {
      final line = rawLine.trim();
      if (line.isEmpty ||
          _isTextHeader(line) ||
          _isRoutineMetadataLine(line) ||
          _isCardioOnlyLine(line) ||
          RegExp(r'\d+\s*[x×]').hasMatch(line)) {
        continue;
      }
      final normalized = _normalizeForDetection(line);
      final hasMuscle = <String>[
        'peito',
        'costas',
        'ombro',
        'triceps',
        'biceps',
        'perna',
        'coxa',
        'gluteo',
        'panturrilha',
        'abdomen',
        'trapezio',
        'full body',
        'corpo inteiro',
        'cardio',
      ].any(normalized.contains);
      if (hasMuscle && line.length <= 100) {
        return _sentenceCase(line);
      }
    }
    return '';
  }

  static bool _looksLikeFocusLine(String line, String focus) {
    if (focus.trim().isEmpty) {
      return false;
    }
    return _normalizeForDetection(line) == _normalizeForDetection(focus);
  }

  static bool _isRoutineMetadataLine(String line) {
    final normalized = _normalizeForDetection(line);
    return normalized.startsWith('descanso') ||
        normalized.startsWith('intervalo') ||
        normalized.contains('entre as series') ||
        normalized.contains('entre os exercicios') ||
        normalized.startsWith('treinador') ||
        normalized.startsWith('prof ') ||
        normalized.startsWith('para assistir') ||
        normalized.startsWith('clique no play') ||
        normalized == 'peso rep peso rep peso rep' ||
        RegExp(r'^(x\s*)+$').hasMatch(normalized) ||
        normalized.startsWith('observacoes');
  }

  static bool _isCardioOnlyLine(String line) {
    final normalized = _normalizeForDetection(line);
    final marker = <String>[
      'cardio',
      'aerobico',
      'esteira',
      'bicicleta',
      'bike',
      'eliptico',
      'corrida',
      'caminhada',
      'escada',
      'degrau',
      'aquecimento',
    ].any(normalized.contains);
    if (!marker) {
      return false;
    }
    return normalized.contains('min') ||
        normalized.contains('bpm') ||
        normalized.contains('velocidade') ||
        normalized.contains('inclina') ||
        normalized.contains('apenas cardio') ||
        normalized.contains('bloco');
  }

  static bool _looksLikeRest(String value) {
    return RegExp(
      r'^\d+(?:\s*(?:a|-|–|—)\s*\d+)?\s*(?:s|seg|min)$',
      caseSensitive: false,
    ).hasMatch(value.trim());
  }

  static String _normalizeForDetection(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9%/+\\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _slug(String value) {
    return _normalizeForDetection(value).replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  static String _cellAt(List<String> cells, int index) {
    if (index < 0 || index >= cells.length) {
      return '';
    }
    return cells[index];
  }

  void _parseTableRows({
    required List<List<String>> rows,
    required _MutableRoutine routine,
    required List<PersonalImportIssue> issues,
  }) {
    if (rows.isEmpty) {
      return;
    }
    final headerRowIndex = rows.indexWhere(_isHeaderRow);
    final header = headerRowIndex >= 0
        ? _TableColumnMap.fromHeader(rows[headerRowIndex])
        : const _TableColumnMap();
    final dataRows = headerRowIndex >= 0 ? rows.skip(headerRowIndex + 1) : rows;

    for (final row in dataRows) {
      if (row.isEmpty || _isHeaderRow(row)) {
        continue;
      }

      final rawExerciseCell = header.exerciseIndex == null
          ? ''
          : _cellAt(row, header.exerciseIndex!);
      if (header.exerciseIndex != null && !rawExerciseCell.contains('\n')) {
        final rawName = rawExerciseCell.trim();
        if (rawName.isEmpty || !_isPotentialLooseExerciseName(rawName)) {
          continue;
        }
        final series = _cellAt(row, header.seriesIndex ?? -1).trim();
        final repetitions = _cellAt(row, header.repetitionsIndex ?? -1).trim();
        final rest = _cellAt(row, header.restIndex ?? -1).trim();
        final observation = _cellAt(row, header.notesIndex ?? -1).trim();
        final technique = _cellAt(row, header.techniqueIndex ?? -1).trim();
        final intensity = _cellAt(row, header.intensityIndex ?? -1).trim();
        final cadence = _cellAt(row, header.cadenceIndex ?? -1).trim();
        final muscle = _cellAt(row, header.muscleIndex ?? -1).trim();

        final cardioDraft = _parseCardioText(
          '$rawName $series $repetitions $observation',
          id: 'import_cardio_${_slug(routine.name)}_${routine.cardio.length}',
        );
        if (cardioDraft != null) {
          routine.cardio.add(cardioDraft);
          continue;
        }

        final mergedSeries = series.isNotEmpty ? series : repetitions;
        final parsed = _normalizePrescription(
          seriesText: mergedSeries,
          repetitionsText: series.isNotEmpty ? repetitions : '',
        );
        final noteParts = <String>[
          if (observation.isNotEmpty) observation,
          if (muscle.isNotEmpty) 'Grupo informado: $muscle',
        ];
        routine.exercises.add(
          _buildExerciseDraft(
            rawName: rawName,
            seriesText: parsed.seriesText,
            repetitions: parsed.repetitions,
            rest: rest,
            note: noteParts.join(' • '),
            routineName: routine.name,
            issues: issues,
            originalPrescription: parsed.original,
            prescriptionKind: parsed.kind,
            techniques: <String>{
              ..._extractTechniques('$technique $observation'),
              if (technique.isNotEmpty) technique,
            }.toList(),
            intensity: intensity,
            cadence: cadence,
          ),
        );
        continue;
      }

      final fallbackCardio = _parseCardioText(
        row.join(' '),
        id: 'import_cardio_${_slug(routine.name)}_${routine.cardio.length}',
      );
      if (fallbackCardio != null) {
        routine.cardio.add(fallbackCardio);
        continue;
      }

      final names = _splitCellParts(row.firstOrNull ?? '')
          .where((part) => !_isObservation(part) && part != '+')
          .toList(growable: false);
      final notes = _splitCellParts(
        row.firstOrNull ?? '',
      ).where(_isObservation).map(_stripParentheses).toList(growable: false);
      final series = row.length > 1
          ? _splitCellParts(row[1]).where((part) => part != '+').toList()
          : const <String>[];
      final repetitions = row.length > 2
          ? _splitCellParts(row[2]).where((part) => part != '+').toList()
          : const <String>[];

      if (names.isEmpty) {
        continue;
      }

      for (var index = 0; index < names.length; index++) {
        final seriesText = _valueAtOrLast(series, index, fallback: '3');
        final repsText = _valueAtOrLast(repetitions, index, fallback: '10-12');
        final note = notes.isEmpty
            ? ''
            : notes.length == names.length
            ? notes[index]
            : notes.join(' ');
        final prescription = _normalizePrescription(
          seriesText: seriesText,
          repetitionsText: repsText,
        );

        routine.exercises.add(
          _buildExerciseDraft(
            rawName: names[index],
            seriesText: prescription.seriesText,
            repetitions: prescription.repetitions,
            rest: '',
            note: note,
            isSupersetLead: names.length > 1 && index < names.length - 1,
            routineName: routine.name,
            issues: issues,
            originalPrescription: prescription.original,
            prescriptionKind: prescription.kind,
          ),
        );
      }
    }
  }

  PersonalImportExerciseDraft _buildExerciseDraft({
    required String rawName,
    required String seriesText,
    required String repetitions,
    required String rest,
    required String note,
    required String routineName,
    required List<PersonalImportIssue> issues,
    bool isSupersetLead = false,
    String originalPrescription = '',
    PersonalImportPrescriptionKind prescriptionKind =
        PersonalImportPrescriptionKind.repetitions,
    List<String> techniques = const <String>[],
    String intensity = '',
    String cadence = '',
  }) {
    final alternatives = _extractAlternatives(rawName);
    final primaryName = alternatives.isEmpty
        ? rawName.trim()
        : alternatives.first;
    final seriesCount = _parseSeries(seriesText);
    final cleanedRepetitions = _cleanRepetitions(repetitions);
    final match = _matcher.match(primaryName);
    final repValues = RegExp(r'\d+')
        .allMatches(cleanedRepetitions)
        .map((item) => int.parse(item.group(0)!))
        .toList(growable: false);
    final detectedTechniques = <String>{
      ...techniques,
      ..._extractTechniques('$rawName $note $originalPrescription'),
    }.toList(growable: false);
    final detectedIntensity = intensity.trim().isNotEmpty
        ? intensity.trim()
        : _extractIntensity('$note $originalPrescription');
    final detectedCadence = cadence.trim().isNotEmpty
        ? cadence.trim()
        : _extractCadence('$note $originalPrescription');

    var needsReview = match.needsReview || alternatives.length > 1;

    if (repValues.length > 2 &&
        prescriptionKind == PersonalImportPrescriptionKind.repetitions &&
        !cleanedRepetitions.toLowerCase().contains(' a ') &&
        repValues.length != seriesCount) {
      needsReview = true;
      issues.add(
        PersonalImportIssue(
          message:
              '$primaryName informa $seriesCount séries, mas possui ${repValues.length} valores de repetição.',
          routineName: routineName,
          exerciseName: primaryName,
        ),
      );
    }

    if (alternatives.length > 1) {
      issues.add(
        PersonalImportIssue(
          message:
              '“$rawName” parece oferecer alternativas. Confirme qual exercício será usado.',
          routineName: routineName,
          exerciseName: primaryName,
        ),
      );
    }

    if (prescriptionKind != PersonalImportPrescriptionKind.repetitions) {
      needsReview = true;
      issues.add(
        PersonalImportIssue(
          message:
              '“$primaryName” usa ${prescriptionKind.label.toLowerCase()}: ${originalPrescription.isEmpty ? '$seriesText x $repetitions' : originalPrescription}.',
          severity: PersonalImportIssueSeverity.info,
          routineName: routineName,
          exerciseName: primaryName,
        ),
      );
    }

    if (match.selectedExerciseId == null) {
      issues.add(
        PersonalImportIssue(
          message:
              '“$primaryName” não foi associado automaticamente à biblioteca.',
          routineName: routineName,
          exerciseName: primaryName,
        ),
      );
    } else if (match.needsReview) {
      final selected = exerciseDatabase
          .where((exercise) => exercise.id == match.selectedExerciseId)
          .firstOrNull;
      issues.add(
        PersonalImportIssue(
          message:
              'Confirme se “$primaryName” corresponde a “${selected?.name ?? primaryName}”.',
          severity: PersonalImportIssueSeverity.info,
          routineName: routineName,
          exerciseName: primaryName,
        ),
      );
    }

    return PersonalImportExerciseDraft(
      rawName: primaryName,
      seriesCount: seriesCount,
      repetitions: cleanedRepetitions,
      rest: rest.trim(),
      note: note.trim(),
      selectedExerciseId: match.selectedExerciseId,
      suggestedExerciseIds: match.suggestedExerciseIds,
      isSupersetLead: isSupersetLead,
      needsReview: needsReview,
      originalPrescription: originalPrescription.trim(),
      prescriptionKind: prescriptionKind,
      techniques: detectedTechniques,
      alternatives: alternatives,
      intensity: detectedIntensity,
      cadence: detectedCadence,
    );
  }

  RoutineCardio? _parseGeneralCardio(
    String? cardioText,
    List<PersonalImportIssue> issues,
  ) {
    if (cardioText == null || cardioText.trim().isEmpty) {
      return null;
    }
    final cardio = _parseCardioText(cardioText, id: 'import_general_cardio');
    if (cardio == null) {
      issues.add(
        const PersonalImportIssue(
          message:
              'Foi encontrada uma orientação de cardio, mas modalidade ou duração precisam ser revisadas.',
        ),
      );
    }
    return cardio;
  }

  RoutineCardio? _parseCardioText(String text, {required String id}) {
    final normalized = _normalizeForDetection(text);
    final hasCardioMarker = <String>[
      'cardio',
      'aerobico',
      'esteira',
      'bicicleta',
      'bike',
      'eliptico',
      'corrida',
      'caminhada',
      'escada',
      'remo',
      'aquecimento',
    ].any(normalized.contains);
    if (!hasCardioMarker) {
      return null;
    }

    final durationMatches = RegExp(
      r'(\d+)\s*(?:-|a)?\s*\d*\s*min',
      caseSensitive: false,
    ).allMatches(text).toList(growable: false);
    final isIntervalStructure =
        normalized.contains('bloco') ||
        normalized.contains('sequencia') ||
        normalized.contains('intervalado');
    var durationWasEstimated = false;
    var duration = durationMatches.isEmpty
        ? 0
        : int.tryParse(durationMatches.first.group(1) ?? '') ?? 0;
    if (isIntervalStructure) {
      final durationTokens = RegExp(
        r'(\d+(?:[.,]\d+)?)\s*(min|seg)',
        caseSensitive: false,
      ).allMatches(text).toList(growable: false);
      if (durationTokens.length > 1) {
        final totalSeconds = durationTokens.fold<double>(0, (total, match) {
          final value =
              double.tryParse((match.group(1) ?? '').replaceAll(',', '.')) ?? 0;
          return total +
              (match.group(2)!.toLowerCase() == 'min' ? value * 60 : value);
        });
        if (totalSeconds > 0) {
          duration = ((totalSeconds + 59) ~/ 60).toInt();
          durationWasEstimated = true;
        }
      }
    }
    if (duration <= 0 && normalized.contains('apenas cardio')) {
      duration = 30;
    }
    if (duration <= 0) {
      return null;
    }

    final modalities = <CardioModality>[
      if (normalized.contains('esteira')) CardioModality.treadmill,
      if (normalized.contains('bicicleta') || normalized.contains('bike'))
        CardioModality.stationaryBike,
      if (normalized.contains('eliptico')) CardioModality.elliptical,
      if (normalized.contains('escada') || normalized.contains('degrau'))
        CardioModality.stairClimber,
      if (normalized.contains('remo')) CardioModality.rowing,
      if (normalized.contains('corrida')) CardioModality.running,
      if (normalized.contains('caminhada')) CardioModality.walking,
    ];
    final uniqueModalities = modalities.toSet().toList(growable: false);
    final modality = uniqueModalities.length == 1
        ? uniqueModalities.first
        : CardioModality.other;
    final notes = <String>[];
    if (uniqueModalities.length > 1) {
      notes.add(
        'Escolher entre ${_joinWithOr(uniqueModalities.map((item) => item.label.toLowerCase()).toList())}.',
      );
    }
    if (normalized.contains('antes') || normalized.contains('aquecimento')) {
      notes.add('Realizar antes da musculação.');
    } else if (normalized.contains('apos') ||
        normalized.contains('final do treino')) {
      notes.add('Realizar após a musculação.');
    } else if (normalized.contains('dia off') ||
        normalized.contains('sessao separada')) {
      notes.add('Realizar em sessão separada.');
    }
    final bpm = RegExp(
      r'(\d{2,3})\s*(?:a|-|–|—)\s*(\d{2,3})\s*bpm',
      caseSensitive: false,
    ).firstMatch(text);
    if (bpm != null) {
      notes.add(
        'Frequência cardíaca alvo: ${bpm.group(1)}–${bpm.group(2)} bpm.',
      );
    }
    final speed = RegExp(
      r'velocidade\s*(?:de\s*)?([0-9]+(?:[.,][0-9]+)?)',
      caseSensitive: false,
    ).firstMatch(text);
    if (speed != null) {
      notes.add('Velocidade informada: ${speed.group(1)}.');
    }
    final incline = RegExp(
      r'inclina[cç][aã]o\s*(?:de\s*)?([0-9]+(?:[.,][0-9]+)?\s*%)',
      caseSensitive: false,
    ).firstMatch(text);
    if (incline != null) {
      notes.add('Inclinação: ${incline.group(1)}.');
    }
    if (normalized.contains('leve a moderada')) {
      notes.add('Intensidade leve a moderada.');
    }
    if (isIntervalStructure) {
      if (durationWasEstimated) {
        notes.add(
          'Duração estimada a partir dos blocos; confirme o total antes de salvar.',
        );
      }
      notes.add(
        'Cardio intervalado: ${text.replaceAll(RegExp(r'\s+'), ' ').trim()}',
      );
    }

    return RoutineCardio(
      id: id,
      modality: modality,
      plannedDurationMinutes: duration,
      notes: notes.join(' ').trim(),
    );
  }

  RoutineCardio? _parseRoutineCardioFromLines(
    List<String> lines, {
    required String id,
    required String focus,
  }) {
    final relevant = <String>[];
    var collectingDetails = _normalizeForDetection(focus).contains('cardio');

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || _isTextHeader(line)) {
        continue;
      }
      if (_isCardioOnlyLine(line)) {
        collectingDetails = true;
        relevant.add(line);
        continue;
      }
      if (!collectingDetails) {
        continue;
      }
      if (_parseInlineExercise(line) != null &&
          !_normalizeForDetection(line).contains('velocidade')) {
        collectingDetails = false;
        continue;
      }
      final normalized = _normalizeForDetection(line);
      final isCardioDetail =
          normalized.startsWith('bloco') ||
          normalized.contains('sequencia') ||
          normalized.contains('velocidade') ||
          normalized.contains('inclina') ||
          normalized.contains('bpm') ||
          normalized.contains('descan') ||
          RegExp(r'\b\d+(?:[.,]\d+)?\s*(?:min|seg)\b').hasMatch(line);
      if (isCardioDetail) {
        relevant.add(line);
      }
    }

    if (relevant.isEmpty) {
      return null;
    }
    return _parseCardioText(relevant.join(' '), id: id);
  }

  _RoutineHeading? _parseRoutineHeading(String text) {
    final trimmed = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) {
      return null;
    }
    final normalized = _normalizeForDetection(trimmed);
    final optional = normalized.contains('opcional');

    final weekdayMatch = RegExp(
      r'^(SEGUNDA(?:-FEIRA)?|TER[CÇ]A(?:-FEIRA)?|QUARTA(?:-FEIRA)?|QUINTA(?:-FEIRA)?|SEXTA(?:-FEIRA)?|S[ÁA]BADO|DOMINGO)(?:\s*\([^)]*\))?(?:\s*[-–—:]+\s*(.*))?$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (weekdayMatch != null) {
      final day = _sentenceCase(weekdayMatch.group(1)!);
      final focus = (weekdayMatch.group(2) ?? '').trim();
      final isRestDay =
          _normalizeForDetection(focus).contains('descanso') ||
          _normalizeForDetection(focus).contains('off');
      return _RoutineHeading(
        name: day,
        focus: isRestDay ? '' : _sentenceCase(focus),
        scheduleLabel: day,
        isOptional: optional,
        isRestDay: isRestDay,
      );
    }

    final match = RegExp(
      r'^(TREINO|S[ÉE]RIE|DIA)\s*([A-Z0-9]+)(?:\s*[-–—:]\s*(.*)|\s+(.+))?$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (match == null) {
      return null;
    }

    final type = _sentenceCase(match.group(1)!);
    final identifier = match.group(2)!.toUpperCase();
    final rawFocus = (match.group(3) ?? match.group(4) ?? '').trim();
    final weekdayInFocus = RegExp(
      r'\b(segunda(?:-feira)?|ter[cç]a(?:-feira)?|quarta(?:-feira)?|quinta(?:-feira)?|sexta(?:-feira)?|s[áa]bado|domingo)\b',
      caseSensitive: false,
    ).firstMatch(rawFocus);
    final scheduleLabel = weekdayInFocus == null
        ? (type.toLowerCase() == 'dia' ? 'Dia $identifier' : '')
        : _sentenceCase(weekdayInFocus.group(1)!);
    final cleanedFocus = weekdayInFocus == null
        ? rawFocus
        : rawFocus
              .replaceFirst(weekdayInFocus.group(0)!, '')
              .replaceAll(RegExp(r'^[\s()\-–—:]+|[\s()\-–—:]+$'), '')
              .trim();
    final isRestDay =
        _normalizeForDetection(cleanedFocus).contains('descanso') ||
        _normalizeForDetection(cleanedFocus) == 'off';
    return _RoutineHeading(
      name: '$type $identifier',
      focus: isRestDay ? '' : _sentenceCase(cleanedFocus),
      scheduleLabel: scheduleLabel,
      isOptional: optional,
      isRestDay: isRestDay,
    );
  }

  _InlineExercise? _parseInlineExercise(String line) {
    final normalized = line.replaceFirst(RegExp(r'^[-•]\s*'), '').trim();
    if (normalized.isEmpty || _isCardioOnlyLine(normalized)) {
      return null;
    }

    final prescriptionPattern = RegExp(
      r'\d{1,2}\s*[x×]\s*(?:m[aá]x\.?|\d{1,3}(?:\s*(?:a|-|–|—)\s*\d{1,3})*)(?:\s*\(?\s*(?:passos|s|seg|min)\s*\)?)?',
      caseSensitive: false,
    );
    final prescriptionMatches = prescriptionPattern
        .allMatches(normalized)
        .toList(growable: false);

    // Linhas periodizadas trazem várias prescrições lado a lado, por exemplo:
    // "Floor Press 3x8a12 4x8a12 ... 6x5a9". O padrão simples abaixo
    // poderia interpretar a última semana como a prescrição ativa e incorporar
    // as semanas anteriores ao nome do exercício. Quando há mais de uma
    // prescrição, deixamos o fluxo avançado escolher a primeira semana ou
    // somar os blocos separados por barra, conforme o formato original.
    if (prescriptionMatches.length <= 1) {
      final commonPattern = RegExp(
        r'^(.+?)\s*(?:[-|:]\s*)?(\d+)\s*(?:x|s[eé]ries?(?:\s+de)?)\s*([0-9]+(?:\s*(?:a|–|—|-)\s*[0-9]+)*)\s*(?:[-|,]\s*(\d+\s*(?:s|seg|min)))?(?:\s*[-|,]\s*(.*))?$',
        caseSensitive: false,
      );
      final commonMatch = commonPattern.firstMatch(normalized);
      if (commonMatch != null) {
        final prescription = _normalizePrescription(
          seriesText: commonMatch.group(2)!,
          repetitionsText: commonMatch.group(3)!,
        );
        final trailingNote = commonMatch.group(5)?.trim() ?? '';
        return _InlineExercise(
          name: commonMatch.group(1)!.trim(),
          series: prescription.seriesText,
          repetitions: prescription.repetitions,
          rest: commonMatch.group(4)?.trim() ?? '',
          note: trailingNote,
          originalPrescription: prescription.original,
          prescriptionKind: prescription.kind,
          techniques: _extractTechniques(trailingNote),
          intensity: _extractIntensity(trailingNote),
          cadence: _extractCadence(trailingNote),
        );
      }
    }

    if (prescriptionMatches.isEmpty) {
      return null;
    }
    final firstMatch = prescriptionMatches.first;
    final name = normalized.substring(0, firstMatch.start).trim();
    if (!_isPotentialLooseExerciseName(name)) {
      return null;
    }
    final allPrescriptions = prescriptionMatches
        .map((match) => match.group(0)!.trim())
        .toList(growable: false);
    final prescriptionSpan = normalized.substring(
      prescriptionMatches.first.start,
      prescriptionMatches.last.end,
    );
    final isPerSetSequence = prescriptionSpan.contains('/');
    final activePrescription = _normalizePrescription(
      seriesText: isPerSetSequence
          ? allPrescriptions.join(' / ')
          : allPrescriptions.first,
      repetitionsText: '',
    );
    final trailing = normalized.substring(prescriptionMatches.last.end).trim();
    final restMatch = RegExp(
      r'\b\d+\s*(?:s|seg|min)\b',
      caseSensitive: false,
    ).firstMatch(trailing);
    final noteParts = <String>[
      if (allPrescriptions.length > 1)
        'Progressão completa: ${allPrescriptions.join(' | ')}',
      if (trailing.isNotEmpty) trailing,
    ];
    return _InlineExercise(
      name: name,
      series: activePrescription.seriesText,
      repetitions: activePrescription.repetitions,
      rest: restMatch?.group(0) ?? '',
      note: noteParts.join(' • '),
      originalPrescription: allPrescriptions.join(' | '),
      prescriptionKind: allPrescriptions.length > 1
          ? PersonalImportPrescriptionKind.perSet
          : activePrescription.kind,
      techniques: _extractTechniques(trailing),
      intensity: _extractIntensity(trailing),
      cadence: _extractCadence(trailing),
    );
  }

  static bool _looksLikeProgramTitle(String text) {
    final normalized = _normalizeForDetection(text);
    if (normalized == 'treino da semana' ||
        normalized.startsWith('plano de treino') ||
        normalized.startsWith('planejamento de') ||
        normalized.startsWith('planner de treino') ||
        normalized.startsWith('planilha de treino') ||
        normalized.startsWith('prescricao do treino')) {
      return true;
    }
    final upper = text.toUpperCase();
    return upper.startsWith('TREINO ') &&
        RegExp(
          r'JULHO|JANEIRO|FEVEREIRO|MARÇO|ABRIL|MAIO|JUNHO|AGOSTO|SETEMBRO|OUTUBRO|NOVEMBRO|DEZEMBRO|20\d{2}',
        ).hasMatch(upper) &&
        _parseStaticRoutineHeading(text) == null;
  }

  static _RoutineHeading? _parseStaticRoutineHeading(String text) {
    final match = RegExp(
      r'^TREINO\s+([A-Z])\s*[-–—:]\s*(.+)$',
      caseSensitive: false,
    ).firstMatch(text.trim());
    if (match == null) {
      return null;
    }
    return _RoutineHeading(
      name: 'Treino ${match.group(1)!.toUpperCase()}',
      focus: match.group(2)!.trim(),
    );
  }

  static String _cleanProgramName(String value) {
    return value
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceFirst(RegExp(r'^TREINO\s*', caseSensitive: false), 'Treino ')
        .trim();
  }

  static bool _isCardioIntro(String text) {
    final normalized = _normalizeForDetection(text);
    return normalized.contains('exercicios aerobicos') ||
        normalized.startsWith('cardio') ||
        normalized.contains('planilha de cardio');
  }

  static bool _isCardioInstruction(String text) {
    final normalized = _normalizeForDetection(text);
    return normalized.contains('minuto') ||
        normalized.contains(' min') ||
        normalized.contains('intensidade') ||
        normalized.contains('apos o treino') ||
        normalized.contains('velocidade') ||
        normalized.contains('inclinacao') ||
        normalized.contains('bpm') ||
        normalized.startsWith('bloco') ||
        normalized.contains('sequencia') ||
        normalized.contains('descans');
  }

  static bool _isHeaderRow(List<String> row) {
    final normalized = _normalizeForDetection(row.join(' '));
    return normalized.contains('exercicio') &&
        (normalized.contains('serie') ||
            normalized.contains('repet') ||
            normalized.contains('set'));
  }

  static List<String> _splitCellParts(String value) {
    return value
        .split(RegExp(r'\r?\n'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
  }

  static bool _isObservation(String value) {
    final trimmed = value.trim();
    return trimmed.startsWith('(') && trimmed.endsWith(')');
  }

  static String _stripParentheses(String value) {
    return value.replaceAll(RegExp(r'^\(|\)$'), '').trim();
  }

  static int _parseSeries(String value) {
    return int.tryParse(RegExp(r'\d+').firstMatch(value)?.group(0) ?? '') ?? 3;
  }

  static String _cleanRepetitions(String value) {
    return value
        .replaceAllMapped(
          RegExp(r'(\d)\s*[Aa]\s*(\d)'),
          (match) => '${match.group(1)} a ${match.group(2)}',
        )
        .replaceAll(RegExp(r'\s+[Aa]\s+'), ' a ')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('>', '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _valueAtOrLast(
    List<String> values,
    int index, {
    required String fallback,
  }) {
    if (values.isEmpty) {
      return fallback;
    }
    return index < values.length ? values[index] : values.last;
  }

  static String _joinWithOr(List<String> items) {
    if (items.length < 2) {
      return items.join();
    }
    return '${items.take(items.length - 1).join(', ')} ou ${items.last}';
  }

  static String _sentenceCase(String value) {
    if (value.isEmpty) {
      return value;
    }
    final lower = value.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }
}

class _RoutineSectionHeading {
  const _RoutineSectionHeading({required this.index, required this.heading});

  final int index;
  final _RoutineHeading heading;
}

class _ParsedExerciseGroup {
  const _ParsedExerciseGroup({
    required this.names,
    required this.notes,
    required this.series,
    required this.repetitions,
    required this.nextIndex,
  });

  final List<String> names;
  final List<String> notes;
  final List<String> series;
  final List<String> repetitions;
  final int nextIndex;
}

class _ParsedRoutineContent {
  const _ParsedRoutineContent({
    required this.exercises,
    required this.cardio,
    required this.notes,
  });

  final List<PersonalImportExerciseDraft> exercises;
  final List<RoutineCardio> cardio;
  final String notes;
}

class _MutableRoutine {
  _MutableRoutine({
    required this.name,
    required this.focus,
    this.scheduleLabel = '',
    this.isOptional = false,
  });

  final String name;
  final String focus;
  final String scheduleLabel;
  final String notes = '';
  final bool isOptional;
  final List<PersonalImportExerciseDraft> exercises =
      <PersonalImportExerciseDraft>[];
  final List<RoutineCardio> cardio = <RoutineCardio>[];

  PersonalImportRoutineDraft toDraft() {
    return PersonalImportRoutineDraft(
      name: name,
      focus: focus,
      exercises: exercises,
      cardio: cardio,
      scheduleLabel: scheduleLabel,
      notes: notes,
      isOptional: isOptional,
    );
  }
}

class _RoutineHeading {
  const _RoutineHeading({
    required this.name,
    required this.focus,
    this.scheduleLabel = '',
    this.isOptional = false,
    this.isRestDay = false,
  });

  final String name;
  final String focus;
  final String scheduleLabel;
  final bool isOptional;
  final bool isRestDay;
}

class _InlineExercise {
  const _InlineExercise({
    required this.name,
    required this.series,
    required this.repetitions,
    required this.rest,
    required this.note,
    this.originalPrescription = '',
    this.prescriptionKind = PersonalImportPrescriptionKind.repetitions,
    this.techniques = const <String>[],
    this.intensity = '',
    this.cadence = '',
  });

  final String name;
  final String series;
  final String repetitions;
  final String rest;
  final String note;
  final String originalPrescription;
  final PersonalImportPrescriptionKind prescriptionKind;
  final List<String> techniques;
  final String intensity;
  final String cadence;
}

class _NormalizedPrescription {
  const _NormalizedPrescription({
    required this.seriesText,
    required this.repetitions,
    required this.original,
    required this.kind,
  });

  final String seriesText;
  final String repetitions;
  final String original;
  final PersonalImportPrescriptionKind kind;
}

class _DocumentClassification {
  const _DocumentClassification({
    required this.kind,
    required this.message,
    this.periodizationWeeks = 0,
  });

  final PersonalImportDocumentKind kind;
  final String message;
  final int periodizationWeeks;
}

class _TableColumnMap {
  const _TableColumnMap({
    this.routineIndex,
    this.dayIndex,
    this.orderIndex,
    this.muscleIndex,
    this.exerciseIndex,
    this.seriesIndex,
    this.repetitionsIndex,
    this.restIndex,
    this.intensityIndex,
    this.notesIndex,
    this.techniqueIndex,
    this.cadenceIndex,
  });

  factory _TableColumnMap.fromHeader(List<String> cells) {
    int? find(bool Function(String value) predicate) {
      for (var index = 0; index < cells.length; index++) {
        final normalized = PersonalWorkoutImportParser._normalizeForDetection(
          cells[index],
        );
        if (predicate(normalized)) {
          return index;
        }
      }
      return null;
    }

    return _TableColumnMap(
      routineIndex: find(
        (value) =>
            value == 'treino' ||
            value == 'ficha' ||
            value == 'programa' ||
            value.startsWith('treino '),
      ),
      dayIndex: find(
        (value) => value == 'dia' || value.contains('dia sugerido'),
      ),
      orderIndex: find((value) => value == 'ordem' || value == 'ord'),
      muscleIndex: find(
        (value) =>
            value.contains('grupo muscular') ||
            value == 'g musc' ||
            value.contains('trabalha'),
      ),
      exerciseIndex: find((value) => value.contains('exercicio')),
      seriesIndex: find((value) {
        final isNumberedSeriesHeader = RegExp(
          r'^(?:(?:n|no|num|numero|qtd|quantidade)(?: de)? )?series?$',
        ).hasMatch(value);
        return isNumberedSeriesHeader ||
            value == 'set' ||
            value == 'sets' ||
            value.contains('series x reps') ||
            value.contains('serie x reps');
      }),
      repetitionsIndex: find(
        (value) =>
            value.contains('repet') ||
            value.contains('rept') ||
            value == 'reps' ||
            value == 'rep',
      ),
      restIndex: find(
        (value) =>
            value.contains('descanso') ||
            value.contains('intervalo') ||
            value == 'int',
      ),
      intensityIndex: find(
        (value) => value == 'intensidade' || value == 'rir' || value == 'rpe',
      ),
      notesIndex: find((value) => value == 'obs' || value.contains('observ')),
      techniqueIndex: find(
        (value) => value.contains('tecnica') || value.contains('metodologia'),
      ),
      cadenceIndex: find(
        (value) =>
            value.contains('cadencia') ||
            value.contains('vel c/e') ||
            value == 'tempo',
      ),
    );
  }

  final int? routineIndex;
  final int? dayIndex;
  final int? orderIndex;
  final int? muscleIndex;
  final int? exerciseIndex;
  final int? seriesIndex;
  final int? repetitionsIndex;
  final int? restIndex;
  final int? intensityIndex;
  final int? notesIndex;
  final int? techniqueIndex;
  final int? cadenceIndex;
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
