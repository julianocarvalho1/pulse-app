import '../../../../models/exercise.dart';
import '../../../workouts/domain/models/cardio_log.dart';
import '../models/workout_generation_request.dart';
import '../models/workout_generation_result.dart';
import 'safety_screening_service.dart';
import 'workout_validation_service.dart';

class WorkoutGenerationService {
  const WorkoutGenerationService({
    this.safetyScreeningService = const SafetyScreeningService(),
    this.validationService = const WorkoutValidationService(),
  });

  final SafetyScreeningService safetyScreeningService;
  final WorkoutValidationService validationService;

  GeneratedWorkoutPlan generate(WorkoutGenerationRequest request) {
    final screening = safetyScreeningService.evaluate(request);
    if (!screening.canGenerate) {
      throw WorkoutGenerationException(screening.message);
    }

    if (request.daysPerWeek < 2 || request.daysPerWeek > 5) {
      throw const WorkoutGenerationException(
        'Escolha entre 2 e 5 dias de treino por semana.',
      );
    }

    if (request.sessionDurationMinutes < 20 ||
        request.sessionDurationMinutes > 90) {
      throw const WorkoutGenerationException(
        'A duração precisa ficar entre 20 e 90 minutos.',
      );
    }

    final programName = _programName(request);
    final templates = request.planType == GeneratedPlanType.cardio
        ? _cardioTemplates(request.daysPerWeek)
        : _strengthTemplates(request);
    final allowedExerciseIds = _allowedIds(request.environment);
    final rotations = <String, int>{};

    final routines = <WorkoutRoutine>[];
    for (var index = 0; index < templates.length; index++) {
      final template = templates[index];
      final exerciseLimit = _exerciseLimit(request);
      final muscles = _prioritizedMuscles(
        template.muscles,
        request.priorityMuscles,
        exerciseLimit,
      );
      final exercises = <Exercise>[];

      if (request.includesStrength) {
        for (var slotIndex = 0; slotIndex < muscles.length; slotIndex++) {
          final exercise = _pickExercise(
            muscle: muscles[slotIndex],
            environment: request.environment,
            avoidedIds: request.avoidedExerciseIds,
            alreadyUsedIds: exercises.map((item) => item.id).toSet(),
            rotations: rotations,
          );
          if (exercise != null) {
            exercises.add(_prescribe(exercise, request));
          }
        }
      }

      final cardio = <RoutineCardio>[];
      if (request.includesCardio) {
        cardio.add(
          RoutineCardio(
            id: 'generated_cardio_${index + 1}',
            modality: request.cardioModality,
            plannedDurationMinutes: _cardioMinutes(request),
            plan: CardioPlan(
              purpose: request.planType == GeneratedPlanType.cardio
                  ? CardioPurpose.standalone
                  : CardioPurpose.postWorkout,
              intensity: request.level == TrainingLevel.beginner
                  ? CardioIntensity.light
                  : CardioIntensity.moderate,
            ),
            notes: _cardioNote(request),
          ),
        );
      }

      routines.add(
        WorkoutRoutine(
          id: 'generated_${request.goal.name}_${request.daysPerWeek}_${index + 1}',
          name: template.name,
          focus: template.focus,
          groupName: programName,
          exercises: exercises,
          cardio: cardio,
        ),
      );
    }

    final program = WorkoutProgram(
      id: 'generated_${request.goal.name}_${request.planType.name}_${request.daysPerWeek}',
      name: programName,
      focus: _programFocus(request),
      routines: routines,
    );

    final validation = validationService.validate(
      request: request,
      program: program,
      allowedExerciseIds: allowedExerciseIds,
    );

    if (!validation.isValid) {
      final reason = validation.errors.map((issue) => issue.message).join(' ');
      throw WorkoutGenerationException(
        reason.isEmpty
            ? 'O plano não passou pela validação de segurança.'
            : reason,
      );
    }

    return GeneratedWorkoutPlan(
      request: request,
      program: program,
      validation: validation,
      explanation: _explanation(request),
    );
  }

