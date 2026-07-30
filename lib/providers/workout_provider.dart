import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart'; // NOVO IMPORT DA VOZ
import '../models/exercise.dart';

class ExerciseSet {
  int reps;
  double weight;
  ExerciseSet({required this.reps, required this.weight});
  Map<String, dynamic> toMap() => {'reps': reps, 'weight': weight};
  factory ExerciseSet.fromMap(Map<String, dynamic> map) => ExerciseSet(
    reps: map['reps'] ?? 0,
    weight: (map['weight'] ?? 0).toDouble(),
  );
}

class ExerciseLog {
  final String exerciseId;
  final String exerciseName;
  final List<ExerciseSet> sets;
  ExerciseLog({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
  });
  Map<String, dynamic> toMap() => {
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'sets': sets.map((e) => e.toMap()).toList(),
  };
  factory ExerciseLog.fromMap(Map<String, dynamic> map) => ExerciseLog(
    exerciseId: map['exerciseId'] ?? '',
    exerciseName: map['exerciseName'] ?? '',
    sets: map['sets'] != null
        ? List<ExerciseSet>.from(map['sets'].map((x) => ExerciseSet.fromMap(x)))
        : [],
  );
}

class WorkoutHistoryItem {
  final String id;
  final String routineName;
  final DateTime date;
  final String duration;
  final List<ExerciseLog> exercises;
  final String notes;

  WorkoutHistoryItem({
    required this.id,
    required this.routineName,
    required this.date,
    required this.duration,
    required this.exercises,
    this.notes = '',
  });

  int get totalExercises => exercises.length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routineName': routineName,
      'date': date.toIso8601String(),
      'duration': duration,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'notes': notes,
    };
  }

  factory WorkoutHistoryItem.fromMap(Map<String, dynamic> map) {
    return WorkoutHistoryItem(
      id: map['id'] ?? '',
      routineName: map['routineName'] ?? '',
      date: DateTime.parse(map['date']),
      duration: map['duration'] ?? '',
      exercises: map['exercises'] != null
          ? List<ExerciseLog>.from(
              map['exercises'].map((x) => ExerciseLog.fromMap(x)),
            )
          : [],
      notes: map['notes'] ?? '',
    );
  }
}

class WorkoutProvider extends ChangeNotifier {
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
  final ValueNotifier<int> workoutDuration = ValueNotifier<int>(0);
  Timer? _globalTimer;

  bool _isResting = false;
  int _restSeconds = 0;
  Timer? _restTimer;

  // Instância do motor de voz
  final FlutterTts _flutterTts = FlutterTts();

  bool get isResting => _isResting;
  int get restSeconds => _restSeconds;

