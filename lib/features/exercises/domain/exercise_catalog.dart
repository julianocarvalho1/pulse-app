import '../../../models/exercise.dart';
import 'exercise_definition.dart';
import 'repdb_exercise_mapping.dart';

class ExerciseCatalogMetadata {
  const ExerciseCatalogMetadata({
    required this.mediaAssetId,
    this.aliases = const <String>[],
  });

  final String mediaAssetId;
  final List<String> aliases;
}

class ExerciseIdentity {
  const ExerciseIdentity({required this.id, required this.name});

  final String id;
  final String name;
}

class ExerciseCatalog {
  const ExerciseCatalog._();

  static const int version = 2;

  static const Map<String, String> _legacyIdToCanonicalId = {
    'ex_pm_1': 'p12',
    'ex_pm_2': 'p7',
    'ex_pm_3': 'o2',
    'ex_pm_4': 'tr1',
    'ex_pm_5': 'c1',
    'ex_pm_6': 'c3',
    'ex_pm_7': 'b1',
    'ex_pm_8': 'b4',
    'ex_pm_9': 'pe1',
    'ex_pm_10': 'pe4',
    'ex_pm_11': 'pe6',
    'ex_pm_12': 'ab1',
    'ex_pm_13': 'p12',
    'ex_pm_14': 'c5',
    'ex_pm_15': 'o7',
    'ex_pm_16': 'pe15',
    'ex_pm_17': 'pe6',
    'ex_pm_18': 'ab1',
    'p13': 'p9',
  };

