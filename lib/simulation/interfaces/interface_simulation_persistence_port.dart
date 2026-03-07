import 'package:air_traffic_sim/simulation/concretes/simulation_stats.dart';

/// Stable identifiers returned when a run is started in persistence.
class SimulationRunHandle {
  final int runId;
  final String scenarioId;

  const SimulationRunHandle({
    required this.runId,
    required this.scenarioId,
  });
}

/// Immutable simulation event payload written to the event stream table.
class SimulationEventPayload {
  final String eventType;
  final String payload;
  final DateTime occurredAt;

  const SimulationEventPayload({
    required this.eventType,
    required this.payload,
    required this.occurredAt,
  });
}

/// Per-aircraft log line with an explicit UTC timestamp.
class AircraftLogPayload {
  final String aircraftId;
  final String message;
  final DateTime recordedAt;

  const AircraftLogPayload({
    required this.aircraftId,
    required this.message,
    required this.recordedAt,
  });
}

/// Final aggregate metrics for one simulation run.
class SummaryMetricsPayload {
  /// Delay/queue/counter stats computed by the simulation engine.
  final SimulationStats stats;

  /// Timestamp representing when the summary snapshot was created.
  final DateTime createdAt;

  const SummaryMetricsPayload({
    required this.stats,
    required this.createdAt,
  });
}

/// Persistence contract used by the simulation layer.
abstract class ISimulationPersistencePort {
  /// Creates a run row for [scenarioId] and returns identifiers used for future writes.
  Future<SimulationRunHandle> startRun({
    required String scenarioId,
    required DateTime startedAt,
  });

  /// Appends one simulation [event] to the run represented by [run].
  Future<void> appendEvent({
    required SimulationRunHandle run,
    required SimulationEventPayload event,
  });

  /// Persists one aircraft-specific log entry [log] for [run].
  Future<void> appendAircraftLog({
    required SimulationRunHandle run,
    required AircraftLogPayload log,
  });

  /// Upserts summary metrics for [run].
  Future<void> publishSummaryMetrics({
    required SimulationRunHandle run,
    required SummaryMetricsPayload summary,
  });

  /// Marks [run] as completed, aborted, or failed at [completedAt].
  Future<void> finalizeRun({
    required SimulationRunHandle run,
    required DateTime completedAt,
    required String status,
  });
}
