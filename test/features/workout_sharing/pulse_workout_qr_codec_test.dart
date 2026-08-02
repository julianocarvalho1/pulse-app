import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/workout_sharing/domain/models/pulse_workout_file.dart';
import 'package:pulse/features/workout_sharing/domain/services/pulse_workout_codec.dart';
import 'package:pulse/features/workout_sharing/domain/services/pulse_workout_qr_codec.dart';
import 'package:pulse/features/workouts/domain/models/advanced_workout_prescription.dart';
import 'package:pulse/features/workouts/domain/models/cardio_log.dart';
import 'package:pulse/models/exercise.dart';

void main() {
  const fileCodec = PulseWorkoutCodec();
  const qrCodec = PulseWorkoutQrCodec();

  Exercise exercise({
    String id = 'p1',
    String name = 'Supino Reto com Barra',
    String reps = '4x 8-10',
    String note = 'Controlar a descida',
  }) {
    return Exercise(
      id: id,
      name: name,
      muscle: 'Peito',
      description: 'Descrição do exercício',
      reps: reps,
      rest: '90 seg',
      customNote: note,
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

  test('gera e lê QR de ficha preservando a prescrição', () {
    final document = fileCodec.routineDocument(routine());
    final encoded = qrCodec.encode(document);
    final decoded = qrCodec.decode(encoded);

    expect(encoded, startsWith('PULSEQR2:'));
    expect(
      encoded.length,
      lessThanOrEqualTo(PulseWorkoutQrCodec.maxQrCharacters),
    );
    expect(decoded.contentType, PulseWorkoutContentType.routine);
    expect(decoded.title, 'Treino A');
    expect(decoded.routine?.exercises.single.name, 'Supino Reto com Barra');
    expect(decoded.routine?.exercises.single.reps, '4x 8-10');
    expect(decoded.routine?.exercises.single.customNote, 'Controlar a descida');
    expect(decoded.routine?.cardio.single.plannedDurationMinutes, 20);
  });

  test('gera e lê QR de programa com várias fichas', () {
    final document = fileCodec.programDocument(
      name: 'Programa Juliano',
      routines: <WorkoutRoutine>[
        routine(id: 'a', name: 'Treino A', groupName: 'Programa Juliano'),
        routine(id: 'b', name: 'Treino B', groupName: 'Programa Juliano'),
      ],
    );

    final decoded = qrCodec.decode(qrCodec.encode(document));

    expect(decoded.contentType, PulseWorkoutContentType.program);
    expect(decoded.program?.name, 'Programa Juliano');
    expect(decoded.routines, hasLength(2));
  });

  test('QR importado usa a mesma proteção contra duplicidade do arquivo', () {
    final document = fileCodec.routineDocument(routine());
    final decoded = qrCodec.decode(qrCodec.encode(document));
    final firstPreview = fileCodec.prepareImport(
      document: decoded,
      localExercises: <Exercise>[exercise()],
      currentRoutines: const <WorkoutRoutine>[],
    );
    final imported = firstPreview.buildBundle('Treino recebido');

    final secondPreview = fileCodec.prepareImport(
      document: decoded,
      localExercises: <Exercise>[exercise()],
      currentRoutines: imported.routines,
    );

    expect(secondPreview.isExactDuplicate, isTrue);
  });

  test('continua lendo QR Code da versão 1', () {
    final compact = <String, Object>{
      'v': 1,
      't': 'r',
      'n': 'Treino legado',
      'c': 0,
      'd': <String, Object>{
        'n': 'Treino legado',
        'e': <Object>[
          <String, Object>{
            'i': 'p1',
            'n': 'Supino',
            'm': 'Peito',
            'r': '3x 10',
            's': '60 seg',
          },
        ],
      },
    };
    final compressed = ZLibEncoder(
      level: 9,
    ).convert(utf8.encode(jsonEncode(compact)));
    final payload = base64UrlEncode(compressed).replaceAll('=', '');

    final decoded = qrCodec.decode('PULSEQR1:$payload');

    expect(decoded.formatVersion, 1);
    expect(decoded.routine?.name, 'Treino legado');
    expect(
      decoded.routine?.exercises.single.advancedPrescription.isEmpty,
      isTrue,
    );
  });

  test('recusa QR que não pertence ao PULSE', () {
    expect(
      () => qrCodec.decode('https://exemplo.com'),
      throwsA(
        isA<PulseWorkoutFileException>().having(
          (error) => error.message,
          'message',
          contains('não contém'),
        ),
      ),
    );
  });

  test('recusa QR criado por versão futura', () {
    expect(
      () => qrCodec.decode('PULSEQR3:abc'),
      throwsA(
        isA<PulseWorkoutFileException>().having(
          (error) => error.message,
          'message',
          contains('versão mais nova'),
        ),
      ),
    );
  });

  test('orienta usar arquivo quando o conteúdo não cabe em um QR', () {
    final exercises = <Exercise>[
      for (var index = 0; index < 100; index++)
        exercise(
          id: 'custom_$index',
          name: 'Exercício personalizado $index',
          note: List<String>.generate(
            80,
            (part) =>
                '${index * 97 + part}-${String.fromCharCode(33 + (part % 80))}',
          ).join('|'),
        ),
    ];
    final document = fileCodec.routineDocument(routine(exercises: exercises));

    expect(
      () => qrCodec.encode(document),
      throwsA(
        isA<PulseWorkoutFileException>().having(
          (error) => error.message,
          'message',
          contains('arquivo .pulse'),
        ),
      ),
    );
  });

  test('QR Code preserva detalhes avançados por série', () {
    const advanced = AdvancedExercisePrescription(
      activeWeek: 1,
      weeks: <WorkoutWeekPrescription>[
        WorkoutWeekPrescription(
          weekNumber: 1,
          sets: <WorkoutSetPrescription>[
            WorkoutSetPrescription(
              setNumber: 1,
              target: '8–10 reps',
              restSeconds: 90,
              targetRir: 2,
              cadence: '3-1-1-0',
              technique: WorkoutTechnique.isometry,
            ),
          ],
        ),
      ],
    );
    final document = fileCodec.routineDocument(
      routine(
        exercises: <Exercise>[
          exercise().copyWith(advancedPrescription: advanced),
        ],
      ),
    );

    final decoded = qrCodec.decode(qrCodec.encode(document));
    final set = decoded
        .routine!
        .exercises
        .single
        .advancedPrescription
        .activePrescription!
        .sets
        .single;

    expect(set.target, '8–10 reps');
    expect(set.targetRir, 2);
    expect(set.cadence, '3-1-1-0');
    expect(set.technique, WorkoutTechnique.isometry);
  });
}
