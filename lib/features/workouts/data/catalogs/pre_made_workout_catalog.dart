import '../../../../models/exercise.dart';
import '../../../exercises/domain/exercise_catalog.dart';
import '../../domain/models/cardio_log.dart';

List<WorkoutProgram> buildPreMadeWorkoutPrograms() {
  return [
    _buildHypertrophyAbcProgram(),
    _buildConditioningProgram(),
    _buildAdaptationProgram(),
    _buildUpperLowerProgram(),
    _buildPplFiveDaysProgram(),
  ];
}

WorkoutProgram _buildHypertrophyAbcProgram() {
  const programName = 'Hipertrofia Moderna (ABC)';

  return WorkoutProgram(
    id: 'prog_hipertrofia_abc',
    name: programName,
    focus:
        'Divisão clássica em três fichas, com volume moderado e progressão de carga.',
    level: 'Intermediário',
    objective: 'Hipertrofia',
    recommendedFrequency: 3,
    estimatedDuration: '50–70 min',
    routines: [
      WorkoutRoutine(
        id: 'rout_hip_A',
        name: 'Treino A - Peito, Ombro e Tríceps',
        focus: 'Movimentos de empurrar e estabilidade dos ombros',
        groupName: programName,
        exercises: [
          ExerciseCatalog.prescribedExercise(
            id: 'p12',
            description: 'Controle a descida e mantenha as escápulas apoiadas.',
            reps: '4x 8-12',
            rest: '75 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'p4',
            description: 'Use amplitude confortável e sem perder o controle.',
            reps: '3x 10-12',
            rest: '60 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'o3',
            description: 'Evite arquear excessivamente a lombar.',
            reps: '3x 8-12',
            rest: '75 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'o4',
            description: 'Suba até a linha dos ombros sem embalo.',
            reps: '3x 12-15',
            rest: '45 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'tr2',
            description: 'Mantenha os cotovelos próximos ao tronco.',
            reps: '3x 10-12',
            rest: '45 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'tr5',
            description: 'Mantenha o braço estável durante o movimento.',
            reps: '2x 12-15',
            rest: '45 seg',
          ),
        ],
      ),
      WorkoutRoutine(
        id: 'rout_hip_B',
        name: 'Treino B - Costas e Bíceps',
        focus: 'Puxadas, remadas e flexão de cotovelo',
        groupName: programName,
        exercises: [
          ExerciseCatalog.prescribedExercise(
            id: 'c1',
            description: 'Conduza os cotovelos para baixo e evite balançar.',
            reps: '4x 8-12',
            rest: '75 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'c5',
            description: 'Aproxime as escápulas no final da remada.',
            reps: '4x 8-12',
            rest: '75 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'c7',
            description: 'Mantenha o tronco firme e puxe com o cotovelo.',
            reps: '3x 10-12',
            rest: '60 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'c10',
            description: 'Abra os braços sem elevar os ombros.',
            reps: '3x 12-15',
            rest: '45 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'b1',
            description: 'Evite projetar os cotovelos e balançar o tronco.',
            reps: '3x 8-12',
            rest: '60 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'b3',
            description: 'Use pegada neutra e movimento controlado.',
            reps: '2x 12-15',
            rest: '45 seg',
          ),
        ],
      ),
      WorkoutRoutine(
        id: 'rout_hip_C',
        name: 'Treino C - Pernas e Abdômen',
        focus: 'Coxas, glúteos, panturrilhas e estabilidade do tronco',
        groupName: programName,
        exercises: [
          ExerciseCatalog.prescribedExercise(
            id: 'pe2',
            description: 'Desça até onde consiga manter a postura estável.',
            reps: '4x 8-12',
            rest: '90 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'pe4',
            description: 'Mantenha os joelhos alinhados com os pés.',
            reps: '4x 10-12',
            rest: '75 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'pe6',
            description: 'Controle a volta e evite tirar o quadril do banco.',
            reps: '3x 12-15',
            rest: '60 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'pe8',
            description: 'Não deixe o quadril levantar durante a flexão.',
            reps: '3x 10-12',
            rest: '60 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'pe19',
            description: 'Leve o quadril para trás e preserve a coluna neutra.',
            reps: '3x 8-12',
            rest: '75 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'pe17',
            description: 'Faça uma pausa curta no topo.',
            reps: '4x 12-15',
            rest: '45 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'ab5',
            description: 'Mantenha o corpo alinhado e respire normalmente.',
            reps: '3x 30-45s',
            rest: '45 seg',
          ),
        ],
      ),
    ],
  );
}

