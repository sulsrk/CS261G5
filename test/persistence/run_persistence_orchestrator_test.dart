/// Integration tests for the run persistence orchestrator.
///
/// These tests verify:
/// 1) `executeRunLifecycle` performs an atomic run lifecycle:
///    - creates the run,
///    - persists events/logs/metrics produced by the simulation callback,
///    - finalizes the run with completion status,
///    - and stores all DateTime values deterministically in UTC.
/// 2) `buildSimulationPersistencePort` returns a persistence adapter that:
///    - persists a run immediately on `startRun`,
///    - writes events/logs/metrics without buffering,
///    - enforces invariants (summary required before finalize),
///    - and upserts summary metrics when published multiple times.
/// 3) Transaction rollback works correctly when the simulation execution throws,
///    leaving the database unchanged (no partial rows).
///
/// Each test uses a fresh temporary SQLite database file to avoid shared state.
import 'package:air_traffic_sim/persistence/database.dart';
import 'dart:io';

import 'package:air_traffic_sim/persistence/models/scenario_record.dart';
import 'package:air_traffic_sim/persistence/repositories/sqlite/sqlite_persistence_store.dart';
import 'package:air_traffic_sim/simulation/orchestration/run_persistence_orchestrator.dart';
import 'package:air_traffic_sim/simulation/interfaces/interface_simulation_persistence_port.dart';
import 'package:air_traffic_sim/simulation/concretes/simulation_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RunPersistenceOrchestrator', () {
    late _OrchestratorTestHarness harness;

    setUp(() {
      harness = _OrchestratorTestHarness.create();
    });

    tearDown(() {
      harness.dispose();
    });

    // Simulates a complete orchestration lifecycle:
    // - create scenario
    // - execute the simulation callback (which appends event + log)
    // - return RunCompletion containing summary metrics + status + completion time
    //
    // Verifies:
    // - a run record is persisted with the returned status + timestamps
    // - events/logs/summaries are linked to the persisted run id
    // - all stored/mapped DateTime values remain UTC
    // - the run record exists at the raw SQL level (ground-truth assertion)
    test('persists run records and propagates completion status', () async {
      const scenarioId = 'scenario-orchestrator-happy';
      final startedAt = DateTime.utc(2026, 2, 1, 10, 0, 0);
      final completedAt = DateTime.utc(2026, 2, 1, 10, 15, 0);

      // Ensure parent scenario exists so run persistence can satisfy FK/domain rules.
      await harness.createScenario(scenarioId);

      // Execute a run lifecycle and capture the persisted run id.
      // The simulation callback writes event + log, then returns completion details.
      final runId = await harness.orchestrator.executeRunLifecycle(
        scenarioId: scenarioId,
        startedAt: startedAt,
        simulationExecution: (session) async {
          // Persist a simulation event during the run.
          await session.appendEvent(
            eventType: 'AIRCRAFT_LANDED',
            payload: '{"aircraftId":"A-1"}',
            occurredAt: DateTime.utc(2026, 2, 1, 10, 5, 0),
          );

          // Persist a per-aircraft log line during the run.
          await session.appendAircraftLog(
            aircraftId: 'A-1',
            message: 'Touchdown complete',
            recordedAt: DateTime.utc(2026, 2, 1, 10, 6, 0),
          );

          // Return run completion information to be persisted by the orchestrator.
          return RunCompletion(
            metrics: const SimulationStats(
              averageLandingDelay: 1.2,
            averageDepartureDelay: 1.2,
            maxLandingDelay: 1.2,
            maxDepartureDelay: 1.2,
              maxInboundQueue: 2,
              maxOutboundQueue: 3,
              totalCancellations: 0,
              totalDiversions: 1,
              totalAircrafts: 4,
            ),
            status: 'aborted',
            completedAt: completedAt,
          );
        },
      );

      // Verify run persistence for this scenario.
      final runs = await harness.runRepository.listRunsByScenario(scenarioId);
      final events = await harness.eventRepository.listEventsByRun(runId);
      final logs = await harness.logRepository.listLogsByRun(runId);
      final summary = await harness.metricsRepository.getSummaryByRun(runId);

      // Run row is created once, uses the returned runId, and stores completion status.
      expect(runs, hasLength(1));
      expect(runs.single.id, runId);
      expect(runs.single.status, 'aborted');
      expect(runs.single.completedAt, completedAt);

      // UTC determinism: the mapper must produce UTC DateTime objects.
      expect(runs.single.startedAt.isUtc, isTrue);
      expect(runs.single.completedAt!.isUtc, isTrue);

      // Event row is persisted and linked to the run, with UTC timestamps.
      expect(events, hasLength(1));
      expect(events.single.runId, runId);
      expect(events.single.occurredAt.isUtc, isTrue);

      // Log row is persisted and linked to the run, with UTC timestamps.
      expect(logs, hasLength(1));
      expect(logs.single.runId, runId);
      expect(logs.single.recordedAt.isUtc, isTrue);

      // Summary is persisted and linked correctly, with UTC timestamps.
      expect(summary, isNotNull);
      expect(summary!.runId, runId);
      expect(summary.scenarioId, scenarioId);
      expect(summary.createdAt.isUtc, isTrue);

      // Raw SQL "ground truth" check: ensure the run row exists in the runs table.
      final rawRunById = harness.provider.database
          .select('SELECT id FROM runs WHERE id = ?', [runId]);
      expect(rawRunById, hasLength(1));
    });

    // Verifies the simulation persistence port adapter writes immediately:
    // - `startRun` persists a run row and returns a stable run id
    // - `appendEvent` inserts an event row (no buffering)
    // - `appendAircraftLog` inserts a log row (no buffering)
    // - `publishSummaryMetrics` inserts a summary row (no buffering)
    // - `finalizeRun` finalizes the same run without changing row counts unexpectedly
    test('buildSimulationPersistencePort persists run id and writes without buffering', () async {
      const scenarioId = 'scenario-buffered-port';
      await harness.createScenario(scenarioId);

      final port = harness.orchestrator.buildSimulationPersistencePort();

      // Starting the run should immediately persist a run row and return a usable id.
      final run = await port.startRun(
        scenarioId: scenarioId,
        startedAt: DateTime.utc(2026, 2, 3, 8, 0, 0),
      );

      final countsAfterStart = harness.tableCounts();
      expect(countsAfterStart['runs'], 1);
      expect(run.runId, greaterThan(0));

      // Appending an event should persist immediately (no buffering).
      await port.appendEvent(
        run: run,
        event: SimulationEventPayload(
          eventType: 'RUN_STARTED',
          payload: '{}',
          occurredAt: DateTime.utc(2026, 2, 3, 8, 1, 0),
        ),
      );

      final countsAfterEvent = harness.tableCounts();
      expect(countsAfterEvent['events'], 1);

      // Appending an aircraft log should persist immediately (no buffering).
      await port.appendAircraftLog(
        run: run,
        log: AircraftLogPayload(
          aircraftId: 'A-100',
          message: 'Queued',
          recordedAt: DateTime.utc(2026, 2, 3, 8, 2, 0),
        ),
      );

      final countsAfterLog = harness.tableCounts();
      expect(countsAfterLog['aircraft_logs'], 1);
      expect(countsAfterLog['metrics_summaries'], 0);

      // Publishing summary metrics should persist immediately.
      await port.publishSummaryMetrics(
        run: run,
        summary: SummaryMetricsPayload(
          stats: const SimulationStats(
            averageLandingDelay: 0,
            averageDepartureDelay: 0,
            maxLandingDelay: 0,
            maxDepartureDelay: 0,
            maxInboundQueue: 0,
            maxOutboundQueue: 0,
            totalCancellations: 0,
            totalDiversions: 0,
            totalAircrafts: 1,
          ),
          createdAt: DateTime.utc(2026, 2, 3, 8, 5, 0),
        ),
      );

      final countsAfterSummary = harness.tableCounts();
      expect(countsAfterSummary['metrics_summaries'], 1);

      // Finalizing the run should not create extra rows;
      // it should only update the existing run record.
      await port.finalizeRun(
        run: run,
        completedAt: DateTime.utc(2026, 2, 3, 8, 6, 0),
        status: 'completed',
      );

      final afterFinalize = harness.tableCounts();
      expect(afterFinalize['runs'], 1);
      expect(afterFinalize['events'], 1);
      expect(afterFinalize['aircraft_logs'], 1);
      expect(afterFinalize['metrics_summaries'], 1);
    });

    // Verifies that a full run created via the port adapter is persisted end-to-end:
    // - startRun produces a run id
    // - events/logs/summary are written and associated with that run id
    // - finalizeRun completes the lifecycle
    //
    // Ensures the run id returned by startRun matches the run id queried from the DB.
    test('buildSimulationPersistencePort persists a full run in one finalize transaction', () async {
      const scenarioId = 'scenario-port-adapter';
      await harness.createScenario(scenarioId);

      final port = harness.orchestrator.buildSimulationPersistencePort();
      final startedAt = DateTime.utc(2026, 2, 3, 12, 0, 0);
      final completedAt = DateTime.utc(2026, 2, 3, 12, 20, 0);

      // Start run and obtain the persisted run id.
      final run = await port.startRun(
        scenarioId: scenarioId,
        startedAt: startedAt,
      );

      // Persist an event for the run.
      await port.appendEvent(
        run: run,
        event: SimulationEventPayload(
          eventType: 'RUN_STARTED',
          payload: '{}',
          occurredAt: DateTime.utc(2026, 2, 3, 12, 1, 0),
        ),
      );

      // Persist a log for the run.
      await port.appendAircraftLog(
        run: run,
        log: AircraftLogPayload(
          aircraftId: 'A-7',
          message: 'Entered holding',
          recordedAt: DateTime.utc(2026, 2, 3, 12, 2, 0),
        ),
      );

      // Publish summary metrics for the run.
      await port.publishSummaryMetrics(
        run: run,
        summary: SummaryMetricsPayload(
          stats: const SimulationStats(
            averageLandingDelay: 0.5,
            averageDepartureDelay: 0.5,
            maxLandingDelay: 0.5,
            maxDepartureDelay: 0.5,
            maxInboundQueue: 1,
            maxOutboundQueue: 2,
            totalCancellations: 0,
            totalDiversions: 0,
            totalAircrafts: 2,
          ),
          createdAt: completedAt,
        ),
      );

      // Finalize run with completion time + status.
      await port.finalizeRun(
        run: run,
        completedAt: completedAt,
        status: 'completed',
      );

      // Ensure a single run exists for the scenario.
      final runs = await harness.runRepository.listRunsByScenario(scenarioId);
      expect(runs, hasLength(1));

      // Ensure the run id returned by the port matches the persisted run row id.
      final persistedRunId = runs.single.id;
      expect(run.runId, persistedRunId);

      // Verify all associated data is persisted for the same run id.
      final events = await harness.eventRepository.listEventsByRun(persistedRunId);
      final logs = await harness.logRepository.listLogsByRun(persistedRunId);
      final summary = await harness.metricsRepository.getSummaryByRun(persistedRunId);

      expect(events, hasLength(1));
      expect(logs, hasLength(1));
      expect(summary, isNotNull);
      expect(summary!.scenarioId, scenarioId);
    });

    // Verifies adapter invariants:
    // finalizing a run requires summary metrics to have been published first.
    //
    // This prevents "completed" runs that lack summary rows, ensuring reporting/UI
    // can assume a summary exists for finalized runs.
    test('buildSimulationPersistencePort requires summary before finalize', () async {
      const scenarioId = 'scenario-missing-summary';
      await harness.createScenario(scenarioId);

      final port = harness.orchestrator.buildSimulationPersistencePort();
      final run = await port.startRun(
        scenarioId: scenarioId,
        startedAt: DateTime.utc(2026, 2, 3, 9, 0, 0),
      );

      // Attempting to finalize without a summary should fail deterministically.
      await expectLater(
        () => port.finalizeRun(
          run: run,
          completedAt: DateTime.utc(2026, 2, 3, 9, 15, 0),
          status: 'completed',
        ),
        throwsA(isA<StateError>()),
      );
    });

    // Verifies summary upsert semantics:
    // publishing summary metrics twice for the same run should update the existing
    // summary row rather than inserting a duplicate.
    test('buildSimulationPersistencePort updates summary when published twice', () async {
      const scenarioId = 'scenario-summary-upsert';
      await harness.createScenario(scenarioId);

      final port = harness.orchestrator.buildSimulationPersistencePort();
      final run = await port.startRun(
        scenarioId: scenarioId,
        startedAt: DateTime.utc(2026, 2, 3, 9, 30, 0),
      );

      // First summary publish inserts the summary row.
      await port.publishSummaryMetrics(
        run: run,
        summary: SummaryMetricsPayload(
          stats: const SimulationStats(
            averageLandingDelay: 3.5,
            averageDepartureDelay: 3.5,
            maxLandingDelay: 3.5,
            maxDepartureDelay: 3.5,
            maxInboundQueue: 6,
            maxOutboundQueue: 2,
            totalCancellations: 1,
            totalDiversions: 1,
            totalAircrafts: 7,
          ),
          createdAt: DateTime.utc(2026, 2, 3, 9, 45, 0),
        ),
      );

      // Second publish should overwrite/update the same summary row.
      await port.publishSummaryMetrics(
        run: run,
        summary: SummaryMetricsPayload(
          stats: const SimulationStats(
            averageLandingDelay: 1.0,
            averageDepartureDelay: 1.0,
            maxLandingDelay: 1.0,
            maxDepartureDelay: 1.0,
            maxInboundQueue: 1,
            maxOutboundQueue: 1,
            totalCancellations: 0,
            totalDiversions: 0,
            totalAircrafts: 3,
          ),
          createdAt: DateTime.utc(2026, 2, 3, 9, 50, 0),
        ),
      );

      await port.finalizeRun(
        run: run,
        completedAt: DateTime.utc(2026, 2, 3, 10, 0, 0),
        status: 'completed',
      );

      // Verify the persisted summary reflects the second publish.
      final summary = await harness.metricsRepository.getSummaryByRun(run.runId);
      expect(summary, isNotNull);
      expect(summary!.stats.averageLandingDelay, 1.0);
      expect(summary.stats.averageDepartureDelay, 1.0);
      expect(summary.stats.maxLandingDelay, 1.0);
      expect(summary.stats.maxDepartureDelay, 1.0);
      expect(summary.stats.totalAircrafts, 3);

      // Ensure upsert did not create duplicate summary rows.
      expect(harness.tableCounts()['metrics_summaries'], 1);
    });

    // Verifies atomicity of `executeRunLifecycle`:
    // if the simulation callback throws after writing partial data, the orchestrator
    // must roll back the entire run persistence, leaving the database unchanged.
    test('rolls back run persistence when simulation execution throws', () async {
      const scenarioId = 'scenario-orchestrator-failure';
      await harness.createScenario(scenarioId);

      // Baseline counts before the failing lifecycle attempt.
      final baseline = harness.tableCounts();

      await expectLater(
        () => harness.orchestrator.executeRunLifecycle(
          scenarioId: scenarioId,
          simulationExecution: (session) async {
            // Write some state (would be partial data if not rolled back).
            await session.appendEvent(
              eventType: 'RUN_STARTED',
              payload: '{}',
              occurredAt: DateTime.utc(2026, 2, 2, 11, 0, 0),
            );

            // Force failure to validate transaction rollback semantics.
            throw _PlannedSimulationFailure();
          },
        ),
        throwsA(isA<_PlannedSimulationFailure>()),
      );

      // Ensure no new rows were persisted (full rollback to baseline).
      final afterFailure = harness.tableCounts();
      expect(afterFailure, baseline);

      // Ensure no run id was allocated/persisted.
      final maxRunIdRow = harness.provider.database
          .select('SELECT MAX(id) AS max_id FROM runs')
          .single;
      expect(maxRunIdRow['max_id'], isNull);
    });
  });
}

