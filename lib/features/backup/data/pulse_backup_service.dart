import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/pulse_database.dart';
import '../domain/pulse_backup.dart';

class PulseBackupService {
  PulseBackupService({
    PulseDatabase? database,
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _database = database ?? PulseDatabase(),
       _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  static const String formatName = 'pulse_backup';
  static const int schemaVersion = 1;
  static const int maxBackupBytes = 20 * 1024 * 1024;

  static const Set<String> _excludedPreferenceKeys = <String>{
    'app_lock_enabled',
    'user_password',
    'usarBiometria',
  };

  static const Set<String> _optionalBackupTables = <String>{
    'workout_history_cardio',
  };

  static const List<String> _exportTableOrder = <String>[
    'app_metadata',
    'custom_exercises',
    'routines',
    'routine_exercises',
    'workout_history',
    'workout_history_exercises',
    'workout_history_sets',
    'workout_history_cardio',
    'active_session',
    'active_session_exercises',
    'active_session_sets',
    'body_measurements',
  ];

  static const List<String> _deleteTableOrder = <String>[
    'active_session_sets',
    'active_session_exercises',
    'active_session',
    'workout_history_sets',
    'workout_history_cardio',
    'workout_history_exercises',
    'workout_history',
    'routine_exercises',
    'routines',
    'custom_exercises',
    'body_measurements',
    'app_metadata',
  ];

  static const Map<String, List<String>> _tableColumns = <String, List<String>>{
    'app_metadata': <String>['key', 'value'],
    'custom_exercises': <String>[
      'id',
      'name',
      'muscle',
      'description',
      'reps',
      'rest',
      'is_superset',
      'custom_note',
      'created_at',
    ],
    'routines': <String>['id', 'name', 'focus', 'group_name', 'sort_order'],
    'routine_exercises': <String>[
      'id',
      'routine_id',
      'exercise_id',
      'sort_order',
      'name',
      'muscle',
      'description',
      'reps',
      'rest',
      'is_superset',
      'custom_note',
    ],
    'workout_history': <String>[
      'id',
      'routine_name',
      'date_ms',
      'duration',
      'notes',
      'status',
    ],
    'workout_history_exercises': <String>[
      'id',
      'history_id',
      'exercise_id',
      'exercise_name',
      'sort_order',
    ],
    'workout_history_sets': <String>[
      'id',
      'history_exercise_id',
      'set_order',
      'reps',
      'weight',
    ],
    'workout_history_cardio': <String>[
      'id',
      'history_id',
      'sort_order',
      'modality',
      'planned_duration_minutes',
      'actual_duration_minutes',
      'distance_km',
      'average_speed_kmh',
      'incline_percent',
      'resistance_level',
      'perceived_effort',
      'average_heart_rate_bpm',
      'notes',
    ],
    'active_session': <String>[
      'id',
      'routine_name',
      'started_at_ms',
      'elapsed_seconds',
      'notes',
    ],
    'active_session_exercises': <String>[
      'id',
      'session_id',
      'exercise_id',
      'sort_order',
      'name',
      'muscle',
      'description',
      'reps',
      'rest',
      'is_superset',
      'custom_note',
    ],
    'active_session_sets': <String>[
      'id',
      'session_exercise_id',
      'set_order',
      'weight_text',
      'reps_text',
      'is_completed',
    ],
    'body_measurements': <String>[
      'id',
      'recorded_at_ms',
      'weight_kg',
      'shoulders_cm',
      'chest_cm',
      'waist_cm',
      'hips_cm',
      'left_arm_cm',
      'right_arm_cm',
      'left_forearm_cm',
      'right_forearm_cm',
      'left_thigh_cm',
      'right_thigh_cm',
      'left_calf_cm',
      'right_calf_cm',
    ],
  };

  static const Map<String, List<String>> _requiredColumns =
      <String, List<String>>{
        'app_metadata': <String>['key', 'value'],
        'custom_exercises': <String>['id', 'name'],
        'routines': <String>['id', 'name'],
        'routine_exercises': <String>['routine_id', 'exercise_id'],
        'workout_history': <String>['id', 'routine_name', 'date_ms'],
        'workout_history_exercises': <String>['history_id', 'exercise_id'],
        'workout_history_sets': <String>['history_exercise_id', 'set_order'],
        'workout_history_cardio': <String>[
          'history_id',
          'sort_order',
          'modality',
          'actual_duration_minutes',
        ],
        'active_session': <String>['id', 'routine_name', 'started_at_ms'],
        'active_session_exercises': <String>['session_id', 'exercise_id'],
        'active_session_sets': <String>['session_exercise_id', 'set_order'],
        'body_measurements': <String>['id', 'recorded_at_ms'],
      };

  final PulseDatabase _database;
  final Future<SharedPreferences> Function() _preferencesLoader;

  Future<Uint8List> exportBytes() async {
    final db = await _database.database;
    final preferences = await _preferencesLoader();
    final tables = await db.transaction<Map<String, Object?>>((
      transaction,
    ) async {
      final snapshot = <String, Object?>{};

      for (final table in _exportTableOrder) {
        snapshot[table] = await transaction.query(table);
      }

      return snapshot;
    });

    final document = <String, Object?>{
      'format': formatName,
      'schemaVersion': schemaVersion,
      'databaseVersion': PulseDatabase.databaseVersion,
      'appVersion': '1.0.0',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'tables': tables,
      'preferences': _readPreferences(preferences),
    };

    final json = const JsonEncoder.withIndent('  ').convert(document);
    return Uint8List.fromList(utf8.encode(json));
  }

  PulseBackupPreview inspectBytes(Uint8List bytes) {
    final document = _decodeAndValidate(bytes);
    final tables = document.tables;

    return PulseBackupPreview(
      createdAt: document.createdAt,
      routineCount: tables['routines']!.length,
      workoutCount: tables['workout_history']!.length,
      measurementCount: tables['body_measurements']!.length,
      customExerciseCount: tables['custom_exercises']!.length,
    );
  }

  Future<void> importBytes(Uint8List bytes) async {
    final document = _decodeAndValidate(bytes);
    final preferences = await _preferencesLoader();
    final previousPreferences = _readPreferences(preferences);
    final previousLockEnabled =
        preferences.getBool('app_lock_enabled') ?? false;

    try {
      await _replacePreferences(
        preferences,
        document.preferences,
        disableAppLock: true,
      );

      final db = await _database.database;
      await db.transaction((transaction) async {
        for (final table in _deleteTableOrder) {
          await transaction.delete(table);
        }

        for (final table in _exportTableOrder) {
          for (final row in document.tables[table]!) {
            await transaction.insert(
              table,
              row,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      });
    } catch (error) {
      await _replacePreferences(
        preferences,
        previousPreferences,
        disableAppLock: false,
      );
      await preferences.setBool('app_lock_enabled', previousLockEnabled);
      rethrow;
    }
  }

  _ValidatedBackup _decodeAndValidate(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const PulseBackupException('O arquivo de backup está vazio.');
    }

    if (bytes.length > maxBackupBytes) {
      throw const PulseBackupException(
        'O arquivo é grande demais para ser um backup válido do PULSE.',
      );
    }

    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const PulseBackupException(
        'O arquivo selecionado não contém um JSON válido.',
      );
    }

    if (decoded is! Map) {
      throw const PulseBackupException('Formato de backup inválido.');
    }

    final root = Map<String, Object?>.from(decoded);

    if (root['format'] != formatName) {
      throw const PulseBackupException(
        'Este arquivo não é um backup reconhecido do PULSE.',
      );
    }

    if (root['schemaVersion'] != schemaVersion) {
      throw const PulseBackupException(
        'Esta versão do backup ainda não é compatível com o aplicativo.',
      );
    }

    final createdAtText = root['createdAt']?.toString();
    final createdAt = createdAtText == null
        ? null
        : DateTime.tryParse(createdAtText)?.toLocal();

    if (createdAt == null) {
      throw const PulseBackupException('A data do backup é inválida.');
    }

    final rawTables = root['tables'];
    if (rawTables is! Map) {
      throw const PulseBackupException('As tabelas do backup estão ausentes.');
    }

    final tables = <String, List<Map<String, Object?>>>{};
    for (final table in _exportTableOrder) {
      final rawRows = rawTables[table];
      if (rawRows == null && _optionalBackupTables.contains(table)) {
        tables[table] = <Map<String, Object?>>[];
        continue;
      }
      if (rawRows is! List) {
        throw PulseBackupException(
          'A seção "$table" do backup está ausente ou corrompida.',
        );
      }

      tables[table] = rawRows
          .map((row) => _sanitizeRow(table, row))
          .toList(growable: false);
    }

    final rawPreferences = root['preferences'];
    if (rawPreferences is! Map) {
      throw const PulseBackupException(
        'As preferências do backup estão ausentes.',
      );
    }

    final preferences = <String, Object>{};
    for (final entry in rawPreferences.entries) {
      final key = entry.key.toString();
      if (_excludedPreferenceKeys.contains(key)) {
        continue;
      }

      preferences[key] = _sanitizePreferenceValue(entry.value, key);
    }

    return _ValidatedBackup(
      createdAt: createdAt,
      tables: tables,
      preferences: preferences,
    );
  }

  Map<String, Object?> _sanitizeRow(String table, Object? rawRow) {
    if (rawRow is! Map) {
      throw PulseBackupException(
        'Existe um registro inválido na seção "$table".',
      );
    }

    final source = Map<String, Object?>.from(rawRow);
    final row = <String, Object?>{};

    for (final column in _tableColumns[table]!) {
      if (!source.containsKey(column)) {
        continue;
      }

      row[column] = _sanitizeSqlValue(source[column], '$table.$column');
    }

    for (final requiredColumn in _requiredColumns[table]!) {
      if (!row.containsKey(requiredColumn) || row[requiredColumn] == null) {
        throw PulseBackupException(
          'O campo "$table.$requiredColumn" está ausente no backup.',
        );
      }
    }

    return row;
  }

  Object? _sanitizeSqlValue(Object? value, String field) {
    if (value == null || value is String || value is num) {
      return value;
    }

    if (value is bool) {
      return value ? 1 : 0;
    }

    throw PulseBackupException('O campo "$field" possui um valor inválido.');
  }

  Object _sanitizePreferenceValue(Object? value, String key) {
    if (value is String || value is bool || value is int || value is double) {
      return value as Object;
    }

    if (value is List && value.every((item) => item is String)) {
      return value.cast<String>();
    }

    throw PulseBackupException(
      'A preferência "$key" possui um valor incompatível.',
    );
  }

  Map<String, Object> _readPreferences(SharedPreferences preferences) {
    final values = <String, Object>{};

    for (final key in preferences.getKeys()) {
      if (_excludedPreferenceKeys.contains(key)) {
        continue;
      }

      final value = preferences.get(key);
      if (value is String ||
          value is bool ||
          value is int ||
          value is double ||
          value is List<String>) {
        values[key] = value as Object;
      }
    }

    return values;
  }

  Future<void> _replacePreferences(
    SharedPreferences preferences,
    Map<String, Object> values, {
    required bool disableAppLock,
  }) async {
    await preferences.clear();

    for (final entry in values.entries) {
      final value = entry.value;
      final saved = switch (value) {
        String() => await preferences.setString(entry.key, value),
        bool() => await preferences.setBool(entry.key, value),
        int() => await preferences.setInt(entry.key, value),
        double() => await preferences.setDouble(entry.key, value),
        List<String>() => await preferences.setStringList(entry.key, value),
        _ => false,
      };

      if (!saved) {
        throw PulseBackupException(
          'Não foi possível restaurar a preferência "${entry.key}".',
        );
      }
    }

    if (disableAppLock) {
      // A proteção local depende das credenciais do aparelho atual e nunca é
      // reativada automaticamente por um arquivo de backup.
      await preferences.setBool('app_lock_enabled', false);
    }
  }
}

class _ValidatedBackup {
  const _ValidatedBackup({
    required this.createdAt,
    required this.tables,
    required this.preferences,
  });

  final DateTime createdAt;
  final Map<String, List<Map<String, Object?>>> tables;
  final Map<String, Object> preferences;
}