WorkoutProgram _buildConditioningProgram() {
  const programName = 'Seca Tudo (Projeto Verão)';

  return WorkoutProgram(
    id: 'prog_seca_tudo',
    name: programName,
    focus:
        'Treinos curtos em pares de exercícios, com pausas menores e cardio leve ao final.',
    level: 'Intermediário',
    objective: 'Condicionamento',
    recommendedFrequency: 2,
    estimatedDuration: '35–50 min',
    routines: [
      WorkoutRoutine(
        id: 'rout_seca_A',
        name: 'Treino A - Superiores Intensos',
        focus: 'Circuito de empurrar, puxar e abdômen',
        groupName: programName,
        exercises: [
          ExerciseCatalog.prescribedExercise(
            id: 'p12',
            description: 'Faça em sequência com a remada baixa.',
            reps: '3x 12-15',
            rest: '0 seg',
            isSuperset: true,
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'c5',
            description: 'Finalize o par e então descanse.',
            reps: '3x 12-15',
            rest: '45 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'o4',
            description: 'Faça em sequência com o voador inverso.',
            reps: '3x 12-15',
            rest: '0 seg',
            isSuperset: true,
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'c10',
            description: 'Movimento controlado e ombros afastados das orelhas.',
            reps: '3x 12-15',
            rest: '45 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'ab1',
            description: 'Expire durante a flexão do tronco.',
            reps: '3x 15-20',
            rest: '30 seg',
          ),
        ],
        cardio: const [
          RoutineCardio(
            id: 'cardio_seca_A',
            modality: CardioModality.treadmill,
            plannedDurationMinutes: 15,
            notes: 'Após a musculação, em intensidade leve a moderada.',
          ),
        ],
      ),
      WorkoutRoutine(
        id: 'rout_seca_B',
        name: 'Treino B - Inferiores Express',
        focus: 'Coxas, glúteos, abdômen e cardio curto',
        groupName: programName,
        exercises: [
          ExerciseCatalog.prescribedExercise(
            id: 'pe15',
            description: 'Use passos firmes e joelho alinhado.',
            reps: '3x 20',
            rest: '45 seg',
            customNote: '10 repetições por perna',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'pe6',
            description: 'Faça em sequência com a mesa flexora.',
            reps: '3x 15',
            rest: '0 seg',
            isSuperset: true,
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'pe7',
            description: 'Finalize o par e então descanse.',
            reps: '3x 12-15',
            rest: '45 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'pe12',
            description:
                'Contraia os glúteos no topo sem hiperestender a lombar.',
            reps: '3x 12-15',
            rest: '45 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'ab5',
            description: 'Mantenha o quadril alinhado ao tronco.',
            reps: '3x 30-45s',
            rest: '30 seg',
          ),
        ],
        cardio: const [
          RoutineCardio(
            id: 'cardio_seca_B',
            modality: CardioModality.stationaryBike,
            plannedDurationMinutes: 15,
            notes: 'Após a musculação, em intensidade leve a moderada.',
          ),
        ],
      ),
    ],
  );
}