  WorkoutProvider() {
    _initPreMadePrograms();
    _initialize();
    _configurarVoz();
  }
  Future<void> _initialize() async {
    try {
      await _loadData();
    } catch (error, stackTrace) {
      debugPrint('Erro ao inicializar o WorkoutProvider: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _configurarVoz() async {
    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setSpeechRate(0.5); // Velocidade normal da voz
    await _flutterTts.setVolume(1.0);
  }

  List<Exercise> get allExercises => [...exerciseDatabase, ..._customExercises];
  List<WorkoutRoutine> get myRoutines => _myRoutines;
  List<WorkoutProgram> get preMadePrograms => _preMadePrograms;
  List<WorkoutHistoryItem> get history => _history;
  bool get isInitialized => _isInitialized;
  bool get isWorkoutActive => _isWorkoutActive;
  List<Exercise> get currentWorkoutExercises => _currentWorkoutExercises;
  String get activeRoutineName => _activeRoutineName;
  String get activeProgramName => _activeProgramName;

  void setActiveProgram(String programName) {
    _activeProgramName = programName;
    _saveData();
    notifyListeners();
  }

  WorkoutRoutine? get nextRoutineToTrain {
    if (_activeProgramName.isEmpty) return null;
    final programRoutines = _myRoutines
        .where((r) => r.groupName == _activeProgramName)
        .toList();
    if (programRoutines.isEmpty) return null;
    programRoutines.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    WorkoutHistoryItem? lastProgramWorkout;
    for (var session in _history) {
      if (programRoutines.any((r) => r.name == session.routineName)) {
        lastProgramWorkout = session;
        break;
      }
    }

    if (lastProgramWorkout == null) return programRoutines.first;

    int lastIndex = programRoutines.indexWhere(
      (r) => r.name == lastProgramWorkout!.routineName,
    );
    if (lastIndex == -1) return programRoutines.first;

    int nextIndex = (lastIndex + 1) % programRoutines.length;
    return programRoutines[nextIndex];
  }

  void startRestTimer(String restString) {
    if (restString.trim().isEmpty) return;
    final text = restString.toLowerCase();
    final match = RegExp(r'\d+').firstMatch(text);
    if (match == null) return;

    int seconds = int.parse(match.group(0)!);
    if (text.contains('min')) seconds *= 60;
    if (seconds <= 0) return;

    _isResting = true;
    _restSeconds = seconds;
    _restTimer?.cancel();

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSeconds > 0) {
        _restSeconds--;
        notifyListeners();
      } else {
        stopRestTimer();
        _playAlarm();
      }
    });
    notifyListeners();
  }

  void stopRestTimer() {
    _restTimer?.cancel();
    _isResting = false;
    _restSeconds = 0;
    notifyListeners();
  }

  // ==========================================================
  // NOVO SISTEMA DE ALARME: INTELIGÊNCIA ARTIFICIAL FALANDO
  // ==========================================================
  Future<void> _playAlarm() async {
    try {
      // Fala a frase em português
      await _flutterTts.speak("Descanso finalizado. Bora pra cima!");
    } catch (e) {
      debugPrint('Erro na voz: $e');
    }

    if (_vibrateAfterRest) {
      for (int i = 0; i < 4; i++) {
        Future.delayed(Duration(milliseconds: i * 600), () {
          HapticFeedback.heavyImpact();
        });
      }
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

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _activeProgramName = prefs.getString('active_program') ?? '';
    _vibrateAfterRest = prefs.getBool('settings_vibrate_after_rest') ?? true;

    try {
      final customExStr = prefs.getString('custom_exercises');
      if (customExStr != null && customExStr.isNotEmpty) {
        final List decoded = jsonDecode(customExStr);
        _customExercises = decoded
            .map((e) => Exercise.fromMap(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Erro ao carregar customExercises: $e');
    }

    try {
      final routinesStr = prefs.getString('my_routines');
      if (routinesStr != null &&
          routinesStr != '[]' &&
          routinesStr.isNotEmpty) {
        final List decoded = jsonDecode(routinesStr);
        _myRoutines = decoded
            .map((e) => WorkoutRoutine.fromMap(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Erro ao carregar myRoutines: $e');
    }

    try {
      final historyStr = prefs.getString('workout_history');
      if (historyStr != null && historyStr.isNotEmpty) {
        final List decoded = jsonDecode(historyStr);
        _history = decoded
            .map((e) => WorkoutHistoryItem.fromMap(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Erro ao carregar workout_history: $e');
    }

    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_program', _activeProgramName);
    await prefs.setString(
      'custom_exercises',
      jsonEncode(_customExercises.map((e) => e.toMap()).toList()),
    );
    await prefs.setString(
      'my_routines',
      jsonEncode(_myRoutines.map((e) => e.toMap()).toList()),
    );
    await prefs.setString(
      'workout_history',
      jsonEncode(_history.map((e) => e.toMap()).toList()),
    );
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
    _saveData();
    notifyListeners();
  }

  void createRoutine(
    String name,
    String focus,
    String groupName,
    List<Exercise> exercises,
  ) {
    String uniqueId =
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
    if (_activeProgramName.isEmpty && groupName.isNotEmpty)
      _activeProgramName = groupName;
    _saveData();
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
    if (index >= 0) {
      _myRoutines[index].name = newName;
      _myRoutines[index].focus = newFocus;
      _myRoutines[index].groupName = newGroupName;
      _myRoutines[index].exercises = List.from(newExercises);
      _saveData();
      notifyListeners();
    }
  }

  void deleteRoutine(String id) {
    _myRoutines.removeWhere((routine) => routine.id == id);
    _saveData();
    notifyListeners();
  }

  void importProgram(WorkoutProgram program) {
    for (var routine in program.routines) {
      _myRoutines.add(
        WorkoutRoutine(
          id: DateTime.now().millisecondsSinceEpoch.toString() + routine.id,
          name: routine.name,
          focus: routine.focus,
          groupName: program.name,
          exercises: List.from(routine.exercises),
        ),
      );
    }
    _activeProgramName = program.name;
    _saveData();
    notifyListeners();
  }

  void importRoutine(WorkoutRoutine routine) {
    _myRoutines.add(
      WorkoutRoutine(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: routine.name,
        focus: routine.focus,
        groupName: '',
        exercises: List.from(routine.exercises),
      ),
    );
    _saveData();
    notifyListeners();
  }

  void _saveToHistory(
    String routineName,
    String duration,
    List<ExerciseLog> exercises,
    String notes,
  ) {
    _history.insert(
      0,
      WorkoutHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        routineName: routineName.isEmpty ? 'Treino Avulso' : routineName,
        date: DateTime.now(),
        duration: duration,
        exercises: exercises,
        notes: notes,
      ),
    );
    _saveData();
    notifyListeners();
  }

  void deleteHistoryItem(String id) {
    _history.removeWhere((item) => item.id == id);
    _saveData();
    notifyListeners();
  }

  void startWorkout() {
    _isWorkoutActive = true;
    _activeRoutineName = 'Treino Livre';
    _currentWorkoutExercises = [];
    _startGlobalTimer();
    notifyListeners();
  }

  void startRoutine(WorkoutRoutine routine) {
    _isWorkoutActive = true;
    _activeRoutineName = routine.name;
    _currentWorkoutExercises = List.from(routine.exercises);
    _startGlobalTimer();
    notifyListeners();
  }

  void _startGlobalTimer() {
    workoutDuration.value = 0;
    _globalTimer?.cancel();
    _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      workoutDuration.value++;
    });
  }

  void addExerciseToWorkout(Exercise exercise) {
    _currentWorkoutExercises.add(exercise);
    notifyListeners();
  }

  void finishWorkout(
    String duration, {
    required bool isIncomplete,
    required List<ExerciseLog> logs,
    String notes = '',
  }) {
    if (logs.isNotEmpty) {
      _saveToHistory(_activeRoutineName, duration, logs, notes);
    }
    _isWorkoutActive = false;
    _currentWorkoutExercises = [];
    _globalTimer?.cancel();
    stopRestTimer();
    notifyListeners();
  }

  void cancelWorkout() {
    _isWorkoutActive = false;
    _currentWorkoutExercises = [];
    _globalTimer?.cancel();
    stopRestTimer();
    notifyListeners();
  }

  Future<void> factoryReset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _myRoutines.clear();
    _history.clear();
    _customExercises.clear();

    _activeProgramName = '';
    _vibrateAfterRest = true;

    if (_isWorkoutActive) cancelWorkout();
    notifyListeners();
  }
}
