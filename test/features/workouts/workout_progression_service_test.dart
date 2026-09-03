import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/workouts/domain/models/exercise_log.dart';
import 'package:pulse/features/workouts/domain/models/advanced_workout_prescription.dart';
import 'package:pulse/features/workouts/domain/models/workout_history_item.dart';
import 'package:pulse/features/workouts/domain/models/workout_progression_mode.dart';
import 'package:pulse/features/workouts/domain/models/workout_set.dart';
import 'package:pulse/features/workouts/domain/services/workout_progression_service.dart';
import 'package:pulse/models/exercise.dart';

void main() {
  const exercise = Exercise(
    id: 'supino',
    name: 'Supino',
    muscle: 'Peito',
    description: '',
    reps: '3x 8-10',
    rest: '60 seg',
  );

  const service = WorkoutProgressionService();

  test('avança as séries mais baixas sem ultrapassar a faixa', () {
    final history = <WorkoutHistoryItem>[
      WorkoutHistoryItem(
        id: 'history-1',
        routineName: 'Treino A',
        date: DateTime(2026, 7, 29),
        duration: '30:00',
        exercises: <ExerciseLog>[
          ExerciseLog(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            sets: const <ExerciseSet>[
              ExerciseSet(reps: 8, weight: 40),
              ExerciseSet(reps: 9, weight: 40),
              ExerciseSet(reps: 8, weight: 40),
            ],
          ),
        ],
      ),
    ];

    final suggestion = service.buildSuggestion(
      exercise: exercise,
      history: history,
      mode: WorkoutProgressionMode.repsThenLoad,
    );

    expect(suggestion.lastPerformance, '40 kg: 8 / 9 / 8 reps');
    expect(suggestion.nextTarget, contains('pelo menos 9 repetições'));
    expect(suggestion.nextTarget, contains('sem passar de 10'));
  });

  test('ignora séries de aquecimento ao calcular a próxima progressão', () {
    final history = <WorkoutHistoryItem>[
      WorkoutHistoryItem(
        id: 'history-warm-up',
        routineName: 'Treino A',
        date: DateTime(2026, 7, 29),
        duration: '30:00',
        exercises: <ExerciseLog>[
          ExerciseLog(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            sets: const <ExerciseSet>[
              ExerciseSet(reps: 20, weight: 20, kind: WorkoutSetKind.warmUp),
              ExerciseSet(reps: 8, weight: 40),
              ExerciseSet(reps: 9, weight: 40),
            ],
          ),
        ],
      ),
    ];

    final suggestion = service.buildSuggestion(
      exercise: exercise,
      history: history,
      mode: WorkoutProgressionMode.repsThenLoad,
    );

    expect(suggestion.lastPerformance, '40 kg: 8 / 9 reps');
    expect(suggestion.lastPerformance, isNot(contains('20')));
  });

  test('não inventa carga quando todas as séries atingem o topo', () {
    final history = <WorkoutHistoryItem>[
      WorkoutHistoryItem(
        id: 'history-2',
        routineName: 'Treino A',
        date: DateTime(2026, 7, 29),
        duration: '30:00',
        exercises: <ExerciseLog>[
          ExerciseLog(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            sets: const <ExerciseSet>[
              ExerciseSet(reps: 10, weight: 40),
              ExerciseSet(reps: 10, weight: 40),
              ExerciseSet(reps: 10, weight: 40),
            ],
          ),
        ],
      ),
    ];

    final suggestion = service.buildSuggestion(
      exercise: exercise,
      history: history,
      mode: WorkoutProgressionMode.repsThenLoad,
    );

    expect(suggestion.nextTarget, contains('menor incremento de carga'));
    expect(suggestion.nextTarget, contains('retorne a 8 repetições'));
    expect(suggestion.nextTarget, isNot(contains('42,5 kg')));
  });

  test('normaliza prescrição descendente antes de limitar a progressão', () {
    const descendingExercise = Exercise(
      id: 'elevacao-lateral',
      name: 'Elevação lateral',
      muscle: 'Ombros',
      description: '',
      reps: '15-12-10',
      rest: '60 seg',
    );
    final history = <WorkoutHistoryItem>[
      WorkoutHistoryItem(
        id: 'history-descending',
        routineName: 'Treino B',
        date: DateTime(2026, 8, 9),
        duration: '30:00',
        exercises: <ExerciseLog>[
          ExerciseLog(
            exerciseId: descendingExercise.id,
            exerciseName: descendingExercise.name,
            sets: <ExerciseSet>[
              ExerciseSet(reps: 15, weight: 8),
              ExerciseSet(reps: 12, weight: 8),
              ExerciseSet(reps: 10, weight: 8),
            ],
          ),
        ],
      ),
    ];

    final suggestion = service.buildSuggestion(
      exercise: descendingExercise,
      history: history,
    );

    expect(suggestion.nextTarget, contains('Prescrição cumprida'));
  });

  test('prescrição fixa nunca sugere uma décima terceira repetição', () {
    const fixedExercise = Exercise(
      id: 'crucifixo',
      name: 'Crucifixo',
      muscle: 'Peito',
      description: '',
      reps: '3x 12',
      rest: '60 seg',
    );
    final history = <WorkoutHistoryItem>[
      WorkoutHistoryItem(
        id: 'history-fixed',
        routineName: 'Treino A',
        date: DateTime(2026, 8, 9),
        duration: '30:00',
        exercises: <ExerciseLog>[
          ExerciseLog(
            exerciseId: fixedExercise.id,
            exerciseName: fixedExercise.name,
            sets: const <ExerciseSet>[
              ExerciseSet(reps: 12, weight: 0),
              ExerciseSet(reps: 12, weight: 0),
              ExerciseSet(reps: 12, weight: 0),
            ],
          ),
        ],
      ),
    ];

    final suggestion = service.buildSuggestion(
      exercise: fixedExercise,
      history: history,
    );

    expect(suggestion.nextTarget, contains('Prescrição cumprida'));
    expect(suggestion.nextTarget, isNot(contains('13')));
  });

  test('ignora carga marcada como não comparável', () {
    final history = <WorkoutHistoryItem>[
      WorkoutHistoryItem(
        id: 'history-new-machine',
        routineName: 'Treino A',
        date: DateTime(2026, 8, 10),
        duration: '30:00',
        exercises: <ExerciseLog>[
          ExerciseLog(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            isLoadComparable: false,
            sets: const <ExerciseSet>[
              ExerciseSet(reps: 10, weight: 80),
              ExerciseSet(reps: 10, weight: 80),
              ExerciseSet(reps: 10, weight: 80),
            ],
          ),
        ],
      ),
      WorkoutHistoryItem(
        id: 'history-comparable',
        routineName: 'Treino A',
        date: DateTime(2026, 8, 8),
        duration: '30:00',
        exercises: <ExerciseLog>[
          ExerciseLog(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            sets: const <ExerciseSet>[
              ExerciseSet(reps: 8, weight: 40),
              ExerciseSet(reps: 8, weight: 40),
              ExerciseSet(reps: 8, weight: 40),
            ],
          ),
        ],
      ),
    ];

    final suggestion = service.buildSuggestion(
      exercise: exercise,
      history: history,
    );

    expect(suggestion.lastPerformance, contains('40 kg'));
    expect(suggestion.lastPerformance, isNot(contains('80 kg')));
  });

  test('modo seguir a ficha não cria progressão automática', () {
    final history = <WorkoutHistoryItem>[
      WorkoutHistoryItem(
        id: 'history-follow-plan',
        routineName: 'Treino A',
        date: DateTime(2026, 8, 11),
        duration: '30:00',
        exercises: <ExerciseLog>[
          ExerciseLog(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            sets: const <ExerciseSet>[
              ExerciseSet(reps: 10, weight: 40),
              ExerciseSet(reps: 10, weight: 40),
              ExerciseSet(reps: 10, weight: 40),
            ],
          ),
        ],
      ),
    ];

    final suggestion = service.buildSuggestion(
      exercise: exercise,
      history: history,
      mode: WorkoutProgressionMode.followPlan,
    );

    expect(suggestion.nextTarget, contains('conforme a ficha'));
    expect(suggestion.nextTarget, isNot(contains('incremento')));
    expect(suggestion.source, contains('modo Seguir a ficha'));
  });

  test('modo dentro da faixa não sugere aumento de carga no topo', () {
    final history = <WorkoutHistoryItem>[
      WorkoutHistoryItem(
        id: 'history-range',
        routineName: 'Treino A',
        date: DateTime(2026, 8, 11),
        duration: '30:00',
        exercises: <ExerciseLog>[
          ExerciseLog(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            sets: const <ExerciseSet>[
              ExerciseSet(reps: 10, weight: 40),
              ExerciseSet(reps: 10, weight: 40),
              ExerciseSet(reps: 10, weight: 40),
            ],
          ),
        ],
      ),
    ];

    final suggestion = service.buildSuggestion(
      exercise: exercise,
      history: history,
      mode: WorkoutProgressionMode.withinRange,
    );

    expect(suggestion.nextTarget, contains('Repita os alvos'));
    expect(suggestion.reason, contains('não sugere aumento automático'));
  });

  test('RIR percebido no limite impede aumento de dificuldade', () {
    final history = <WorkoutHistoryItem>[
      WorkoutHistoryItem(
        id: 'history-rir-zero',
        routineName: 'Treino A',
        date: DateTime(2026, 8, 11),
        duration: '30:00',
        exercises: <ExerciseLog>[
          ExerciseLog(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            perceivedRir: 0,
            sets: const <ExerciseSet>[
              ExerciseSet(reps: 10, weight: 40),
              ExerciseSet(reps: 10, weight: 40),
              ExerciseSet(reps: 10, weight: 40),
            ],
          ),
        ],
      ),
    ];

    final suggestion = service.buildSuggestion(
      exercise: exercise,
      history: history,
      mode: WorkoutProgressionMode.repsThenLoad,
    );

    expect(suggestion.nextTarget, contains('não aumente'));
    expect(suggestion.reason, contains('RIR 0'));
    expect(suggestion.source, contains('RIR 0 informado'));
  });

  test('RIR abaixo do alvo prescrito é somente um freio auxiliar', () {
    final exerciseWithRir = exercise.copyWith(
      advancedPrescription: const AdvancedExercisePrescription(
        weeks: <WorkoutWeekPrescription>[
          WorkoutWeekPrescription(
            weekNumber: 1,
            sets: <WorkoutSetPrescription>[
              WorkoutSetPrescription(setNumber: 1, target: '8-10'),
              WorkoutSetPrescription(setNumber: 2, target: '8-10'),
              WorkoutSetPrescription(
                setNumber: 3,
                target: '8-10',
                targetRir: 2,
              ),
            ],
          ),
        ],
      ),
    );
    final history = <WorkoutHistoryItem>[
      WorkoutHistoryItem(
        id: 'history-rir-target',
        routineName: 'Treino A',
        date: DateTime(2026, 8, 11),
        duration: '30:00',
        exercises: <ExerciseLog>[
          ExerciseLog(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            perceivedRir: 1,
            sets: const <ExerciseSet>[
              ExerciseSet(reps: 10, weight: 40),
              ExerciseSet(reps: 10, weight: 40),
              ExerciseSet(reps: 10, weight: 40),
            ],
          ),
        ],
      ),
    ];

    final suggestion = service.buildSuggestion(
      exercise: exerciseWithRir,
      history: history,
      mode: WorkoutProgressionMode.repsThenLoad,
    );

    expect(suggestion.nextTarget, contains('não aumente'));
    expect(suggestion.reason, contains('abaixo do RIR 2'));
  });

  test('isometria por tempo nunca transforma segundos em repetições', () {
    const isometry = Exercise(
      id: 'prancha',
      name: 'Prancha isométrica',
      muscle: 'Abdômen',
      description: '',
      reps: '3x 30 segundos',
      rest: '45 seg',
    );
    final history = <WorkoutHistoryItem>[
      WorkoutHistoryItem(
        id: 'history-isometry',
        routineName: 'Core',
        date: DateTime(2026, 8, 11),
        duration: '10:00',
        exercises: <ExerciseLog>[
          ExerciseLog(
            exerciseId: isometry.id,
            exerciseName: isometry.name,
            sets: const <ExerciseSet>[
              ExerciseSet(reps: 30, weight: 0),
              ExerciseSet(reps: 30, weight: 0),
              ExerciseSet(reps: 30, weight: 0),
            ],
          ),
        ],
      ),
    ];

    final suggestion = service.buildSuggestion(
      exercise: isometry,
      history: history,
      mode: WorkoutProgressionMode.repsThenLoad,
    );

    expect(suggestion.nextTarget, contains('duração prescrita'));
    expect(suggestion.nextTarget, isNot(contains('31 repetições')));
    expect(suggestion.reason, contains('segundos não são tratados'));
  });
}