  String _programName(WorkoutGenerationRequest request) {
    return 'Plano PULSE • ${request.goal.label} ${request.daysPerWeek}x';
  }

  String _programFocus(WorkoutGenerationRequest request) {
    return '${request.goal.label} • ${request.level.label} • '
        '${request.planType.label} • ${request.sessionDurationMinutes} min';
  }

  String _explanation(WorkoutGenerationRequest request) {
    final split = switch (request.daysPerWeek) {
      2 => 'Full Body A/B',
      3 when request.level == TrainingLevel.beginner => 'Full Body A/B/C',
      3 => 'Empurrar/Puxar/Pernas',
      4 => 'Superior/Inferior',
      _ => 'Empurrar/Puxar/Pernas/Superior/Inferior',
    };

    if (request.planType == GeneratedPlanType.cardio) {
      return 'O plano distribui ${request.daysPerWeek} sessões de cardio de '
          '${request.sessionDurationMinutes} minutos. As métricas reais serão '
          'registradas durante cada sessão.';
    }

    final cardioText = request.planType == GeneratedPlanType.mixed
        ? ' Cada ficha termina com ${_cardioMinutes(request)} minutos de cardio.'
        : '';

    return 'Divisão $split com exercícios do catálogo do PULSE, ajustada para '
        '${request.environment.label.toLowerCase()} e sessões de até '
        '${request.sessionDurationMinutes} minutos.$cardioText';
  }

