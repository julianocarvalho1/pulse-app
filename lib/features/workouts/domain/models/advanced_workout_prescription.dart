import 'package:flutter/foundation.dart';

enum WorkoutTechnique {
  none,
  dropSet,
  restPause,
  isometry,
  failure,
  partialFailure,
  deadStop,
  cluster,
  myoReps;

  String get storageValue => name;

  String get label => switch (this) {
    WorkoutTechnique.none => 'Nenhuma',
    WorkoutTechnique.dropSet => 'Drop-set',
    WorkoutTechnique.restPause => 'Rest-pause',
    WorkoutTechnique.isometry => 'Isometria',
    WorkoutTechnique.failure => 'Falha concêntrica',
    WorkoutTechnique.partialFailure => 'Falha parcial',
    WorkoutTechnique.deadStop => 'Dead stop',
    WorkoutTechnique.cluster => 'Cluster set',
    WorkoutTechnique.myoReps => 'Myo-reps',
  };

  static WorkoutTechnique fromStorage(Object? value) {
    final target = value?.toString() ?? '';
    return WorkoutTechnique.values.firstWhere(
      (item) => item.storageValue == target,
      orElse: () => WorkoutTechnique.none,
    );
  }
}

@immutable
class WorkoutSetPrescription {
  const WorkoutSetPrescription({
    required this.setNumber,
    this.target = '',
    this.restSeconds,
    this.targetRir,
    this.cadence = '',
    this.technique = WorkoutTechnique.none,
    this.notes = '',
  });

  final int setNumber;
  final String target;
  final int? restSeconds;
  final int? targetRir;
  final String cadence;
  final WorkoutTechnique technique;
  final String notes;

  bool get hasDetails =>
      target.trim().isNotEmpty ||
      restSeconds != null ||
      targetRir != null ||
      cadence.trim().isNotEmpty ||
      technique != WorkoutTechnique.none ||
      notes.trim().isNotEmpty;

  String get summary {
    final parts = <String>[];
    if (target.trim().isNotEmpty) {
      parts.add(target.trim());
    }
    if (targetRir != null) {
      parts.add('RIR $targetRir');
    }
    if (cadence.trim().isNotEmpty) {
      parts.add('Cadência ${cadence.trim()}');
    }
    if (technique != WorkoutTechnique.none) {
      parts.add(technique.label);
    }
    if (restSeconds != null && restSeconds! > 0) {
      parts.add('${restSeconds}s descanso');
    }
    return parts.isEmpty ? 'Sem detalhes' : parts.join(' • ');
  }

  WorkoutSetPrescription copyWith({
    int? setNumber,
    String? target,
    int? restSeconds,
    bool clearRestSeconds = false,
    int? targetRir,
    bool clearTargetRir = false,
    String? cadence,
    WorkoutTechnique? technique,
    String? notes,
  }) {
    return WorkoutSetPrescription(
      setNumber: setNumber ?? this.setNumber,
      target: target ?? this.target,
      restSeconds: clearRestSeconds ? null : (restSeconds ?? this.restSeconds),
      targetRir: clearTargetRir ? null : (targetRir ?? this.targetRir),
      cadence: cadence ?? this.cadence,
      technique: technique ?? this.technique,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'setNumber': setNumber,
      'target': target,
      if (restSeconds != null) 'restSeconds': restSeconds,
      if (targetRir != null) 'targetRir': targetRir,
      'cadence': cadence,
      'technique': technique.storageValue,
      'notes': notes,
    };
  }

  factory WorkoutSetPrescription.fromMap(Map<String, dynamic> map) {
    return WorkoutSetPrescription(
      setNumber: _readInt(map['setNumber'], 1).clamp(1, 30).toInt(),
      target: map['target']?.toString() ?? '',
      restSeconds: _readNullableInt(map['restSeconds']),
      targetRir: _readNullableInt(map['targetRir']),
      cadence: map['cadence']?.toString() ?? '',
      technique: WorkoutTechnique.fromStorage(map['technique']),
      notes: map['notes']?.toString() ?? '',
    );
  }
}

@immutable
class WorkoutWeekPrescription {
  const WorkoutWeekPrescription({
    required this.weekNumber,
    this.label = '',
    this.sets = const <WorkoutSetPrescription>[],
    this.notes = '',
  });

  final int weekNumber;
  final String label;
  final List<WorkoutSetPrescription> sets;
  final String notes;

  String get displayName =>
      label.trim().isEmpty ? 'Semana $weekNumber' : label.trim();

  WorkoutWeekPrescription copyWith({
    int? weekNumber,
    String? label,
    List<WorkoutSetPrescription>? sets,
    String? notes,
  }) {
    return WorkoutWeekPrescription(
      weekNumber: weekNumber ?? this.weekNumber,
      label: label ?? this.label,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'weekNumber': weekNumber,
      'label': label,
      'sets': sets.map((set) => set.toMap()).toList(growable: false),
      'notes': notes,
    };
  }

