import '../../../../models/exercise.dart';
import '../../../exercises/domain/exercise_catalog.dart';

class CoreExtraSessionCatalog {
  const CoreExtraSessionCatalog._();

  static final List<WorkoutRoutine> routines = <WorkoutRoutine>[
    WorkoutRoutine(
      id: 'extra_core_express',
      name: 'Core expresso',
      focus:
          'Estabilidade do tronco em uma sessão curta de cerca de 10 minutos.',
      exercises: <Exercise>[
        _exercise('repdb_dead-bug', reps: '3x 8-10 por lado', rest: '30 seg'),
        _exercise('ab5', reps: '3x 30 seg', rest: '30 seg'),
        _exercise('ab2', reps: '3x 12-15', rest: '30 seg'),
      ],
    ),
    WorkoutRoutine(
      id: 'extra_core_complete',
      name: 'Core completo',
      focus:
          'Flexão, anti-extensão, anti-rotação e estabilidade lateral do core.',
      exercises: <Exercise>[
        _exercise('ab1', reps: '3x 12-15', rest: '45 seg'),
        _exercise('repdb_dead-bug', reps: '3x 10 por lado', rest: '45 seg'),
        _exercise(
          'repdb_cable-pallof-press',
          reps: '3x 10-12 por lado',
          rest: '45 seg',
        ),
        _exercise(
          'repdb_side-plank',
          reps: '6x 30 seg alternando lados',
          rest: '45 seg',
        ),
        _exercise('repdb_bird-dog', reps: '3x 10 por lado', rest: '45 seg'),
      ],
    ),
    WorkoutRoutine(
      id: 'extra_core_circuit',
      name: 'Core em circuito',
      focus: 'Três voltas alternando controle, rotação e movimentos dinâmicos.',
      exercises: <Exercise>[
        _exercise(
          'ab1',
          reps: '3x 30 seg',
          rest: '30 seg',
          customNote:
              'Faça uma série e siga para o próximo exercício. Repita o circuito 3 vezes.',
        ),
        _exercise('repdb_mountain-climbers', reps: '3x 30 seg', rest: '30 seg'),
        _exercise('repdb_bird-dog', reps: '3x 30 seg', rest: '30 seg'),
        _exercise('ab6', reps: '3x 30 seg', rest: '30 seg'),
      ],
    ),
  ];

  static Exercise _exercise(
    String id, {
    required String reps,
    required String rest,
    String customNote = '',
  }) {
    final definition = ExerciseCatalog.definitionForId(id);
    if (definition == null) {
      throw StateError('Exercício $id não encontrado no catálogo do PULSE.');
    }

    return ExerciseCatalog.prescribedExercise(
      id: id,
      description: definition.description,
      reps: reps,
      rest: rest,
      customNote: customNote,
    );
  }
}