WorkoutProgram _buildAdaptationProgram() {
  const programName = 'Adaptação - 3 dias';

  return WorkoutProgram(
    id: 'prog_adaptacao_3_dias',
    name: programName,
    focus:
        'Rotina de corpo inteiro para aprender movimentos, criar regularidade e evoluir com calma.',
    level: 'Iniciante',
    objective: 'Adaptação',
    recommendedFrequency: 3,
    estimatedDuration: '40–55 min',
    routines: [
      WorkoutRoutine(
        id: 'rout_adapt_A',
        name: 'Treino A - Corpo Inteiro',
        focus: 'Base com máquinas e movimentos simples',
        groupName: programName,
        exercises: [
          ExerciseCatalog.prescribedExercise(
            id: 'pe5',
            description: 'Use amplitude confortável e mantenha os pés firmes.',
            reps: '3x 10-12',
            rest: '75 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'p12',
            description: 'Mantenha as costas apoiadas e controle a descida.',
            reps: '3x 10-12',
            rest: '60 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'c5',
            description: 'Puxe sem balançar e aproxime as escápulas.',
            reps: '3x 10-12',
            rest: '60 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'o3',
            description: 'Ajuste o banco e não force a amplitude.',
            reps: '2x 10-12',
            rest: '60 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'pe8',
            description: 'Controle a volta do aparelho.',
            reps: '2x 12-15',
            rest: '45 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'ab1',
            description: 'Faça o movimento devagar e sem puxar o pescoço.',
            reps: '2x 12-15',
            rest: '45 seg',
          ),
        ],
      ),
      WorkoutRoutine(
        id: 'rout_adapt_B',
        name: 'Treino B - Corpo Inteiro',
        focus: 'Coordenação, postura e controle de movimento',
        groupName: programName,
        exercises: [
          ExerciseCatalog.prescribedExercise(
            id: 'pe2',
            description: 'Use pouca carga até dominar a trajetória.',
            reps: '3x 10-12',
            rest: '75 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'p5',
            description: 'Mantenha as escápulas apoiadas.',
            reps: '3x 10-12',
            rest: '60 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'c2',
            description: 'Puxe o triângulo em direção à parte alta do peito.',
            reps: '3x 10-12',
            rest: '60 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'o4',
            description: 'Use carga leve e evite elevar os ombros.',
            reps: '2x 12-15',
            rest: '45 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'pe12',
            description: 'Suba apertando os glúteos e desça com controle.',
            reps: '3x 10-12',
            rest: '60 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'ab5',
            description: 'Interrompa quando perder o alinhamento.',
            reps: '3x 20-30s',
            rest: '45 seg',
          ),
        ],
      ),
      WorkoutRoutine(
        id: 'rout_adapt_C',
        name: 'Treino C - Corpo Inteiro',
        focus: 'Repetição dos padrões com pequenas variações',
        groupName: programName,
        exercises: [
          ExerciseCatalog.prescribedExercise(
            id: 'pe4',
            description: 'Mantenha os joelhos alinhados e não trave no topo.',
            reps: '3x 10-12',
            rest: '75 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'p9',
            description: 'Aproxime as mãos sem tirar os ombros do apoio.',
            reps: '3x 10-12',
            rest: '60 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'c6',
            description: 'Mantenha o peito apoiado e puxe com os cotovelos.',
            reps: '3x 10-12',
            rest: '60 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'tr2',
            description: 'Evite abrir os cotovelos.',
            reps: '2x 12-15',
            rest: '45 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'b3',
            description: 'Não balance o tronco durante a rosca.',
            reps: '2x 12-15',
            rest: '45 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'pe17',
            description: 'Use amplitude completa e ritmo controlado.',
            reps: '3x 12-15',
            rest: '45 seg',
          ),
        ],
      ),
    ],
  );
}

