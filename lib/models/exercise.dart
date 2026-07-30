import 'dart:collection';

import 'package:flutter/foundation.dart';

@immutable
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.muscle,
    required this.description,
    required this.reps,
    required this.rest,
    this.isSuperset = false,
    this.customNote = '',
  });

  final String id;
  final String name;
  final String muscle;
  final String description;
  final String reps;
  final String rest;
  final bool isSuperset;
  final String customNote;

  Exercise copyWith({
    String? id,
    String? name,
    String? muscle,
    String? description,
    String? reps,
    String? rest,
    bool? isSuperset,
    String? customNote,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      muscle: muscle ?? this.muscle,
      description: description ?? this.description,
      reps: reps ?? this.reps,
      rest: rest ?? this.rest,
      isSuperset: isSuperset ?? this.isSuperset,
      customNote: customNote ?? this.customNote,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'muscle': muscle,
      'description': description,
      'reps': reps,
      'rest': rest,
      'isSuperset': isSuperset,
      'customNote': customNote,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      muscle: map['muscle']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      reps: map['reps']?.toString() ?? '3x 10-12',
      rest: map['rest']?.toString() ?? '60 seg',
      isSuperset: map['isSuperset'] == true,
      customNote: map['customNote']?.toString() ?? '',
    );
  }
}

@immutable
class WorkoutRoutine {
  WorkoutRoutine({
    required this.id,
    required this.name,
    required this.focus,
    this.groupName = '',
    required List<Exercise> exercises,
  }) : exercises = UnmodifiableListView<Exercise>(
         List<Exercise>.from(exercises),
       );

  final String id;
  final String name;
  final String focus;
  final String groupName;
  final List<Exercise> exercises;

  WorkoutRoutine copyWith({
    String? id,
    String? name,
    String? focus,
    String? groupName,
    List<Exercise>? exercises,
  }) {
    return WorkoutRoutine(
      id: id ?? this.id,
      name: name ?? this.name,
      focus: focus ?? this.focus,
      groupName: groupName ?? this.groupName,
      exercises: exercises ?? this.exercises,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'focus': focus,
      'groupName': groupName,
      'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
    };
  }

  factory WorkoutRoutine.fromMap(Map<String, dynamic> map) {
    final rawExercises = map['exercises'];

    return WorkoutRoutine(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      focus: map['focus']?.toString() ?? '',
      groupName: map['groupName']?.toString() ?? '',
      exercises: rawExercises is List
          ? rawExercises
                .whereType<Map>()
                .map(
                  (exercise) =>
                      Exercise.fromMap(Map<String, dynamic>.from(exercise)),
                )
                .toList()
          : const <Exercise>[],
    );
  }
}

@immutable
class WorkoutProgram {
  WorkoutProgram({
    required this.id,
    required this.name,
    required this.focus,
    required List<WorkoutRoutine> routines,
  }) : routines = UnmodifiableListView<WorkoutRoutine>(
         List<WorkoutRoutine>.from(routines),
       );

  final String id;
  final String name;
  final String focus;
  final List<WorkoutRoutine> routines;

  WorkoutProgram copyWith({
    String? id,
    String? name,
    String? focus,
    List<WorkoutRoutine>? routines,
  }) {
    return WorkoutProgram(
      id: id ?? this.id,
      name: name ?? this.name,
      focus: focus ?? this.focus,
      routines: routines ?? this.routines,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'focus': focus,
      'routines': routines.map((routine) => routine.toMap()).toList(),
    };
  }

  factory WorkoutProgram.fromMap(Map<String, dynamic> map) {
    final rawRoutines = map['routines'];

    return WorkoutProgram(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      focus: map['focus']?.toString() ?? '',
      routines: rawRoutines is List
          ? rawRoutines
                .whereType<Map>()
                .map(
                  (routine) => WorkoutRoutine.fromMap(
                    Map<String, dynamic>.from(routine),
                  ),
                )
                .toList()
          : const <WorkoutRoutine>[],
    );
  }
}