  List<_RoutineTemplate> _strengthTemplates(WorkoutGenerationRequest request) {
    return switch (request.daysPerWeek) {
      2 => const <_RoutineTemplate>[
        _RoutineTemplate(
          name: 'Full Body A',
          focus: 'Corpo inteiro com ênfase em movimentos básicos',
          muscles: <String>[
            'Pernas',
            'Peito',
            'Costas',
            'Ombros',
            'Pernas',
            'Bíceps',
            'Tríceps',
            'Abdômen',
          ],
        ),
        _RoutineTemplate(
          name: 'Full Body B',
          focus: 'Corpo inteiro com variação dos padrões de movimento',
          muscles: <String>[
            'Pernas',
            'Costas',
            'Peito',
            'Ombros',
            'Pernas',
            'Tríceps',
            'Bíceps',
            'Abdômen',
          ],
        ),
      ],
      3 when request.level == TrainingLevel.beginner =>
        const <_RoutineTemplate>[
          _RoutineTemplate(
            name: 'Full Body A',
            focus: 'Base técnica e corpo inteiro',
            muscles: <String>['Pernas', 'Peito', 'Costas', 'Ombros', 'Abdômen'],
          ),
          _RoutineTemplate(
            name: 'Full Body B',
            focus: 'Variação de movimentos para o corpo inteiro',
            muscles: <String>['Pernas', 'Costas', 'Peito', 'Bíceps', 'Tríceps'],
          ),
          _RoutineTemplate(
            name: 'Full Body C',
            focus: 'Consolidação da semana e estabilidade',
            muscles: <String>['Pernas', 'Peito', 'Costas', 'Ombros', 'Abdômen'],
          ),
        ],
      3 => const <_RoutineTemplate>[
        _RoutineTemplate(
          name: 'Treino A • Empurrar',
          focus: 'Peito, ombros e tríceps',
          muscles: <String>[
            'Peito',
            'Peito',
            'Ombros',
            'Ombros',
            'Tríceps',
            'Tríceps',
            'Abdômen',
          ],
        ),
        _RoutineTemplate(
          name: 'Treino B • Puxar',
          focus: 'Costas, bíceps e deltoide posterior',
          muscles: <String>[
            'Costas',
            'Costas',
            'Costas',
            'Ombros',
            'Bíceps',
            'Bíceps',
            'Abdômen',
          ],
        ),
        _RoutineTemplate(
          name: 'Treino C • Pernas',
          focus: 'Quadríceps, posteriores, glúteos e panturrilhas',
          muscles: <String>[
            'Pernas',
            'Pernas',
            'Pernas',
            'Pernas',
            'Panturrilha',
            'Panturrilha',
            'Abdômen',
          ],
        ),
      ],
      4 => const <_RoutineTemplate>[
        _RoutineTemplate(
          name: 'Superior A',
          focus: 'Peito, costas, ombros e braços',
          muscles: <String>[
            'Peito',
            'Costas',
            'Peito',
            'Costas',
            'Ombros',
            'Bíceps',
            'Tríceps',
          ],
        ),
        _RoutineTemplate(
          name: 'Inferior A',
          focus: 'Quadríceps, posteriores e panturrilhas',
          muscles: <String>[
            'Pernas',
            'Pernas',
            'Pernas',
            'Panturrilha',
            'Abdômen',
          ],
        ),
        _RoutineTemplate(
          name: 'Superior B',
          focus: 'Variação para o tronco e braços',
          muscles: <String>[
            'Costas',
            'Peito',
            'Costas',
            'Ombros',
            'Ombros',
            'Tríceps',
            'Bíceps',
          ],
        ),
        _RoutineTemplate(
          name: 'Inferior B',
          focus: 'Posteriores, glúteos, quadríceps e core',
          muscles: <String>[
            'Pernas',
            'Pernas',
            'Pernas',
            'Panturrilha',
            'Abdômen',
          ],
        ),
      ],
      _ => const <_RoutineTemplate>[
        _RoutineTemplate(
          name: 'Empurrar',
          focus: 'Peito, ombros e tríceps',
          muscles: <String>[
            'Peito',
            'Peito',
            'Ombros',
            'Ombros',
            'Tríceps',
            'Tríceps',
          ],
        ),
        _RoutineTemplate(
          name: 'Puxar',
          focus: 'Costas, bíceps e deltoide posterior',
          muscles: <String>[
            'Costas',
            'Costas',
            'Costas',
            'Ombros',
            'Bíceps',
            'Bíceps',
          ],
        ),
        _RoutineTemplate(
          name: 'Pernas',
          focus: 'Quadríceps, posteriores e panturrilhas',
          muscles: <String>[
            'Pernas',
            'Pernas',
            'Pernas',
            'Pernas',
            'Panturrilha',
            'Abdômen',
          ],
        ),
        _RoutineTemplate(
          name: 'Superior',
          focus: 'Volume complementar para o tronco',
          muscles: <String>[
            'Peito',
            'Costas',
            'Ombros',
            'Peito',
            'Costas',
            'Bíceps',
            'Tríceps',
          ],
        ),
        _RoutineTemplate(
          name: 'Inferior',
          focus: 'Volume complementar para pernas e core',
          muscles: <String>[
            'Pernas',
            'Pernas',
            'Pernas',
            'Panturrilha',
            'Abdômen',
          ],
        ),
      ],
    };
  }

  List<_RoutineTemplate> _cardioTemplates(int days) {
    return List<_RoutineTemplate>.generate(
      days,
      (index) => _RoutineTemplate(
        name: 'Cardio ${String.fromCharCode(65 + index)}',
        focus: index.isEven
            ? 'Ritmo contínuo e confortável'
            : 'Ritmo moderado com progressão gradual',
        muscles: const <String>[],
      ),
    );
  }

  int _exerciseLimit(WorkoutGenerationRequest request) {
    final base = switch (request.sessionDurationMinutes) {
      <= 30 => 4,
      <= 45 => 5,
      <= 60 => 6,
      _ => 7,
    };

    if (request.planType == GeneratedPlanType.mixed) {
      return base > 4 ? base - 1 : base;
    }

    return base;
  }

