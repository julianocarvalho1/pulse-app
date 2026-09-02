import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/exercises/domain/exercise_catalog.dart';
import 'package:pulse/features/workouts/data/services/workout_feedback_service.dart';
import 'package:pulse/features/workouts/domain/models/active_workout_session.dart';
import 'package:pulse/features/workouts/domain/models/exercise_log.dart';
import 'package:pulse/features/workouts/domain/models/workout_history_item.dart';
import 'package:pulse/features/workouts/domain/repositories/workout_repository.dart';
import 'package:pulse/features/workouts/presentation/providers/workout_controller.dart';
import 'package:pulse/models/exercise.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _catalogSnapshotPath =
    'test/fixtures/exercises/exercise_catalog_v4.snapshot';
const _previousCatalogSnapshotPath =
    'test/fixtures/exercises/exercise_catalog_v3.snapshot';
const _legacyStateFixturePath =
    'test/fixtures/exercises/legacy_workout_state_v1.json';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'settings_voice_after_rest': false,
    });
  });

  group('contrato do catálogo v4', () {
    late _CatalogSnapshot snapshot;

    setUpAll(() {
      snapshot = _CatalogSnapshot.read(_catalogSnapshotPath);
    });

    test('congela as identidades e os nomes de mídia oficiais', () {
      final actualEntries = exerciseDatabase
          .map((exercise) {
            final definition = ExerciseCatalog.definitionFor(exercise);
            expect(
              definition,
              isNotNull,
              reason:
                  'O exercício ${exercise.id} precisa de definição canônica.',
            );

            return <String>[
              exercise.id,
              exercise.name,
              exercise.muscle,
              definition!.mediaAssetId,
            ].join('|');
          })
          .toList(growable: false);

      expect(ExerciseCatalog.version, snapshot.catalogVersion);
      expect(exerciseDatabase, hasLength(snapshot.exerciseCount));
      expect(actualEntries, snapshot.entries);
      expect(_fnv1a32(actualEntries.join('\n')), snapshot.identityHash);
    });

    test(
      'detecta alteração silenciosa em prescrições ou arquivos de mídia',
      () {
        final contentSnapshot = exerciseDatabase
            .map(
              (exercise) => jsonEncode(<String, Object?>{
                ...exercise.toMap(),
                'mediaAssetId': ExerciseCatalog.definitionFor(
                  exercise,
                )!.mediaAssetId,
              }),
            )
            .join('\n');
        final mediaSnapshot = exerciseDatabase
            .map(
              (exercise) =>
                  '${exercise.id}|${ExerciseCatalog.mediaPathFor(exercise)}',
            )
            .join('\n');

        expect(_fnv1a32(contentSnapshot), snapshot.contentHash);
        expect(_fnv1a32(mediaSnapshot), snapshot.mediaHash);
      },
    );

    test('mantém IDs, mídias e distribuição muscular sem duplicidades', () {
      final ids = exerciseDatabase.map((exercise) => exercise.id).toSet();
      final mediaPaths = exerciseDatabase
          .map(ExerciseCatalog.mediaPathFor)
          .toSet();
      final muscleCounts = <String, int>{};

      for (final exercise in exerciseDatabase) {
        muscleCounts.update(
          exercise.muscle,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }

      expect(ids, hasLength(snapshot.exerciseCount));
      expect(mediaPaths, hasLength(snapshot.exerciseCount));
      expect(muscleCounts, <String, int>{
        'Abdômen': 13,
        'Antebraço': 2,
        'Bíceps': 6,
        'Costas': 13,
        'Ombros': 14,
        'Panturrilha': 4,
        'Peito': 14,
        'Pernas': 25,
        'Trapézio': 2,
        'Tríceps': 11,
      });
    });

    test('mantém todos os IDs e nomes do catálogo v3 resolvíveis', () {
      final previousSnapshot = _CatalogSnapshot.read(
        _previousCatalogSnapshotPath,
      );
      final currentIds = exerciseDatabase
          .map((exercise) => exercise.id)
          .toSet();

      expect(previousSnapshot.catalogVersion, 3);
      expect(previousSnapshot.exerciseCount, 101);

      for (final entry in previousSnapshot.entries) {
        final fields = entry.split('|');
        final previousId = fields[0];
        final previousName = fields[1];

        expect(currentIds, contains(previousId));
        expect(
          ExerciseCatalog.canonicalIdFor('', exerciseName: previousName),
          previousId,
          reason:
              'O nome legado "$previousName" precisa resolver para $previousId.',
        );
      }
    });
  });

  test(
    'migra fixture de ficha, histórico e sessão sem perder dados do usuário',
    () async {
      final fixture = _readJsonMap(_legacyStateFixturePath);
      expect(fixture['schemaVersion'], 1);

      final customExercises = _readMapList(
        fixture['customExercises'],
      ).map(Exercise.fromMap).toList(growable: false);
      final routines = _readMapList(
        fixture['routines'],
      ).map(WorkoutRoutine.fromMap).toList(growable: false);
      final history = _readMapList(
        fixture['history'],
      ).map(WorkoutHistoryItem.fromMap).toList(growable: false);
      final activeSession = ActiveWorkoutSession.fromMap(
        Map<String, dynamic>.from(fixture['activeSession']! as Map),
      );
      final repository = _FixtureWorkoutRepository(
        customExercises: customExercises,
        routines: routines,
        history: history,
        activeSession: activeSession,
      );
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(repository),
          workoutFeedbackServiceProvider.overrideWithValue(
            _SilentWorkoutFeedbackService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(workoutBootstrapControllerProvider.future);

      final library = container.read(workoutLibraryControllerProvider);
      final migratedHistory = container
          .read(workoutHistoryControllerProvider)
          .items
          .single;
      final migratedSession = container
          .read(workoutSessionControllerProvider)
          .activeSession!;
      final migratedExercises = library.routines.single.exercises;

      expect(
        library.customExercises.single.toMap(),
        customExercises.single.toMap(),
      );
      expect(migratedExercises, hasLength(3));
      _expectCanonicalExercise(
        migratedExercises[0],
        source: routines.single.exercises[0],
        expectedId: 'p12',
        expectedName: 'Supino Reto Articulado',
      );
      _expectCanonicalExercise(
        migratedExercises[1],
        source: routines.single.exercises[1],
        expectedId: 'p9',
        expectedName: 'Voador Peitoral na Máquina',
      );
      expect(
        migratedExercises[2].toMap(),
        routines.single.exercises[2].toMap(),
      );

      expect(
        migratedHistory.exercises
            .map((log) => '${log.exerciseId}|${log.exerciseName}')
            .toList(),
        <String>[
          'p12|Supino Reto Articulado',
          'p9|Voador Peitoral na Máquina',
          'custom_fixture_1|Remada adaptada sentada',
        ],
      );
      expect(
        migratedHistory.exercises.map((log) => log.sets).toList(),
        history.single.exercises.map((log) => log.sets).toList(),
      );
      expect(migratedHistory.notes, history.single.notes);
      expect(migratedHistory.duration, history.single.duration);

      _expectCanonicalExercise(
        migratedSession.exercises[0].exercise,
        source: activeSession.exercises[0].exercise,
        expectedId: 'p9',
        expectedName: 'Voador Peitoral na Máquina',
      );
      expect(
        migratedSession.exercises[0].sets.map((set) => set.toMap()).toList(),
        activeSession.exercises[0].sets.map((set) => set.toMap()).toList(),
      );
      expect(
        migratedSession.exercises[1].toMap(),
        activeSession.exercises[1].toMap(),
      );
      expect(migratedSession.notes, activeSession.notes);

      expect(repository.saveRoutinesCalls, 1);
      expect(repository.saveHistoryCalls, 1);
      expect(repository.saveActiveSessionCalls, 1);
      expect(repository.saveCustomExercisesCalls, 0);
      expect(
        repository.routines.single.toMap(),
        library.routines.single.toMap(),
      );
      expect(repository.history.single.toMap(), migratedHistory.toMap());
      expect(
        repository.activeSession!.exercises
            .map((item) => item.toMap())
            .toList(),
        migratedSession.exercises.map((item) => item.toMap()).toList(),
      );
    },
  );
}

void _expectCanonicalExercise(
  Exercise actual, {
  required Exercise source,
  required String expectedId,
  required String expectedName,
}) {
  expect(actual.id, expectedId);
  expect(actual.name, expectedName);
  expect(actual.muscle, source.muscle);
  expect(actual.description, source.description);
  expect(actual.reps, source.reps);
  expect(actual.rest, source.rest);
  expect(actual.isSuperset, source.isSuperset);
  expect(actual.customNote, source.customNote);
  expect(actual.advancedPrescription, source.advancedPrescription);
}

Map<String, dynamic> _readJsonMap(String path) {
  return Map<String, dynamic>.from(
    jsonDecode(File(path).readAsStringSync())! as Map,
  );
}

List<Map<String, dynamic>> _readMapList(Object? value) {
  return (value! as List)
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList(growable: false);
}

String _fnv1a32(String value) {
  var hash = 0x811c9dc5;

  for (final byte in utf8.encode(value)) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xffffffff;
  }

  return hash.toRadixString(16).padLeft(8, '0');
}

