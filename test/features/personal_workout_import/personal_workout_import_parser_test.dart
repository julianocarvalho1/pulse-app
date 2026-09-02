import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/personal_workout_import/domain/models/personal_workout_import.dart';
import 'package:pulse/features/personal_workout_import/domain/services/personal_workout_import_parser.dart';
import 'package:pulse/features/workouts/domain/models/cardio_log.dart';

void main() {
  const parser = PersonalWorkoutImportParser();

  test('interpreta ficha DOCX com tabelas, bi-set e cardio geral', () {
    final draft = parser.parseDocument(
      sourceLabel: 'TREINO JULIANO.docx',
      blocks: <PersonalImportDocumentBlock>[
        const PersonalImportParagraph(
          'TREINO 1 - JULIANO DA SILVA - JULHO DE 2026',
        ),
        const PersonalImportParagraph(
          'EXERCÍCIOS AERÓBICOS: BICICLETA, ESTEIRA OU ELÍPTICO.',
        ),
        const PersonalImportParagraph(
          'Fazer por 45 minutos ou mais intercalando em intensidade leve a moderada, após o treino com pesos.',
        ),
        const PersonalImportParagraph(
          'TREINO A – PEITO, ESTÍMULO PARA OMBRO, TRÍCEPS E PANTURRILHA',
        ),
        PersonalImportTable(<List<String>>[
          <String>['EXERCÍCIOS', 'N° SÉRIES', 'N° REPETIÇÕES'],
          <String>[
            'SUPINO INCLINADO ARTICULADO\n(AS DUAS ÚLTIMAS SÉRIES COM FALHA PARCIAL)',
            '03',
            '15-12-10',
          ],
          <String>[
            'PULLEY TRÍCEPS BARRA\n+\nPULLEY TRÍCEPS TESTA COM BARRA',
            '03\n+\n03',
            '08 A 12\n+\n08 A 12',
          ],
          <String>['GÊMEOS MÁQUINA', '03', '08 A 12'],
        ]),
        const PersonalImportParagraph('TREINO C – COXA COMPLETA'),
        PersonalImportTable(<List<String>>[
          <String>['EXERCÍCIOS', 'N° SÉRIES', 'N° REPETIÇÕES'],
          <String>[
            'CADEIRA FLEXORA\n(AS DUAS ÚLTIMAS SÉRIES COM FALHA PARCIAL)',
            '03',
            '15-12-10-10',
          ],
        ]),
      ],
    );

    expect(draft.routines, hasLength(2));
    expect(draft.routines.first.exercises, hasLength(4));
    expect(draft.routines.first.exercises.first.selectedExerciseId, 'p5');
    expect(draft.routines.first.exercises[1].selectedExerciseId, 'tr1');
    expect(draft.routines.first.exercises[1].isSupersetLead, isTrue);
    expect(draft.routines.first.exercises[2].selectedExerciseId, 'tr4');
    expect(draft.generalCardio, isNotNull);
    expect(draft.generalCardio!.modality, CardioModality.other);
    expect(draft.generalCardio!.plannedDurationMinutes, 45);
    expect(draft.generalCardio!.notes, contains('após a musculação'));
    expect(
      draft.issues.any(
        (issue) => issue.message.contains('4 valores de repetição'),
      ),
      isTrue,
    );
  });

  test('interpreta texto livre em formato comum', () {
    final draft = parser.parseText(
      text: '''
Treino A - Peito e tríceps
Supino reto com barra - 4x8-12 - 60s
Tríceps na polia com corda - 3x10-12 - 45s
''',
    );

    expect(draft.routines, hasLength(1));
    expect(draft.routines.first.exercises, hasLength(2));
    expect(draft.routines.first.exercises.first.selectedExerciseId, 'p1');
    expect(draft.routines.first.exercises.first.seriesCount, 4);
    expect(draft.routines.first.exercises.first.repetitions, '8-12');
    expect(draft.routines.first.exercises.first.rest, '60s');
    expect(draft.routines.first.exercises[1].selectedExerciseId, 'tr2');
  });

  test('mantém exercício desconhecido como personalizado para revisão', () {
    final draft = parser.parseText(
      text: '''
Treino A - Corpo inteiro
Exercício inventado do personal - 3x12 - 60s
''',
    );

    final exercise = draft.routines.single.exercises.single;
    expect(exercise.selectedExerciseId, isNull);
    expect(exercise.needsReview, isTrue);

    final program = draft.toProgram();
    expect(
      program.routines.single.exercises.single.id,
      startsWith('custom_import_'),
    );
    expect(
      program.routines.single.exercises.single.name,
      'Exercício inventado do personal',
    );
  });

  test('interpreta texto copiado de tabela do Word sem formato em linha', () {
    final draft = parser.parseText(
      text: '''
TREINO 1 - JULIANO DA SILVA - JULHO DE 2026
EXERCÍCIOS AERÓBICOS: BICICLETA, ESTEIRA OU ELÍPTICO.
Fazer por 45 minutos ou mais em intensidade leve a moderada, após o treino com pesos.
TREINO A – PEITO, OMBRO E TRÍCEPS
EXERCÍCIOS N° SÉRIES N° REPETIÇÕES
SUPINO INCLINADO ARTICULADO
(AS DUAS ÚLTIMAS SÉRIES COM FALHA PARCIAL)
03
15-12-10
PULLEY TRÍCEPS BARRA
+
PULLEY TRÍCEPS TESTA COM BARRA
03
+
03
08 A 12
+
08 A 12
''',
    );

    expect(draft.routines, hasLength(1));
    expect(draft.routines.single.exercises, hasLength(3));
    expect(draft.routines.single.exercises.first.selectedExerciseId, 'p5');
    expect(draft.routines.single.exercises[1].selectedExerciseId, 'tr1');
    expect(draft.routines.single.exercises[1].isSupersetLead, isTrue);
    expect(draft.routines.single.exercises[2].selectedExerciseId, 'tr4');
    expect(draft.generalCardio?.plannedDurationMinutes, 45);
  });

  test('interpreta texto completo copiado da ficha do personal', () {
    final draft = parser.parseText(
      text: r'''
TREINO 1 - JULIANO DA SILVA - JULHO DE 2026

EXERCÍCIOS AERÓBICOS: BICICLETA, ESTEIRA OU ELÍPTICO.
Fazer por 45 minutos ou mais intercalando em intensidade leve a moderada, após o treino com pesos.

EXERCICIOS ANAERÓBICOS: MUSCULAÇÃO.

TREINO A – PEITO, ESTÍMULO PARA OMBRO. TRÍCEPS E PANTURRILHA
EXERCÍCIOS	N° SÉRIES	N° REPTIÇÕES
SUPINO INCLINADO ARTICULADO
(AS DUAS ÚLTIMAS SÉRIES COM FALHA PARCIAL)	03	15-12-10
SUPINO RETO ARTICULADO
(AS DUAS ÚLTIMAS SÉRIES COM FALHA PARCIAL)	03	08 A 12
CRUCIFIXO MÁQUINA
(AS DUAS ÚLTIMAS SÉRIES COM FALHA PARCIAL)	03	06 A 12
ELEVAÇÃO FRONTAL COM CORDA	02	08 A 12
TRÍCEPS FRANCÊS COM HALTER	03	08 A 12
PULLEY TRÍCEPS BARRA
+
PULLEY TRÍCEPS TESTA COM BARRA	03
+
03	08 A 12
+
08 A 12
GÊMEOS MÁQUINA	03	08 A 12

TREINO B – COSTA, ESTÍMULO PARA POSTERIOR DE OMBRO, BÍCEPS E PANTURRILHA
EXERCÍCIOS	N° SÉRIES	N° REPTIÇÕES
PULLEY FRENTE COM BARRA LONGA
(AS DUAS ÚLTIMAS SÉRIES COM FALHA PARCIAL)	03	15-12-10
REMADA BAIXA COM TRIÂNGULO
(AS DUAS ÚLTIMAS SÉRIES COM FALHA PARCIAL)	03	08 A 12
REMADA CURVADA COM BARRA
(AS DUAS ÚLTIMAS SÉRIES COM FALHA PARCIAL)	03	06 A 12
CRUCIFIXO INVERSO COM HALTERES	02	08 A 12
ROSCA DIRETA COM BARRA W	03	08 A 12
ROSCA INCLINADA COM HALTERES	03	08 A 12
BANCO SÓLEO	03	08 A 12

TREINO C – COXA COMPLETA
EXERCÍCIOS	N° SÉRIES	N° REPTIÇÕES
AGACHAMENTO BARRA GUIADA	03	15-12-10
LEG PRESS 45
(AS DUAS ÚLTIMAS SÉRIES COM FALHA PARCIAL)	03	08 A 12
CADEIRA EXTENSORA
(AS DUAS ÚLTIMAS SÉRIES COM FALHA PARCIAL)	03	06 A 12
CADEIRA FLEXORA
(AS DUAS ÚLTIMAS SÉRIES COM FALHA PARCIAL)	03	15-12-10-10
MESA FLEXORA
(AS DUAS ÚLTIMAS SÉRIES COM FALHA PARCIAL)	03	08 A 12
STIFF	03	06 A 12

TREINO D – OMBRO COMPLETO E ESTÍMULO PARA PEITO E PANTURRILHA
EXERCÍCIOS	N° SÉRIES	N° REPTIÇÕES
ELEVAÇÃO LATERAL COM HALTERES
(AS DUAS ÚLTIMAS SÉRIES COM FALHA PARCIAL)	03	15-12-10
DESENVOLVIMENTO COM BARRA
(AS DUAS ÚLTIMAS SÉRIES COM FALHA PARCIAL)	03	08 A 12
ELEVAÇÃO FRONTAL COM CORDA
(AS DUAS ÚLTIMAS SÉRIES COM FALHA PARCIAL)	03	06 A 12
CRUCIFIXO INVERSO COM HALTERES
(AS DUAS ÚLTIMAS SÉRIES COM FALHA PARCIAL)	02	06 A 12
ENCOLHIMENTO COM HALTERES
(AS DUAS ÚLTIMAS SÉRIES COM FALHA PARCIAL)	03	08 A 12
CRUCIFIXO MÁQUINA	03	06 A 12
GÊMEOS MÁQUINA	03	08 A 12

TREINO E – COSTA, BÍCEPS, TRÍCEPS E PANTURRILHA
EXERCÍCIOS	N° SÉRIES	N° REPTIÇÕES
PULLEY FRENTE COM BARRA LONGA
(AS DUAS ÚLTIMAS SÉRIES COM FALHA PARCIAL)	03	15-12-10
REMADA BAIXA COM TRIÂNGULO
(AS DUAS ÚLTIMAS SÉRIES COM FALHA PARCIAL)	03	08 A 12
REMADA CURVADA COM BARRA
(AS DUAS ÚLTIMAS SÉRIES COM FALHA PARCIAL)	03	06 A 12
ROSCA DIRETA COM BARRA W	03	08 A 12
ROSCA INCLINADA COM HALTERES	03	08 A 12
PULLEY TRÍCEPS BARRA
+
PULLEY TRÍCEPS TESTA COM BARRA	03
+
03	08 A 12
+
08 A 12
BANCO SÓLEO	03	08 A 12
''',
    );

    expect(draft.routines.map((routine) => routine.name), <String>[
      'Treino A',
      'Treino B',
      'Treino C',
      'Treino D',
      'Treino E',
    ]);
    expect(draft.routines.map((routine) => routine.exercises.length), <int>[
      8,
      7,
      6,
      7,
      8,
    ]);
    expect(draft.exerciseCount, 36);
    expect(
      draft.routines
          .expand((routine) => routine.exercises)
          .where((exercise) => exercise.isSupersetLead),
      hasLength(2),
    );
    expect(
      draft.routines
          .expand((routine) => routine.exercises)
          .any((exercise) => exercise.rawName.startsWith('TREINO ')),
      isFalse,
    );
    expect(draft.generalCardio?.plannedDurationMinutes, 45);
    expect(
      draft.issues.any(
        (issue) => issue.message.contains('4 valores de repetição'),
      ),
      isTrue,
    );
  });

  test('remove avisos do exercício depois da revisão confirmada', () {
    final original = parser.parseText(
      text: '''
Treino A - Corpo inteiro
Exercício inventado do personal - 3x12 - 60s
''',
    );
    final routine = original.routines.single;
    final reviewedExercise = routine.exercises.single.copyWith(
      needsReview: false,
    );
    final reviewedRoutine = routine.copyWith(
      exercises: <PersonalImportExerciseDraft>[reviewedExercise],
    );

    final resolved = original.resolveExerciseReview(
      routineName: routine.name,
      exerciseNames: <String>{routine.exercises.single.rawName},
      routines: <PersonalImportRoutineDraft>[reviewedRoutine],
    );

    expect(resolved.reviewCount, 0);
    expect(
      resolved.issues.where(
        (issue) => issue.exerciseName == routine.exercises.single.rawName,
      ),
      isEmpty,
    );
  });

  test('validação agrupa pendências antes de salvar', () {
    final draft = parser.parseText(
      text: '''
Treino A - Corpo inteiro
Exercício inventado - 3x12
''',
    );

    final validation = draft.validateForSave();

    expect(validation.hasBlockingIssues, isFalse);
    expect(validation.hasWarnings, isTrue);
    expect(
      validation.warningMessages.any(
        (message) => message.contains('não foram revisados'),
      ),
      isTrue,
    );
    expect(
      validation.warningMessages.any(
        (message) => message.contains('Descanso não informado'),
      ),
      isTrue,
    );
  });

  test('validação bloqueia exercício sem repetições', () {
    final draft = PersonalWorkoutImportDraft(
      programName: 'Programa',
      focus: '',
      routines: <PersonalImportRoutineDraft>[
        PersonalImportRoutineDraft(
          name: 'Treino A',
          focus: '',
          exercises: const <PersonalImportExerciseDraft>[
            PersonalImportExerciseDraft(
              rawName: 'Supino',
              seriesCount: 3,
              repetitions: '',
              rest: '60 seg',
              note: '',
              suggestedExerciseIds: <String>[],
            ),
          ],
        ),
      ],
      issues: const <PersonalImportIssue>[],
    );

    final validation = draft.validateForSave();
    expect(validation.hasBlockingIssues, isTrue);
    expect(
      validation.blockingMessages.any(
        (message) => message.contains('sem repetições'),
      ),
      isTrue,
    );
  });

  test('aplica descanso em lote apenas nos campos vazios', () {
    final draft = parser.parseText(
      text: '''
Treino A - Peito
Supino reto com barra - 3x10
Crucifixo com halteres - 3x12 - 45s
''',
    );

    final updated = draft.applyRestToMissing('60 seg');

    expect(updated.missingRestCount, 0);
    expect(updated.routines.single.exercises.first.rest, '60 seg');
    expect(updated.routines.single.exercises.last.rest, '45s');
  });

  group('importador avançado', () {
    test('reconhece treino numérico, série, dia, semana e descanso', () {
      final draft = parser.parseText(
        text: '''
Plano de treino semanal
Treino 1 - Peito e tríceps
Supino reto 3x8-12
Série B - Costas e bíceps
Remada curvada 3x10
Quarta-feira --- DESCANSO
Dia 3 - Cardio
Esteira 20 min velocidade 6 inclinação de 5%
''',
      );

      expect(draft.routines.map((item) => item.name), <String>[
        'Treino 1',
        'Série B',
        'Dia 3',
      ]);
      expect(draft.exerciseCount, 2);
      expect(draft.routines.last.cardio, hasLength(1));
      expect(draft.routines.last.cardio.single.plannedDurationMinutes, 20);
      expect(
        draft.issues.any((issue) => issue.message.contains('descanso')),
        isTrue,
      );
    });

    test('interpreta CSV com colunas, RIR, descanso e observação', () {
      final draft = parser.parseText(
        sourceLabel: 'ficha.csv',
        text: '''
Treino;Dia sugerido;Ordem;Grupo muscular;Exercício;Séries;Repetições;Descanso (segundos);Intensidade;Observações
A - Superior;Segunda-feira;2;Costas;Puxada frontal na polia;4;8-12;90;RIR 1-2;Controle a volta
A - Superior;Segunda-feira;1;Peito;Supino reto na máquina;4;8-12;90;RIR 1-2;Mantenha os ombros confortáveis
''',
      );

      expect(draft.routines, hasLength(1));
      expect(draft.routines.single.scheduleLabel, 'Segunda-feira');
      expect(
        draft.routines.single.exercises.first.rawName,
        'Supino reto na máquina',
      );
      expect(draft.routines.single.exercises.first.rest, '90 seg');
      expect(draft.routines.single.exercises.first.intensity, 'RIR 1-2');
      expect(
        draft.routines.single.exercises.first.note,
        contains('Mantenha os ombros confortáveis'),
      );
    });

    test('preserva alternativas e diferencia de bi-set', () {
      final draft = parser.parseText(
        text: r'''
Treino 1 - Peito
Peck peito \ Voador 3x8-12
Pullover / Crucifixo 3x8-12
Supino reto 3x10
+
Crucifixo máquina 3x12
''',
      );

      final exercises = draft.routines.single.exercises;
      expect(exercises[0].alternatives, <String>['Peck peito', 'Voador']);
      expect(exercises[0].hasAlternatives, isTrue);
      expect(exercises[1].alternatives, <String>['Pullover', 'Crucifixo']);
      expect(exercises[2].isSupersetLead, isTrue);
      expect(exercises[3].isSupersetLead, isFalse);
    });

    test(
      'reconhece técnicas, intensidade, cadência e prescrições especiais',
      () {
        final draft = parser.parseText(
          text: '''
Treino A - Avançado
Extensora 4x6 DROP 60s 70%
Barra fixa 1x15 REST PAUSE (10s)
Agachamento no Smith 2x12/2x10/1x8 1 min
Prancha 4xMÁX. 60s
Passadas livres 4x40 passos 60s
Pulley frente 3x8-15 40 seg cadência 1 por 1 falha concêntrica
''',
        );

        final exercises = draft.routines.single.exercises;
        expect(exercises[0].techniques, contains('Drop-set'));
        expect(exercises[0].intensity, '70%');
        expect(exercises[1].techniques, contains('Rest-pause'));
        expect(
          exercises[2].prescriptionKind,
          PersonalImportPrescriptionKind.perSet,
        );
        expect(exercises[2].seriesCount, 5);
        expect(exercises[2].originalPrescription, contains('2x12'));
        expect(
          exercises[3].prescriptionKind,
          PersonalImportPrescriptionKind.maximum,
        );
        expect(
          exercises[4].prescriptionKind,
          PersonalImportPrescriptionKind.steps,
        );
        expect(exercises[5].cadence, '1 por 1');
        expect(exercises[5].techniques, contains('Falha concêntrica'));
      },
    );

    test('reconhece cardio antes, depois e sessão separada', () {
      final draft = parser.parseText(
        text: '''
Treino A - Pernas
Aquecimento na esteira 10 min antes da musculação
Agachamento livre 3x8-10
Treino B - Peito
Supino reto 3x10
No final do treino, cardio de 30 min na esteira (140 a 160 BPM)
Dia 3 - Cardio opcional
Bicicleta 25 min em sessão separada
''',
      );

      expect(draft.routines, hasLength(3));
      expect(draft.routines[0].cardio.single.notes, contains('antes'));
      expect(
        draft.routines[0].cardio.single.plan.purpose,
        CardioPurpose.warmUp,
      );
      expect(draft.routines[1].cardio.single.notes, contains('após'));
      expect(
        draft.routines[1].cardio.single.plan.purpose,
        CardioPurpose.postWorkout,
      );
      expect(draft.routines[1].cardio.single.notes, contains('140–160 bpm'));
      expect(draft.routines[2].isOptional, isTrue);
      expect(
        draft.routines[2].cardio.single.notes,
        contains('sessão separada'),
      );
      expect(
        draft.routines[2].cardio.single.plan.purpose,
        CardioPurpose.standalone,
      );
    });

    test('preserva cardio intervalado sem inventar blocos ausentes', () {
      final draft = parser.parseText(
        text: '''
Dia 3 - Cardio intervalado
Esteira 20 min intervalado em intensidade vigorosa, em sessão separada
''',
      );

      final cardio = draft.routines.single.cardio.single;
      expect(cardio.plannedDurationMinutes, 20);
      expect(cardio.plan.purpose, CardioPurpose.standalone);
      expect(cardio.plan.format, CardioFormat.intervals);
      expect(cardio.plan.intensity, CardioIntensity.vigorous);
      expect(cardio.plan.intervals, isNull);
      expect(cardio.notes, contains('Cardio intervalado'));
    });

    test('converte linha de cardio em tabela para etapa de cardio', () {
      final draft = parser.parseDocument(
        sourceLabel: 'planilha.docx',
        blocks: <PersonalImportDocumentBlock>[
          const PersonalImportParagraph('Treino A - (segunda-feira)'),
          PersonalImportTable(<List<String>>[
            <String>['Exercício', 'Séries', 'Repetições'],
            <String>['Aquecimento na bike', '30 min', ''],
            <String>['Agachamento livre', '3', '8-12'],
          ]),
        ],
      );

      expect(draft.routines.single.scheduleLabel, 'Segunda-feira');
      expect(draft.routines.single.cardio, hasLength(1));
      expect(draft.routines.single.cardio.single.plannedDurationMinutes, 30);
      expect(draft.routines.single.exercises, hasLength(1));
    });

    test('classifica progressão de oito semanas e usa primeira prescrição', () {
      final draft = parser.parseText(
        text: '''
Planejamento de 8 semanas
Exercício Semana 1 Semana 2 Semana 3 Semana 4 Semana 5 Semana 6 Semana 7 Semana 8
Treino A
Floor Press 3x8a12 4x8a12 4x5a9 5x5a9 2x8a12 4x5a9 6x3a7 6x5a9
Treino B
Barra Fixa 1x15 1x20 1x25 1x30 1x10 1x30 1x35 1x40 REST PAUSE (10s)
''',
      );

      expect(draft.documentKind, PersonalImportDocumentKind.periodizedPlan);
      expect(draft.periodizationWeeks, 8);
      expect(draft.routines.first.exercises.first.seriesCount, 3);
      expect(draft.routines.first.exercises.first.repetitions, '8 a 12');
      expect(
        draft.routines.first.exercises.first.note,
        contains('Progressão completa'),
      );
    });

    test('bloqueia modelo vazio e material didático', () {
      final emptyTemplate = parser.parseText(
        text: '''
FICHA DE TREINAMENTO
NOME:
OBJETIVO:
VALIDADE DA FICHA:
G. MUSC. EXERCÍCIOS INT. KG SÉRIE REPT
PEITO Supino Reto Supino Inclinado Crucifixo
''',
      );
      expect(
        emptyTemplate.documentKind,
        PersonalImportDocumentKind.emptyTemplate,
      );
      expect(emptyTemplate.routines, isEmpty);

      final educational = parser.parseText(
        text: '''
SUMÁRIO
INTRODUÇÃO
CAPÍTULO 1 - ENTENDENDO A MUSCULAÇÃO
OBJETIVOS DE APRENDIZAGEM
REFERÊNCIAS BIBLIOGRÁFICAS
Este material apresenta orientações gerais para prescrição de exercícios.
''',
      );
      expect(
        educational.documentKind,
        PersonalImportDocumentKind.educationalMaterial,
      );
      expect(educational.routines, isEmpty);
    });
  });

  test('reconhece cabeçalho REPTIÇÕES usado na ficha real', () {
    final draft = parser.parseDocument(
      sourceLabel: 'ficha-real.docx',
      blocks: <PersonalImportDocumentBlock>[
        const PersonalImportParagraph('Treino A - Peito'),
        PersonalImportTable(<List<String>>[
          <String>['EXERCÍCIOS', 'N° SÉRIES', 'N° REPTIÇÕES'],
          <String>['SUPINO RETO ARTICULADO', '03', '08 A 12'],
          <String>['CRUCIFIXO MÁQUINA', '03', '06 A 12'],
        ]),
      ],
    );

    expect(draft.routines.single.exercises, hasLength(2));
    expect(draft.routines.single.exercises.first.seriesCount, 3);
    expect(draft.routines.single.exercises.first.repetitions, '08 a 12');
    expect(draft.missingRepetitionsCount, 0);
  });

  test('resume exercícios pendentes sem obrigar busca ficha por ficha', () {
    final draft = PersonalWorkoutImportDraft(
      programName: 'Programa',
      focus: 'Teste',
      issues: const <PersonalImportIssue>[],
      routines: <PersonalImportRoutineDraft>[
        PersonalImportRoutineDraft(
          name: 'Treino A',
          focus: 'Peito',
          exercises: const <PersonalImportExerciseDraft>[
            PersonalImportExerciseDraft(
              rawName: 'Exercício desconhecido',
              seriesCount: 3,
              repetitions: '10',
              rest: '',
              note: '',
              suggestedExerciseIds: <String>[],
              needsReview: true,
            ),
          ],
        ),
      ],
    );

    expect(draft.pendingExerciseCount, 1);
    expect(draft.routinesWithPendingCount, 1);
    expect(
      draft.routines.first.exercises.single.pendingReasons,
      contains('Exercício não identificado pelo PULSE'),
    );
  });
}