  List<String> _prioritizedMuscles(
    List<String> original,
    Set<String> priorities,
    int limit,
  ) {
    final muscles = List<String>.from(original);

    for (final priority in priorities.toList()..sort()) {
      final existingIndex = muscles.indexOf(priority);
      if (existingIndex >= 0) {
        final value = muscles.removeAt(existingIndex);
        muscles.insert(muscles.length >= 3 ? 3 : muscles.length, value);
      } else if (muscles.isNotEmpty) {
        muscles.insert(muscles.length >= 3 ? 3 : muscles.length, priority);
      }
    }

    return muscles.take(limit).toList(growable: false);
  }

  Exercise? _pickExercise({
    required String muscle,
    required TrainingEnvironment environment,
    required Set<String> avoidedIds,
    required Set<String> alreadyUsedIds,
    required Map<String, int> rotations,
  }) {
    final candidates = _candidateIds(environment, muscle)
        .where((id) => !avoidedIds.contains(id) && !alreadyUsedIds.contains(id))
        .toList(growable: false);

    if (candidates.isEmpty) {
      return null;
    }

    final rotationKey = '${environment.name}:$muscle';
    final index = rotations[rotationKey] ?? 0;
    rotations[rotationKey] = index + 1;
    final selectedId = candidates[index % candidates.length];

    for (final exercise in exerciseDatabase) {
      if (exercise.id == selectedId) {
        return exercise;
      }
    }
    return null;
  }

  Exercise _prescribe(Exercise exercise, WorkoutGenerationRequest request) {
    final compound = _compoundIds.contains(exercise.id);
    late final String reps;
    late final String rest;

    switch (request.goal) {
      case WorkoutGoal.strength:
        reps = compound ? '4x 4-6' : '3x 8-10';
        rest = compound ? '120 seg' : '90 seg';
        break;
      case WorkoutGoal.hypertrophy:
        reps = switch (request.level) {
          TrainingLevel.beginner => '3x 10-12',
          TrainingLevel.intermediate => compound ? '4x 8-10' : '3x 10-12',
          TrainingLevel.advanced => compound ? '4x 6-10' : '4x 10-12',
        };
        rest = compound ? '90 seg' : '60 seg';
        break;
      case WorkoutGoal.weightLoss:
        reps = request.level == TrainingLevel.beginner
            ? '3x 10-12'
            : '3x 10-15';
        rest = '60 seg';
        break;
      case WorkoutGoal.conditioning:
        reps = request.level == TrainingLevel.advanced ? '4x 8-12' : '3x 10-12';
        rest = '60 seg';
        break;
    }

    return exercise.copyWith(
      reps: reps,
      rest: rest,
      isSuperset: false,
      customNote:
          'Gerado pelo PULSE. Ajuste cargas somente após revisar a ficha.',
    );
  }

  int _cardioMinutes(WorkoutGenerationRequest request) {
    if (request.planType == GeneratedPlanType.cardio) {
      return request.sessionDurationMinutes;
    }

    final base = switch (request.sessionDurationMinutes) {
      <= 30 => 10,
      <= 45 => 12,
      <= 60 => 15,
      _ => 20,
    };

    return switch (request.goal) {
      WorkoutGoal.weightLoss => base + 5,
      WorkoutGoal.conditioning => base + 5,
      _ => base,
    };
  }

  String _cardioNote(WorkoutGenerationRequest request) {
    return switch (request.goal) {
      WorkoutGoal.weightLoss =>
        'Ritmo sustentável. Registre duração e esforço reais, sem estimativa automática de calorias.',
      WorkoutGoal.conditioning =>
        'Mantenha um esforço controlado e registre a percepção de esforço ao terminar.',
      _ => 'Cardio complementar em ritmo confortável após a musculação.',
    };
  }