  static const Map<String, ExerciseCatalogMetadata> _metadataById = {
    'p1': ExerciseCatalogMetadata(
      mediaAssetId: 'supino_reto_com_barra',
      aliases: <String>[
        'Supino com Barra',
        'Bench Press',
        'Barbell Bench Press',
      ],
    ),
    'p2': ExerciseCatalogMetadata(
      mediaAssetId: 'supino_reto_com_halteres',
      aliases: <String>['Supino com Halteres', 'Dumbbell Bench Press'],
    ),
    'p3': ExerciseCatalogMetadata(
      mediaAssetId: 'supino_inclinado_com_barra',
      aliases: <String>[
        'Supino Inclinado Barra',
        'Incline Barbell Bench Press',
      ],
    ),
    'p4': ExerciseCatalogMetadata(
      mediaAssetId: 'supino_inclinado_com_halteres',
      aliases: <String>[
        'Supino Inclinado Halteres',
        'Incline Dumbbell Bench Press',
      ],
    ),
    'p5': ExerciseCatalogMetadata(
      mediaAssetId: 'supino_inclinado_articulado',
      aliases: <String>[
        'Supino Inclinado Máquina',
        'Incline Chest Press Machine',
      ],
    ),
    'p6': ExerciseCatalogMetadata(
      mediaAssetId: 'supino_declinado',
      aliases: <String>['Decline Bench Press'],
    ),
    'p7': ExerciseCatalogMetadata(
      mediaAssetId: 'crucifixo_reto',
      aliases: <String>[
        'Crucifixo com Halteres',
        'Crucifixo Reto',
        'Dumbbell Fly',
      ],
    ),
    'p8': ExerciseCatalogMetadata(
      mediaAssetId: 'crucifixo_inclinado',
      aliases: <String>[
        'Crucifixo Inclinado com Halteres',
        'Incline Dumbbell Fly',
      ],
    ),
    'p9': ExerciseCatalogMetadata(
      mediaAssetId: 'peck_deck_voador',
      aliases: <String>[
        'Peck Deck',
        'Voador',
        'Machine Fly',
        'Crucifixo na Máquina',
        'Crucifixo Máquina',
        'Machine Chest Fly',
      ],
    ),
    'p10': ExerciseCatalogMetadata(
      mediaAssetId: 'crossover_polia_alta',
      aliases: <String>['Crossover Alto', 'High Cable Crossover'],
    ),
    'p11': ExerciseCatalogMetadata(
      mediaAssetId: 'crossover_polia_baixa',
      aliases: <String>['Crossover Baixo', 'Low Cable Crossover'],
    ),
    'p12': ExerciseCatalogMetadata(
      mediaAssetId: 'supino_reto_articulado',
      aliases: <String>['Chest Press', 'Supino Máquina', 'Machine Chest Press'],
    ),
    'c1': ExerciseCatalogMetadata(
      mediaAssetId: 'puxada_frontal_aberta',
      aliases: <String>[
        'Puxada na Frente',
        'Lat Pulldown',
        'Wide Grip Lat Pulldown',
      ],
    ),
    'c2': ExerciseCatalogMetadata(
      mediaAssetId: 'puxada_triangulo_fechada',
      aliases: <String>[
        'Puxada Triângulo',
        'Close Grip Lat Pulldown',
        'Neutral Grip Pulldown',
      ],
    ),
    'c3': ExerciseCatalogMetadata(
      mediaAssetId: 'remada_curvada_com_barra',
      aliases: <String>['Remada Curvada', 'Barbell Row', 'Bent Over Row'],
    ),
    'c4': ExerciseCatalogMetadata(
      mediaAssetId: 'remada_cavalinho',
      aliases: <String>['Remada T', 'T-Bar Row'],
    ),
    'c5': ExerciseCatalogMetadata(
      mediaAssetId: 'remada_baixa_sentada',
      aliases: <String>['Remada Baixa', 'Remada Sentada', 'Seated Cable Row'],
    ),
    'c6': ExerciseCatalogMetadata(
      mediaAssetId: 'remada_articulada',
      aliases: <String>['Machine Row', 'Remada Máquina'],
    ),
    'c7': ExerciseCatalogMetadata(
      mediaAssetId: 'serrote_remada_unilateral',
      aliases: <String>[
        'Serrote',
        'One Arm Dumbbell Row',
        'Single Arm Dumbbell Row',
      ],
    ),
    'c8': ExerciseCatalogMetadata(
      mediaAssetId: 'barra_fixa',
      aliases: <String>['Pull Up', 'Pull-Up', 'Chin Up'],
    ),
    'c9': ExerciseCatalogMetadata(
      mediaAssetId: 'pull_down_na_polia',
      aliases: <String>[
        'Pull-down na Polia',
        'Pulldown Braços Estendidos',
        'Straight Arm Pulldown',
      ],
    ),
    'c10': ExerciseCatalogMetadata(
      mediaAssetId: 'voador_dorsal_inverso',
      aliases: <String>[
        'Voador Dorsal',
        'Reverse Pec Deck',
        'Rear Delt Fly Machine',
      ],
    ),
    'o1': ExerciseCatalogMetadata(
      mediaAssetId: 'desenvolvimento_com_halteres',
      aliases: <String>['Desenvolvimento Halteres', 'Dumbbell Shoulder Press'],
    ),
    'o2': ExerciseCatalogMetadata(
      mediaAssetId: 'desenvolvimento_com_barra',
      aliases: <String>[
        'Desenvolvimento Militar',
        'Military Press',
        'Barbell Shoulder Press',
      ],
    ),
    'o3': ExerciseCatalogMetadata(
      mediaAssetId: 'desenvolvimento_articulado',
      aliases: <String>['Shoulder Press Machine', 'Desenvolvimento Máquina'],
    ),
    'o4': ExerciseCatalogMetadata(
      mediaAssetId: 'elevacao_lateral_com_halteres',
      aliases: <String>['Elevação Lateral Halteres', 'Dumbbell Lateral Raise'],
    ),
    'o5': ExerciseCatalogMetadata(
      mediaAssetId: 'elevacao_lateral_na_polia',
      aliases: <String>['Cable Lateral Raise', 'Elevação Lateral Cabo'],
    ),
    'o6': ExerciseCatalogMetadata(
      mediaAssetId: 'elevacao_frontal_com_halteres',
      aliases: <String>['Elevação Frontal Halteres', 'Dumbbell Front Raise'],
    ),
    'o7': ExerciseCatalogMetadata(
      mediaAssetId: 'elevacao_frontal_com_barra_anilha',
      aliases: <String>[
        'Elevação Frontal com Barra',
        'Barbell Front Raise',
        'Plate Front Raise',
      ],
    ),
    'o8': ExerciseCatalogMetadata(
      mediaAssetId: 'crucifixo_inverso_com_halteres',
      aliases: <String>[
        'Crucifixo Inverso',
        'Reverse Dumbbell Fly',
        'Rear Delt Dumbbell Fly',
      ],
    ),
    'o9': ExerciseCatalogMetadata(
      mediaAssetId: 'elevacao_frontal_na_polia',
      aliases: <String>['Cable Front Raise', 'Elevação Frontal Cabo'],
    ),
    't1': ExerciseCatalogMetadata(
      mediaAssetId: 'encolhimento_com_halteres',
      aliases: <String>['Dumbbell Shrug', 'Encolhimento Halteres'],
    ),
    't2': ExerciseCatalogMetadata(
      mediaAssetId: 'encolhimento_na_barra_smith',
      aliases: <String>['Encolhimento no Smith', 'Smith Machine Shrug'],
    ),
    'b1': ExerciseCatalogMetadata(
      mediaAssetId: 'rosca_direta_com_barra',
      aliases: <String>['Rosca Direta', 'Barbell Curl'],
    ),
    'b2': ExerciseCatalogMetadata(
      mediaAssetId: 'rosca_alternada_com_halteres',
      aliases: <String>['Rosca Alternada', 'Alternating Dumbbell Curl'],
    ),
    'b3': ExerciseCatalogMetadata(
      mediaAssetId: 'rosca_martelo',
      aliases: <String>['Hammer Curl'],
    ),
    'b4': ExerciseCatalogMetadata(
      mediaAssetId: 'rosca_scott_maquina',
      aliases: <String>['Rosca Scott', 'Preacher Curl Machine'],
    ),
    'b5': ExerciseCatalogMetadata(
      mediaAssetId: 'rosca_concentrada',
      aliases: <String>['Concentration Curl'],
    ),
    'b6': ExerciseCatalogMetadata(
      mediaAssetId: 'rosca_na_polia_baixa',
      aliases: <String>['Cable Curl', 'Rosca Cabo'],
    ),
    'b7': ExerciseCatalogMetadata(
      mediaAssetId: 'rosca_inversa',
      aliases: <String>['Reverse Curl'],
    ),
    'b8': ExerciseCatalogMetadata(
      mediaAssetId: 'flexao_de_punho',
      aliases: <String>['Wrist Curl'],
    ),
    'tr1': ExerciseCatalogMetadata(
      mediaAssetId: 'triceps_pulley_barra_reta',
      aliases: <String>[
        'Tríceps Pulley Barra Reta',
        'Tríceps na Polia',
        'Cable Pushdown',
        'Triceps Pushdown',
      ],
    ),
    'tr2': ExerciseCatalogMetadata(
      mediaAssetId: 'triceps_corda',
      aliases: <String>[
        'Tríceps Corda',
        'Rope Pushdown',
        'Rope Triceps Pushdown',
      ],
    ),
    'tr3': ExerciseCatalogMetadata(
      mediaAssetId: 'triceps_testa_com_barra_w',
      aliases: <String>['Skull Crusher', 'EZ Bar Skull Crusher'],
    ),
    'tr4': ExerciseCatalogMetadata(
      mediaAssetId: 'triceps_testa_na_polia',
      aliases: <String>['Cable Skull Crusher'],
    ),
    'tr5': ExerciseCatalogMetadata(
      mediaAssetId: 'triceps_frances_com_halter',
      aliases: <String>['Overhead Dumbbell Triceps Extension'],
    ),
    'tr6': ExerciseCatalogMetadata(
      mediaAssetId: 'triceps_frances_na_polia',
      aliases: <String>['Cable Overhead Triceps Extension'],
    ),
    'tr7': ExerciseCatalogMetadata(
      mediaAssetId: 'triceps_coice_na_polia',
      aliases: <String>['Cable Triceps Kickback'],
    ),
    'tr8': ExerciseCatalogMetadata(
      mediaAssetId: 'mergulho_nas_paralelas',
      aliases: <String>['Dips', 'Parallel Bar Dips'],
    ),
    'tr9': ExerciseCatalogMetadata(
      mediaAssetId: 'supino_fechado',
      aliases: <String>['Close Grip Bench Press'],
    ),
    'pe1': ExerciseCatalogMetadata(
      mediaAssetId: 'agachamento_livre',
      aliases: <String>['Agachamento', 'Back Squat', 'Barbell Squat'],
    ),
    'pe2': ExerciseCatalogMetadata(
      mediaAssetId: 'agachamento_no_smith',
      aliases: <String>['Smith Machine Squat'],
    ),
    'pe3': ExerciseCatalogMetadata(
      mediaAssetId: 'agachamento_hack',
      aliases: <String>['Hack Squat'],
    ),
    'pe4': ExerciseCatalogMetadata(
      mediaAssetId: 'leg_press_45',
      aliases: <String>['Leg Press', '45 Degree Leg Press'],
    ),
    'pe5': ExerciseCatalogMetadata(
      mediaAssetId: 'leg_press_90_horizontal',
      aliases: <String>['Leg Press 90°', 'Horizontal Leg Press'],
    ),
    'pe6': ExerciseCatalogMetadata(
      mediaAssetId: 'cadeira_extensora',
      aliases: <String>['Leg Extension'],
    ),
    'pe7': ExerciseCatalogMetadata(
      mediaAssetId: 'mesa_flexora',
      aliases: <String>['Lying Leg Curl'],
    ),
    'pe8': ExerciseCatalogMetadata(
      mediaAssetId: 'cadeira_flexora',
      aliases: <String>['Seated Leg Curl'],
    ),
    'pe9': ExerciseCatalogMetadata(
      mediaAssetId: 'flexora_em_pe_unilateral',
      aliases: <String>['Standing Single Leg Curl'],
    ),
    'pe10': ExerciseCatalogMetadata(
      mediaAssetId: 'stiff_com_barra',
      aliases: <String>[
        'Romanian Deadlift Barra',
        'Barbell Romanian Deadlift',
        'RDL Barra',
      ],
    ),
    'pe11': ExerciseCatalogMetadata(
      mediaAssetId: 'levantamento_terra',
      aliases: <String>['Deadlift'],
    ),
    'pe12': ExerciseCatalogMetadata(
      mediaAssetId: 'levantamento_pelvico_hip_thrust',
      aliases: <String>[
        'Levantamento Pélvico',
        'Hip Thrust',
        'Barbell Hip Thrust',
      ],
    ),
    'pe13': ExerciseCatalogMetadata(
      mediaAssetId: 'cadeira_abdutora',
      aliases: <String>['Hip Abduction Machine'],
    ),
    'pe14': ExerciseCatalogMetadata(
      mediaAssetId: 'cadeira_adutora',
      aliases: <String>['Hip Adduction Machine'],
    ),
    'pe15': ExerciseCatalogMetadata(
      mediaAssetId: 'passada_afundo',
      aliases: <String>[
        'Passada / Afundo',
        'Passada',
        'Afundo',
        'Lunge',
        'Walking Lunge',
      ],
    ),
    'pe16': ExerciseCatalogMetadata(
      mediaAssetId: 'elevacao_plantar_em_pe',
      aliases: <String>['Panturrilha em Pé', 'Standing Calf Raise'],
    ),
    'pe17': ExerciseCatalogMetadata(
      mediaAssetId: 'gemeos_sentado_maquina',
      aliases: <String>['Gêmeos Sentado', 'Seated Calf Raise'],
    ),
    'pe18': ExerciseCatalogMetadata(
      mediaAssetId: 'panturrilha_no_leg_press',
      aliases: <String>['Leg Press Calf Raise'],
    ),
    'pe19': ExerciseCatalogMetadata(
      mediaAssetId: 'stiff_com_halteres',
      aliases: <String>[
        'Romanian Deadlift Halteres',
        'Dumbbell Romanian Deadlift',
        'Dumbbell RDL',
      ],
    ),
    'ab1': ExerciseCatalogMetadata(
      mediaAssetId: 'abdominal_supra',
      aliases: <String>['Crunch Abdominal', 'Crunch', 'Abdominal Tradicional'],
    ),
    'ab2': ExerciseCatalogMetadata(
      mediaAssetId: 'abdominal_infra',
      aliases: <String>['Reverse Crunch', 'Leg Raise'],
    ),
    'ab3': ExerciseCatalogMetadata(
      mediaAssetId: 'abdominal_maquina',
      aliases: <String>['Machine Crunch', 'Abdominal Máquina'],
    ),
    'ab4': ExerciseCatalogMetadata(
      mediaAssetId: 'abdominal_polia_crunch',
      aliases: <String>['Cable Crunch', 'Abdominal Polia (Crunch)'],
    ),
    'ab5': ExerciseCatalogMetadata(
      mediaAssetId: 'prancha_isometrica',
      aliases: <String>['Plank'],
    ),
    'ab6': ExerciseCatalogMetadata(
      mediaAssetId: 'abdominal_obliquo_russo',
      aliases: <String>['Russian Twist', 'Abdominal Oblíquo Russo'],
    ),
  };

