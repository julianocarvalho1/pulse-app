enum RepDbMatchStatus { exact, reviewRequired, unavailable }

class RepDbExerciseMatch {
  const RepDbExerciseMatch.exact(this.repDbId, this.sourceName)
    : status = RepDbMatchStatus.exact,
      reviewNote = '';

  const RepDbExerciseMatch.reviewRequired(
    this.repDbId,
    this.sourceName,
    this.reviewNote,
  ) : status = RepDbMatchStatus.reviewRequired;

  const RepDbExerciseMatch.unavailable(this.reviewNote)
    : repDbId = null,
      sourceName = null,
      status = RepDbMatchStatus.unavailable;

  final String? repDbId;
  final String? sourceName;
  final RepDbMatchStatus status;
  final String reviewNote;

  bool get isApproved => status == RepDbMatchStatus.exact;

  List<String> get approvedAliases {
    final name = sourceName;
    if (!isApproved || name == null || name.isEmpty) {
      return const <String>[];
    }
    return <String>[name];
  }
}

class RepDbCatalogAddition {
  const RepDbCatalogAddition({
    required this.repDbId,
    required this.namePtBr,
    required this.primaryMuscle,
    this.aliases = const <String>[],
  });

  final String repDbId;
  final String namePtBr;
  final String primaryMuscle;
  final List<String> aliases;
}

class RepDbExerciseMapping {
  const RepDbExerciseMapping._();

  static const int version = 1;
  static const String attributionText = 'Exercise data by RepDB (repdb.co)';
  static const String attributionUrl = 'https://repdb.co';

