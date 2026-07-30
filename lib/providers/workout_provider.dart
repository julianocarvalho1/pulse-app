import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/workouts/data/mappers/legacy_workout_mapper.dart';
import '../features/workouts/data/repositories/workout_repository_impl.dart';
import '../features/workouts/domain/models/active_workout_session.dart';
import '../features/workouts/domain/models/exercise_log.dart';
import '../features/workouts/domain/models/workout_history_item.dart';
import '../features/workouts/domain/models/workout_session_status.dart';
import '../features/workouts/domain/repositories/workout_repository.dart';
import '../models/exercise.dart';

class WorkoutProvider extends ChangeNotifier {
  WorkoutProvider({WorkoutRepository? repository})
    : _repository = repository ?? WorkoutRepositoryImpl() {
    _initPreMadePrograms();
    _initialize();
    _configurarVoz();
  }

  final WorkoutRepository _repository;

  List<Exercise> _customExercises = [];
  List<WorkoutRoutine> _myRoutines = [];
  List<WorkoutHistoryItem> _history = [];
  List<WorkoutProgram> _preMadePrograms = [];

  bool _isInitialized = false;
  bool _vibrateAfterRest = true;
  bool _isWorkoutActive = false;
  List<Exercise> _currentWorkoutExercises = [];
  String _activeRoutineName = 'Treino do Dia';
  String _activeProgramName = '';

  ActiveWorkoutSession? _activeSession;

  final ValueNotifier<int> workoutDuration = ValueNotifier<int>(0);
  Timer? _globalTimer;

  bool _isResting = false;
  int _restSeconds = 0;
  Timer? _restTimer;

  final FlutterTts _flutterTts = FlutterTts();

  bool get isResting => _isResting;
  int get restSeconds => _restSeconds;
  List<Exercise> get allExercises => [...exerciseDatabase, ..._customExercises];
  List<WorkoutRoutine> get myRoutines => _myRoutines;
  List<WorkoutProgram> get preMadePrograms => _preMadePrograms;
  List<WorkoutHistoryItem> get history => _history;
  bool get isInitialized => _isInitialized;
  bool get isWorkoutActive => _isWorkoutActive;
  List<Exercise> get currentWorkoutExercises => _currentWorkoutExercises;
  String get activeRoutineName => _activeRoutineName;
  String get activeProgramName => _activeProgramName;
  ActiveWorkoutSession? get activeSession => _activeSession;

  Future<void> _initialize() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      _vibrateAfterRest =
          preferences.getBool('settings_vibrate_after_rest') ?? true;

      await _repository.initialize();

      _customExercises = await _repository.loadCustomExercises();
      _myRoutines = await _repository.loadRoutines();
      _history = await _repository.loadHistory();
      _activeProgramName = await _repository.loadActiveProgramName();

      _activeSession = await _repository.loadActiveSession();