  static final Map<String, ExerciseDefinition> _definitionsById = {
    for (final exercise in exerciseDatabase)
      exercise.id: ExerciseDefinition(
        id: exercise.id,
        name: exercise.name,
        primaryMuscle: standardizedMuscle(exercise.muscle),
        description: exercise.description,
        mediaAssetId:
            _metadataById[exercise.id]?.mediaAssetId ?? _slugify(exercise.name),
        aliases: _aliasesFor(exercise.id),
      ),
  };

  static List<String> _aliasesFor(String exerciseId) {
    return <String>{
      ...?_metadataById[exerciseId]?.aliases,
      ...RepDbExerciseMapping.approvedAliasesFor(exerciseId),
    }.toList(growable: false);
  }

  static List<ExerciseDefinition> get definitions =>
      List<ExerciseDefinition>.unmodifiable(_definitionsById.values);

  static final Map<String, String> _normalizedNameToId =
      _buildNormalizedNameIndex();

  static Exercise prescribedExercise({
    required String id,
    required String description,
    required String reps,
    required String rest,
    bool isSuperset = false,
    String customNote = '',
  }) {
    final definition = definitionForId(id);
    if (definition == null) {
      throw ArgumentError.value(
        id,
        'id',
        'Exercício não encontrado no catálogo.',
      );
    }

    return definition.prescribe(
      ExercisePrescription(
        descriptionOverride: description,
        repsText: reps,
        restText: rest,
        isSuperset: isSuperset,
        customNote: customNote,
      ),
    );
  }

