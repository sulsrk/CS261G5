import 'package:air_traffic_sim/persistence/repositories/aircraft_log_repository.dart';
import 'package:air_traffic_sim/persistence/repositories/event_repository.dart';
import 'package:air_traffic_sim/persistence/repositories/metrics_summary_repository.dart';
import 'package:air_traffic_sim/persistence/repositories/run_repository.dart';
import 'package:air_traffic_sim/simulation/interfaces/interface_simulation_persistence_port.dart';

/// Simple adapter that writes simulation records directly to persistent storage.
class OrchestratedSimulationPersistencePort implements ISimulationPersistencePort {
  final RunRepository _runRepository;
  final EventRepository _eventRepository;
  final AircraftLogRepository _aircraftLogRepository;
  final MetricsSummaryRepository _metricsSummaryRepository;

  OrchestratedSimulationPersistencePort({
    required RunRepository runRepository,
    required EventRepository eventRepository,
    required AircraftLogRepository aircraftLogRepository,
    required MetricsSummaryRepository metricsSummaryRepository,
  })  : _runRepository = runRepository,
        _eventRepository = eventRepository,
        _aircraftLogRepository = aircraftLogRepository,
        _metricsSummaryRepository = metricsSummaryRepository;

  @override
  Future<SimulationRunHandle> startRun({
    required String scenarioId,
    required DateTime startedAt,
  }) async {
    final persistedRunId = await _runRepository.inTransaction((transaction) {
      return _runRepository.createRun(
        transaction: transaction,
        scenarioId: scenarioId,
        startedAt: startedAt,
      );
    });

    return SimulationRunHandle(
      runId: persistedRunId,
      scenarioId: scenarioId,
    );
  }

  @override
  Future<void> appendEvent({
    required SimulationRunHandle run,
    required SimulationEventPayload event,
  }) async {
    await _runRepository.inTransaction((transaction) {
      return _eventRepository.appendEvent(
        transaction: transaction,
        runId: run.runId,
        eventType: event.eventType,
        payload: event.payload,
        occurredAt: event.occurredAt,
      );
    });
  }

  @override
  Future<void> appendAircraftLog({
    required SimulationRunHandle run,
    required AircraftLogPayload log,
  }) async {
    await _runRepository.inTransaction((transaction) {
      return _aircraftLogRepository.appendLog(
        transaction: transaction,
        runId: run.runId,
        aircraftId: log.aircraftId,
        message: log.message,
        recordedAt: log.recordedAt,
      );
    });
  }

  @override
  Future<void> publishSummaryMetrics({
    required SimulationRunHandle run,
    required SummaryMetricsPayload summary,
  }) async {
    await _runRepository.inTransaction((transaction) {
      return _metricsSummaryRepository.insertSummary(
        transaction: transaction,
        runId: run.runId,
        stats: summary.stats,
        createdAt: summary.createdAt,
      );
    });
  }

  @override
  Future<void> finalizeRun({
    required SimulationRunHandle run,
    required DateTime completedAt,
    required String status,
  }) async {
    final summary = await _metricsSummaryRepository.getSummaryByRun(run.runId);
    if (summary == null) {
      throw StateError('Run ${run.runId} cannot be finalized without summary metrics.');
    }

    await _runRepository.inTransaction((transaction) async {
      await _runRepository.finalizeRun(
        transaction: transaction,
        runId: run.runId,
        completedAt: completedAt,
        status: status,
      );
    });
  }
}