WorkoutProgram _buildUpperLowerProgram() {
  const programName = 'Superior/Inferior - 4 dias';

  return WorkoutProgram(
    id: 'prog_superior_inferior_4_dias',
    name: programName,
    focus:
        'Cada grupo muscular é trabalhado duas vezes por semana, alternando membros superiores e inferiores.',
    level: 'Intermediário',
    objective: 'Hipertrofia',
    recommendedFrequency: 4,
    estimatedDuration: '55–70 min',
    routines: [
      WorkoutRoutine(
        id: 'rout_upper_lower_upper_A',
        name: 'Superior A',
        focus: 'Peito e costas com movimentos básicos',
        groupName: programName,
        exercises: [
          ExerciseCatalog.prescribedExercise(
            id: 'p1',
            description: 'Mantenha os pés firmes e controle a barra.',
            reps: '4x 6-10',
            rest: '90 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'c1',
            description: 'Puxe com os cotovelos sem inclinar o tronco.',
            reps: '4x 8-12',
            rest: '75 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'o1',
            description: 'Evite arquear a lombar.',
            reps: '3x 8-12',
            rest: '75 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'c5',
            description: 'Aproxime as escápulas no final.',
            reps: '3x 10-12',
            rest: '60 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'tr2',
            description: 'Cotovelos próximos ao tronco.',
            reps: '3x 10-15',
            rest: '45 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'b2',
            description: 'Alterne sem girar o corpo.',
            reps: '3x 10-12',
            rest: '45 seg',
          ),
        ],
      ),
      WorkoutRoutine(
        id: 'rout_upper_lower_lower_A',
        name: 'Inferior A',
        focus: 'Quadríceps, glúteos e estabilidade',
        groupName: programName,
        exercises: [
          ExerciseCatalog.prescribedExercise(
            id: 'pe1',
            description: 'Priorize técnica e amplitude segura.',
            reps: '4x 6-10',
            rest: '120 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'pe4',
            description: 'Não deixe os joelhos fecharem.',
            reps: '3x 10-12',
            rest: '75 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'pe7',
            description: 'Controle a fase de retorno.',
            reps: '3x 10-12',
            rest: '60 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'pe12',
            description: 'Faça uma pausa curta no topo.',
            reps: '3x 8-12',
            rest: '75 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'pe16',
            description: 'Suba e desça com amplitude completa.',
            reps: '4x 12-15',
            rest: '45 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'ab5',
            description: 'Mantenha o corpo alinhado.',
            reps: '3x 30-45s',
            rest: '45 seg',
          ),
        ],
      ),
      WorkoutRoutine(
        id: 'rout_upper_lower_upper_B',
        name: 'Superior B',
        focus: 'Variações para peito, costas, ombros e braços',
        groupName: programName,
        exercises: [
          ExerciseCatalog.prescribedExercise(
            id: 'p4',
            description: 'Controle os halteres em toda a amplitude.',
            reps: '4x 8-12',
            rest: '75 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'c7',
            description: 'Puxe com o cotovelo e mantenha o tronco estável.',
            reps: '4x 8-12',
            rest: '75 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'o4',
            description: 'Não use impulso para subir os halteres.',
            reps: '3x 12-15',
            rest: '45 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'c2',
            description: 'Mantenha o peito elevado durante a puxada.',
            reps: '3x 10-12',
            rest: '60 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'tr3',
            description: 'Mantenha os braços estáveis.',
            reps: '3x 10-12',
            rest: '45 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'b3',
            description: 'Use pegada neutra e ritmo constante.',
            reps: '3x 10-12',
            rest: '45 seg',
          ),
        ],
      ),
      WorkoutRoutine(
        id: 'rout_upper_lower_lower_B',
        name: 'Inferior B',
        focus: 'Posteriores de coxa, glúteos e quadríceps',
        groupName: programName,
        exercises: [
          ExerciseCatalog.prescribedExercise(
            id: 'pe11',
            description:
                'Use técnica consistente e carga que permita controle.',
            reps: '4x 5-8',
            rest: '120 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'pe3',
            description: 'Desça sem perder o apoio da lombar.',
            reps: '3x 8-12',
            rest: '90 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'pe6',
            description: 'Segure brevemente no topo.',
            reps: '3x 12-15',
            rest: '60 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'pe8',
            description: 'Controle o retorno do aparelho.',
            reps: '3x 10-12',
            rest: '60 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'pe17',
            description: 'Use amplitude completa.',
            reps: '4x 12-15',
            rest: '45 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'ab4',
            description: 'Flexione o tronco sem puxar com os braços.',
            reps: '3x 12-15',
            rest: '45 seg',
          ),
        ],
      ),
    ],
  );
}