  static ExerciseDefinition? definitionFor(Exercise exercise) {
    return definitionForId(exercise.id, exerciseName: exercise.name);
  }

  static ExerciseDefinition? definitionForId(
    String exerciseId, {
    String exerciseName = '',
  }) {
    final canonicalId = canonicalIdFor(exerciseId, exerciseName: exerciseName);
    return _definitionsById[canonicalId];
  }

  static ExercisePrescription prescriptionFor(Exercise exercise) {
    return ExercisePrescription.fromExercise(exercise);
  }

  static bool hasMetadata(String exerciseId) {
    return definitionForId(exerciseId) != null;
  }

  static String mediaPathFor(Exercise exercise) {
    final canonicalId = canonicalIdFor(
      exercise.id,
      exerciseName: exercise.name,
    );
    final mediaAssetId = _definitionsById[canonicalId]?.mediaAssetId;

    if (mediaAssetId != null && mediaAssetId.isNotEmpty) {
      return 'assets/images/$mediaAssetId.gif';
    }

    return 'assets/images/${_slugify(exercise.name)}.gif';
  }

  static RepDbExerciseMedia? repDbMediaFor(Exercise exercise) {
    final canonicalId = canonicalIdFor(
      exercise.id,
      exerciseName: exercise.name,
    );
    return RepDbExerciseMapping.approvedMediaFor(canonicalId);
  }