  factory WorkoutWeekPrescription.fromMap(Map<String, dynamic> map) {
    final rawSets = map['sets'];
    return WorkoutWeekPrescription(
      weekNumber: _readInt(map['weekNumber'], 1).clamp(1, 52).toInt(),
      label: map['label']?.toString() ?? '',
      sets: rawSets is List
          ? rawSets
                .whereType<Map>()
                .map(
                  (set) => WorkoutSetPrescription.fromMap(
                    Map<String, dynamic>.from(set),
                  ),
                )
                .toList(growable: false)
          : const <WorkoutSetPrescription>[],
      notes: map['notes']?.toString() ?? '',
    );
  }
}

@immutable
class ExerciseAlternative {
  const ExerciseAlternative({
    required this.exerciseId,
    required this.name,
    this.muscle = '',
  });

  final String exerciseId;
  final String name;
  final String muscle;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'exerciseId': exerciseId,
      'name': name,
      'muscle': muscle,
    };
  }

  factory ExerciseAlternative.fromMap(Map<String, dynamic> map) {
    return ExerciseAlternative(
      exerciseId: map['exerciseId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      muscle: map['muscle']?.toString() ?? '',
    );
  }
}

@immutable
class AdvancedExercisePrescription {
  const AdvancedExercisePrescription({
    this.activeWeek = 1,
    this.weeks = const <WorkoutWeekPrescription>[],
    this.alternatives = const <ExerciseAlternative>[],
  });

  final int activeWeek;
  final List<WorkoutWeekPrescription> weeks;
  final List<ExerciseAlternative> alternatives;

  bool get hasPeriodization => weeks.length > 1;
  bool get hasSetDetails => weeks.any((week) => week.sets.isNotEmpty);
  bool get hasAlternatives => alternatives.isNotEmpty;
  bool get isEmpty => !hasSetDetails && !hasAlternatives;

  WorkoutWeekPrescription? get activePrescription {
    if (weeks.isEmpty) {
      return null;
    }
    return weeks.firstWhere(
      (week) => week.weekNumber == activeWeek,
      orElse: () => weeks.first,
    );
  }

  /// Prescrição principal usada enquanto o planejamento por semanas
  /// permanece oculto no aplicativo. As demais semanas continuam preservadas
  /// para compatibilidade com backups e arquivos antigos.
  WorkoutWeekPrescription? get primaryPrescription {
    if (weeks.isEmpty) {
      return null;
    }
    final ordered = List<WorkoutWeekPrescription>.from(weeks)
      ..sort((a, b) => a.weekNumber.compareTo(b.weekNumber));
    return ordered.first;
  }

  String get summary {
    final parts = <String>[];
    final setCount = primaryPrescription?.sets.length ?? 0;
    if (setCount > 0) {
      parts.add(
        '$setCount série${setCount == 1 ? '' : 's'} detalhada${setCount == 1 ? '' : 's'}',
      );
    }
    if (alternatives.isNotEmpty) {
      parts.add(
        '${alternatives.length} alternativa${alternatives.length == 1 ? '' : 's'}',
      );
    }
    return parts.join(' • ');
  }

  AdvancedExercisePrescription copyWith({
    int? activeWeek,
    List<WorkoutWeekPrescription>? weeks,
    List<ExerciseAlternative>? alternatives,
  }) {
    return AdvancedExercisePrescription(
      activeWeek: activeWeek ?? this.activeWeek,
      weeks: weeks ?? this.weeks,
      alternatives: alternatives ?? this.alternatives,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'activeWeek': activeWeek,
      'weeks': weeks.map((week) => week.toMap()).toList(growable: false),
      'alternatives': alternatives
          .map((alternative) => alternative.toMap())
          .toList(growable: false),
    };
  }

  factory AdvancedExercisePrescription.fromMap(Map<String, dynamic> map) {
    final rawWeeks = map['weeks'];
    final rawAlternatives = map['alternatives'];
    return AdvancedExercisePrescription(
      activeWeek: _readInt(map['activeWeek'], 1).clamp(1, 52).toInt(),
      weeks: rawWeeks is List
          ? rawWeeks
                .whereType<Map>()
                .map(
                  (week) => WorkoutWeekPrescription.fromMap(
                    Map<String, dynamic>.from(week),
                  ),
                )
                .toList(growable: false)
          : const <WorkoutWeekPrescription>[],
      alternatives: rawAlternatives is List
          ? rawAlternatives
                .whereType<Map>()
                .map(
                  (alternative) => ExerciseAlternative.fromMap(
                    Map<String, dynamic>.from(alternative),
                  ),
                )
                .where((alternative) => alternative.name.trim().isNotEmpty)
                .toList(growable: false)
          : const <ExerciseAlternative>[],
    );
  }
}

int _readInt(Object? value, int fallback) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _readNullableInt(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
}