WorkoutProgram _buildPplFiveDaysProgram() {
  const programName = 'PPL + Superior/Inferior - 5 dias';

  return WorkoutProgram(
    id: 'prog_ppl_5_dias',
    name: programName,
    focus:
        'Cinco sessões para distribuir o volume entre empurrar, puxar, pernas e dois reforços semanais.',
    level: 'Intermediário/Avançado',
    objective: 'Hipertrofia',
    recommendedFrequency: 5,
    estimatedDuration: '60–75 min',
    routines: [
      WorkoutRoutine(
        id: 'rout_ppl_push',
        name: 'Push - Peito, Ombro e Tríceps',
        focus: 'Movimentos de empurrar',
        groupName: programName,
        exercises: [
          ExerciseCatalog.prescribedExercise(
            id: 'p1',
            description: 'Controle a barra e mantenha as escápulas estáveis.',
            reps: '4x 6-10',
            rest: '90 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'p4',
            description: 'Use amplitude confortável.',
            reps: '3x 8-12',
            rest: '75 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'o1',
            description: 'Evite arquear a lombar.',
            reps: '3x 8-12',
            rest: '75 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'o4',
            description: 'Suba sem impulso.',
            reps: '3x 12-15',
            rest: '45 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'tr3',
            description: 'Mantenha os cotovelos apontados para frente.',
            reps: '3x 10-12',
            rest: '60 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'tr2',
            description: 'Estenda completamente sem abrir os cotovelos.',
            reps: '3x 12-15',
            rest: '45 seg',
          ),
        ],
      ),
      WorkoutRoutine(
        id: 'rout_ppl_pull',
        name: 'Pull - Costas e Bíceps',
        focus: 'Puxadas, remadas e braços',
        groupName: programName,
        exercises: [
          ExerciseCatalog.prescribedExercise(
            id: 'c1',
            description: 'Puxe com os cotovelos e mantenha o peito alto.',
            reps: '4x 8-12',
            rest: '75 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'c3',
            description: 'Mantenha a coluna neutra.',
            reps: '4x 6-10',
            rest: '90 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'c7',
            description: 'Evite girar o tronco.',
            reps: '3x 10-12',
            rest: '60 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'c10',
            description: 'Abra os braços sem elevar os ombros.',
            reps: '3x 12-15',
            rest: '45 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'b1',
            description: 'Não balance o corpo.',
            reps: '3x 8-12',
            rest: '60 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'b3',
            description: 'Mantenha os punhos neutros.',
            reps: '3x 10-12',
            rest: '45 seg',
          ),
        ],
      ),
      WorkoutRoutine(
        id: 'rout_ppl_legs',
        name: 'Legs - Pernas Completas',
        focus: 'Quadríceps, posteriores, glúteos e panturrilhas',
        groupName: programName,
        exercises: [
          ExerciseCatalog.prescribedExercise(
            id: 'pe1',
            description: 'Priorize técnica e amplitude segura.',
            reps: '4x 6-10',
            rest: '120 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'pe4',
            description: 'Mantenha os pés firmes e os joelhos alinhados.',
            reps: '4x 10-12',
            rest: '90 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'pe6',
            description: 'Controle a volta e segure no topo.',
            reps: '3x 12-15',
            rest: '60 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'pe8',
            description: 'Não deixe o quadril levantar.',
            reps: '3x 10-12',
            rest: '60 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'pe10',
            description: 'Leve o quadril para trás com a coluna neutra.',
            reps: '3x 8-12',
            rest: '90 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'pe17',
            description: 'Faça uma pausa curta no topo.',
            reps: '4x 12-15',
            rest: '45 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'ab5',
            description: 'Mantenha o corpo alinhado.',
            reps: '3x 30-45s',
            rest: '45 seg',
          ),
        ],
      ),
      WorkoutRoutine(
        id: 'rout_ppl_upper',
        name: 'Superior - Reforço',
        focus: 'Segundo estímulo de peito, costas, ombros e braços',
        groupName: programName,
        exercises: [
          ExerciseCatalog.prescribedExercise(
            id: 'p12',
            description: 'Controle a descida.',
            reps: '3x 8-12',
            rest: '75 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'c6',
            description: 'Mantenha o peito apoiado.',
            reps: '3x 8-12',
            rest: '75 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'p9',
            description: 'Não projete os ombros para frente.',
            reps: '3x 12-15',
            rest: '45 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'c2',
            description: 'Conduza os cotovelos para baixo.',
            reps: '3x 10-12',
            rest: '60 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'o4',
            description: 'Use carga moderada e sem balanço.',
            reps: '3x 12-15',
            rest: '45 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'tr2',
            description: 'Mantenha os cotovelos estáveis.',
            reps: '2x 12-15',
            rest: '45 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'b2',
            description: 'Alterne os braços sem girar o tronco.',
            reps: '2x 12-15',
            rest: '45 seg',
          ),
        ],
      ),
      WorkoutRoutine(
        id: 'rout_ppl_lower',
        name: 'Inferior - Reforço',
        focus: 'Posteriores, glúteos e segundo estímulo de quadríceps',
        groupName: programName,
        exercises: [
          ExerciseCatalog.prescribedExercise(
            id: 'pe11',
            description: 'Use técnica consistente e evite perder a postura.',
            reps: '4x 5-8',
            rest: '120 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'pe3',
            description: 'Controle a descida no aparelho.',
            reps: '3x 8-12',
            rest: '90 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'pe7',
            description: 'Controle o retorno.',
            reps: '3x 10-12',
            rest: '60 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'pe12',
            description: 'Contraia os glúteos no topo.',
            reps: '3x 8-12',
            rest: '75 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'pe18',
            description: 'Use amplitude completa.',
            reps: '4x 12-15',
            rest: '45 seg',
          ),
          ExerciseCatalog.prescribedExercise(
            id: 'ab4',
            description: 'Flexione o tronco sem puxar com os braços.',
            reps: '3x 12-15',
            rest: '45 seg',
          ),
        ],
      ),
    ],
  );
}
