// Integration checks for the run persistence orchestrator.
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

    test('persists run records and propagates completion status', () async {
      const scenarioId = 'scenario-orchestrator-happy';
      final startedAt = DateTime.utc(2026, 2, 1, 10, 0, 0);
      final completedAt = DateTime.utc(2026, 2, 1, 10, 15, 0);

      await harness.createScenario(scenarioId);

      final runId = await harness.orchestrator.executeRunLifecycle(
        scenarioId: scenarioId,
        startedAt: startedAt,
        simulationExecution: (session) async {
          await session.appendEvent(
            eventType: 'AIRCRAFT_LANDED',
            payload: '{"aircraftId":"A-1"}',
            occurredAt: DateTime.utc(2026, 2, 1, 10, 5, 0),
          );

          await session.appendAircraftLog(
            aircraftId: 'A-1',
            message: 'Touchdown complete',
            recordedAt: DateTime.utc(2026, 2, 1, 10, 6, 0),
          );

          return RunCompletion(
            metrics: const SimulationStats(
              averageLandingDelay: 1.2,
              averageHoldTime: 1.2,
              sectionAverageLandingDelayList: const [],
              averageDepartureDelay: 1.2,
              averageWaitTime: 1.2,
              sectionAverageDepartureDelayList: const [],
              maxLandingDelay: 1,
              maxDepartureDelay: 1,
              maxInboundQueue: 2,
              maxOutboundQueue: 3,
              totalCancellations: 0,
              totalDiversions: 1,
              totalLandingAircraft: 2,
              totalDepartingAircraft: 2,
              runwayUtilisation: 0.5,
            ),
            status: 'aborted',
            completedAt: completedAt,
          );
        },
      );

      final runs = await harness.runRepository.listRunsByScenario(scenarioId);
      final events = await harness.eventRepository.listEventsByRun(runId);
      final logs = await harness.logRepository.listLogsByRun(runId);
      final summary = await harness.metricsRepository.getSummaryByRun(runId);

      expect(runs, hasLength(1));
      expect(runs.single.id, runId);
      expect(runs.single.status, 'aborted');
      expect(runs.single.completedAt, completedAt);

      expect(runs.single.startedAt.isUtc, isTrue);
      expect(runs.single.completedAt!.isUtc, isTrue);

      expect(events, hasLength(1));
      expect(events.single.runId, runId);
      expect(events.single.occurredAt.isUtc, isTrue);

      expect(logs, hasLength(1));
      expect(logs.single.runId, runId);
      expect(logs.single.recordedAt.isUtc, isTrue);

      expect(summary, isNotNull);
      expect(summary!.runId, runId);
      expect(summary.scenarioId, scenarioId);
      expect(summary.createdAt.isUtc, isTrue);

      // Double-check directly in SQL.
      final rawRunById = harness.provider.database
          .select('SELECT id FROM runs WHERE id = ?', [runId]);
      expect(rawRunById, hasLength(1));
    });

    test('buildSimulationPersistencePort persists run id and writes without buffering', () async {
      const scenarioId = 'scenario-buffered-port';
      await harness.createScenario(scenarioId);

      final port = harness.orchestrator.buildSimulationPersistencePort();

      final run = await port.startRun(
        scenarioId: scenarioId,
        startedAt: DateTime.utc(2026, 2, 3, 8, 0, 0),
      );

      final countsAfterStart = harness.tableCounts();
      expect(countsAfterStart['runs'], 1);
      expect(run.runId, greaterThan(0));

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

      await port.publishSummaryMetrics(
        run: run,
        summary: SummaryMetricsPayload(
          stats: const SimulationStats(
            averageLandingDelay: 0,
            averageHoldTime: 0,
            sectionAverageLandingDelayList: const [],
            averageDepartureDelay: 0,
            averageWaitTime: 0,
            sectionAverageDepartureDelayList: const [],
            maxLandingDelay: 0,
            maxDepartureDelay: 0,
            maxInboundQueue: 0,
            maxOutboundQueue: 0,
            totalCancellations: 0,
            totalDiversions: 0,
            totalLandingAircraft: 1,
            totalDepartingAircraft: 0,
            runwayUtilisation: 0,
          ),
          createdAt: DateTime.utc(2026, 2, 3, 8, 5, 0),
        ),
      );

      final countsAfterSummary = harness.tableCounts();
      expect(countsAfterSummary['metrics_summaries'], 1);

      // Finalise should only update rows, not add extras.
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

    test('buildSimulationPersistencePort requires summary before finalise', () async {
      const scenarioId = 'scenario-missing-summary';
      await harness.createScenario(scenarioId);

      final port = harness.orchestrator.buildSimulationPersistencePort();
      final run = await port.startRun(
        scenarioId: scenarioId,
        startedAt: DateTime.utc(2026, 2, 3, 9, 0, 0),
      );

      // Finalise should fail without a summary.
      await expectLater(
        () => port.finalizeRun(
          run: run,
          completedAt: DateTime.utc(2026, 2, 3, 9, 15, 0),
          status: 'completed',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('buildSimulationPersistencePort updates summary when published twice', () async {
      const scenarioId = 'scenario-summary-upsert';
      await harness.createScenario(scenarioId);

      final port = harness.orchestrator.buildSimulationPersistencePort();
      final run = await port.startRun(
        scenarioId: scenarioId,
        startedAt: DateTime.utc(2026, 2, 3, 9, 30, 0),
      );

      await port.publishSummaryMetrics(
        run: run,
        summary: SummaryMetricsPayload(
          stats: const SimulationStats(
            averageLandingDelay: 3.5,
            averageHoldTime: 3.5,
            sectionAverageLandingDelayList: const [],
            averageDepartureDelay: 3.5,
            averageWaitTime: 3.5,
            sectionAverageDepartureDelayList: const [],
            maxLandingDelay: 3,
            maxDepartureDelay: 3,
            maxInboundQueue: 6,
            maxOutboundQueue: 2,
            totalCancellations: 1,
            totalDiversions: 1,
            totalLandingAircraft: 4,
            totalDepartingAircraft: 3,
            runwayUtilisation: 0.7,
          ),
          createdAt: DateTime.utc(2026, 2, 3, 9, 45, 0),
        ),
      );

      await port.publishSummaryMetrics(
        run: run,
        summary: SummaryMetricsPayload(
          stats: const SimulationStats(
            averageLandingDelay: 1.0,
            averageHoldTime: 1.0,
            sectionAverageLandingDelayList: const [],
            averageDepartureDelay: 1.0,
            averageWaitTime: 1.0,
            sectionAverageDepartureDelayList: const [],
            maxLandingDelay: 1,
            maxDepartureDelay: 1,
            maxInboundQueue: 1,
            maxOutboundQueue: 1,
            totalCancellations: 0,
            totalDiversions: 0,
            totalLandingAircraft: 2,
            totalDepartingAircraft: 1,
            runwayUtilisation: 0.3,
          ),
          createdAt: DateTime.utc(2026, 2, 3, 9, 50, 0),
        ),
      );

      await port.finalizeRun(
        run: run,
        completedAt: DateTime.utc(2026, 2, 3, 10, 0, 0),
        status: 'completed',
      );

      final summary = await harness.metricsRepository.getSummaryByRun(run.runId);
      expect(summary, isNotNull);
      expect(summary!.stats.averageLandingDelay, 1.0);
      expect(summary.stats.averageDepartureDelay, 1.0);
      expect(summary.stats.maxLandingDelay, 1);
      expect(summary.stats.maxDepartureDelay, 1);
      expect(summary.stats.totalAircraft, 3);

      expect(harness.tableCounts()['metrics_summaries'], 1);
    });

    test('rolls back run persistence when simulation execution throws', () async {
      const scenarioId = 'scenario-orchestrator-failure';
      await harness.createScenario(scenarioId);

      final baseline = harness.tableCounts();

      await expectLater(
        () => harness.orchestrator.executeRunLifecycle(
          scenarioId: scenarioId,
          simulationExecution: (session) async {
            await session.appendEvent(
              eventType: 'RUN_STARTED',
              payload: '{}',
              occurredAt: DateTime.utc(2026, 2, 2, 11, 0, 0),
            );

            throw _PlannedSimulationFailure();
          },
        ),
        throwsA(isA<_PlannedSimulationFailure>()),
      );

      final afterFailure = harness.tableCounts();
      expect(afterFailure, baseline);

      // No run should remain after rollback.
      final maxRunIdRow = harness.provider.database
          .select('SELECT MAX(id) AS max_id FROM runs')
          .single;
      expect(maxRunIdRow['max_id'], isNull);
    });
  });
}

// Shared setup for orchestrator persistence tests.
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
    final tempDir = Directory.systemTemp.createTempSync('sqlite-orchestrator-test-');
    final dbPath = '${tempDir.path}/ephemeral.db';
    final provider = DatabaseProvider(dbPath);

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

  void dispose() {
    provider.dispose();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }
}

// Used to trigger rollback paths.
class _PlannedSimulationFailure implements Exception {}