// ==========================================
// BANCO DE DADOS DE EXERCÍCIOS
// ==========================================
final List<Exercise> exerciseDatabase = [
  // PEITO
  Exercise(
    id: 'p1',
    name: 'Supino Reto com Barra',
    muscle: 'Peito',
    description: 'Foco no peitoral maior.',
    reps: '4x 8-10',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'p2',
    name: 'Supino Reto com Halteres',
    muscle: 'Peito',
    description: 'Maior amplitude de movimento.',
    reps: '4x 8-10',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'p3',
    name: 'Supino Inclinado com Barra',
    muscle: 'Peito',
    description: 'Foco na porção superior.',
    reps: '4x 8-10',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'p4',
    name: 'Supino Inclinado com Halteres',
    muscle: 'Peito',
    description: 'Porção superior com halteres.',
    reps: '3x 10-12',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'p5',
    name: 'Supino Inclinado Articulado',
    muscle: 'Peito',
    description: 'Máquina articulada convergente superior.',
    reps: '3x 10-12',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'p6',
    name: 'Supino Declinado',
    muscle: 'Peito',
    description: 'Foco na porção inferior.',
    reps: '3x 8-10',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'p7',
    name: 'Crucifixo com Halteres',
    muscle: 'Peito',
    description: 'Isolamento do peitoral utilizando halteres no banco reto.',
    reps: '3x 10-12',
    rest: '1 min',
  ),
  Exercise(
    id: 'p8',
    name: 'Crucifixo Inclinado',
    muscle: 'Peito',
    description:
        'Isolamento do peitoral superior utilizando halteres no banco inclinado.',
    reps: '3x 10-12',
    rest: '1 min',
  ),
  Exercise(
    id: 'p9',
    name: 'Peck Deck (Voador)',
    muscle: 'Peito',
    description: 'Máquina para isolamento (braços flexionados).',
    reps: '2x 12-15',
    rest: '1 min',
  ),
  Exercise(
    id: 'p10',
    name: 'Crossover Polia Alta',
    muscle: 'Peito',
    description: 'Foco porção inferior/miolo do peitoral.',
    reps: '3x 12-15',
    rest: '1 min',
  ),
  Exercise(
    id: 'p11',
    name: 'Crossover Polia Baixa',
    muscle: 'Peito',
    description: 'Foco porção clavicular (superior).',
    reps: '3x 12-15',
    rest: '1 min',
  ),
  Exercise(
    id: 'p12',
    name: 'Supino Reto Articulado',
    muscle: 'Peito',
    description: 'Máquina articulada reta. Foco central do peito.',
    reps: '3x 10-12',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'p13',
    name: 'Crucifixo Máquina',
    muscle: 'Peito',
    description: 'Isolamento na máquina (braços estendidos).',
    reps: '3x 10-12',
    rest: '1 min',
  ),

  // COSTAS
  Exercise(
    id: 'c1',
    name: 'Puxada Frontal Aberta',
    muscle: 'Costas',
    description: 'Foco em expansão de dorsais.',
    reps: '3x 10-12',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'c2',
    name: 'Puxada Triângulo (Fechada)',
    muscle: 'Costas',
    description: 'Foco no miolo das costas.',
    reps: '3x 10-12',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'c3',
    name: 'Remada Curvada com Barra',
    muscle: 'Costas',
    description: 'Espessura de dorsais.',
    reps: '4x 8-10',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'c4',
    name: 'Remada Cavalinho',
    muscle: 'Costas',
    description: 'Com barra T ou máquina.',
    reps: '4x 8-10',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'c5',
    name: 'Remada Baixa Sentada',
    muscle: 'Costas',
    description: 'No triângulo ou barra reta.',
    reps: '3x 10-12',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'c6',
    name: 'Remada Articulada',
    muscle: 'Costas',
    description: 'Máquina articulada (pegada neutra ou pronada).',
    reps: '3x 10-12',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'c7',
    name: 'Serrote (Remada Unilateral)',
    muscle: 'Costas',
    description: 'Com halter apoiado no banco.',
    reps: '3x 10-12 por braço',
    rest: '1 min',
  ),
  Exercise(
    id: 'c8',
    name: 'Barra Fixa',
    muscle: 'Costas',
    description: 'Peso corporal. Puxada vertical.',
    reps: '4x 8-10',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'c9',
    name: 'Pull-down na Polia',
    muscle: 'Costas',
    description: 'Foco em grande dorsal com braços esticados.',
    reps: '3x 12-15',
    rest: '1 min',
  ),
  Exercise(
    id: 'c10',
    name: 'Voador Dorsal (Inverso)',
    muscle: 'Costas',
    description: 'Foco em posterior de ombro e miolo das costas.',
    reps: '3x 12-15',
    rest: '1 min',
  ),

  // OMBROS E TRAPÉZIO
  Exercise(
    id: 'o1',
    name: 'Desenvolvimento com Halteres',
    muscle: 'Ombros',
    description: 'Foco em deltóide anterior e medial.',
    reps: '3x 10-12',
    rest: '1 min',
  ),
  Exercise(
    id: 'o2',
    name: 'Desenvolvimento com Barra',
    muscle: 'Ombros',
    description: 'Militar em pé ou sentado.',
    reps: '4x 8-10',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'o3',
    name: 'Desenvolvimento Articulado',
    muscle: 'Ombros',
    description: 'Máquina convergente para ombros.',
    reps: '3x 10-12',
    rest: '1 min',
  ),
  Exercise(
    id: 'o4',
    name: 'Elevação Lateral com Halteres',
    muscle: 'Ombros',
    description: 'Isolamento da porção medial (lateral).',
    reps: '3x 12-15',
    rest: '1 min',
  ),
  Exercise(
    id: 'o5',
    name: 'Elevação Lateral na Polia',
    muscle: 'Ombros',
    description: 'Tensão contínua no cabo. Porção medial.',
    reps: '3x 12-15',
    rest: '1 min',
  ),
  Exercise(
    id: 'o6',
    name: 'Elevação Frontal com Halteres',
    muscle: 'Ombros',
    description: 'Porção anterior do deltóide.',
    reps: '3x 12-15',
    rest: '1 min',
  ),
  Exercise(
    id: 'o7',
    name: 'Elevação Frontal com Barra',
    muscle: 'Ombros',
    description: 'Ambas as mãos simultâneas usando barra.',
    reps: '3x 12-15',
    rest: '1 min',
  ),
  Exercise(
    id: 'o8',
    name: 'Crucifixo Inverso com Halteres',
    muscle: 'Ombros',
    description: 'Isolamento do posterior de ombro livre, tronco curvado.',
    reps: '3x 12-15',
    rest: '1 min',
  ),
  Exercise(
    id: 'o9',
    name: 'Elevação Frontal na Polia',
    muscle: 'Ombros',
    description: 'Polia baixa passando por entre as pernas (corda ou barra).',
    reps: '3x 12-15',
    rest: '1 min',
  ),
  Exercise(
    id: 't1',
    name: 'Encolhimento com Halteres',
    muscle: 'Trapézio',
    description: 'Elevação de escápulas lateralmente.',
    reps: '4x 10-12',
    rest: '1 min',
  ),
  Exercise(
    id: 't2',
    name: 'Encolhimento no Smith',
    muscle: 'Trapézio',
    description: 'Elevação de escápulas com barra guiada (cargas mais altas).',
    reps: '4x 8-10',
    rest: '1 min',
  ),

  // BÍCEPS E ANTEBRAÇO
  Exercise(
    id: 'b1',
    name: 'Rosca Direta com Barra',
    muscle: 'Bíceps',
    description: 'Barra reta ou barra W.',
    reps: '3x 10-12',
    rest: '1 min',
  ),
  Exercise(
    id: 'b2',
    name: 'Rosca Alternada com Halteres',
    muscle: 'Bíceps',
    description: 'Movimento supinado individualizado.',
    reps: '3x 10-12',
    rest: '1 min',
  ),
  Exercise(
    id: 'b3',
    name: 'Rosca Martelo',
    muscle: 'Bíceps',
    description: 'Foco no músculo braquial e antebraço.',
    reps: '3x 10-12',
    rest: '1 min',
  ),
  Exercise(
    id: 'b4',
    name: 'Rosca Scott Máquina',
    muscle: 'Bíceps',
    description: 'Isolamento no banco inclinando estabilizado.',
    reps: '3x 10-12',
    rest: '1 min',
  ),
  Exercise(
    id: 'b5',
    name: 'Rosca Concentrada',
    muscle: 'Bíceps',
    description: 'Apoiado na coxa interna.',
    reps: '3x 12-15 por braço',
    rest: '1 min',
  ),
  Exercise(
    id: 'b6',
    name: 'Rosca na Polia Baixa',
    muscle: 'Bíceps',
    description: 'Tensão constante utilizando barra reta ou corda.',
    reps: '3x 12-15',
    rest: '1 min',
  ),
  Exercise(
    id: 'b7',
    name: 'Rosca Inversa',
    muscle: 'Antebraço',
    description: 'Pegada pronada com barra.',
    reps: '3x 12-15',
    rest: '1 min',
  ),
  Exercise(
    id: 'b8',
    name: 'Flexão de Punho',
    muscle: 'Antebraço',
    description: 'Apoiado no banco com barra ou halter.',
    reps: '3x 12-15',
    rest: '1 min',
  ),

  // TRÍCEPS
  Exercise(
    id: 'tr1',
    name: 'Tríceps Pulley Barra Reta',
    muscle: 'Tríceps',
    description: 'Polia alta com barra reta.',
    reps: '4x 10-12',
    rest: '1 min',
  ),
  Exercise(
    id: 'tr2',
    name: 'Tríceps Corda',
    muscle: 'Tríceps',
    description: 'Polia com maior extensão final abrindo a corda.',
    reps: '3x 12-15',
    rest: '1 min',
  ),
  Exercise(
    id: 'tr3',
    name: 'Tríceps Testa com Barra W',
    muscle: 'Tríceps',
    description: 'Deitado no banco livre.',
    reps: '3x 10-12',
    rest: '1 min',
  ),
  Exercise(
    id: 'tr4',
    name: 'Tríceps Testa na Polia',
    muscle: 'Tríceps',
    description: 'Mais tensão contínua que o peso livre.',
    reps: '3x 10-12',
    rest: '1 min',
  ),
  Exercise(
    id: 'tr5',
    name: 'Tríceps Francês com Halter',
    muscle: 'Tríceps',
    description: 'Atrás da cabeça, alongamento máximo.',
    reps: '3x 10-12',
    rest: '1 min',
  ),
  Exercise(
    id: 'tr6',
    name: 'Tríceps Francês na Polia',
    muscle: 'Tríceps',
    description: 'Corda puxada por trás da cabeça.',
    reps: '3x 10-12',
    rest: '1 min',
  ),
  Exercise(
    id: 'tr7',
    name: 'Tríceps Coice na Polia',
    muscle: 'Tríceps',
    description: 'Tronco curvado utilizando o cabo.',
    reps: '3x 12-15',
    rest: '1 min',
  ),
  Exercise(
    id: 'tr8',
    name: 'Mergulho nas Paralelas',
    muscle: 'Tríceps',
    description: 'Peso corporal ou máquina (Graviton).',
    reps: '3x 10-12',
    rest: '1 min',
  ),
  Exercise(
    id: 'tr9',
    name: 'Supino Fechado',
    muscle: 'Tríceps',
    description: 'Foco em tríceps e miolo do peitoral.',
    reps: '3x 8-10',
    rest: '1 a 2 min',
  ),

  // PERNAS E GLÚTEOS
  Exercise(
    id: 'pe1',
    name: 'Agachamento Livre',
    muscle: 'Pernas',
    description: 'Barra nas costas. Exercício composto.',
    reps: '4x 8-10',
    rest: '1 a 5 min',
  ),
  Exercise(
    id: 'pe2',
    name: 'Agachamento no Smith',
    muscle: 'Pernas',
    description: 'Agachamento guiado na barra fixa.',
    reps: '4x 8-10',
    rest: '1 a 3 min',
  ),
  Exercise(
    id: 'pe3',
    name: 'Agachamento Hack',
    muscle: 'Pernas',
    description: 'Máquina Hack.',
    reps: '3x 8-10',
    rest: '1 a 3 min',
  ),
  Exercise(
    id: 'pe4',
    name: 'Leg Press 45°',
    muscle: 'Pernas',
    description: 'Foco em quadríceps e glúteos na máquina.',
    reps: '4x 10-12',
    rest: '1 a 3 min',
  ),
  Exercise(
    id: 'pe5',
    name: 'Leg Press 90° (Horizontal)',
    muscle: 'Pernas',
    description: 'Empurre horizontal na máquina.',
    reps: '4x 10-12',
    rest: '1 a 3 min',
  ),
  Exercise(
    id: 'pe6',
    name: 'Cadeira Extensora',
    muscle: 'Pernas',
    description: 'Isolamento total de quadríceps sentado.',
    reps: '3x 12-15',
    rest: '1 min',
  ),
  Exercise(
    id: 'pe7',
    name: 'Mesa Flexora',
    muscle: 'Pernas',
    description: 'Isolamento de posteriores (deitado).',
    reps: '3x 12-15',
    rest: '1 min',
  ),
  Exercise(
    id: 'pe8',
    name: 'Cadeira Flexora',
    muscle: 'Pernas',
    description: 'Isolamento de posteriores (sentado).',
    reps: '3x 12-15',
    rest: '1 min',
  ),
  Exercise(
    id: 'pe9',
    name: 'Flexora em Pé Unilateral',
    muscle: 'Pernas',
    description: 'Trabalho de isquiotibiais focado em um lado.',
    reps: '3x 12-15 por perna',
    rest: '1 min',
  ),
  Exercise(
    id: 'pe10',
    name: 'Stiff com Barra',
    muscle: 'Pernas',
    description: 'Alongamento de posteriores com barra longa.',
    reps: '4x 10-12',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'pe11',
    name: 'Levantamento Terra',
    muscle: 'Pernas',
    description: 'Exercício de força global (cadeia posterior).',
    reps: '4x 6-8',
    rest: '2 a 5 min',
  ),
  Exercise(
    id: 'pe12',
    name: 'Levantamento Pélvico (Hip Thrust)',
    muscle: 'Pernas',
    description: 'Foco máximo de contração em glúteos.',
    reps: '4x 10-12',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'pe13',
    name: 'Cadeira Abdutora',
    muscle: 'Pernas',
    description: 'Trabalho focado em glúteo médio/lateral.',
    reps: '3x 15-20',
    rest: '1 min',
  ),
  Exercise(
    id: 'pe14',
    name: 'Cadeira Adutora',
    muscle: 'Pernas',
    description: 'Trabalho da parte interna da coxa.',
    reps: '3x 15-20',
    rest: '1 min',
  ),
  Exercise(
    id: 'pe15',
    name: 'Passada / Afundo',
    muscle: 'Pernas',
    description:
        'Movimento unilateral focado em quadríceps e glúteos. Pode ser feito andando (passada) ou no lugar (afundo).',
    reps: '3x 10-12 por perna',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'pe16',
    name: 'Elevação Plantar em Pé',
    muscle: 'Panturrilha',
    description: 'Panturrilha no degrau ou máquina vertical.',
    reps: '3x 15-20',
    rest: '1 min',
  ),
  Exercise(
    id: 'pe17',
    name: 'Gêmeos Sentado (Máquina)',
    muscle: 'Panturrilha',
    description: 'Foco no músculo sóleo.',
    reps: '4x 15-20',
    rest: '1 min',
  ),
  Exercise(
    id: 'pe18',
    name: 'Panturrilha no Leg Press',
    muscle: 'Panturrilha',
    description: 'Com os joelhos semi-estendidos na máquina.',
    reps: '4x 15-20',
    rest: '1 min',
  ),
  Exercise(
    id: 'pe19',
    name: 'Stiff com Halteres',
    muscle: 'Pernas',
    description: 'Alongamento de posteriores com carga lateral.',
    reps: '4x 10-12',
    rest: '1 a 2 min',
  ),

  // ABDÔMEN
  Exercise(
    id: 'ab1',
    name: 'Abdominal Supra',
    muscle: 'Abdômen',
    description: 'Clássico no chão, flexionando o tronco.',
    reps: '4x 15-20',
    rest: '45 a 60 seg',
  ),
  Exercise(
    id: 'ab2',
    name: 'Abdominal Infra',
    muscle: 'Abdômen',
    description: 'Elevação de pernas deitado ou pendurado.',
    reps: '3x 15-20',
    rest: '45 a 60 seg',
  ),
  Exercise(
    id: 'ab3',
    name: 'Abdominal Máquina',
    muscle: 'Abdômen',
    description: 'Flexão com resistência/carga na máquina.',
    reps: '3x 15-20',
    rest: '45 a 60 seg',
  ),
  Exercise(
    id: 'ab4',
    name: 'Abdominal Polia (Crunch)',
    muscle: 'Abdômen',
    description: 'Ajoelhado de frente ou costas para a polia.',
    reps: '3x 15-20',
    rest: '45 a 60 seg',
  ),
  Exercise(
    id: 'ab5',
    name: 'Prancha Isométrica',
    muscle: 'Abdômen',
    description: 'Sustentação do core e estabilização.',
    reps: '3x 30-60 seg',
    rest: '45 a 60 seg',
  ),
  Exercise(
    id: 'ab6',
    name: 'Abdominal Oblíquo (Russo)',
    muscle: 'Abdômen',
    description: 'Rotação de tronco lateral.',
    reps: '3x 15-20',
    rest: '45 a 60 seg',
  ),
];
