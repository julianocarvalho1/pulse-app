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
    required this.sourceName,
    required this.namePtBr,
    required this.primaryMuscle,
    this.aliases = const <String>[],
  });

  final String repDbId;
  final String sourceName;
  final String namePtBr;
  final String primaryMuscle;
  final List<String> aliases;

  String get pulseId => 'repdb_$repDbId';
}

class RepDbExerciseMedia {
  const RepDbExerciseMedia.paired({
    required this.startAssetPath,
    required this.peakAssetPath,
  }) : mainAssetPath = null;

  const RepDbExerciseMedia.single({required this.mainAssetPath})
    : startAssetPath = null,
      peakAssetPath = null;

  final String? startAssetPath;
  final String? peakAssetPath;
  final String? mainAssetPath;

  bool get hasPosePair => startAssetPath != null && peakAssetPath != null;
}

class RepDbExerciseMapping {
  const RepDbExerciseMapping._();

  static const int version = 2;
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
    'p5': RepDbExerciseMatch.exact(
      'smith-machine-incline-bench-press',
      'Smith Machine Incline Bench Press',
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
    'p10': RepDbExerciseMatch.exact('cable-fly', 'Cable Fly'),
    'p11': RepDbExerciseMatch.exact('cable-chest-press', 'Cable Chest Press'),
    'p12': RepDbExerciseMatch.exact(
      'chest-press-machine',
      'Machine Chest Press',
    ),
    'c1': RepDbExerciseMatch.exact('lat-pulldown', 'Lat Pulldown'),
    'c2': RepDbExerciseMatch.exact('v-bar-lat-pulldown', 'V-Bar Lat Pulldown'),
    'c3': RepDbExerciseMatch.exact('barbell-row', 'Bent-Over Barbell Row'),
    'c4': RepDbExerciseMatch.exact('t-bar-row', 'T-Bar Row'),
    'c5': RepDbExerciseMatch.exact(
      'wide-grip-seated-cable-row',
      'Wide Grip Seated Cable Row',
    ),
    'c6': RepDbExerciseMatch.exact(
      'smith-machine-bent-over-row',
      'Smith Machine Bent Over Row',
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
    'c10': RepDbExerciseMatch.exact(
      'barbell-rear-delt-row',
      'Barbell Rear Delt Row',
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
    'b2': RepDbExerciseMatch.exact(
      'seated-dumbbell-curl',
      'Seated Dumbbell Curl',
    ),
    'b3': RepDbExerciseMatch.exact('hammer-curl', 'Dumbbell Hammer Curl'),
    'b4': RepDbExerciseMatch.exact(
      'machine-preacher-curl',
      'Machine Preacher Curl',
    ),
    'b5': RepDbExerciseMatch.exact('concentration-curl', 'Concentration Curl'),
    'b6': RepDbExerciseMatch.exact('cable-curl', 'Cable Curl'),
    'b7': RepDbExerciseMatch.exact('reverse-curl', 'Reverse Curl'),
    'b8': RepDbExerciseMatch.exact(
      'dumbbell-wrist-curl',
      'Dumbbell Wrist Curl',
    ),
    'tr1': RepDbExerciseMatch.exact(
      'v-bar-tricep-pushdown',
      'V-Bar Tricep Pushdown',
    ),
    'tr2': RepDbExerciseMatch.exact('tricep-pushdown', 'Cable Tricep Pushdown'),
    'tr3': RepDbExerciseMatch.exact('skull-crusher', 'Skull Crusher'),
    'tr4': RepDbExerciseMatch.exact(
      'lying-tricep-extension',
      'Lying Tricep Extension',
    ),
    'tr5': RepDbExerciseMatch.exact(
      'overhead-tricep-extension',
      'Overhead Tricep Extension',
    ),
    'tr6': RepDbExerciseMatch.exact(
      'ez-bar-overhead-extension',
      'EZ-Bar Overhead Tricep Extension',
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
    'pe9': RepDbExerciseMatch.exact(
      'single-leg-lying-leg-curl',
      'Single Leg Lying Leg Curl',
    ),
    'pe10': RepDbExerciseMatch.exact(
      'stiff-leg-deadlift',
      'Stiff Leg Deadlift',
    ),
    'pe11': RepDbExerciseMatch.exact('deadlift', 'Barbell Deadlift'),
    'pe12': RepDbExerciseMatch.exact('hip-thrust', 'Barbell Hip Thrust'),
    'pe13': RepDbExerciseMatch.exact('hip-abduction', 'Machine Hip Abduction'),
    'pe14': RepDbExerciseMatch.exact('hip-adduction', 'Hip Adduction'),
    'pe15': RepDbExerciseMatch.exact('lunge', 'Lunge'),
    'pe16': RepDbExerciseMatch.exact(
      'standing-calf-raise',
      'Standing Calf Raise',
    ),
    'pe17': RepDbExerciseMatch.exact('seated-calf-raise', 'Seated Calf Raise'),
    'pe18': RepDbExerciseMatch.exact(
      'hack-squat-calf-raise',
      'Hack Squat Calf Raise',
    ),
    'pe19': RepDbExerciseMatch.exact(
      'dumbbell-romanian-deadlift',
      'Dumbbell Romanian Deadlift',
    ),
    'ab1': RepDbExerciseMatch.exact('crunches', 'Crunches'),
    'ab2': RepDbExerciseMatch.exact('reverse-crunches', 'Reverse Crunches'),
    'ab3': RepDbExerciseMatch.exact(
      'weighted-wall-crunch',
      'Weighted Wall Crunch',
    ),
    'ab4': RepDbExerciseMatch.exact('cable-crunch', 'Cable Crunch'),
    'ab5': RepDbExerciseMatch.exact('plank', 'Plank'),
    'ab6': RepDbExerciseMatch.exact('russian-twist', 'Russian Twist'),
  };

  static const List<RepDbCatalogAddition> catalogAdditions = [
    RepDbCatalogAddition(
      repDbId: 'push-up',
      sourceName: 'Push-Up',
      namePtBr: 'Flexão de Braços',
      primaryMuscle: 'Peito',
      aliases: <String>['Flexão', 'Push-Up'],
    ),
    RepDbCatalogAddition(
      repDbId: 'incline-push-ups',
      sourceName: 'Incline Push-Up',
      namePtBr: 'Flexão de Braços Inclinada',
      primaryMuscle: 'Peito',
      aliases: <String>['Flexão Inclinada', 'Incline Push-Up'],
    ),
    RepDbCatalogAddition(
      repDbId: 'diamond-push-ups',
      sourceName: 'Diamond Push Ups',
      namePtBr: 'Flexão Diamante',
      primaryMuscle: 'Tríceps',
      aliases: <String>['Diamond Push-Up'],
    ),
    RepDbCatalogAddition(
      repDbId: 'assisted-pull-ups',
      sourceName: 'Assisted Pull Ups',
      namePtBr: 'Barra Fixa Assistida',
      primaryMuscle: 'Costas',
      aliases: <String>['Pull-Up Assistido', 'Assisted Pull-Up'],
    ),
    RepDbCatalogAddition(
      repDbId: 'chin-ups',
      sourceName: 'Chin-Ups',
      namePtBr: 'Barra Fixa com Pegada Supinada',
      primaryMuscle: 'Costas',
      aliases: <String>['Chin-Up', 'Barra Supinada'],
    ),
    RepDbCatalogAddition(
      repDbId: 'chest-supported-db-row',
      sourceName: 'Chest-Supported Dumbbell Row',
      namePtBr: 'Remada com Halteres Apoiada no Banco',
      primaryMuscle: 'Costas',
      aliases: <String>['Chest-Supported Dumbbell Row'],
    ),
    RepDbCatalogAddition(
      repDbId: 'face-pull',
      sourceName: 'Cable Face Pull',
      namePtBr: 'Face Pull na Polia',
      primaryMuscle: 'Ombros',
      aliases: <String>['Face Pull', 'Puxada para o Rosto'],
    ),
    RepDbCatalogAddition(
      repDbId: 'db-pullover',
      sourceName: 'Dumbbell Pullover',
      namePtBr: 'Pullover com Halter',
      primaryMuscle: 'Costas',
      aliases: <String>['Dumbbell Pullover', 'Pull Over com Halter'],
    ),
    RepDbCatalogAddition(
      repDbId: 'arnold-press',
      sourceName: 'Arnold Press',
      namePtBr: 'Desenvolvimento Arnold',
      primaryMuscle: 'Ombros',
      aliases: <String>['Arnold Press'],
    ),
    RepDbCatalogAddition(
      repDbId: 'upright-row',
      sourceName: 'Barbell Upright Row',
      namePtBr: 'Remada Alta com Barra',
      primaryMuscle: 'Ombros',
      aliases: <String>['Barbell Upright Row', 'Remada Alta'],
    ),
    RepDbCatalogAddition(
      repDbId: 'cable-upright-row',
      sourceName: 'Cable Upright Row',
      namePtBr: 'Remada Alta na Polia',
      primaryMuscle: 'Ombros',
      aliases: <String>['Cable Upright Row'],
    ),
    RepDbCatalogAddition(
      repDbId: 'assisted-dips',
      sourceName: 'Machine Assisted Dips',
      namePtBr: 'Mergulho Assistido na Máquina',
      primaryMuscle: 'Tríceps',
      aliases: <String>['Machine Assisted Dips', 'Paralelas Assistidas'],
    ),
    RepDbCatalogAddition(
      repDbId: 'front-squat',
      sourceName: 'Front Squat',
      namePtBr: 'Agachamento Frontal com Barra',
      primaryMuscle: 'Pernas',
      aliases: <String>['Front Squat', 'Agachamento Frontal'],
    ),
    RepDbCatalogAddition(
      repDbId: 'goblet-squat',
      sourceName: 'Goblet Squat',
      namePtBr: 'Agachamento Goblet',
      primaryMuscle: 'Pernas',
      aliases: <String>['Goblet Squat', 'Agachamento Cálice'],
    ),
    RepDbCatalogAddition(
      repDbId: 'bulgarian-split-squat',
      sourceName: 'Bulgarian Split Squat',
      namePtBr: 'Agachamento Búlgaro com Halteres',
      primaryMuscle: 'Pernas',
      aliases: <String>['Bulgarian Split Squat', 'Afundo Búlgaro'],
    ),
    RepDbCatalogAddition(
      repDbId: 'walking-lunge',
      sourceName: 'Walking Lunge',
      namePtBr: 'Passada Caminhando',
      primaryMuscle: 'Pernas',
      aliases: <String>['Walking Lunge', 'Avanço Caminhando'],
    ),
    RepDbCatalogAddition(
      repDbId: 'romanian-deadlift',
      sourceName: 'Romanian Deadlift',
      namePtBr: 'Levantamento Terra Romeno com Barra',
      primaryMuscle: 'Pernas',
      aliases: <String>['Romanian Deadlift', 'RDL com Barra'],
    ),
    RepDbCatalogAddition(
      repDbId: 'sumo-deadlift',
      sourceName: 'Sumo Deadlift',
      namePtBr: 'Levantamento Terra Sumô',
      primaryMuscle: 'Pernas',
      aliases: <String>['Sumo Deadlift', 'Terra Sumô'],
    ),
    RepDbCatalogAddition(
      repDbId: 'glute-bridge',
      sourceName: 'Glute Bridge',
      namePtBr: 'Ponte de Glúteos',
      primaryMuscle: 'Pernas',
      aliases: <String>['Glute Bridge', 'Ponte de Quadril'],
    ),
    RepDbCatalogAddition(
      repDbId: 'single-leg-romanian-deadlift',
      sourceName: 'Single Leg Romanian Deadlift',
      namePtBr: 'Terra Romeno Unilateral com Halteres',
      primaryMuscle: 'Pernas',
      aliases: <String>['Single Leg Romanian Deadlift', 'RDL Unilateral'],
    ),
    RepDbCatalogAddition(
      repDbId: 'good-morning',
      sourceName: 'Good Morning',
      namePtBr: 'Good Morning com Barra',
      primaryMuscle: 'Pernas',
      aliases: <String>['Bom Dia com Barra', 'Barbell Good Morning'],
    ),
    RepDbCatalogAddition(
      repDbId: 'dumbbell-calf-raise',
      sourceName: 'Dumbbell Calf Raise',
      namePtBr: 'Panturrilha em Pé com Halteres',
      primaryMuscle: 'Panturrilha',
      aliases: <String>['Elevação Plantar com Halteres'],
    ),
    RepDbCatalogAddition(
      repDbId: 'ab-wheel-rollout',
      sourceName: 'Ab Wheel Rollout',
      namePtBr: 'Roda Abdominal',
      primaryMuscle: 'Abdômen',
      aliases: <String>['Ab Wheel Rollout', 'Abdominal com Roda'],
    ),
    RepDbCatalogAddition(
      repDbId: 'hanging-leg-raise',
      sourceName: 'Hanging Leg Raise',
      namePtBr: 'Elevação de Pernas Suspenso',
      primaryMuscle: 'Abdômen',
      aliases: <String>['Hanging Leg Raise', 'Elevação de Pernas na Barra'],
    ),
    RepDbCatalogAddition(
      repDbId: 'side-plank',
      sourceName: 'Side Plank',
      namePtBr: 'Prancha Lateral',
      primaryMuscle: 'Abdômen',
      aliases: <String>['Side Plank'],
    ),
    RepDbCatalogAddition(
      repDbId: 'mountain-climbers',
      sourceName: 'Mountain Climbers',
      namePtBr: 'Escalador',
      primaryMuscle: 'Abdômen',
      aliases: <String>['Mountain Climbers', 'Corrida do Alpinista'],
    ),
  ];

  static final Map<String, RepDbCatalogAddition> _additionsByPulseId = {
    for (final addition in catalogAdditions) addition.pulseId: addition,
  };

  static RepDbCatalogAddition? additionFor(String pulseExerciseId) {
    return _additionsByPulseId[pulseExerciseId];
  }

  static RepDbExerciseMatch? matchFor(String pulseExerciseId) {
    final legacyMatch = legacyMatches[pulseExerciseId];
    if (legacyMatch != null) {
      return legacyMatch;
    }

    final addition = additionFor(pulseExerciseId);
    if (addition == null) {
      return null;
    }

    return RepDbExerciseMatch.exact(addition.repDbId, addition.sourceName);
  }

  static List<String> approvedAliasesFor(String pulseExerciseId) {
    final addition = additionFor(pulseExerciseId);
    if (addition != null) {
      return <String>{
        addition.sourceName,
        ...addition.aliases,
      }.toList(growable: false);
    }

    return legacyMatches[pulseExerciseId]?.approvedAliases ?? const <String>[];
  }

  static RepDbExerciseMedia? approvedMediaFor(String pulseExerciseId) {
    final match = matchFor(pulseExerciseId);
    if (match == null || !match.isApproved || match.repDbId == null) {
      return null;
    }

    final sourceId = match.repDbId!;
    final assetPrefix = 'assets/images/$sourceId';

    if (sourceId == 'plank' || sourceId == 'side-plank') {
      return RepDbExerciseMedia.single(mainAssetPath: '$assetPrefix-main.webp');
    }

    return RepDbExerciseMedia.paired(
      startAssetPath: '$assetPrefix-start.webp',
      peakAssetPath: '$assetPrefix-peak.webp',
    );
  }
}
