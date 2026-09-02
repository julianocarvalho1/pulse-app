import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../features/workouts/domain/models/advanced_workout_prescription.dart';
import '../features/workouts/domain/models/cardio_log.dart';

enum RoutineType {
  strength,
  cardio,
  mixed;

  String get label {
    return switch (this) {
      RoutineType.strength => 'Musculação',
      RoutineType.cardio => 'Cardio',
      RoutineType.mixed => 'Misto',
    };
  }

  String get description {
    return switch (this) {
      RoutineType.strength => 'Exercícios com séries e repetições.',
      RoutineType.cardio => 'Somente atividades de cardio.',
      RoutineType.mixed => 'Musculação seguida de cardio.',
    };
  }

  bool get includesStrength => this != RoutineType.cardio;
  bool get includesCardio => this != RoutineType.strength;
}

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
    this.advancedPrescription = const AdvancedExercisePrescription(),
  });

  final String id;
  final String name;
  final String muscle;
  final String description;
  final String reps;
  final String rest;
  final bool isSuperset;
  final String customNote;
  final AdvancedExercisePrescription advancedPrescription;

  Exercise copyWith({
    String? id,
    String? name,
    String? muscle,
    String? description,
    String? reps,
    String? rest,
    bool? isSuperset,
    String? customNote,
    AdvancedExercisePrescription? advancedPrescription,
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
      advancedPrescription: advancedPrescription ?? this.advancedPrescription,
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
      if (!advancedPrescription.isEmpty)
        'advancedPrescription': advancedPrescription.toMap(),
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
      advancedPrescription: map['advancedPrescription'] is Map
          ? AdvancedExercisePrescription.fromMap(
              Map<String, dynamic>.from(map['advancedPrescription'] as Map),
            )
          : const AdvancedExercisePrescription(),
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
    List<RoutineCardio> cardio = const <RoutineCardio>[],
  }) : exercises = UnmodifiableListView<Exercise>(
         List<Exercise>.from(exercises),
       ),
       cardio = UnmodifiableListView<RoutineCardio>(
         List<RoutineCardio>.from(cardio),
       );

  final String id;
  final String name;
  final String focus;
  final String groupName;
  final List<Exercise> exercises;
  final List<RoutineCardio> cardio;

  int get totalActivities => exercises.length + cardio.length;

  RoutineType get type {
    if (exercises.isNotEmpty && cardio.isNotEmpty) {
      return RoutineType.mixed;
    }
    if (cardio.isNotEmpty) {
      return RoutineType.cardio;
    }
    return RoutineType.strength;
  }

  String get typeLabel => type.label;

  String get activitySummary {
    final parts = <String>[];
    if (exercises.isNotEmpty) {
      parts.add(
        '${exercises.length} exercício${exercises.length == 1 ? '' : 's'}',
      );
    }
    if (cardio.isNotEmpty) {
      parts.add('${cardio.length} cardio');
    }
    return parts.isEmpty ? 'Sem atividades' : parts.join(' • ');
  }

  WorkoutRoutine copyWith({
    String? id,
    String? name,
    String? focus,
    String? groupName,
    List<Exercise>? exercises,
    List<RoutineCardio>? cardio,
  }) {
    return WorkoutRoutine(
      id: id ?? this.id,
      name: name ?? this.name,
      focus: focus ?? this.focus,
      groupName: groupName ?? this.groupName,
      exercises: exercises ?? this.exercises,
      cardio: cardio ?? this.cardio,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'focus': focus,
      'groupName': groupName,
      'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
      'cardio': cardio.map((entry) => entry.toMap()).toList(),
    };
  }

  factory WorkoutRoutine.fromMap(Map<String, dynamic> map) {
    final rawExercises = map['exercises'];
    final rawCardio = map['cardio'];

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
      cardio: rawCardio is List
          ? rawCardio
                .whereType<Map>()
                .map(
                  (entry) =>
                      RoutineCardio.fromMap(Map<String, dynamic>.from(entry)),
                )
                .toList()
          : const <RoutineCardio>[],
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
    this.level = '',
    this.objective = '',
    this.recommendedFrequency = 0,
    this.estimatedDuration = '',
  }) : routines = UnmodifiableListView<WorkoutRoutine>(
         List<WorkoutRoutine>.from(routines),
       );

  final String id;
  final String name;
  final String focus;
  final List<WorkoutRoutine> routines;
  final String level;
  final String objective;
  final int recommendedFrequency;
  final String estimatedDuration;

  int get frequencyPerWeek =>
      recommendedFrequency > 0 ? recommendedFrequency : routines.length;

  WorkoutProgram copyWith({
    String? id,
    String? name,
    String? focus,
    List<WorkoutRoutine>? routines,
    String? level,
    String? objective,
    int? recommendedFrequency,
    String? estimatedDuration,
  }) {
    return WorkoutProgram(
      id: id ?? this.id,
      name: name ?? this.name,
      focus: focus ?? this.focus,
      routines: routines ?? this.routines,
      level: level ?? this.level,
      objective: objective ?? this.objective,
      recommendedFrequency: recommendedFrequency ?? this.recommendedFrequency,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'focus': focus,
      'level': level,
      'objective': objective,
      'recommendedFrequency': recommendedFrequency,
      'estimatedDuration': estimatedDuration,
      'routines': routines.map((routine) => routine.toMap()).toList(),
    };
  }

  factory WorkoutProgram.fromMap(Map<String, dynamic> map) {
    final rawRoutines = map['routines'];

    return WorkoutProgram(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      focus: map['focus']?.toString() ?? '',
      level: map['level']?.toString() ?? '',
      objective: map['objective']?.toString() ?? '',
      recommendedFrequency: _readIntValue(map['recommendedFrequency']) ?? 0,
      estimatedDuration: map['estimatedDuration']?.toString() ?? '',
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

  static int? _readIntValue(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
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
    name: 'Supino Inclinado no Smith',
    muscle: 'Peito',
    description: 'Supino inclinado com trajetória guiada pela barra Smith.',
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
    name: 'Crucifixo Reto com Halteres',
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
    name: 'Voador Peitoral na Máquina',
    muscle: 'Peito',
    description: 'Máquina para isolamento (braços flexionados).',
    reps: '2x 12-15',
    rest: '1 min',
  ),
  Exercise(
    id: 'p10',
    name: 'Crossover na Polia Alta',
    muscle: 'Peito',
    description: 'Foco porção inferior/miolo do peitoral.',
    reps: '3x 12-15',
    rest: '1 min',
  ),
  Exercise(
    id: 'p11',
    name: 'Supino em Pé na Polia',
    muscle: 'Peito',
    description: 'Empurre os cabos à frente do peito mantendo o tronco firme.',
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
    name: 'Puxada Fechada com Triângulo',
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
    name: 'Remada Baixa Aberta na Polia',
    muscle: 'Costas',
    description: 'Remada sentada com pegada aberta na barra da polia baixa.',
    reps: '3x 10-12',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'c6',
    name: 'Remada Curvada no Smith',
    muscle: 'Costas',
    description: 'Remada curvada com a barra guiada pela máquina Smith.',
    reps: '3x 10-12',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'c7',
    name: 'Remada Unilateral com Halter',
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
    name: 'Puxada com Braços Estendidos na Polia',
    muscle: 'Costas',
    description: 'Foco em grande dorsal com braços esticados.',
    reps: '3x 12-15',
    rest: '1 min',
  ),
  Exercise(
    id: 'c10',
    name: 'Remada para Deltoide Posterior com Barra',
    muscle: 'Ombros',
    description:
        'Remada com cotovelos abertos para enfatizar ombros posteriores.',
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
    name: 'Elevação Frontal com Barra ou Anilha',
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
    name: 'Encolhimento na Barra Smith',
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
    name: 'Rosca Sentada com Halteres',
    muscle: 'Bíceps',
    description: 'Rosca com halteres executada sentado e com pegada supinada.',
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
    name: 'Rosca Scott na Máquina',
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
    name: 'Flexão de Punho com Halter',
    muscle: 'Antebraço',
    description:
        'Flexione o punho com o antebraço apoiado e segurando um halter.',
    reps: '3x 12-15',
    rest: '1 min',
  ),

  // TRÍCEPS
  Exercise(
    id: 'tr1',
    name: 'Tríceps na Polia com Barra V',
    muscle: 'Tríceps',
    description: 'Extensão de cotovelos na polia alta usando a barra V.',
    reps: '4x 10-12',
    rest: '1 min',
  ),
  Exercise(
    id: 'tr2',
    name: 'Tríceps na Polia',
    muscle: 'Tríceps',
    description: 'Extensão de cotovelos na polia alta com pegador curto.',
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
    name: 'Tríceps Testa com Halteres',
    muscle: 'Tríceps',
    description: 'Extensão de cotovelos deitado no banco com halteres.',
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
    name: 'Tríceps Francês com Barra W',
    muscle: 'Tríceps',
    description: 'Extensão acima da cabeça segurando uma barra W.',
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
    name: 'Leg Press Horizontal',
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
    name: 'Mesa Flexora Unilateral',
    muscle: 'Pernas',
    description: 'Flexão de joelho deitado, trabalhando uma perna por vez.',
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
    name: 'Elevação Pélvica com Barra',
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
    name: 'Afundo',
    muscle: 'Pernas',
    description: 'Movimento unilateral parado para quadríceps e glúteos.',
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
    name: 'Panturrilha Sentada na Máquina',
    muscle: 'Panturrilha',
    description: 'Foco no músculo sóleo.',
    reps: '4x 15-20',
    rest: '1 min',
  ),
  Exercise(
    id: 'pe18',
    name: 'Panturrilha no Hack',
    muscle: 'Panturrilha',
    description: 'Elevação dos calcanhares em pé na máquina hack.',
    reps: '4x 15-20',
    rest: '1 min',
  ),
  Exercise(
    id: 'pe19',
    name: 'Terra Romeno com Halteres',
    muscle: 'Pernas',
    description:
        'Movimento de quadril com halteres para posteriores e glúteos.',
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
    name: 'Abdominal com Halter na Parede',
    muscle: 'Abdômen',
    description: 'Flexão do tronco na parede segurando um halter como carga.',
    reps: '3x 15-20',
    rest: '45 a 60 seg',
  ),
  Exercise(
    id: 'ab4',
    name: 'Abdominal na Polia',
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
    name: 'Abdominal Russo',
    muscle: 'Abdômen',
    description: 'Rotação de tronco lateral.',
    reps: '3x 15-20',
    rest: '45 a 60 seg',
  ),

  // ADIÇÕES REPDB — CALISTENIA E VARIAÇÕES ÚTEIS
  Exercise(
    id: 'repdb_push-up',
    name: 'Flexão de Braços',
    muscle: 'Peito',
    description: 'Flexão no solo mantendo o corpo alinhado e o core firme.',
    reps: '3x 10-15',
    rest: '1 min',
  ),
  Exercise(
    id: 'repdb_incline-push-ups',
    name: 'Flexão de Braços Inclinada',
    muscle: 'Peito',
    description:
        'Flexão com as mãos elevadas, adequada para progredir com controle.',
    reps: '3x 10-15',
    rest: '1 min',
  ),
  Exercise(
    id: 'repdb_diamond-push-ups',
    name: 'Flexão Diamante',
    muscle: 'Tríceps',
    description:
        'Flexão com as mãos próximas para aumentar a ênfase nos tríceps.',
    reps: '3x 8-12',
    rest: '1 min',
  ),
  Exercise(
    id: 'repdb_assisted-pull-ups',
    name: 'Barra Fixa Assistida',
    muscle: 'Costas',
    description: 'Barra fixa com assistência para desenvolver força de puxada.',
    reps: '3x 8-12',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'repdb_chin-ups',
    name: 'Barra Fixa com Pegada Supinada',
    muscle: 'Costas',
    description: 'Puxada na barra com as palmas voltadas para você.',
    reps: '3x 6-10',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'repdb_chest-supported-db-row',
    name: 'Remada com Halteres Apoiada no Banco',
    muscle: 'Costas',
    description: 'Remada com o peito apoiado para reduzir o balanço do tronco.',
    reps: '3x 8-12',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'repdb_face-pull',
    name: 'Face Pull na Polia',
    muscle: 'Ombros',
    description: 'Puxe o cabo em direção ao rosto com os cotovelos abertos.',
    reps: '3x 12-15',
    rest: '1 min',
  ),
  Exercise(
    id: 'repdb_db-pullover',
    name: 'Pullover com Halter',
    muscle: 'Costas',
    description:
        'Leve o halter atrás da cabeça mantendo os braços controlados.',
    reps: '3x 10-12',
    rest: '1 min',
  ),
  Exercise(
    id: 'repdb_arnold-press',
    name: 'Desenvolvimento Arnold',
    muscle: 'Ombros',
    description: 'Desenvolvimento com halteres combinando rotação e elevação.',
    reps: '3x 8-12',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'repdb_upright-row',
    name: 'Remada Alta com Barra',
    muscle: 'Ombros',
    description: 'Eleve a barra junto ao corpo até uma amplitude confortável.',
    reps: '3x 10-12',
    rest: '1 min',
  ),
  Exercise(
    id: 'repdb_cable-upright-row',
    name: 'Remada Alta na Polia',
    muscle: 'Ombros',
    description: 'Remada alta usando a polia baixa e movimento controlado.',
    reps: '3x 10-12',
    rest: '1 min',
  ),
  Exercise(
    id: 'repdb_assisted-dips',
    name: 'Mergulho Assistido na Máquina',
    muscle: 'Tríceps',
    description: 'Mergulho em paralelas com assistência regulável da máquina.',
    reps: '3x 8-12',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'repdb_front-squat',
    name: 'Agachamento Frontal com Barra',
    muscle: 'Pernas',
    description: 'Agachamento com a barra apoiada à frente dos ombros.',
    reps: '4x 6-10',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'repdb_goblet-squat',
    name: 'Agachamento Goblet',
    muscle: 'Pernas',
    description: 'Agachamento segurando um halter junto ao peito.',
    reps: '3x 10-15',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'repdb_bulgarian-split-squat',
    name: 'Agachamento Búlgaro com Halteres',
    muscle: 'Pernas',
    description: 'Agachamento unilateral com o pé traseiro elevado.',
    reps: '3x 8-12 por perna',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'repdb_walking-lunge',
    name: 'Passada Caminhando',
    muscle: 'Pernas',
    description: 'Avance alternando as pernas e controlando cada passada.',
    reps: '3x 10-12 por perna',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'repdb_romanian-deadlift',
    name: 'Levantamento Terra Romeno com Barra',
    muscle: 'Pernas',
    description:
        'Dobre o quadril com a barra próxima ao corpo e coluna neutra.',
    reps: '4x 8-10',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'repdb_sumo-deadlift',
    name: 'Levantamento Terra Sumô',
    muscle: 'Pernas',
    description: 'Levantamento terra com base ampla e mãos entre as pernas.',
    reps: '4x 6-8',
    rest: '2 min',
  ),
  Exercise(
    id: 'repdb_glute-bridge',
    name: 'Ponte de Glúteos',
    muscle: 'Pernas',
    description: 'Eleve o quadril no solo contraindo glúteos no topo.',
    reps: '3x 12-15',
    rest: '1 min',
  ),
  Exercise(
    id: 'repdb_single-leg-romanian-deadlift',
    name: 'Terra Romeno Unilateral com Halteres',
    muscle: 'Pernas',
    description: 'Dobradiça de quadril em uma perna para força e equilíbrio.',
    reps: '3x 8-12 por perna',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'repdb_good-morning',
    name: 'Good Morning com Barra',
    muscle: 'Pernas',
    description: 'Incline o tronco pelo quadril mantendo a coluna neutra.',
    reps: '3x 8-12',
    rest: '1 a 2 min',
  ),
  Exercise(
    id: 'repdb_dumbbell-calf-raise',
    name: 'Panturrilha em Pé com Halteres',
    muscle: 'Panturrilha',
    description:
        'Eleve os calcanhares em pé segurando halteres ao lado do corpo.',
    reps: '4x 15-20',
    rest: '1 min',
  ),
  Exercise(
    id: 'repdb_ab-wheel-rollout',
    name: 'Roda Abdominal',
    muscle: 'Abdômen',
    description: 'Estenda o corpo com a roda mantendo o abdômen contraído.',
    reps: '3x 8-12',
    rest: '1 min',
  ),
  Exercise(
    id: 'repdb_hanging-leg-raise',
    name: 'Elevação de Pernas Suspenso',
    muscle: 'Abdômen',
    description: 'Eleve as pernas pendurado na barra sem usar balanço.',
    reps: '3x 10-15',
    rest: '1 min',
  ),
  Exercise(
    id: 'repdb_side-plank',
    name: 'Prancha Lateral',
    muscle: 'Abdômen',
    description: 'Sustente o corpo de lado em linha reta com o core ativo.',
    reps: '3x 30-45 seg por lado',
    rest: '45 seg',
  ),
  Exercise(
    id: 'repdb_mountain-climbers',
    name: 'Escalador',
    muscle: 'Abdômen',
    description: 'Alterne os joelhos em direção ao peito mantendo a prancha.',
    reps: '3x 30-45 seg',
    rest: '45 seg',
  ),
  Exercise(
    id: 'repdb_dead-bug',
    name: 'Dead Bug',
    muscle: 'Abdômen',
    description:
        'Estenda braço e perna opostos mantendo a lombar apoiada no chão.',
    reps: '3x 8-12 por lado',
    rest: '45 seg',
  ),
  Exercise(
    id: 'repdb_bird-dog',
    name: 'Bird-Dog',
    muscle: 'Abdômen',
    description:
        'Em quatro apoios, estenda braço e perna opostos sem girar o tronco.',
    reps: '3x 8-12 por lado',
    rest: '45 seg',
  ),
  Exercise(
    id: 'repdb_cable-pallof-press',
    name: 'Pallof Press na Polia',
    muscle: 'Abdômen',
    description:
        'Empurre o cabo à frente e resista à rotação mantendo o tronco firme.',
    reps: '3x 10-12 por lado',
    rest: '45 a 60 seg',
  ),
];
