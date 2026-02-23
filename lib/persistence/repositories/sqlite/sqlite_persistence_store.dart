import 'package:air_traffic_sim/persistence/database.dart';
import 'package:air_traffic_sim/persistence/models/aircraft_log_record.dart';
import 'package:air_traffic_sim/persistence/models/metrics_summary_record.dart';
import 'package:air_traffic_sim/persistence/models/run_record.dart';
import 'package:air_traffic_sim/persistence/models/scenario_record.dart';
import 'package:air_traffic_sim/persistence/models/simulation_event_record.dart';
import 'package:air_traffic_sim/persistence/repositories/aircraft_log_repository.dart';
import 'package:air_traffic_sim/persistence/repositories/event_repository.dart';
import 'package:air_traffic_sim/persistence/repositories/metrics_summary_repository.dart';
import 'package:air_traffic_sim/persistence/repositories/run_repository.dart';
import 'package:air_traffic_sim/persistence/repositories/scenario_repository.dart';
import 'package:air_traffic_sim/persistence/repositories/sqlite/sqlite_aircraft_log_repository.dart';
import 'package:air_traffic_sim/persistence/repositories/sqlite/sqlite_event_repository.dart';
import 'package:air_traffic_sim/persistence/repositories/sqlite/sqlite_metrics_summary_repository.dart';
import 'package:air_traffic_sim/persistence/repositories/sqlite/sqlite_run_repository.dart';
import 'package:air_traffic_sim/persistence/repositories/sqlite/sqlite_scenario_repository.dart';
import 'package:air_traffic_sim/simulation/simulation_stats.dart';
import 'package:sqlite3/sqlite3.dart';

/// Unified SQLite-backed persistence store.
///
/// A thin composition root that wires feature-specific repositories while still
/// satisfying repository interfaces used by orchestration code.
class SqlitePersistenceStore
    implements
        ScenarioRepository,
        RunRepository,
        EventRepository,
        AircraftLogRepository,
        MetricsSummaryRepository {
  final DatabaseAccessor databaseProvider;

  late final SqliteScenarioRepository _scenarioRepository;
  late final SqliteRunRepository _runRepository;
  late final SqliteEventRepository _eventRepository;
  late final SqliteAircraftLogRepository _aircraftLogRepository;
  late final SqliteMetricsSummaryRepository _metricsSummaryRepository;

  SqlitePersistenceStore(this.databaseProvider) {
    _scenarioRepository = SqliteScenarioRepository(databaseProvider);
    _runRepository = SqliteRunRepository(databaseProvider);
    _eventRepository = SqliteEventRepository(databaseProvider);
    _aircraftLogRepository = SqliteAircraftLogRepository(databaseProvider);
    _metricsSummaryRepository = SqliteMetricsSummaryRepository(databaseProvider);
  }

  @override
  Future<T> inTransaction<T>(Future<T> Function(Database transaction) operation) {
    return _runRepository.inTransaction(operation);
  }

  @override
  Future<void> upsertScenario(ScenarioRecord scenario) {
    return _scenarioRepository.upsertScenario(scenario);
  }

  @override
  Future<ScenarioRecord?> getScenarioById(String id) {
    return _scenarioRepository.getScenarioById(id);
  }

  @override
  Future<List<ScenarioRecord>> listScenarios() {
    return _scenarioRepository.listScenarios();
  }

  @override
  Future<int> createRun({
    required Database transaction,
    required String scenarioId,
    required DateTime startedAt,
  }) {
    return _runRepository.createRun(
      transaction: transaction,
      scenarioId: scenarioId,
      startedAt: startedAt,
    );
  }

  @override
  Future<void> finalizeRun({
    required Database transaction,
    required int runId,
    required DateTime completedAt,
    required String status,
  }) {
    return _runRepository.finalizeRun(
      transaction: transaction,
      runId: runId,
      completedAt: completedAt,
      status: status,
    );
  }

  @override
  Future<List<RunRecord>> listRunsByScenario(String scenarioId) {
    return _runRepository.listRunsByScenario(scenarioId);
  }

  @override
  Future<void> appendEvent({
    required Database transaction,
    required int runId,
    required String eventType,
    required String payload,
    required DateTime occurredAt,
  }) {
    return _eventRepository.appendEvent(
      transaction: transaction,
      runId: runId,
      eventType: eventType,
      payload: payload,
      occurredAt: occurredAt,
    );
  }

  @override
  Future<List<SimulationEventRecord>> listEventsByRun(int runId) {
    return _eventRepository.listEventsByRun(runId);
  }

  @override
  Future<void> appendLog({
    required Database transaction,
    required int runId,
    required String aircraftId,
    required String message,
    required DateTime recordedAt,
  }) {
    return _aircraftLogRepository.appendLog(
      transaction: transaction,
      runId: runId,
      aircraftId: aircraftId,
      message: message,
      recordedAt: recordedAt,
    );
  }

  @override
  Future<List<AircraftLogRecord>> listLogsByRun(int runId) {
    return _aircraftLogRepository.listLogsByRun(runId);
  }

  @override
  Future<void> insertSummary({
    required Database transaction,
    required int runId,
    required SimulationStats stats,
    required DateTime createdAt,
  }) {
    return _metricsSummaryRepository.insertSummary(
      transaction: transaction,
      runId: runId,
      stats: stats,
      createdAt: createdAt,
    );
  }

  @override
  Future<List<MetricsSummaryRecord>> listSummariesByScenario(String scenarioId) {
    return _metricsSummaryRepository.listSummariesByScenario(scenarioId);
  }

  @override
  Future<MetricsSummaryRecord?> getSummaryByRun(int runId) {
    return _metricsSummaryRepository.getSummaryByRun(runId);
  }
}
