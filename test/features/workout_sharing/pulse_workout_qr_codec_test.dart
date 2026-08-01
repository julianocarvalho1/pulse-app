import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/workout_sharing/domain/models/pulse_workout_file.dart';
import 'package:pulse/features/workout_sharing/domain/services/pulse_workout_codec.dart';
import 'package:pulse/features/workout_sharing/domain/services/pulse_workout_qr_codec.dart';
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

    expect(encoded, startsWith('PULSEQR1:'));
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
      () => qrCodec.decode('PULSEQR2:abc'),
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
}