  static bool matches(Exercise exercise, String rawQuery) {
    final query = normalize(rawQuery);
    if (query.isEmpty) {
      return true;
    }

    final canonicalId = canonicalIdFor(
      exercise.id,
      exerciseName: exercise.name,
    );
    final definition = _definitionsById[canonicalId];
    final searchableValues = <String>[
      exercise.name,
      exercise.muscle,
      if (definition != null) definition.name,
      if (definition != null) definition.primaryMuscle,
      ...?definition?.aliases,
    ];

    return searchableValues.any((value) => normalize(value).contains(query));
  }

  static Exercise canonicalizeIdentity(Exercise exercise) {
    if (_isCustomExerciseId(exercise.id)) {
      return exercise;
    }

    final canonicalId = canonicalIdFor(
      exercise.id,
      exerciseName: exercise.name,
    );
    final definition = _definitionsById[canonicalId];

    if (definition == null) {
      return exercise;
    }

    if (exercise.id == definition.id &&
        exercise.name == definition.name &&
        exercise.muscle == definition.primaryMuscle) {
      return exercise;
    }

    return exercise.copyWith(
      id: definition.id,
      name: definition.name,
      muscle: definition.primaryMuscle,
    );
  }

  static ExerciseIdentity resolveIdentity({
    required String exerciseId,
    required String exerciseName,
  }) {
    if (_isCustomExerciseId(exerciseId)) {
      return ExerciseIdentity(id: exerciseId, name: exerciseName);
    }

    final canonicalId = canonicalIdFor(exerciseId, exerciseName: exerciseName);
    final definition = _definitionsById[canonicalId];

    return ExerciseIdentity(
      id: definition?.id ?? exerciseId,
      name: definition?.name ?? exerciseName,
    );
  }