/// Test harness that creates an isolated temporary SQLite database
/// and wires a single SqlitePersistenceStore into the orchestrator and repositories.
///
/// This ensures the integration tests exercise real SQLite I/O, schema constraints,
/// and transactional behavior (commit/rollback) end-to-end.
class _OrchestratorTestHarness {
  final Directory tempDir;
  final DatabaseProvider provider;
  final SqlitePersistenceStore scenarioRepository;
  final SqlitePersistenceStore runRepository;
  final SqlitePersistenceStore eventRepository;
  final SqlitePersistenceStore logRepository;
  final SqlitePersistenceStore metricsRepository;
  final RunPersistenceOrchestrator orchestrator;

  _OrchestratorTestHarness._({
    required this.tempDir,
    required this.provider,
    required this.scenarioRepository,
    required this.runRepository,
    required this.eventRepository,
    required this.logRepository,
    required this.metricsRepository,
    required this.orchestrator,
  });

  factory _OrchestratorTestHarness.create() {
    // Create a fresh, isolated database per test suite run.
    final tempDir = Directory.systemTemp.createTempSync('sqlite-orchestrator-test-');
    final dbPath = '${tempDir.path}/ephemeral.db';
    final provider = DatabaseProvider(dbPath);

    // Use a single store instance as the backing implementation for all repositories.
    final store = SqlitePersistenceStore(provider);

    return _OrchestratorTestHarness._(
      tempDir: tempDir,
      provider: provider,
      scenarioRepository: store,
      runRepository: store,
      eventRepository: store,
      logRepository: store,
      metricsRepository: store,
      orchestrator: RunPersistenceOrchestrator(
        runRepository: store,
        eventRepository: store,
        aircraftLogRepository: store,
        metricsSummaryRepository: store,
      ),
    );
  }

  // Inserts a scenario record so run persistence can satisfy FK/domain rules.
  Future<void> createScenario(String id) {
    return scenarioRepository.upsertScenario(
      ScenarioRecord(
        id: id,
        name: 'Scenario $id',
        description: 'orchestrator test scenario',
        createdAt: DateTime.utc(2026, 2, 1, 0, 0, 0),
      ),
    );
  }

  // Convenience method for asserting persistence side-effects
  // at the table level (helps verify rollback/no buffering).
  Map<String, int> tableCounts() {
    return <String, int>{
      'runs': _tableCount('runs'),
      'events': _tableCount('events'),
      'aircraft_logs': _tableCount('aircraft_logs'),
      'metrics_summaries': _tableCount('metrics_summaries'),
    };
  }

  int _tableCount(String tableName) {
    final row = provider.database
        .select('SELECT COUNT(*) AS count FROM $tableName')
        .single;
    return row['count'] as int;
  }

  // Closes the SQLite connection and removes the temporary database directory.
  void dispose() {
    provider.dispose();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }
}

/// Sentinel exception used to force a failure inside the simulation callback
/// so tests can verify transaction rollback semantics.
class _PlannedSimulationFailure implements Exception {}