class _CatalogSnapshot {
  const _CatalogSnapshot({
    required this.catalogVersion,
    required this.exerciseCount,
    required this.identityHash,
    required this.contentHash,
    required this.mediaHash,
    required this.entries,
  });

  factory _CatalogSnapshot.read(String path) {
    final lines = File(path).readAsLinesSync();
    final separatorIndex = lines.indexOf('---');
    expect(separatorIndex, greaterThan(0));

    final metadata = <String, String>{
      for (final line in lines.take(separatorIndex))
        line.substring(0, line.indexOf('=')): line.substring(
          line.indexOf('=') + 1,
        ),
    };

    return _CatalogSnapshot(
      catalogVersion: int.parse(metadata['catalog_version']!),
      exerciseCount: int.parse(metadata['exercise_count']!),
      identityHash: metadata['identity_hash']!,
      contentHash: metadata['content_hash']!,
      mediaHash: metadata['media_hash']!,
      entries: lines.skip(separatorIndex + 1).toList(growable: false),
    );
  }

  final int catalogVersion;
  final int exerciseCount;
  final String identityHash;
  final String contentHash;
  final String mediaHash;
  final List<String> entries;
}

class _SilentWorkoutFeedbackService implements WorkoutFeedbackService {
  @override
  Future<void> configure() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<void> playRestFinished({required bool enabled}) async {}
}