  static String canonicalIdFor(String exerciseId, {String exerciseName = ''}) {
    final legacyId = _legacyIdToCanonicalId[exerciseId];
    if (legacyId != null) {
      return legacyId;
    }

    if (_definitionsById.containsKey(exerciseId)) {
      return exerciseId;
    }

    if (exerciseId.isEmpty || exerciseId.startsWith('ex_pm_')) {
      return _normalizedNameToId[normalize(exerciseName)] ?? exerciseId;
    }

    return exerciseId;
  }

  static List<String> aliasesFor(Exercise exercise) {
    final canonicalId = canonicalIdFor(
      exercise.id,
      exerciseName: exercise.name,
    );
    return List<String>.unmodifiable(
      _definitionsById[canonicalId]?.aliases ?? const <String>[],
    );
  }

  static String standardizedMuscle(String value) {
    return switch (normalize(value)) {
      'ombro' || 'ombros' => 'Ombros',
      'core' || 'abdomen' || 'abdominal' => 'Abdômen',
      'perna' || 'pernas' || 'membros inferiores' => 'Pernas',
      'panturrilha' || 'panturrilhas' => 'Panturrilha',
      'peito' || 'peitoral' => 'Peito',
      'costa' || 'costas' || 'dorsal' || 'dorsais' => 'Costas',
      'biceps' => 'Bíceps',
      'triceps' => 'Tríceps',
      'antebraco' || 'antebracos' => 'Antebraço',
      'trapezio' => 'Trapézio',
      _ => value.trim().isEmpty ? 'Outros' : value.trim(),
    };
  }

  static String normalize(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static Map<String, String> _buildNormalizedNameIndex() {
    final index = <String, String>{};

    for (final definition in _definitionsById.values) {
      index[normalize(definition.name)] = definition.id;
      for (final alias in definition.aliases) {
        index.putIfAbsent(normalize(alias), () => definition.id);
      }
    }

    return index;
  }

  static bool _isCustomExerciseId(String id) {
    return id.startsWith('custom_') || id.startsWith('manual_');
  }

  static String _slugify(String value) {
    return normalize(value).replaceAll(' ', '_');
  }
}