  static const Map<String, RepDbExerciseMatch> legacyMatches = {
    'p1': RepDbExerciseMatch.exact('bench-press', 'Barbell Bench Press'),
    'p2': RepDbExerciseMatch.exact('db-bench-press', 'Dumbbell Bench Press'),
    'p3': RepDbExerciseMatch.exact(
      'incline-bench-press',
      'Incline Barbell Bench Press',
    ),
    'p4': RepDbExerciseMatch.exact(
      'incline-db-press',
      'Incline Dumbbell Press',
    ),
    'p5': RepDbExerciseMatch.reviewRequired(
      'chest-press-machine',
      'Machine Chest Press',
      'A fonte não confirma o ângulo inclinado e articulado.',
    ),
    'p6': RepDbExerciseMatch.exact(
      'decline-bench-press',
      'Decline Bench Press',
    ),
    'p7': RepDbExerciseMatch.exact('db-fly', 'Dumbbell Fly'),
    'p8': RepDbExerciseMatch.exact(
      'incline-dumbbell-fly',
      'Incline Dumbbell Fly',
    ),
    'p9': RepDbExerciseMatch.exact('pec-deck', 'Pec Deck'),
    'p10': RepDbExerciseMatch.reviewRequired(
      'cable-fly',
      'Cable Fly',
      'A direção de cima para baixo não está confirmada.',
    ),
    'p11': RepDbExerciseMatch.reviewRequired(
      'cable-fly',
      'Cable Fly',
      'A direção de baixo para cima não está confirmada.',
    ),
    'p12': RepDbExerciseMatch.exact(
      'chest-press-machine',
      'Machine Chest Press',
    ),
    'c1': RepDbExerciseMatch.reviewRequired(
      'lat-pulldown',
      'Lat Pulldown',
      'A pegada aberta não está confirmada.',
    ),
    'c2': RepDbExerciseMatch.exact('v-bar-lat-pulldown', 'V-Bar Lat Pulldown'),
    'c3': RepDbExerciseMatch.exact('barbell-row', 'Bent-Over Barbell Row'),
    'c4': RepDbExerciseMatch.exact('t-bar-row', 'T-Bar Row'),
    'c5': RepDbExerciseMatch.reviewRequired(
      'wide-grip-seated-cable-row',
      'Wide Grip Seated Cable Row',
      'A fonte fixa pegada aberta, diferente da descrição atual.',
    ),
    'c6': RepDbExerciseMatch.unavailable(
      'Não foi encontrada remada articulada fiel no plano gratuito.',
    ),
    'c7': RepDbExerciseMatch.exact(
      'single-arm-db-row',
      'Single-Arm Dumbbell Row',
    ),
    'c8': RepDbExerciseMatch.exact('pull-up', 'Pull-Up'),
    'c9': RepDbExerciseMatch.exact(
      'straight-arm-pulldown',
      'Straight-Arm Pulldown',
    ),
    'c10': RepDbExerciseMatch.reviewRequired(
      'rear-delt-fly',
      'Rear Delt Fly',
      'A fonte demonstra halteres, não o voador inverso na máquina.',
    ),
    'o1': RepDbExerciseMatch.exact(
      'dumbbell-shoulder-press',
      'Dumbbell Shoulder Press',
    ),
    'o2': RepDbExerciseMatch.exact('ohp', 'Barbell Overhead Press'),
    'o3': RepDbExerciseMatch.exact(
      'machine-shoulder-press',
      'Machine Shoulder Press',
    ),
    'o4': RepDbExerciseMatch.exact('lateral-raise', 'Dumbbell Lateral Raise'),
    'o5': RepDbExerciseMatch.exact(
      'cable-lateral-raise',
      'Cable Lateral Raise',
    ),
    'o6': RepDbExerciseMatch.exact(
      'dumbbell-front-raise',
      'Dumbbell Front Raise',
    ),
    'o7': RepDbExerciseMatch.exact(
      'barbell-front-raise',
      'Barbell Front Raise',
    ),
    'o8': RepDbExerciseMatch.exact(
      'dumbbell-reverse-fly',
      'Dumbbell Reverse Fly',
    ),
    'o9': RepDbExerciseMatch.exact('cable-front-raise', 'Cable Front Raise'),
    't1': RepDbExerciseMatch.exact('db-shrug', 'Dumbbell Shrug'),
    't2': RepDbExerciseMatch.exact(
      'smith-machine-shrug',
      'Smith Machine Shrug',
    ),
    'b1': RepDbExerciseMatch.exact('barbell-curl', 'Barbell Curl'),
    'b2': RepDbExerciseMatch.reviewRequired(
      'bicep-curl',
      'Dumbbell Bicep Curl',
      'A execução alternada não está confirmada.',
    ),
    'b3': RepDbExerciseMatch.exact('hammer-curl', 'Dumbbell Hammer Curl'),
    'b4': RepDbExerciseMatch.exact(
      'machine-preacher-curl',
      'Machine Preacher Curl',
    ),
    'b5': RepDbExerciseMatch.exact('concentration-curl', 'Concentration Curl'),
    'b6': RepDbExerciseMatch.exact('cable-curl', 'Cable Curl'),
    'b7': RepDbExerciseMatch.exact('reverse-curl', 'Reverse Curl'),
    'b8': RepDbExerciseMatch.reviewRequired(
      'dumbbell-wrist-curl',
      'Dumbbell Wrist Curl',
      'A fonte fixa halter, enquanto o cadastro atual aceita barra.',
    ),
    'tr1': RepDbExerciseMatch.reviewRequired(
      'tricep-pushdown',
      'Cable Tricep Pushdown',
      'O acessório de barra reta não está confirmado.',
    ),
    'tr2': RepDbExerciseMatch.reviewRequired(
      'tricep-pushdown',
      'Cable Tricep Pushdown',
      'O acessório de corda não está confirmado.',
    ),
    'tr3': RepDbExerciseMatch.exact('skull-crusher', 'Skull Crusher'),
    'tr4': RepDbExerciseMatch.unavailable(
      'Não foi encontrada extensão de tríceps deitada na polia.',
    ),
    'tr5': RepDbExerciseMatch.exact(
      'overhead-tricep-extension',
      'Overhead Tricep Extension',
    ),
    'tr6': RepDbExerciseMatch.unavailable(
      'Não foi encontrada extensão de tríceps acima da cabeça na polia.',
    ),
    'tr7': RepDbExerciseMatch.exact(
      'cable-tricep-kickback',
      'Cable Tricep Kickback',
    ),
    'tr8': RepDbExerciseMatch.exact('dips', 'Chest Dips'),
    'tr9': RepDbExerciseMatch.exact(
      'close-grip-bench-press',
      'Close-Grip Bench Press',
    ),
    'pe1': RepDbExerciseMatch.exact('squat', 'Barbell Back Squat'),
    'pe2': RepDbExerciseMatch.exact(
      'smith-machine-squat',
      'Smith Machine Squat',
    ),
    'pe3': RepDbExerciseMatch.exact('hack-squat', 'Hack Squat'),
    'pe4': RepDbExerciseMatch.exact('leg-press', 'Leg Press'),
    'pe5': RepDbExerciseMatch.exact(
      'horizontal-leg-press',
      'Horizontal Leg Press',
    ),
    'pe6': RepDbExerciseMatch.exact('leg-extension', 'Leg Extension'),
    'pe7': RepDbExerciseMatch.exact('leg-curl', 'Lying Leg Curl'),
    'pe8': RepDbExerciseMatch.exact('seated-leg-curl', 'Seated Leg Curl'),
    'pe9': RepDbExerciseMatch.reviewRequired(
      'single-leg-lying-leg-curl',
      'Single Leg Lying Leg Curl',
      'A fonte demonstra a execução deitada, não em pé.',
    ),
    'pe10': RepDbExerciseMatch.exact(
      'stiff-leg-deadlift',
      'Stiff Leg Deadlift',
    ),
    'pe11': RepDbExerciseMatch.exact('deadlift', 'Barbell Deadlift'),
    'pe12': RepDbExerciseMatch.exact('hip-thrust', 'Barbell Hip Thrust'),
    'pe13': RepDbExerciseMatch.exact('hip-abduction', 'Machine Hip Abduction'),
    'pe14': RepDbExerciseMatch.exact('hip-adduction', 'Hip Adduction'),
    'pe15': RepDbExerciseMatch.reviewRequired(
      'lunge',
      'Lunge',
      'O cadastro atual combina afundo parado e passada caminhando.',
    ),
    'pe16': RepDbExerciseMatch.exact(
      'standing-calf-raise',
      'Standing Calf Raise',
    ),
    'pe17': RepDbExerciseMatch.exact('seated-calf-raise', 'Seated Calf Raise'),
    'pe18': RepDbExerciseMatch.unavailable(
      'Não foi encontrada panturrilha executada no leg press.',
    ),
    'pe19': RepDbExerciseMatch.reviewRequired(
      'dumbbell-romanian-deadlift',
      'Dumbbell Romanian Deadlift',
      'Terra romeno e stiff estrito não são execuções idênticas.',
    ),
    'ab1': RepDbExerciseMatch.exact('crunches', 'Crunches'),
    'ab2': RepDbExerciseMatch.exact('reverse-crunches', 'Reverse Crunches'),
    'ab3': RepDbExerciseMatch.reviewRequired(
      'crunches',
      'Crunches',
      'A fonte não utiliza máquina ou resistência externa.',
    ),
    'ab4': RepDbExerciseMatch.exact('cable-crunch', 'Cable Crunch'),
    'ab5': RepDbExerciseMatch.exact('plank', 'Plank'),
    'ab6': RepDbExerciseMatch.exact('russian-twist', 'Russian Twist'),
  };

