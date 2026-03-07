/// Integration tests for the SQLite persistence layer.
///
/// These tests verify:
/// 1) The database schema is created correctly (tables, indexes, constraints).
/// 2) Repository APIs support full insert → read “round-trip” workflows.
/// 3) All DateTime values are stored and mapped deterministically in UTC.
///
/// Each test uses a fresh temporary database to avoid shared state.
import 'package:air_traffic_sim/persistence/database.dart';
import 'dart:io';

import 'package:air_traffic_sim/persistence/models/scenario_record.dart';
import 'package:air_traffic_sim/persistence/repositories/sqlite/sqlite_persistence_store.dart';
import 'package:air_traffic_sim/simulation/concretes/simulation_stats.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  group('SQLite persistence test suite', () {
    late _PersistenceTestHarness harness;

    setUp(() {
      harness = _PersistenceTestHarness.create();
    });

    tearDown(() {
      harness.dispose();
    });

    // Ensures schema bootstrap creates all required tables, indexes,
    // uniqueness constraints, and enforces foreign key behavior.
    test('schema bootstrap creates expected tables, constraints, indexes and FK behavior', () {
      final db = harness.provider.database;

      final tables = db
          .select("SELECT name FROM sqlite_master WHERE type = 'table'")
          .map((row) => row['name'] as String)
          .toSet();

      expect(tables, containsAll(<String>{
        'scenarios',
        'runs',
        'events',
        'aircraft_logs',
        'metrics_summaries',
      }));

      final runsIndexes = _indexNames(db, 'runs');
      final eventsIndexes = _indexNames(db, 'events');
      final logsIndexes = _indexNames(db, 'aircraft_logs');

      expect(runsIndexes, contains('idx_runs_scenario_started'));
      expect(eventsIndexes, contains('idx_events_run_time'));
      expect(logsIndexes, contains('idx_aircraft_logs_run_aircraft'));

      final metricsUniqueRunId = _hasUniqueIndexOnColumns(
        db,
        table: 'metrics_summaries',
        columns: const ['run_id'],
      );
      expect(metricsUniqueRunId, isTrue);

      final metricsColumns = harness.provider.database
          .select('PRAGMA table_info(metrics_summaries)')
          .map((row) => row['name'] as String)
          .toSet();
      expect(metricsColumns, isNot(contains('scenario_id')));

      expect(
        () => db.execute(
          'INSERT INTO runs (scenario_id, started_at, status) VALUES (?, ?, ?)',
          ['missing-scenario', DateTime.now().toUtc().toIso8601String(), 'running'],
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    // Simulates a full simulation lifecycle and verifies all repositories
    // correctly persist and retrieve domain data.
    test('repositories support scenario/run/event/log/metrics round-trips', () async {
      final scenarioA = ScenarioRecord(
        id: 'scenario-A',
        name: 'Scenario A',
        description: 'primary scenario',
        createdAt: DateTime.utc(2026, 1, 1, 12),
      );
      final scenarioB = ScenarioRecord(
        id: 'scenario-B',
        name: 'Scenario B',
        description: null,
        createdAt: DateTime.utc(2026, 1, 2, 12),
      );

      await harness.scenarioRepository.upsertScenario(scenarioA);
      await harness.scenarioRepository.upsertScenario(scenarioB);

      final updatedScenarioA = ScenarioRecord(
        id: scenarioA.id,
        name: 'Scenario A Updated',
        description: 'updated description',
        createdAt: DateTime.utc(2026, 1, 3, 12),
      );
      await harness.scenarioRepository.upsertScenario(updatedScenarioA);

      final fetchedScenario = await harness.scenarioRepository.getScenarioById(scenarioA.id);
      expect(fetchedScenario, isNotNull);
      expect(fetchedScenario!.name, updatedScenarioA.name);
      expect(fetchedScenario.description, updatedScenarioA.description);

      final listedScenarios = await harness.scenarioRepository.listScenarios();
      expect(listedScenarios.map((s) => s.id), ['scenario-A', 'scenario-B']);

      late int runId;
      late int scenarioBRunId;
      await harness.runRepository.inTransaction((transaction) async {
        runId = await harness.runRepository.createRun(
          transaction: transaction,
          scenarioId: scenarioA.id,
          startedAt: DateTime.utc(2026, 1, 3, 12, 5),
        );

        await harness.eventRepository.appendEvent(
          transaction: transaction,
          runId: runId,
          eventType: 'AIRCRAFT_LANDED',
          payload: '{"aircraftId":"A-1"}',
          occurredAt: DateTime.utc(2026, 1, 3, 12, 6),
        );

        await harness.logRepository.appendLog(
          transaction: transaction,
          runId: runId,
          aircraftId: 'A-1',
          message: 'Touchdown complete',
          recordedAt: DateTime.utc(2026, 1, 3, 12, 7),
        );

        await harness.metricsRepository.insertSummary(
          transaction: transaction,
          runId: runId,
          stats: const SimulationStats(
            averageLandingDelay: 1.5,
            averageDepartureDelay: 1.5,
            maxLandingDelay: 1.5,
            maxDepartureDelay: 1.5,
            maxInboundQueue: 2,
            maxOutboundQueue: 3,
            totalCancellations: 0,
            totalDiversions: 1,
            totalAircrafts: 4,
          ),
          createdAt: DateTime.utc(2026, 1, 3, 12, 8),
        );

        await harness.runRepository.finalizeRun(
          transaction: transaction,
          runId: runId,
          completedAt: DateTime.utc(2026, 1, 3, 12, 9),
          status: 'completed',
        );

        scenarioBRunId = await harness.runRepository.createRun(
          transaction: transaction,
          scenarioId: scenarioB.id,
          startedAt: DateTime.utc(2026, 1, 3, 13, 5),
        );

        await harness.metricsRepository.insertSummary(
          transaction: transaction,
          runId: scenarioBRunId,
          stats: const SimulationStats(
            averageLandingDelay: 9.5,
            averageDepartureDelay: 9.5,
            maxLandingDelay: 9.5,
            maxDepartureDelay: 9.5,
            maxInboundQueue: 8,
            maxOutboundQueue: 7,
            totalCancellations: 6,
            totalDiversions: 5,
            totalAircrafts: 4,
          ),
          createdAt: DateTime.utc(2026, 1, 3, 13, 8),
        );
      });

      final runs = await harness.runRepository.listRunsByScenario(scenarioA.id);
      expect(runs, hasLength(1));
      expect(runs.single.id, runId);
      expect(runs.single.status, 'completed');

      final events = await harness.eventRepository.listEventsByRun(runId);
      expect(events, hasLength(1));
      expect(events.single.eventType, 'AIRCRAFT_LANDED');

      final logs = await harness.logRepository.listLogsByRun(runId);
      expect(logs, hasLength(1));
      expect(logs.single.aircraftId, 'A-1');

      final summaryByRun = await harness.metricsRepository.getSummaryByRun(runId);
      expect(summaryByRun, isNotNull);
      expect(summaryByRun!.scenarioId, scenarioA.id);
      expect(summaryByRun.stats.averageLandingDelay, 1.5);
      expect(summaryByRun.stats.averageDepartureDelay, 1.5);
      expect(summaryByRun.stats.maxLandingDelay, 1.5);
      expect(summaryByRun.stats.maxDepartureDelay, 1.5);

      final summariesByScenario = await harness.metricsRepository.listSummariesByScenario(scenarioA.id);
      expect(summariesByScenario, hasLength(1));
      expect(summariesByScenario.single.runId, runId);

      final scenarioBSummaries = await harness.metricsRepository.listSummariesByScenario(scenarioB.id);
      expect(scenarioBSummaries, hasLength(1));
      expect(scenarioBSummaries.single.runId, scenarioBRunId);
      expect(scenarioBSummaries.single.scenarioId, scenarioB.id);
    });

    // Verifies that all DateTime values are stored as UTC ISO-8601 strings
    // and map back to identical UTC DateTime objects.
    test('date values are stored as UTC ISO strings and map back deterministically', () async {
      final sourceDate = DateTime.utc(2027, 3, 14, 9, 26, 53);
      final scenario = ScenarioRecord(
        id: 'scenario-time',
        name: 'Date Scenario',
        description: 'date checks',
        createdAt: sourceDate,
      );

      await harness.scenarioRepository.upsertScenario(scenario);

      final storedScenarioCreatedAt = harness.provider.database
          .select('SELECT created_at FROM scenarios WHERE id = ?', [scenario.id])
          .single['created_at'] as String;

      expect(storedScenarioCreatedAt, sourceDate.toIso8601String());
      expect(DateTime.parse(storedScenarioCreatedAt).isUtc, isTrue);

      late int runId;
      final runStartedAt = DateTime.utc(2027, 3, 14, 10, 0, 0);
      final runCompletedAt = DateTime.utc(2027, 3, 14, 11, 0, 0);
      final eventOccurredAt = DateTime.utc(2027, 3, 14, 10, 15, 0);
      final logRecordedAt = DateTime.utc(2027, 3, 14, 10, 30, 0);
      final summaryCreatedAt = DateTime.utc(2027, 3, 14, 11, 5, 0);

      await harness.runRepository.inTransaction((transaction) async {
        runId = await harness.runRepository.createRun(
          transaction: transaction,
          scenarioId: scenario.id,
          startedAt: runStartedAt,
        );

        await harness.eventRepository.appendEvent(
          transaction: transaction,
          runId: runId,
          eventType: 'DATE_EVENT',
          payload: '{}',
          occurredAt: eventOccurredAt,
        );

        await harness.logRepository.appendLog(
          transaction: transaction,
          runId: runId,
          aircraftId: 'AC-UTC',
          message: 'Recorded for UTC check',
          recordedAt: logRecordedAt,
        );

        await harness.metricsRepository.insertSummary(
          transaction: transaction,
          runId: runId,
          stats: const SimulationStats(
            averageLandingDelay: 0.5,
            averageDepartureDelay: 0.5,
            maxLandingDelay: 0.5,
            maxDepartureDelay: 0.5,
            maxInboundQueue: 1,
            maxOutboundQueue: 1,
            totalCancellations: 0,
            totalDiversions: 0,
            totalAircrafts: 1,
          ),
          createdAt: summaryCreatedAt,
        );

        await harness.runRepository.finalizeRun(
          transaction: transaction,
          runId: runId,
          completedAt: runCompletedAt,
          status: 'completed',
        );
      });

      final rawRun = harness.provider.database
          .select('SELECT started_at, completed_at FROM runs WHERE id = ?', [runId])
          .single;
      expect(rawRun['started_at'], runStartedAt.toIso8601String());
      expect(rawRun['completed_at'], runCompletedAt.toIso8601String());

      final rawEvent = harness.provider.database
          .select('SELECT occurred_at FROM events WHERE run_id = ?', [runId])
          .single;
      expect(rawEvent['occurred_at'], eventOccurredAt.toIso8601String());

      final rawLog = harness.provider.database
          .select('SELECT recorded_at FROM aircraft_logs WHERE run_id = ?', [runId])
          .single;
      expect(rawLog['recorded_at'], logRecordedAt.toIso8601String());

      final rawSummary = harness.provider.database
          .select('SELECT created_at FROM metrics_summaries WHERE run_id = ?', [runId])
          .single;
      expect(rawSummary['created_at'], summaryCreatedAt.toIso8601String());

      final mappedScenario = await harness.scenarioRepository.getScenarioById(scenario.id);
      final mappedRun = (await harness.runRepository.listRunsByScenario(scenario.id)).single;
      final mappedEvent = (await harness.eventRepository.listEventsByRun(runId)).single;
      final mappedLog = (await harness.logRepository.listLogsByRun(runId)).single;
      final mappedSummary = (await harness.metricsRepository.getSummaryByRun(runId))!;

      expect(mappedScenario!.createdAt, sourceDate);
      expect(mappedRun.startedAt, runStartedAt);
      expect(mappedRun.completedAt, runCompletedAt);
      expect(mappedEvent.occurredAt, eventOccurredAt);
      expect(mappedLog.recordedAt, logRecordedAt);
      expect(mappedSummary.createdAt, summaryCreatedAt);

      expect(mappedScenario.createdAt.isUtc, isTrue);
      expect(mappedRun.startedAt.isUtc, isTrue);
      expect(mappedRun.completedAt!.isUtc, isTrue);
      expect(mappedEvent.occurredAt.isUtc, isTrue);
      expect(mappedLog.recordedAt.isUtc, isTrue);
      expect(mappedSummary.createdAt.isUtc, isTrue);
    });
  });
}

Set<String> _indexNames(Database db, String table) {
  return db
      .select('PRAGMA index_list($table)')
      .map((row) => row['name'] as String)
      .toSet();
}

bool _hasUniqueIndexOnColumns(
  Database db, {
  required String table,
  required List<String> columns,
}) {
  final indexes = db.select('PRAGMA index_list($table)');

  for (final index in indexes) {
    if ((index['unique'] as int) != 1) {
      continue;
    }

    final indexName = index['name'] as String;
    final indexedColumns = db
        .select('PRAGMA index_info($indexName)')
        .map((row) => row['name'] as String)
        .toList(growable: false);

    if (_sameColumnSet(indexedColumns, columns)) {
      return true;
    }
  }

  return false;
}

bool _sameColumnSet(List<String> a, List<String> b) {
  if (a.length != b.length) {
    return false;
  }

  final aSet = a.toSet();
  final bSet = b.toSet();
  return aSet.length == a.length && bSet.length == b.length && aSet.containsAll(bSet);
}

/// Test harness that creates an isolated temporary SQLite database
/// and exposes repositories backed by that database.
class _PersistenceTestHarness {
  final Directory tempDir;
  final DatabaseProvider provider;
  final SqlitePersistenceStore scenarioRepository;
  final SqlitePersistenceStore runRepository;
  final SqlitePersistenceStore eventRepository;
  final SqlitePersistenceStore logRepository;
  final SqlitePersistenceStore metricsRepository;

  _PersistenceTestHarness._({
    required this.tempDir,
    required this.provider,
    required this.scenarioRepository,
    required this.runRepository,
    required this.eventRepository,
    required this.logRepository,
    required this.metricsRepository,
  });

  factory _PersistenceTestHarness.create() {
    final tempDir = Directory.systemTemp.createTempSync('sqlite-persistence-test-');
    final dbPath = '${tempDir.path}/ephemeral.db';
    final provider = DatabaseProvider(dbPath);
    final store = SqlitePersistenceStore(provider);

    return _PersistenceTestHarness._(
      tempDir: tempDir,
      provider: provider,
      scenarioRepository: store,
      runRepository: store,
      eventRepository: store,
      logRepository: store,
      metricsRepository: store,
    );
  }

  void dispose() {
    provider.dispose();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }
}
