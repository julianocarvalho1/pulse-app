import '../../../../models/exercise.dart';
import '../../../exercises/domain/exercise_catalog.dart';

List<WorkoutProgram> buildPreMadeWorkoutPrograms() {
  return [
    WorkoutProgram(
      id: 'prog_hipertrofia_abc',
      name: 'Hipertrofia Moderna (ABC)',
      focus: 'Divisão clássica para volume e densidade.',
      routines: [
        WorkoutRoutine(
          id: 'rout_hip_A',
          name: 'Treino A - Peito, Ombro e Tríceps',
          focus: 'Foco em movimentos de empurrar',
          groupName: 'Hipertrofia Moderna (ABC)',
          exercises: [
            ExerciseCatalog.prescribedExercise(
              id: 'p12',
              description: 'Controle bem a descida.',
              reps: '4x 8-12',
              rest: '60 seg',
            ),
            ExerciseCatalog.prescribedExercise(
              id: 'p7',
              description: 'Foque no alongamento do músculo.',
              reps: '3x 12',
              rest: '45 seg',
            ),
            ExerciseCatalog.prescribedExercise(
              id: 'o2',
              description: 'Sente-se com a coluna reta.',
              reps: '4x 10',
              rest: '60 seg',
            ),
            ExerciseCatalog.prescribedExercise(
              id: 'tr1',
              description: 'Mantenha o cotovelo colado no corpo.',
              reps: '3x 12',
              rest: '45 seg',
              customNote: 'Falha Muscular | Use a corda se preferir',
            ),
          ],
        ),
        WorkoutRoutine(
          id: 'rout_hip_B',
          name: 'Treino B - Costas e Bíceps',
          focus: 'Foco em movimentos de puxar',
          groupName: 'Hipertrofia Moderna (ABC)',
          exercises: [
            ExerciseCatalog.prescribedExercise(
              id: 'c1',
              description: 'Estufe o peito na puxada.',
              reps: '4x 10',
              rest: '60 seg',
            ),
            ExerciseCatalog.prescribedExercise(
              id: 'c3',
              description: 'Mantenha a lombar travada.',
              reps: '4x 8-10',
              rest: '60 seg',
            ),
            ExerciseCatalog.prescribedExercise(
              id: 'b1',
              description: 'Não balance o tronco.',
              reps: '3x 12',
              rest: '45 seg',
            ),
            ExerciseCatalog.prescribedExercise(
              id: 'b4',
              description: 'Isole completamente o músculo.',
              reps: '3x 10',
              rest: '45 seg',
              customNote: 'Drop-Set | Na última série',
            ),
          ],
        ),
        WorkoutRoutine(
          id: 'rout_hip_C',
          name: 'Treino C - Pernas e Abdômen',
          focus: 'Membros inferiores e abdômen',
          groupName: 'Hipertrofia Moderna (ABC)',
          exercises: [
            ExerciseCatalog.prescribedExercise(
              id: 'pe1',
              description: 'Quebre a paralela se tiver mobilidade.',
              reps: '4x 8-10',
              rest: '90 seg',
            ),
            ExerciseCatalog.prescribedExercise(
              id: 'pe4',
              description: 'Não trave o joelho em cima.',
              reps: '4x 12',
              rest: '60 seg',
            ),
            ExerciseCatalog.prescribedExercise(
              id: 'pe6',
              description: 'Aperte no topo por 1 segundo.',
              reps: '3x 15',
              rest: '45 seg',
              customNote: 'Falha Muscular',
            ),
            ExerciseCatalog.prescribedExercise(
              id: 'ab1',
              description: 'Foque em dobrar o tronco.',
              reps: '4x 15-20',
              rest: '45 seg',
            ),
          ],
        ),
      ],
    ),
    WorkoutProgram(
      id: 'prog_seca_tudo',
      name: 'Seca Tudo (Projeto Verão)',
      focus: 'Alta intensidade, bi-sets e pausas curtas.',
      routines: [
        WorkoutRoutine(
          id: 'rout_seca_A',
          name: 'Treino A - Superiores Intensos',
          focus: 'Gasto Calórico',
          groupName: 'Seca Tudo (Projeto Verão)',
          exercises: [
            ExerciseCatalog.prescribedExercise(
              id: 'p12',
              description: 'Sem pausa.',
              reps: '3x 15',
              rest: '0 seg',
              isSuperset: true,
            ),
            ExerciseCatalog.prescribedExercise(
              id: 'c5',
              description: 'Direto do supino articulado.',
              reps: '3x 15',
              rest: '45 seg',
            ),
            ExerciseCatalog.prescribedExercise(
              id: 'o7',
              description: 'Movimento controlado.',
              reps: '3x 15',
              rest: '30 seg',
            ),
          ],
        ),
        WorkoutRoutine(
          id: 'rout_seca_B',
          name: 'Treino B - Inferiores Express',
          focus: 'Gasto Calórico',
          groupName: 'Seca Tudo (Projeto Verão)',
          exercises: [
            ExerciseCatalog.prescribedExercise(
              id: 'pe15',
              description: 'Passos largos.',
              reps: '4x 20',
              rest: '45 seg',
              customNote: '10 cada perna',
            ),
            ExerciseCatalog.prescribedExercise(
              id: 'pe6',
              description: 'Explosivo.',
              reps: '3x 15',
              rest: '0 seg',
              isSuperset: true,
            ),
            ExerciseCatalog.prescribedExercise(
              id: 'ab1',
              description: 'Até queimar.',
              reps: '3x 20',
              rest: '45 seg',
            ),
          ],
        ),
      ],
    ),
  ];
}
