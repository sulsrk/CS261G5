import 'package:air_traffic_sim/persistence/models/aircraft_log_record.dart';
import 'package:air_traffic_sim/persistence/models/metrics_summary_record.dart';
import 'package:air_traffic_sim/persistence/models/run_record.dart';
import 'package:air_traffic_sim/persistence/models/simulation_event_record.dart';
import 'package:air_traffic_sim/persistence/repositories/aircraft_log_repository.dart';
import 'package:air_traffic_sim/persistence/repositories/event_repository.dart';
import 'package:air_traffic_sim/persistence/repositories/metrics_summary_repository.dart';
import 'package:air_traffic_sim/persistence/repositories/run_repository.dart';
import 'package:air_traffic_sim/simulation/simulation_stats.dart';
import 'package:sqlite3/sqlite3.dart';

import 'orchestrated_simulation_persistence_port.dart';

export 'orchestrated_simulation_persistence_port.dart';

/// Final run completion returned by simulation execution.
class RunCompletion {
  final SimulationStats metrics;
  final String status;
  final DateTime completedAt;

  const RunCompletion({
    required this.metrics,
    this.status = 'completed',
    required this.completedAt,
  });
}

/// Transaction-scoped writer used while persisting a run.
class RunLifecycleSession {
  final Database transaction;
  final EventRepository eventRepository;
  final AircraftLogRepository aircraftLogRepository;
  final MetricsSummaryRepository metricsSummaryRepository;
  final RunRepository runRepository;

  final int runId;
  final String scenarioId;

  const RunLifecycleSession({
    required this.transaction,
    required this.eventRepository,
    required this.aircraftLogRepository,
    required this.metricsSummaryRepository,
    required this.runRepository,
    required this.runId,
    required this.scenarioId,
  });

  Future<void> appendEvent({
    required String eventType,
    required String payload,
    required DateTime occurredAt,
  }) {
    return eventRepository.appendEvent(
      transaction: transaction,
      runId: runId,
      eventType: eventType,
      payload: payload,
      occurredAt: occurredAt,
    );
  }

  Future<void> appendAircraftLog({
    required String aircraftId,
    required String message,
    required DateTime recordedAt,
  }) {
    return aircraftLogRepository.appendLog(
      transaction: transaction,
      runId: runId,
      aircraftId: aircraftId,
      message: message,
      recordedAt: recordedAt,
    );
  }

  Future<void> publishSummaryMetrics({
    required SimulationStats stats,
    required DateTime createdAt,
  }) {
    return metricsSummaryRepository.insertSummary(
      transaction: transaction,
      runId: runId,
      stats: stats,
      createdAt: createdAt,
    );
  }

  Future<void> finalizeRun({
    required DateTime completedAt,
    required String status,
  }) {
    return runRepository.finalizeRun(
      transaction: transaction,
      runId: runId,
      completedAt: completedAt,
      status: status,
    );
  }
}

/// Orchestrates persistence for a single simulation run transaction.
class RunPersistenceOrchestrator {
  final RunRepository runRepository;
  final EventRepository eventRepository;
  final AircraftLogRepository aircraftLogRepository;
  final MetricsSummaryRepository metricsSummaryRepository;

  const RunPersistenceOrchestrator({
    required this.runRepository,
    required this.eventRepository,
    required this.aircraftLogRepository,
    required this.metricsSummaryRepository,
  });

  Future<int> executeRunLifecycle({
    required String scenarioId,
    required Future<RunCompletion> Function(RunLifecycleSession session)
        simulationExecution,
    DateTime? startedAt,
  }) {
    return runRepository.inTransaction((transaction) async {
      final runId = await runRepository.createRun(
        transaction: transaction,
        scenarioId: scenarioId,
        startedAt: startedAt ?? DateTime.now(),
      );

      final session = RunLifecycleSession(
        transaction: transaction,
        eventRepository: eventRepository,
        aircraftLogRepository: aircraftLogRepository,
        metricsSummaryRepository: metricsSummaryRepository,
        runRepository: runRepository,
        runId: runId,
        scenarioId: scenarioId,
      );

      final completion = await simulationExecution(session);
      await session.finalizeRun(
        completedAt: completion.completedAt,
        status: completion.status,
      );
      await session.publishSummaryMetrics(
        stats: completion.metrics,
        createdAt: completion.completedAt,
      );

      return runId;
    });
  }

  Future<int> persistRunLifecycle({
    required String scenarioId,
    required Iterable<SimulationEventRecord> events,
    required Iterable<AircraftLogRecord> aircraftLogs,
    required SimulationStats metrics,
    DateTime? startedAt,
    DateTime? completedAt,
    String completionStatus = 'completed',
  }) {
    final finishTime = completedAt ?? DateTime.now();

    return executeRunLifecycle(
      scenarioId: scenarioId,
      startedAt: startedAt,
      simulationExecution: (session) async {
        for (final event in events) {
          await session.appendEvent(
            eventType: event.eventType,
            payload: event.payload,
            occurredAt: event.occurredAt,
          );
        }

        for (final log in aircraftLogs) {
          await session.appendAircraftLog(
            aircraftId: log.aircraftId,
            message: log.message,
            recordedAt: log.recordedAt,
          );
        }

        return RunCompletion(
          metrics: metrics,
          status: completionStatus,
          completedAt: finishTime,
        );
      },
    );
  }

  Future<List<RunRecord>> listRunsForScenario(String scenarioId) {
    return runRepository.listRunsByScenario(scenarioId);
  }

  Future<List<MetricsSummaryRecord>> listMetricsForScenario(String scenarioId) {
    return metricsSummaryRepository.listSummariesByScenario(scenarioId);
  }

  Future<MetricsSummaryRecord?> getMetricsForRun(int runId) {
    return metricsSummaryRepository.getSummaryByRun(runId);
  }

  OrchestratedSimulationPersistencePort buildSimulationPersistencePort() {
    return OrchestratedSimulationPersistencePort(
      runRepository: runRepository,
      eventRepository: eventRepository,
      aircraftLogRepository: aircraftLogRepository,
      metricsSummaryRepository: metricsSummaryRepository,
    );
  }
}