  static const List<RepDbCatalogAddition> plannedAdditions = [
    RepDbCatalogAddition(
      repDbId: 'push-up',
      namePtBr: 'Flexão de Braços',
      primaryMuscle: 'Peito',
      aliases: <String>['Flexão', 'Push-Up'],
    ),
    RepDbCatalogAddition(
      repDbId: 'incline-push-ups',
      namePtBr: 'Flexão de Braços Inclinada',
      primaryMuscle: 'Peito',
      aliases: <String>['Flexão Inclinada', 'Incline Push-Up'],
    ),
    RepDbCatalogAddition(
      repDbId: 'diamond-push-ups',
      namePtBr: 'Flexão Diamante',
      primaryMuscle: 'Tríceps',
      aliases: <String>['Diamond Push-Up'],
    ),
    RepDbCatalogAddition(
      repDbId: 'assisted-pull-ups',
      namePtBr: 'Barra Fixa Assistida',
      primaryMuscle: 'Costas',
      aliases: <String>['Pull-Up Assistido', 'Assisted Pull-Up'],
    ),
    RepDbCatalogAddition(
      repDbId: 'chin-ups',
      namePtBr: 'Barra Fixa com Pegada Supinada',
      primaryMuscle: 'Costas',
      aliases: <String>['Chin-Up', 'Barra Supinada'],
    ),
    RepDbCatalogAddition(
      repDbId: 'chest-supported-db-row',
      namePtBr: 'Remada com Halteres Apoiada no Banco',
      primaryMuscle: 'Costas',
      aliases: <String>['Chest-Supported Dumbbell Row'],
    ),
    RepDbCatalogAddition(
      repDbId: 'face-pull',
      namePtBr: 'Face Pull na Polia',
      primaryMuscle: 'Ombros',
      aliases: <String>['Face Pull', 'Puxada para o Rosto'],
    ),
    RepDbCatalogAddition(
      repDbId: 'db-pullover',
      namePtBr: 'Pullover com Halter',
      primaryMuscle: 'Costas',
      aliases: <String>['Dumbbell Pullover', 'Pull Over com Halter'],
    ),
    RepDbCatalogAddition(
      repDbId: 'arnold-press',
      namePtBr: 'Desenvolvimento Arnold',
      primaryMuscle: 'Ombros',
      aliases: <String>['Arnold Press'],
    ),
    RepDbCatalogAddition(
      repDbId: 'upright-row',
      namePtBr: 'Remada Alta com Barra',
      primaryMuscle: 'Ombros',
      aliases: <String>['Barbell Upright Row', 'Remada Alta'],
    ),
    RepDbCatalogAddition(
      repDbId: 'cable-upright-row',
      namePtBr: 'Remada Alta na Polia',
      primaryMuscle: 'Ombros',
      aliases: <String>['Cable Upright Row'],
    ),
    RepDbCatalogAddition(
      repDbId: 'assisted-dips',
      namePtBr: 'Mergulho Assistido na Máquina',
      primaryMuscle: 'Tríceps',
      aliases: <String>['Machine Assisted Dips', 'Paralelas Assistidas'],
    ),
    RepDbCatalogAddition(
      repDbId: 'front-squat',
      namePtBr: 'Agachamento Frontal com Barra',
      primaryMuscle: 'Pernas',
      aliases: <String>['Front Squat', 'Agachamento Frontal'],
    ),
    RepDbCatalogAddition(
      repDbId: 'goblet-squat',
      namePtBr: 'Agachamento Goblet',
      primaryMuscle: 'Pernas',
      aliases: <String>['Goblet Squat', 'Agachamento Cálice'],
    ),
    RepDbCatalogAddition(
      repDbId: 'bulgarian-split-squat',
      namePtBr: 'Agachamento Búlgaro com Halteres',
      primaryMuscle: 'Pernas',
      aliases: <String>['Bulgarian Split Squat', 'Afundo Búlgaro'],
    ),
    RepDbCatalogAddition(
      repDbId: 'walking-lunge',
      namePtBr: 'Passada Caminhando',
      primaryMuscle: 'Pernas',
      aliases: <String>['Walking Lunge', 'Avanço Caminhando'],
    ),
    RepDbCatalogAddition(
      repDbId: 'romanian-deadlift',
      namePtBr: 'Levantamento Terra Romeno com Barra',
      primaryMuscle: 'Pernas',
      aliases: <String>['Romanian Deadlift', 'RDL com Barra'],
    ),
    RepDbCatalogAddition(
      repDbId: 'sumo-deadlift',
      namePtBr: 'Levantamento Terra Sumô',
      primaryMuscle: 'Pernas',
      aliases: <String>['Sumo Deadlift', 'Terra Sumô'],
    ),
    RepDbCatalogAddition(
      repDbId: 'glute-bridge',
      namePtBr: 'Ponte de Glúteos',
      primaryMuscle: 'Pernas',
      aliases: <String>['Glute Bridge', 'Ponte de Quadril'],
    ),
    RepDbCatalogAddition(
      repDbId: 'single-leg-romanian-deadlift',
      namePtBr: 'Terra Romeno Unilateral com Halteres',
      primaryMuscle: 'Pernas',
      aliases: <String>['Single Leg Romanian Deadlift', 'RDL Unilateral'],
    ),
    RepDbCatalogAddition(
      repDbId: 'good-morning',
      namePtBr: 'Good Morning com Barra',
      primaryMuscle: 'Pernas',
      aliases: <String>['Bom Dia com Barra', 'Barbell Good Morning'],
    ),
    RepDbCatalogAddition(
      repDbId: 'hack-squat-calf-raise',
      namePtBr: 'Panturrilha no Hack',
      primaryMuscle: 'Panturrilha',
      aliases: <String>['Hack Squat Calf Raise'],
    ),
    RepDbCatalogAddition(
      repDbId: 'ab-wheel-rollout',
      namePtBr: 'Roda Abdominal',
      primaryMuscle: 'Abdômen',
      aliases: <String>['Ab Wheel Rollout', 'Abdominal com Roda'],
    ),
    RepDbCatalogAddition(
      repDbId: 'hanging-leg-raise',
      namePtBr: 'Elevação de Pernas Suspenso',
      primaryMuscle: 'Abdômen',
      aliases: <String>['Hanging Leg Raise', 'Elevação de Pernas na Barra'],
    ),
    RepDbCatalogAddition(
      repDbId: 'side-plank',
      namePtBr: 'Prancha Lateral',
      primaryMuscle: 'Abdômen',
      aliases: <String>['Side Plank'],
    ),
    RepDbCatalogAddition(
      repDbId: 'mountain-climbers',
      namePtBr: 'Escalador',
      primaryMuscle: 'Abdômen',
      aliases: <String>['Mountain Climbers', 'Corrida do Alpinista'],
    ),
  ];

  static RepDbExerciseMatch? matchFor(String pulseExerciseId) {
    return legacyMatches[pulseExerciseId];
  }

  static List<String> approvedAliasesFor(String pulseExerciseId) {
    return legacyMatches[pulseExerciseId]?.approvedAliases ?? const <String>[];
  }
}