  Set<String> _allowedIds(TrainingEnvironment environment) {
    return _environmentCandidates[environment]!.values
        .expand((ids) => ids)
        .toSet();
  }

  List<String> _candidateIds(TrainingEnvironment environment, String muscle) {
    return _environmentCandidates[environment]![muscle] ?? const <String>[];
  }

  static const Set<String> _compoundIds = <String>{
    'p1',
    'p2',
    'p3',
    'p4',
    'p5',
    'p6',
    'p12',
    'c1',
    'c2',
    'c3',
    'c4',
    'c5',
    'c6',
    'c7',
    'c8',
    'o1',
    'o2',
    'o3',
    'pe1',
    'pe2',
    'pe3',
    'pe4',
    'pe5',
    'pe10',
    'pe11',
    'pe12',
    'pe15',
    'pe19',
    'tr8',
    'tr9',
  };

  static const Map<TrainingEnvironment, Map<String, List<String>>>
  _environmentCandidates = <TrainingEnvironment, Map<String, List<String>>>{
    TrainingEnvironment.fullGym: <String, List<String>>{
      'Peito': <String>['p12', 'p4', 'p5', 'p9', 'p1', 'p10'],
      'Costas': <String>['c1', 'c5', 'c6', 'c7', 'c3', 'c9'],
      'Ombros': <String>['o3', 'o4', 'o5', 'o1', 'o8'],
      'Trapézio': <String>['t1', 't2'],
      'Bíceps': <String>['b1', 'b3', 'b4', 'b6', 'b2'],
      'Antebraço': <String>['b7', 'b8'],
      'Tríceps': <String>['tr1', 'tr2', 'tr5', 'tr4', 'tr9'],
      'Pernas': <String>['pe4', 'pe6', 'pe7', 'pe10', 'pe12', 'pe15', 'pe3'],
      'Panturrilha': <String>['pe17', 'pe18', 'pe16'],
      'Abdômen': <String>['ab3', 'ab4', 'ab5', 'ab1'],
    },
    TrainingEnvironment.machinesAndCables: <String, List<String>>{
      'Peito': <String>['p12', 'p5', 'p9', 'p10', 'p11'],
      'Costas': <String>['c1', 'c2', 'c5', 'c6', 'c9', 'c10'],
      'Ombros': <String>['o3', 'o5', 'o9'],
      'Trapézio': <String>['t2'],
      'Bíceps': <String>['b4', 'b6'],
      'Antebraço': <String>['b7'],
      'Tríceps': <String>['tr1', 'tr2', 'tr4', 'tr6', 'tr7'],
      'Pernas': <String>[
        'pe3',
        'pe4',
        'pe5',
        'pe6',
        'pe7',
        'pe8',
        'pe13',
        'pe14',
      ],
      'Panturrilha': <String>['pe17', 'pe18'],
      'Abdômen': <String>['ab3', 'ab4'],
    },
    TrainingEnvironment.freeWeights: <String, List<String>>{
      'Peito': <String>['p1', 'p2', 'p3', 'p4', 'p7', 'p8'],
      'Costas': <String>['c3', 'c7', 'c8'],
      'Ombros': <String>['o1', 'o2', 'o4', 'o6', 'o8'],
      'Trapézio': <String>['t1'],
      'Bíceps': <String>['b1', 'b2', 'b3', 'b5'],
      'Antebraço': <String>['b7', 'b8'],
      'Tríceps': <String>['tr3', 'tr5', 'tr8', 'tr9'],
      'Pernas': <String>['pe1', 'pe10', 'pe11', 'pe12', 'pe15', 'pe19'],
      'Panturrilha': <String>['pe16'],
      'Abdômen': <String>['ab1', 'ab2', 'ab5', 'ab6'],
    },
  };
}

class _RoutineTemplate {
  const _RoutineTemplate({
    required this.name,
    required this.focus,
    required this.muscles,
  });

  final String name;
  final String focus;
  final List<String> muscles;
}
