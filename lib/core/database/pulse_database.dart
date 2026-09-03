import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class PulseDatabase {
  factory PulseDatabase({
    DatabaseFactory? databaseFactoryOverride,
    String? databasePathOverride,
  }) {
    return PulseDatabase._(databaseFactoryOverride, databasePathOverride);
  }

  PulseDatabase._(this._databaseFactoryOverride, this._databasePathOverride);

  static const String databaseName = 'pulse.db';
  static const int databaseVersion = 12;

  final DatabaseFactory? _databaseFactoryOverride;
  final String? _databasePathOverride;

  Database? _database;

  DatabaseFactory get _factory => _databaseFactoryOverride ?? databaseFactory;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null && existing.isOpen) {
      return existing;
    }

    final databasePath =
        _databasePathOverride ??
        path.join(await getDatabasesPath(), databaseName);

    _database = await _factory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: databaseVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _createSchema,
        onUpgrade: _upgradeSchema,
      ),
    );

    return _database!;
  }

  Future<void> close() async {
    final existing = _database;
    _database = null;

    if (existing != null && existing.isOpen) {
      await existing.close();
    }
  }

  Future<void> deleteDatabaseFile() async {
    await close();

    final databasePath =
        _databasePathOverride ??
        path.join(await getDatabasesPath(), databaseName);

    await _factory.deleteDatabase(databasePath);
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE app_metadata (
        key TEXT PRIMARY KEY NOT NULL,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE custom_exercises (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        muscle TEXT NOT NULL,
        description TEXT NOT NULL,
        reps TEXT NOT NULL,
        rest TEXT NOT NULL,
        is_superset INTEGER NOT NULL DEFAULT 0,
        custom_note TEXT NOT NULL DEFAULT '',
        advanced_prescription_json TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE routines (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        focus TEXT NOT NULL,
        group_name TEXT NOT NULL DEFAULT '',
        sort_order INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE routine_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        routine_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        name TEXT NOT NULL,
        muscle TEXT NOT NULL,
        description TEXT NOT NULL,
        reps TEXT NOT NULL,
        rest TEXT NOT NULL,
        is_superset INTEGER NOT NULL DEFAULT 0,
        custom_note TEXT NOT NULL DEFAULT '',
        advanced_prescription_json TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (routine_id)
          REFERENCES routines (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX routine_exercises_order_index
      ON routine_exercises (routine_id, sort_order)
    ''');

    await db.execute('''
      CREATE TABLE workout_history (
        id TEXT PRIMARY KEY NOT NULL,
        routine_name TEXT NOT NULL,
        date_ms INTEGER NOT NULL,
        duration TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_history_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        history_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        exercise_name TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        is_load_comparable INTEGER NOT NULL DEFAULT 1,
        perceived_rir INTEGER,
        FOREIGN KEY (history_id)
          REFERENCES workout_history (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX workout_history_exercises_order_index
      ON workout_history_exercises (history_id, sort_order)
    ''');

    await db.execute('''
      CREATE TABLE workout_history_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        history_exercise_id INTEGER NOT NULL,
        set_order INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight REAL NOT NULL,
        set_kind TEXT NOT NULL DEFAULT 'working',
        target_type TEXT NOT NULL DEFAULT 'repetitions',
        planned_duration_seconds INTEGER NOT NULL DEFAULT 0,
        actual_duration_seconds INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (history_exercise_id)
          REFERENCES workout_history_exercises (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX workout_history_sets_order_index
      ON workout_history_sets (history_exercise_id, set_order)
    ''');

    await db.execute('''
      CREATE TABLE active_session (
        id TEXT PRIMARY KEY NOT NULL,
        routine_name TEXT NOT NULL,
        started_at_ms INTEGER NOT NULL,
        elapsed_seconds INTEGER NOT NULL DEFAULT 0,
        notes TEXT NOT NULL DEFAULT '',
        rest_seconds INTEGER NOT NULL DEFAULT 0,
        rest_end_at_ms INTEGER,
        is_rest_paused INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE active_session_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        name TEXT NOT NULL,
        muscle TEXT NOT NULL,
        description TEXT NOT NULL,
        reps TEXT NOT NULL,
        rest TEXT NOT NULL,
        is_superset INTEGER NOT NULL DEFAULT 0,
        custom_note TEXT NOT NULL DEFAULT '',
        advanced_prescription_json TEXT NOT NULL DEFAULT '',
        session_notes TEXT NOT NULL DEFAULT '',
        is_load_comparable INTEGER NOT NULL DEFAULT 1,
        perceived_rir INTEGER,
        FOREIGN KEY (session_id)
          REFERENCES active_session (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX active_session_exercises_order_index
      ON active_session_exercises (session_id, sort_order)
    ''');

    await db.execute('''
      CREATE TABLE active_session_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_exercise_id INTEGER NOT NULL,
        set_order INTEGER NOT NULL,
        weight_text TEXT NOT NULL DEFAULT '',
        reps_text TEXT NOT NULL DEFAULT '',
        is_completed INTEGER NOT NULL DEFAULT 0,
        set_kind TEXT NOT NULL DEFAULT 'working',
        target_text TEXT NOT NULL DEFAULT '',
        target_rir INTEGER,
        cadence TEXT NOT NULL DEFAULT '',
        technique TEXT NOT NULL DEFAULT 'none',
        prescribed_rest_seconds INTEGER,
        prescription_notes TEXT NOT NULL DEFAULT '',
        target_type TEXT NOT NULL DEFAULT 'repetitions',
        planned_duration_seconds INTEGER NOT NULL DEFAULT 0,
        actual_duration_seconds INTEGER NOT NULL DEFAULT 0,
        duration_started_at_ms INTEGER,
        FOREIGN KEY (session_exercise_id)
          REFERENCES active_session_exercises (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX active_session_sets_order_index
      ON active_session_sets (session_exercise_id, set_order)
    ''');

    await _createBodyMeasurementsTable(db);
    await _createWorkoutHistoryCardioTable(db);
    await _createWorkoutHistoryFreeActivitiesTable(db);
    await _createRoutineCardioTable(db);
    await _createActiveSessionCardioTable(db);
  }

  Future<void> _upgradeSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createBodyMeasurementsTable(db);
    }

    if (oldVersion < 3) {
      await _createWorkoutHistoryCardioTable(db);
    }

    if (oldVersion < 4) {
      await _createRoutineCardioTable(db);
      await _createActiveSessionCardioTable(db);
    }

    if (oldVersion < 5) {
      await _addAdvancedPrescriptionColumns(db);
    }

    if (oldVersion < 6) {
      await _createWorkoutHistoryFreeActivitiesTable(db);
    }

    if (oldVersion < 7) {
      await _addActiveSessionRestColumns(db);
    }

    if (oldVersion < 8) {
      await _addExerciseSessionNoteColumns(db);
    }

    if (oldVersion < 9) {
      await _addExercisePerceivedRirColumns(db);
    }

    if (oldVersion < 10) {
      await _addTimedSetColumns(db);
    }

    if (oldVersion < 11) {
      await _addStructuredCardioColumns(db);
    }

    if (oldVersion < 12) {
      await _addSetKindColumns(db);
    }
  }

  Future<void> _addSetKindColumns(DatabaseExecutor db) async {
    for (final table in <String>[
      'active_session_sets',
      'workout_history_sets',
    ]) {
      await _addColumnIfMissing(
        db,
        table: table,
        column: 'set_kind',
        definition: "TEXT NOT NULL DEFAULT 'working'",
      );
    }
  }

  Future<void> _addStructuredCardioColumns(DatabaseExecutor db) async {
    for (final table in <String>[
      'routine_cardio',
      'active_session_cardio',
      'workout_history_cardio',
    ]) {
      if (await _tableExists(db, table)) {
        await _addColumnIfMissing(
          db,
          table: table,
          column: 'plan_json',
          definition: "TEXT NOT NULL DEFAULT ''",
        );
      }
    }
  }

  Future<void> _addTimedSetColumns(DatabaseExecutor db) async {
    await _addColumnIfMissing(
      db,
      table: 'active_session_sets',
      column: 'target_type',
      definition: "TEXT NOT NULL DEFAULT 'repetitions'",
    );
    await _addColumnIfMissing(
      db,
      table: 'active_session_sets',
      column: 'planned_duration_seconds',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(
      db,
      table: 'active_session_sets',
      column: 'actual_duration_seconds',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(
      db,
      table: 'active_session_sets',
      column: 'duration_started_at_ms',
      definition: 'INTEGER',
    );
    await _addColumnIfMissing(
      db,
      table: 'workout_history_sets',
      column: 'target_type',
      definition: "TEXT NOT NULL DEFAULT 'repetitions'",
    );
    await _addColumnIfMissing(
      db,
      table: 'workout_history_sets',
      column: 'planned_duration_seconds',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(
      db,
      table: 'workout_history_sets',
      column: 'actual_duration_seconds',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
  }

  Future<void> _addExercisePerceivedRirColumns(DatabaseExecutor db) async {
    await _addColumnIfMissing(
      db,
      table: 'active_session_exercises',
      column: 'perceived_rir',
      definition: 'INTEGER',
    );
    await _addColumnIfMissing(
      db,
      table: 'workout_history_exercises',
      column: 'perceived_rir',
      definition: 'INTEGER',
    );
  }

  Future<void> _addExerciseSessionNoteColumns(DatabaseExecutor db) async {
    await _addColumnIfMissing(
      db,
      table: 'active_session_exercises',
      column: 'session_notes',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
    await _addColumnIfMissing(
      db,
      table: 'active_session_exercises',
      column: 'is_load_comparable',
      definition: 'INTEGER NOT NULL DEFAULT 1',
    );
    await _addColumnIfMissing(
      db,
      table: 'workout_history_exercises',
      column: 'notes',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
    await _addColumnIfMissing(
      db,
      table: 'workout_history_exercises',
      column: 'is_load_comparable',
      definition: 'INTEGER NOT NULL DEFAULT 1',
    );
  }

  Future<void> _addActiveSessionRestColumns(DatabaseExecutor db) async {
    await _addColumnIfMissing(
      db,
      table: 'active_session',
      column: 'rest_seconds',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(
      db,
      table: 'active_session',
      column: 'rest_end_at_ms',
      definition: 'INTEGER',
    );
    await _addColumnIfMissing(
      db,
      table: 'active_session',
      column: 'is_rest_paused',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
  }

  Future<void> _addAdvancedPrescriptionColumns(DatabaseExecutor db) async {
    await _addColumnIfMissing(
      db,
      table: 'custom_exercises',
      column: 'advanced_prescription_json',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
    await _addColumnIfMissing(
      db,
      table: 'routine_exercises',
      column: 'advanced_prescription_json',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
    await _addColumnIfMissing(
      db,
      table: 'active_session_exercises',
      column: 'advanced_prescription_json',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
    await _addColumnIfMissing(
      db,
      table: 'active_session_sets',
      column: 'target_text',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
    await _addColumnIfMissing(
      db,
      table: 'active_session_sets',
      column: 'target_rir',
      definition: 'INTEGER',
    );
    await _addColumnIfMissing(
      db,
      table: 'active_session_sets',
      column: 'cadence',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
    await _addColumnIfMissing(
      db,
      table: 'active_session_sets',
      column: 'technique',
      definition: "TEXT NOT NULL DEFAULT 'none'",
    );
    await _addColumnIfMissing(
      db,
      table: 'active_session_sets',
      column: 'prescribed_rest_seconds',
      definition: 'INTEGER',
    );
    await _addColumnIfMissing(
      db,
      table: 'active_session_sets',
      column: 'prescription_notes',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
  }

  Future<void> _addColumnIfMissing(
    DatabaseExecutor db, {
    required String table,
    required String column,
    required String definition,
  }) async {
    if (!await _tableExists(db, table)) {
      return;
    }

    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final alreadyExists = columns.any(
      (row) => row['name']?.toString() == column,
    );
    if (alreadyExists) {
      return;
    }

    await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
  }

  Future<bool> _tableExists(DatabaseExecutor db, String table) async {
    final rows = await db.rawQuery(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ? LIMIT 1",
      <Object?>[table],
    );
    return rows.isNotEmpty;
  }

  Future<void> _createRoutineCardioTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS routine_cardio (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        routine_id TEXT NOT NULL,
        cardio_id TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        modality TEXT NOT NULL,
        planned_duration_minutes INTEGER NOT NULL,
        plan_json TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (routine_id)
          REFERENCES routines (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS routine_cardio_order_index
      ON routine_cardio (routine_id, sort_order)
    ''');
  }

  Future<void> _createActiveSessionCardioTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS active_session_cardio (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        cardio_id TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        modality TEXT NOT NULL,
        planned_duration_minutes INTEGER NOT NULL,
        plan_json TEXT NOT NULL DEFAULT '',
        actual_duration_minutes INTEGER NOT NULL DEFAULT 0,
        distance_km REAL,
        average_speed_kmh REAL,
        incline_percent REAL,
        resistance_level REAL,
        perceived_effort INTEGER,
        average_heart_rate_bpm INTEGER,
        notes TEXT NOT NULL DEFAULT '',
        is_completed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (session_id)
          REFERENCES active_session (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS active_session_cardio_order_index
      ON active_session_cardio (session_id, sort_order)
    ''');
  }

  Future<void> _createWorkoutHistoryCardioTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workout_history_cardio (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        history_id TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        modality TEXT NOT NULL,
        planned_duration_minutes INTEGER NOT NULL DEFAULT 0,
        plan_json TEXT NOT NULL DEFAULT '',
        actual_duration_minutes INTEGER NOT NULL,
        distance_km REAL,
        average_speed_kmh REAL,
        incline_percent REAL,
        resistance_level REAL,
        perceived_effort INTEGER,
        average_heart_rate_bpm INTEGER,
        notes TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (history_id)
          REFERENCES workout_history (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS workout_history_cardio_order_index
      ON workout_history_cardio (history_id, sort_order)
    ''');
  }

  Future<void> _createWorkoutHistoryFreeActivitiesTable(
    DatabaseExecutor db,
  ) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workout_history_free_activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        history_id TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        activity_type TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        intensity TEXT NOT NULL,
        replaced_planned_workout INTEGER NOT NULL DEFAULT 0,
        custom_name TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (history_id)
          REFERENCES workout_history (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS workout_history_free_activities_order_index
      ON workout_history_free_activities (history_id, sort_order)
    ''');
  }

  Future<void> _createBodyMeasurementsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS body_measurements (
        id TEXT PRIMARY KEY NOT NULL,
        recorded_at_ms INTEGER NOT NULL,
        weight_kg REAL,
        shoulders_cm REAL,
        chest_cm REAL,
        waist_cm REAL,
        hips_cm REAL,
        left_arm_cm REAL,
        right_arm_cm REAL,
        left_forearm_cm REAL,
        right_forearm_cm REAL,
        left_thigh_cm REAL,
        right_thigh_cm REAL,
        left_calf_cm REAL,
        right_calf_cm REAL
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS body_measurements_date_index
      ON body_measurements (recorded_at_ms DESC)
    ''');
  }
}
