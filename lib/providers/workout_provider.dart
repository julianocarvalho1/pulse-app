import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  ExerciseLog({required this.exerciseId, required this.exerciseName, required this.sets});
  Map<String, dynamic> toMap() => {
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'sets': sets.map((e) => e.toMap()).toList(),
  };
  factory ExerciseLog.fromMap(Map<String, dynamic> map) => ExerciseLog(
    exerciseId: map['exerciseId'] ?? '',
    exerciseName: map['exerciseName'] ?? '',
    sets: map['sets'] != null ? List<ExerciseSet>.from(map['sets'].map((x) => ExerciseSet.fromMap(x))) : [],
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
    this.notes = ''
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
      exercises: map['exercises'] != null ? List<ExerciseLog>.from(map['exercises'].map((x) => ExerciseLog.fromMap(x))) : [],
      notes: map['notes'] ?? '',
    );
  }
}

class WorkoutProvider extends ChangeNotifier {
  List<Exercise> _customExercises = [];
  List<WorkoutRoutine> _myRoutines = [];
  List<WorkoutHistoryItem> _history = [];
  List<WorkoutProgram> _preMadePrograms = [];

  String _userName = '';
  String _userPassword = '';
  double _userWeight = 0.0; // NOVO: Guarda o peso corporal do usuário
  bool _isAuthenticated = false;

  bool _usarBiometria = false;
  bool get usarBiometria => _usarBiometria;

  bool _isWorkoutActive = false;
  List<Exercise> _currentWorkoutExercises = [];
  String _activeRoutineName = 'Treino do Dia';

  String _activeProgramName = '';
  final ValueNotifier<int> workoutDuration = ValueNotifier<int>(0);
  Timer? _globalTimer;

  bool _isResting = false;
  int _restSeconds = 0;
  Timer? _restTimer;

  bool get isResting => _isResting;
  int get restSeconds => _restSeconds;

  WorkoutProvider() {
    _initPreMadePrograms();
    _loadData();
  }

  List<Exercise> get allExercises => [...exerciseDatabase, ..._customExercises];
  List<WorkoutRoutine> get myRoutines => _myRoutines;
  List<WorkoutProgram> get preMadePrograms => _preMadePrograms;
  List<WorkoutHistoryItem> get history => _history;
  String get userName => _userName;
  double get userWeight => _userWeight;
  bool get hasPassword => _userPassword.isNotEmpty;
  bool get isAuthenticated => _isAuthenticated;
  bool get isWorkoutActive => _isWorkoutActive;
  List<Exercise> get currentWorkoutExercises => _currentWorkoutExercises;
  String get activeRoutineName => _activeRoutineName;
  String get activeProgramName => _activeProgramName;

  void setActiveProgram(String programName) {
    _activeProgramName = programName;
    _saveData();
    notifyListeners();
  }

  void setUserWeight(double weight) {
    _userWeight = weight;
    _saveData();
    notifyListeners();
  }

  WorkoutRoutine? get nextRoutineToTrain {
    if (_activeProgramName.isEmpty) return null;
    final programRoutines = _myRoutines.where((r) => r.groupName == _activeProgramName).toList();
    if (programRoutines.isEmpty) return null;
    programRoutines.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    WorkoutHistoryItem? lastProgramWorkout;
    for (var session in _history) {
      if (programRoutines.any((r) => r.name == session.routineName)) {
        lastProgramWorkout = session;
        break;
      }
    }

    if (lastProgramWorkout == null) return programRoutines.first;

    int lastIndex = programRoutines.indexWhere((r) => r.name == lastProgramWorkout!.routineName);
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

  void _playAlarm() {
    for (int i = 0; i < 6; i++) {
      Future.delayed(Duration(milliseconds: i * 350), () {
        HapticFeedback.vibrate();
        SystemSound.play(SystemSoundType.alert);
      });
    }
  }

  void _initPreMadePrograms() {
    _preMadePrograms = [
      WorkoutProgram(id: 'prog_hipertrofia', name: 'Hipertrofia Extrema (ABCD)', focus: 'Foco total em volume muscular.', routines: []),
      WorkoutProgram(id: 'prog_forca', name: 'Força e Base (Powerbuilding)', focus: 'Aumento de carga nos compostos.', routines: []),
      WorkoutProgram(id: 'prog_emagrecimento', name: 'Seca Tudo (Emagrecimento)', focus: 'Alta intensidade e pausas curtas.', routines: []),
      WorkoutProgram(id: 'prog_terapeutico', name: 'Saúde Articular (Terapêutico)', focus: 'Fortalecer tendões e postura.', routines: []),
    ];
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name') ?? '';
    _userPassword = prefs.getString('user_password') ?? '';
    _userWeight = prefs.getDouble('user_weight') ?? 0.0;
    _activeProgramName = prefs.getString('active_program') ?? '';
    _usarBiometria = prefs.getBool('usarBiometria') ?? false;

    final customExStr = prefs.getString('custom_exercises');
    if (customExStr != null) {
      final List decoded = jsonDecode(customExStr);
      _customExercises = decoded.map((e) => Exercise.fromMap(e)).toList();
    }

    final routinesStr = prefs.getString('my_routines');
    if (routinesStr != null && routinesStr != '[]') {
      final List decoded = jsonDecode(routinesStr);
      _myRoutines = decoded.map((e) => WorkoutRoutine.fromMap(e)).toList();
    }

    final historyStr = prefs.getString('workout_history');
    if (historyStr != null) {
      final List decoded = jsonDecode(historyStr);
      _history = decoded.map((e) => WorkoutHistoryItem.fromMap(e)).toList();
    }
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _userName);
    await prefs.setString('user_password', _userPassword);
    await prefs.setDouble('user_weight', _userWeight);
    await prefs.setString('active_program', _activeProgramName);
    await prefs.setString('custom_exercises', jsonEncode(_customExercises.map((e) => e.toMap()).toList()));
    await prefs.setString('my_routines', jsonEncode(_myRoutines.map((e) => e.toMap()).toList()));
    await prefs.setString('workout_history', jsonEncode(_history.map((e) => e.toMap()).toList()));
  }

