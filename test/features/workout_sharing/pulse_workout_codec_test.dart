import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/workout_sharing/domain/models/pulse_workout_file.dart';
import 'package:pulse/features/workout_sharing/domain/services/pulse_workout_codec.dart';
import 'package:pulse/features/workouts/domain/models/advanced_workout_prescription.dart';
import 'package:pulse/features/workouts/domain/models/cardio_log.dart';
import 'package:pulse/models/exercise.dart';

void main() {
  const codec = PulseWorkoutCodec();

  Exercise exercise({
    String id = 'p1',
    String name = 'Supino Reto com Barra',
    String reps = '4x 8-10',
  }) {
    return Exercise(
      id: id,
      name: name,
      muscle: 'Peito',
      description: 'Descrição',
      reps: reps,
      rest: '90 seg',
      customNote: 'Controlar a descida',
    );
  }

  WorkoutRoutine routine({
    String id = 'r1',
    String name = 'Treino A',
    String groupName = '',
    List<Exercise>? exercises,
  }) {
    return WorkoutRoutine(
      id: id,
      name: name,
      focus: 'Peito e tríceps',
      groupName: groupName,
      exercises: exercises ?? <Exercise>[exercise()],
      cardio: const <RoutineCardio>[
        RoutineCardio(
          id: 'cardio_1',
          modality: CardioModality.treadmill,
          plannedDurationMinutes: 20,
          notes: 'Após a musculação',
        ),
      ],
    );
  }

  test('exporta e lê uma ficha preservando toda a prescrição', () {
    final original = routine();
    final document = codec.routineDocument(original);
    final decoded = codec.decode(codec.encode(document));

    expect(decoded.contentType, PulseWorkoutContentType.routine);
    expect(decoded.title, 'Treino A');
    expect(decoded.routine?.exercises.single.reps, '4x 8-10');
    expect(decoded.routine?.exercises.single.customNote, 'Controlar a descida');
    expect(decoded.routine?.cardio.single.plannedDurationMinutes, 20);
  });

  test('exporta e lê programa com várias fichas', () {
    final document = codec.programDocument(
      name: 'Programa Juliano',
      routines: <WorkoutRoutine>[
        routine(id: 'a', name: 'Treino A', groupName: 'Programa Juliano'),
        routine(id: 'b', name: 'Treino B', groupName: 'Programa Juliano'),
      ],
    );

    final decoded = codec.decode(codec.encode(document));

    expect(decoded.contentType, PulseWorkoutContentType.program);
    expect(decoded.program?.name, 'Programa Juliano');
    expect(decoded.routines, hasLength(2));
  });

  test('recusa arquivo com formato diferente', () {
    final bytes = Uint8List.fromList(
      utf8.encode(jsonEncode(<String, Object?>{'format': 'outro'})),
    );

    expect(
      () => codec.decode(bytes),
      throwsA(isA<PulseWorkoutFileException>()),
    );
  });

  test('continua lendo arquivo .pulse da versão 1', () {
    final map = codec.routineDocument(routine()).toMap();
    map['formatVersion'] = 1;
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(map)));

    final decoded = codec.decode(bytes);

    expect(decoded.formatVersion, 1);
    expect(decoded.routine?.name, 'Treino A');
    expect(
      decoded.routine?.exercises.single.advancedPrescription.isEmpty,
      isTrue,
    );
  });

  test('recusa arquivo criado por versão futura', () {
    final map = codec.routineDocument(routine()).toMap();
    map['formatVersion'] = PulseWorkoutDocument.currentVersion + 1;
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(map)));

    expect(
      () => codec.decode(bytes),
      throwsA(
        isA<PulseWorkoutFileException>().having(
          (error) => error.message,
          'message',
          contains('versão mais nova'),
        ),
      ),
    );
  });

  test('associa exercício conhecido e preserva séries recebidas', () {
    final incoming = routine(
      exercises: <Exercise>[
        exercise(
          id: 'id_externo',
          name: 'Supino Reto com Barra',
          reps: '3x 12',
        ),
      ],
    );
    final local = exercise(id: 'p1', reps: '4x 8-10');

    final preview = codec.prepareImport(
      document: codec.routineDocument(incoming),
      localExercises: <Exercise>[local],
      currentRoutines: const <WorkoutRoutine>[],
    );

    final resolved = preview.resolvedRoutines.single.exercises.single;
    expect(resolved.id, 'p1');
    expect(resolved.reps, '3x 12');
    expect(preview.unmatchedExerciseCount, 0);
  });

  test('mantém exercício desconhecido como personalizado', () {
    final incoming = routine(
      exercises: <Exercise>[
        exercise(id: 'externo_1', name: 'Exercício do Personal'),
      ],
    );

    final preview = codec.prepareImport(
      document: codec.routineDocument(incoming),
      localExercises: const <Exercise>[],
      currentRoutines: const <WorkoutRoutine>[],
    );

    expect(preview.unmatchedExerciseCount, 1);
    expect(preview.customExercises, hasLength(1));
    expect(preview.customExercises.single.id, startsWith('custom_shared_'));
    expect(
      preview.resolvedRoutines.single.exercises.single.id,
      preview.customExercises.single.id,
    );
  });

  test('detecta ficha idêntica e impede duplicação acidental', () {
    final existing = routine(id: 'existing');
    final incoming = routine(id: 'incoming');

    final preview = codec.prepareImport(
      document: codec.routineDocument(incoming),
      localExercises: <Exercise>[exercise()],
      currentRoutines: <WorkoutRoutine>[existing],
    );

    expect(preview.isExactDuplicate, isTrue);
    expect(preview.suggestedName, 'Treino A (2)');
  });

  test('detecta reimportação mesmo quando a primeira cópia foi renomeada', () {
    final document = codec.routineDocument(routine());
    final firstPreview = codec.prepareImport(
      document: document,
      localExercises: <Exercise>[exercise()],
      currentRoutines: const <WorkoutRoutine>[],
    );
    final firstImport = firstPreview.buildBundle('Treino A (2)');

    final secondPreview = codec.prepareImport(
      document: document,
      localExercises: <Exercise>[exercise()],
      currentRoutines: firstImport.routines,
    );

    expect(secondPreview.isExactDuplicate, isTrue);
  });

  test('detecta programa duplicado mesmo após renomear as fichas', () {
    final document = codec.programDocument(
      name: 'Programa recebido',
      routines: <WorkoutRoutine>[
        routine(id: 'a', name: 'Treino A', groupName: 'Programa recebido'),
        routine(id: 'b', name: 'Treino B', groupName: 'Programa recebido'),
      ],
    );
    final firstPreview = codec.prepareImport(
      document: document,
      localExercises: <Exercise>[exercise()],
      currentRoutines: const <WorkoutRoutine>[],
    );
    final firstImport = firstPreview.buildBundle('Programa novo');
    final renamedRoutines = <WorkoutRoutine>[
      firstImport.routines[0].copyWith(name: 'Peito'),
      firstImport.routines[1].copyWith(name: 'Costas'),
    ];

    final secondPreview = codec.prepareImport(
      document: document,
      localExercises: <Exercise>[exercise()],
      currentRoutines: renamedRoutines,
    );

    expect(secondPreview.isExactDuplicate, isTrue);
  });

  test('não bloqueia ficha com prescrição diferente', () {
    final existing = routine(
      id: 'existing',
      name: 'Outro nome',
      exercises: <Exercise>[exercise(reps: '4x 8-10')],
    );
    final incoming = routine(
      id: 'incoming',
      exercises: <Exercise>[exercise(reps: '3x 12')],
    );

    final preview = codec.prepareImport(
      document: codec.routineDocument(incoming),
      localExercises: <Exercise>[exercise()],
      currentRoutines: <WorkoutRoutine>[existing],
    );

    expect(preview.isExactDuplicate, isFalse);
  });

  test('gera novos ids e aplica nome revisado ao importar programa', () {
    final document = codec.programDocument(
      name: 'Programa recebido',
      routines: <WorkoutRoutine>[
        routine(name: 'Treino A', groupName: 'Programa recebido'),
      ],
    );
    final preview = codec.prepareImport(
      document: document,
      localExercises: <Exercise>[exercise()],
      currentRoutines: const <WorkoutRoutine>[],
    );

    final bundle = preview.buildBundle('Programa novo');

    expect(bundle.activeProgramName, 'Programa novo');
    expect(bundle.routines.single.groupName, 'Programa novo');
    expect(bundle.routines.single.id, startsWith('shared_'));
    expect(
      bundle.routines.single.cardio.single.id,
      startsWith('shared_cardio_'),
    );
  });

  test('arquivo .pulse preserva periodização e diferencia prescrições', () {
    const advanced = AdvancedExercisePrescription(
      activeWeek: 2,
      weeks: <WorkoutWeekPrescription>[
        WorkoutWeekPrescription(
          weekNumber: 1,
          sets: <WorkoutSetPrescription>[
            WorkoutSetPrescription(setNumber: 1, target: '10–12 reps'),
          ],
        ),
        WorkoutWeekPrescription(
          weekNumber: 2,
          sets: <WorkoutSetPrescription>[
            WorkoutSetPrescription(
              setNumber: 1,
              target: '6–8 reps',
              targetRir: 1,
              technique: WorkoutTechnique.dropSet,
            ),
          ],
        ),
      ],
    );
    final advancedRoutine = routine(
      exercises: <Exercise>[
        exercise().copyWith(advancedPrescription: advanced),
      ],
    );
    final decoded = codec.decode(
      codec.encode(codec.routineDocument(advancedRoutine)),
    );

    expect(
      decoded.routine?.exercises.single.advancedPrescription.activeWeek,
      2,
    );
    expect(
      decoded
          .routine
          ?.exercises
          .single
          .advancedPrescription
          .activePrescription
          ?.sets
          .single
          .technique,
      WorkoutTechnique.dropSet,
    );

    final simplePreview = codec.prepareImport(
      document: codec.routineDocument(routine()),
      localExercises: <Exercise>[exercise()],
      currentRoutines: <WorkoutRoutine>[advancedRoutine],
    );
    expect(simplePreview.isExactDuplicate, isFalse);
  });
}
