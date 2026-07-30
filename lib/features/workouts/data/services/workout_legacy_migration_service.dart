import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../models/exercise.dart';
import '../../domain/models/workout_history_item.dart';
import 'workout_local_service.dart';

class WorkoutLegacyMigrationService {
  WorkoutLegacyMigrationService({required WorkoutLocalService localService})
    : _localService = localService;

  static const String _migrationKey = 'workout_sqlite_migration_v1_completed';

  static const String _customExercisesKey = 'custom_exercises';
  static const String _routinesKey = 'my_routines';
  static const String _historyKey = 'workout_history';
  static const String _activeProgramKey = 'active_program';

  final WorkoutLocalService _localService;

  Future<void> migrateIfNeeded() async {
    final preferences = await SharedPreferences.getInstance();

    if (preferences.getBool(_migrationKey) == true) {
      return;
    }

    try {
      final databaseHasData = await _localService.hasWorkoutData();

      if (!databaseHasData) {
        final customExercises = _decodeList(
          preferences.getString(_customExercisesKey),
          Exercise.fromMap,
        );

        final routines = _decodeList(
          preferences.getString(_routinesKey),
          WorkoutRoutine.fromMap,
        );

        final history = _decodeList(
          preferences.getString(_historyKey),
          WorkoutHistoryItem.fromMap,
        );

        final activeProgram = preferences.getString(_activeProgramKey) ?? '';

        if (customExercises.isNotEmpty) {
          await _localService.saveCustomExercises(customExercises);
        }

        if (routines.isNotEmpty) {
          await _localService.saveRoutines(routines);
        }

        if (history.isNotEmpty) {
          await _localService.saveHistory(history);
        }

        if (activeProgram.isNotEmpty) {
          await _localService.saveActiveProgramName(activeProgram);
        }
      }

      await preferences.setBool(_migrationKey, true);

      await preferences.remove(_customExercisesKey);
      await preferences.remove(_routinesKey);
      await preferences.remove(_historyKey);
      await preferences.remove(_activeProgramKey);
    } catch (error, stackTrace) {
      debugPrint('Falha ao migrar dados de treino para SQLite: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  List<T> _decodeList<T>(
    String? encoded,
    T Function(Map<String, dynamic>) fromMap,
  ) {
    if (encoded == null || encoded.trim().isEmpty || encoded.trim() == '[]') {
      return <T>[];
    }

    try {
      final decoded = jsonDecode(encoded);

      if (decoded is! List) {
        return <T>[];
      }

      return decoded
          .whereType<Map>()
          .map((item) => fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (error, stackTrace) {
      debugPrint('Não foi possível ler um bloco legado de treino: $error');
      debugPrintStack(stackTrace: stackTrace);
      return <T>[];
    }
  }
}