  void registerUser(String name, String password) {
    _userName = name.trim().isEmpty ? 'Atleta' : name.trim();
    _userPassword = password.trim();
    _isAuthenticated = true;
    _saveData();
    notifyListeners();
  }

  void setUserName(String name) {
    _userName = name.trim().isEmpty ? 'Atleta' : name.trim();
    _saveData();
    notifyListeners();
  }

  bool login(String password) {
    if (_userPassword == password.trim() && _userPassword.isNotEmpty) {
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }

  void createCustomExercise(String name, String muscle) {
    _customExercises.add(Exercise(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}', name: name, muscle: muscle, description: 'Exercicio personalizado.', reps: '3x 10-12', rest: '60 seg'
    ));
    _saveData();
    notifyListeners();
  }

  void createRoutine(String name, String focus, String groupName, List<Exercise> exercises) {
    String uniqueId = '${DateTime.now().millisecondsSinceEpoch}_${name.hashCode}_${exercises.length}';
    _myRoutines.add(WorkoutRoutine(id: uniqueId, name: name, focus: focus, groupName: groupName, exercises: exercises));
    if (_activeProgramName.isEmpty && groupName.isNotEmpty) _activeProgramName = groupName;
    _saveData();
    notifyListeners();
  }

  void updateRoutine(String id, String newName, String newFocus, String newGroupName, List<Exercise> newExercises) {
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
      _myRoutines.add(WorkoutRoutine(
        id: DateTime.now().millisecondsSinceEpoch.toString() + routine.id,
        name: routine.name, focus: routine.focus, groupName: program.name, exercises: List.from(routine.exercises),
      ));
    }
    _activeProgramName = program.name;
    _saveData();
    notifyListeners();
  }

  void importRoutine(WorkoutRoutine routine) {
    _myRoutines.add(WorkoutRoutine(
        id: DateTime.now().millisecondsSinceEpoch.toString(), name: routine.name, focus: routine.focus, groupName: '', exercises: List.from(routine.exercises)
    ));
    _saveData();
    notifyListeners();
  }

  void _saveToHistory(String routineName, String duration, List<ExerciseLog> exercises, String notes) {
    _history.insert(0, WorkoutHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      routineName: routineName.isEmpty ? 'Treino Avulso' : routineName,
      date: DateTime.now(),
      duration: duration,
      exercises: exercises,
      notes: notes,
    ));
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
    _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) { workoutDuration.value++; });
  }

  void addExerciseToWorkout(Exercise exercise) {
    _currentWorkoutExercises.add(exercise);
    notifyListeners();
  }

  void finishWorkout(String duration, {required bool isIncomplete, required List<ExerciseLog> logs, String notes = ''}) {
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

    _userName = '';
    _userPassword = '';
    _userWeight = 0.0;
    _isAuthenticated = false;
    _usarBiometria = false;
    _activeProgramName = '';

    if (_isWorkoutActive) cancelWorkout();
    notifyListeners();
  }

  Future<void> toggleBiometria(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('usarBiometria', value);
    _usarBiometria = value;
    notifyListeners();
  }
}