class _FixtureWorkoutRepository implements WorkoutRepository {
  _FixtureWorkoutRepository({
    required List<Exercise> customExercises,
    required List<WorkoutRoutine> routines,
    required List<WorkoutHistoryItem> history,
    required this.activeSession,
  }) : customExercises = List<Exercise>.from(customExercises),
       routines = List<WorkoutRoutine>.from(routines),
       history = List<WorkoutHistoryItem>.from(history);

  List<Exercise> customExercises;
  List<WorkoutRoutine> routines;
  List<WorkoutHistoryItem> history;
  ActiveWorkoutSession? activeSession;
  String activeProgramName = 'ABC legado';

  int saveCustomExercisesCalls = 0;
  int saveRoutinesCalls = 0;
  int saveHistoryCalls = 0;
  int saveActiveSessionCalls = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<List<Exercise>> loadCustomExercises() async =>
      List<Exercise>.from(customExercises);

  @override
  Future<List<WorkoutRoutine>> loadRoutines() async =>
      List<WorkoutRoutine>.from(routines);

  @override
  Future<List<WorkoutHistoryItem>> loadHistory() async =>
      List<WorkoutHistoryItem>.from(history);

  @override
  Future<String> loadActiveProgramName() async => activeProgramName;

  @override
  Future<ActiveWorkoutSession?> loadActiveSession() async => activeSession;

  @override
  Future<void> saveCustomExercises(List<Exercise> exercises) async {
    saveCustomExercisesCalls++;
    customExercises = List<Exercise>.from(exercises);
  }

  @override
  Future<void> saveRoutines(List<WorkoutRoutine> routines) async {
    saveRoutinesCalls++;
    this.routines = List<WorkoutRoutine>.from(routines);
  }

  @override
  Future<void> saveHistory(List<WorkoutHistoryItem> history) async {
    saveHistoryCalls++;
    this.history = List<WorkoutHistoryItem>.from(history);
  }

  @override
  Future<void> saveActiveProgramName(String programName) async {
    activeProgramName = programName;
  }

  @override
  Future<void> saveCompletedWorkout({
    required String routineName,
    required String duration,
    required List<ExerciseLog> exercises,
    required String notes,
    required bool isIncomplete,
  }) async {}

  @override
  Future<void> finalizeWorkout(WorkoutHistoryItem item) async {
    history = <WorkoutHistoryItem>[item];
    activeSession = null;
  }

  @override
  Future<void> saveActiveSession(ActiveWorkoutSession session) async {
    saveActiveSessionCalls++;
    activeSession = session;
  }

  @override
  Future<void> clearActiveSession() async {
    activeSession = null;
  }

  @override
  Future<void> clearAll() async {
    customExercises = <Exercise>[];
    routines = <WorkoutRoutine>[];
    history = <WorkoutHistoryItem>[];
    activeSession = null;
    activeProgramName = '';
  }
}
