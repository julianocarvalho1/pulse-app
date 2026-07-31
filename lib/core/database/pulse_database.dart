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
  static const int databaseVersion = 4;

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
        notes TEXT NOT NULL DEFAULT ''
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