      final restoredSession = _activeSession;
      if (restoredSession != null) {
        _isWorkoutActive = true;
        _activeRoutineName = restoredSession.routineName;
        _currentWorkoutExercises = restoredSession.exercises
            .map((activeExercise) => activeExercise.exercise)
            .toList();

        _startGlobalTimer(initialSeconds: restoredSession.elapsedSeconds);
      }
    } catch (error, stackTrace) {
      debugPrint('Erro ao inicializar o WorkoutProvider: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _configurarVoz() async {
    await _flutterTts.setLanguage('pt-BR');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
  }

  void setActiveProgram(String programName) {
    _activeProgramName = programName;
    _persist(
      () => _repository.saveActiveProgramName(programName),
      'salvar programa ativo',
    );
    notifyListeners();
  }

  WorkoutRoutine? get nextRoutineToTrain {
    if (_activeProgramName.isEmpty) {
      return null;
    }

    final programRoutines = _myRoutines
        .where((routine) => routine.groupName == _activeProgramName)
        .toList();

    if (programRoutines.isEmpty) {
      return null;
    }

    programRoutines.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    WorkoutHistoryItem? lastProgramWorkout;

    for (final session in _history) {
      if (programRoutines.any(
        (routine) => routine.name == session.routineName,
      )) {
        lastProgramWorkout = session;
        break;
      }
    }

    if (lastProgramWorkout == null) {
      return programRoutines.first;
    }

    final lastIndex = programRoutines.indexWhere(
      (routine) => routine.name == lastProgramWorkout!.routineName,
    );

    if (lastIndex == -1) {
      return programRoutines.first;
    }

    final nextIndex = (lastIndex + 1) % programRoutines.length;
    return programRoutines[nextIndex];
  }

  void startRestTimer(String restString) {
    if (restString.trim().isEmpty) {
      return;
    }

    final seconds = LegacyWorkoutMapper.parseRestSeconds(restString);

    if (seconds <= 0) {
      return;
    }

    _isResting = true;
    _restSeconds = seconds;
    _restTimer?.cancel();

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSeconds > 0) {
        _restSeconds--;
        notifyListeners();
        return;
      }

      stopRestTimer();
      _playAlarm();
    });

    notifyListeners();
  }

  void stopRestTimer() {
    _restTimer?.cancel();
    _isResting = false;
    _restSeconds = 0;
    notifyListeners();
  }

  Future<void> _playAlarm() async {
    try {
      await _flutterTts.speak('Descanso finalizado. Bora pra cima!');
    } catch (error) {
      debugPrint('Erro na voz: $error');
    }

    if (!_vibrateAfterRest) {
      return;
    }

    for (var index = 0; index < 4; index++) {
      Future.delayed(
        Duration(milliseconds: index * 600),
        HapticFeedback.heavyImpact,
      );
    }
  }

  void _initPreMadePrograms() {
    _preMadePrograms = [
      WorkoutProgram(
        id: 'prog_hipertrofia_abc',
        name: 'Hipertrofia Moderna (ABC)',
        focus: 'Divisão clássica para volume e densidade.',
        routines: [
          WorkoutRoutine(
            id: 'rout_hip_A',
            name: 'Treino A - Peito, Ombro e Tríceps',
            focus: 'Foco em empurrar (Push)',
            groupName: 'Hipertrofia Moderna (ABC)',
            exercises: [
              Exercise(
                id: 'ex_pm_1',
                name: 'Chest Press',
                muscle: 'Peito',
                description: 'Controle bem a descida.',
                reps: '4x 8-12',
                rest: '60 seg',
                customNote: '',
              ),
              Exercise(
                id: 'ex_pm_2',
                name: 'Crucifixo com Halteres',
                muscle: 'Peito',
                description: 'Foque no alongamento do músculo.',
                reps: '3x 12',
                rest: '45 seg',
                customNote: '',
              ),
              Exercise(
                id: 'ex_pm_3',
                name: 'Desenvolvimento Militar',
                muscle: 'Ombro',
                description: 'Sente-se com a coluna reta.',
                reps: '4x 10',
                rest: '60 seg',
                customNote: '',
              ),
              Exercise(
                id: 'ex_pm_4',
                name: 'Tríceps na Polia',
                muscle: 'Tríceps',
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
            focus: 'Foco em puxar (Pull)',
            groupName: 'Hipertrofia Moderna (ABC)',
            exercises: [
              Exercise(
                id: 'ex_pm_5',
                name: 'Puxada na Frente',
                muscle: 'Costas',
                description: 'Estufe o peito na puxada.',
                reps: '4x 10',
                rest: '60 seg',
                customNote: '',
              ),
              Exercise(
                id: 'ex_pm_6',
                name: 'Remada Curvada',
                muscle: 'Costas',
                description: 'Mantenha a lombar travada.',
                reps: '4x 8-10',
                rest: '60 seg',
                customNote: '',
              ),
              Exercise(
                id: 'ex_pm_7',
                name: 'Rosca Direta',
                muscle: 'Bíceps',
                description: 'Não balance o tronco.',
                reps: '3x 12',
                rest: '45 seg',
                customNote: '',
              ),
              Exercise(
                id: 'ex_pm_8',
                name: 'Rosca Scott',
                muscle: 'Bíceps',
                description: 'Isole completamente o músculo.',
                reps: '3x 10',
                rest: '45 seg',
                customNote: 'Drop-Set | Na última série',
              ),
            ],
          ),
          WorkoutRoutine(
            id: 'rout_hip_C',
            name: 'Treino C - Pernas e Core',
            focus: 'Membros Inferiores (Legs)',
            groupName: 'Hipertrofia Moderna (ABC)',
            exercises: [
              Exercise(
                id: 'ex_pm_9',
                name: 'Agachamento',
                muscle: 'Pernas',
                description: 'Quebre a paralela se tiver mobilidade.',
                reps: '4x 8-10',
                rest: '90 seg',
                customNote: '',
              ),
              Exercise(
                id: 'ex_pm_10',
                name: 'Leg Press',
                muscle: 'Pernas',
                description: 'Não trave o joelho em cima.',
                reps: '4x 12',
                rest: '60 seg',
                customNote: '',
              ),
              Exercise(
                id: 'ex_pm_11',
                name: 'Cadeira Extensora',
                muscle: 'Pernas',
                description: 'Aperte no topo por 1 segundo.',
                reps: '3x 15',
                rest: '45 seg',
                customNote: 'Falha Muscular',
              ),
              Exercise(
                id: 'ex_pm_12',
                name: 'Crunch Abdominal',
                muscle: 'Core',
                description: 'Foque em dobrar o tronco.',
                reps: '4x 15-20',
                rest: '45 seg',
                customNote: '',
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
              Exercise(
                id: 'ex_pm_13',
                name: 'Chest Press',
                muscle: 'Peito',
                description: 'Sem pausa.',
                reps: '3x 15',
                rest: '0 seg',
                isSuperset: true,
                customNote: '',
              ),
              Exercise(
                id: 'ex_pm_14',
                name: 'Remada Baixa',
                muscle: 'Costas',
                description: 'Direto do Chest Press.',
                reps: '3x 15',
                rest: '45 seg',
                customNote: '',
              ),
              Exercise(
                id: 'ex_pm_15',
                name: 'Elevação Frontal com Barra',
                muscle: 'Ombro',
                description: 'Movimento controlado.',
                reps: '3x 15',
                rest: '30 seg',
                customNote: '',
              ),
            ],
          ),
          WorkoutRoutine(
            id: 'rout_seca_B',
            name: 'Treino B - Inferiores Express',
            focus: 'Gasto Calórico',
            groupName: 'Seca Tudo (Projeto Verão)',
            exercises: [
              Exercise(
                id: 'ex_pm_16',
                name: 'Passada / Afundo',
                muscle: 'Pernas',
                description: 'Passos largos.',
                reps: '4x 20',
                rest: '45 seg',
                customNote: '10 cada perna',
              ),
              Exercise(
                id: 'ex_pm_17',
                name: 'Cadeira Extensora',
                muscle: 'Pernas',
                description: 'Explosivo.',
                reps: '3x 15',
                rest: '0 seg',
                isSuperset: true,
                customNote: '',
              ),
              Exercise(
                id: 'ex_pm_18',
                name: 'Crunch Abdominal',
                muscle: 'Core',
                description: 'Até queimar.',
                reps: '3x 20',
                rest: '45 seg',
                customNote: '',
              ),
            ],
          ),
        ],
      ),
    ];
  }

  void setVibrateAfterRest(bool enabled) {
    _vibrateAfterRest = enabled;
  }

  void createCustomExercise(String name, String muscle) {
    _customExercises.add(
      Exercise(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        muscle: muscle,
        description: 'Exercicio personalizado.',
        reps: '3x 10-12',
        rest: '60 seg',
      ),
    );

    _persist(
      () => _repository.saveCustomExercises(_customExercises),
      'salvar exercício personalizado',
    );

    notifyListeners();
  }

  void createRoutine(
    String name,
    String focus,
    String groupName,
    List<Exercise> exercises,
  ) {
    final uniqueId =
        '${DateTime.now().millisecondsSinceEpoch}_${name.hashCode}_${exercises.length}';

    _myRoutines.add(
      WorkoutRoutine(
        id: uniqueId,
        name: name,
        focus: focus,
        groupName: groupName,
        exercises: exercises,
      ),
    );

    if (_activeProgramName.isEmpty && groupName.isNotEmpty) {
      _activeProgramName = groupName;

      _persist(
        () => _repository.saveActiveProgramName(_activeProgramName),
        'salvar programa ativo',
      );
    }

    _saveRoutines();
    notifyListeners();
  }

  void updateRoutine(
    String id,
    String newName,
    String newFocus,
    String newGroupName,
    List<Exercise> newExercises,
  ) {
    final index = _myRoutines.indexWhere((routine) => routine.id == id);

    if (index < 0) {
      return;
    }

    _myRoutines[index] = _myRoutines[index].copyWith(
      name: newName,
      focus: newFocus,
      groupName: newGroupName,
      exercises: newExercises,
    );

    _saveRoutines();
    notifyListeners();
  }

  void deleteRoutine(String id) {
    _myRoutines.removeWhere((routine) => routine.id == id);

    _saveRoutines();
    notifyListeners();
  }

  void importProgram(WorkoutProgram program) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    for (var index = 0; index < program.routines.length; index++) {
      final routine = program.routines[index];

      _myRoutines.add(
        WorkoutRoutine(
          id: '${timestamp + index}_${routine.id}',
          name: routine.name,
          focus: routine.focus,
          groupName: program.name,
          exercises: List<Exercise>.from(routine.exercises),
        ),
      );
    }

    _activeProgramName = program.name;
    _saveRoutines();

    _persist(
      () => _repository.saveActiveProgramName(_activeProgramName),
      'salvar programa importado',
    );

    notifyListeners();
  }

  void importRoutine(WorkoutRoutine routine) {
    _myRoutines.add(
      WorkoutRoutine(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: routine.name,
        focus: routine.focus,
        groupName: '',
        exercises: List<Exercise>.from(routine.exercises),
      ),
    );

    _saveRoutines();
    notifyListeners();
  }

  void _saveToHistory(
    String routineName,
    String duration,
    List<ExerciseLog> exercises,
    String notes, {
    required WorkoutSessionStatus status,
  }) {
    _history.insert(
      0,
      WorkoutHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        routineName: routineName.isEmpty ? 'Treino Avulso' : routineName,
        date: DateTime.now(),
        duration: duration,
        exercises: exercises,
        notes: notes,
        status: status,
      ),
    );

    _persist(() => _repository.saveHistory(_history), 'salvar histórico');

    notifyListeners();
  }

  void deleteHistoryItem(String id) {
    _history.removeWhere((item) => item.id == id);

    _persist(
      () => _repository.saveHistory(_history),
      'excluir item do histórico',
    );

    notifyListeners();
  }

  void startWorkout() {
    _beginWorkout(routineName: 'Treino Livre', exercises: const <Exercise>[]);
  }

  void startRoutine(WorkoutRoutine routine) {
    _beginWorkout(routineName: routine.name, exercises: routine.exercises);
  }

  void _beginWorkout({
    required String routineName,
    required List<Exercise> exercises,
  }) {
    _isWorkoutActive = true;
    _activeRoutineName = routineName;
    _currentWorkoutExercises = List<Exercise>.from(exercises);

    final startedAt = DateTime.now();

    _activeSession = ActiveWorkoutSession(
      id: 'active',
      routineName: routineName,
      startedAt: startedAt,
      elapsedSeconds: 0,
      exercises: _buildActiveExercises(_currentWorkoutExercises),
    );

    _startGlobalTimer();

    _persistActiveSession();
    notifyListeners();
  }

  void _startGlobalTimer({int initialSeconds = 0}) {
    workoutDuration.value = initialSeconds;
    _globalTimer?.cancel();

    _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      workoutDuration.value++;

      if (workoutDuration.value % 10 == 0) {
        final session = _activeSession;

        if (session != null) {
          _activeSession = session.copyWith(
            elapsedSeconds: workoutDuration.value,
          );

          _persistActiveSession();
        }
      }
    });
  }

  void addExerciseToWorkout(Exercise exercise) {
    _currentWorkoutExercises.add(exercise);

    final session = _activeSession;
    if (session != null) {
      _activeSession = session.copyWith(
        exercises: [...session.exercises, _buildActiveExercise(exercise)],
      );

      _persistActiveSession();
    }

    notifyListeners();
  }

  void saveActiveSessionProgress({
    required Map<int, List<bool>> setsStatus,
    required Map<int, List<String>> weights,
    required Map<int, List<String>> reps,
    required String notes,
  }) {
    final session = _activeSession;

    if (session == null) {
      return;
    }

    final updatedExercises = <ActiveWorkoutExercise>[];

    for (
      var exerciseIndex = 0;
      exerciseIndex < _currentWorkoutExercises.length;
      exerciseIndex++
    ) {
      final exercise = _currentWorkoutExercises[exerciseIndex];
      final completedValues = setsStatus[exerciseIndex] ?? const <bool>[];
      final weightValues = weights[exerciseIndex] ?? const <String>[];
      final repsValues = reps[exerciseIndex] ?? const <String>[];

      final expectedCount = [
        completedValues.length,
        weightValues.length,
        repsValues.length,
        LegacyWorkoutMapper.parseExerciseConfig(
          reps: exercise.reps,
          rest: exercise.rest,
        ).seriesCount,
      ].reduce((a, b) => a > b ? a : b);

      final activeSets = List<ActiveWorkoutSet>.generate(
        expectedCount,
        (setIndex) => ActiveWorkoutSet(
          setNumber: setIndex + 1,
          weightText: setIndex < weightValues.length
              ? weightValues[setIndex]
              : '',
          repsText: setIndex < repsValues.length ? repsValues[setIndex] : '',
          isCompleted: setIndex < completedValues.length
              ? completedValues[setIndex]
              : false,
        ),
      );

      updatedExercises.add(
        ActiveWorkoutExercise(exercise: exercise, sets: activeSets),
      );
    }

    _activeSession = session.copyWith(
      elapsedSeconds: workoutDuration.value,
      notes: notes,
      exercises: updatedExercises,
    );

    _persistActiveSession();
  }

  void finishWorkout(
    String duration, {
    required bool isIncomplete,
    required List<ExerciseLog> logs,
    String notes = '',
  }) {
    if (logs.isNotEmpty) {
      _saveToHistory(
        _activeRoutineName,
        duration,
        logs,
        notes,
        status: isIncomplete
            ? WorkoutSessionStatus.incomplete
            : WorkoutSessionStatus.completed,
      );
    }

    _endActiveWorkout();
  }

  void cancelWorkout() {
    _endActiveWorkout();
  }

  void _endActiveWorkout() {
    _isWorkoutActive = false;
    _currentWorkoutExercises = [];
    _activeSession = null;
    _globalTimer?.cancel();
    workoutDuration.value = 0;

    _persist(_repository.clearActiveSession, 'limpar sessão ativa');

    stopRestTimer();
    notifyListeners();
  }

  Future<void> factoryReset() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.clear();
    await _repository.clearAll();

    _myRoutines.clear();
    _history.clear();
    _customExercises.clear();
    _activeProgramName = '';
    _vibrateAfterRest = true;
    _isWorkoutActive = false;
    _currentWorkoutExercises = [];
    _activeSession = null;

    _globalTimer?.cancel();
    workoutDuration.value = 0;
    _restTimer?.cancel();
    _isResting = false;
    _restSeconds = 0;

    notifyListeners();
  }

  List<ActiveWorkoutExercise> _buildActiveExercises(List<Exercise> exercises) {
    return exercises.map(_buildActiveExercise).toList();
  }

  ActiveWorkoutExercise _buildActiveExercise(Exercise exercise) {
    final config = LegacyWorkoutMapper.parseExerciseConfig(
      reps: exercise.reps,
      rest: exercise.rest,
    );

    return ActiveWorkoutExercise(
      exercise: exercise,
      sets: List<ActiveWorkoutSet>.generate(
        config.seriesCount,
        (index) => ActiveWorkoutSet(setNumber: index + 1),
      ),
    );
  }

  void _saveRoutines() {
    _persist(() => _repository.saveRoutines(_myRoutines), 'salvar fichas');
  }

  void _persistActiveSession() {
    final session = _activeSession;

    if (session == null) {
      return;
    }

    _persist(
      () => _repository.saveActiveSession(session),
      'salvar sessão ativa',
    );
  }

  void _persist(Future<void> Function() operation, String label) {
    unawaited(
      (() async {
        try {
          await operation();
        } catch (error, stackTrace) {
          debugPrint('Erro ao $label: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      })(),
    );
  }

  @override
  void dispose() {
    _globalTimer?.cancel();
    _restTimer?.cancel();
    workoutDuration.dispose();
    _flutterTts.stop();
    super.dispose();
  }
}
