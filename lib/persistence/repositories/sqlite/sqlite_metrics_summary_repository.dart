import 'dart:convert';

import 'package:air_traffic_sim/persistence/database.dart';
import 'package:air_traffic_sim/persistence/models/metrics_summary_record.dart';
import 'package:air_traffic_sim/persistence/repositories/metrics_summary_repository.dart';
import 'package:air_traffic_sim/persistence/repositories/sqlite/sqlite_row_mappers.dart';
import 'package:air_traffic_sim/simulation/concretes/simulation_stats.dart';
import 'package:sqlite3/sqlite3.dart';

/// SQLite-backed implementation for persisting aggregate simulation metrics.
class SqliteMetricsSummaryRepository implements MetricsSummaryRepository {
  final DatabaseAccessor databaseAccessor;

  const SqliteMetricsSummaryRepository(this.databaseAccessor);

  /// Upserts one summary row for a run.
  ///
  /// Uses `run_id` uniqueness to keep a single canonical summary per run.
  @override
  Future<void> insertSummary({
    required Database transaction,
    required int runId,
    required SimulationStats stats,
    required DateTime createdAt,
  }) async {
    transaction.execute(
      '''
      INSERT INTO metrics_summaries (
        run_id,
        average_landing_delay, average_hold_time, section_average_landing_delay_list,
        average_departure_delay, average_wait_time, section_average_departure_delay_list,
        max_landing_delay, max_departure_delay, max_inbound_queue,
        max_outbound_queue, total_cancellations, total_diversions,
        total_landing_aircraft, total_departing_aircraft, runway_utilisation,
        total_aircrafts, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(run_id) DO UPDATE SET
        average_landing_delay = excluded.average_landing_delay,
        average_hold_time = excluded.average_hold_time,
        section_average_landing_delay_list = excluded.section_average_landing_delay_list,
        average_departure_delay = excluded.average_departure_delay,
        average_wait_time = excluded.average_wait_time,
        section_average_departure_delay_list = excluded.section_average_departure_delay_list,
        max_landing_delay = excluded.max_landing_delay,
        max_departure_delay = excluded.max_departure_delay,
        max_inbound_queue = excluded.max_inbound_queue,
        max_outbound_queue = excluded.max_outbound_queue,
        total_cancellations = excluded.total_cancellations,
        total_diversions = excluded.total_diversions,
        total_landing_aircraft = excluded.total_landing_aircraft,
        total_departing_aircraft = excluded.total_departing_aircraft,
        runway_utilisation = excluded.runway_utilisation,
        total_aircrafts = excluded.total_aircrafts,
        created_at = excluded.created_at
      ''',
      [
        runId,
        stats.averageLandingDelay,
        stats.averageHoldTime,
        jsonEncode(stats.sectionAverageLandingDelayList),
        stats.averageDepartureDelay,
        stats.averageWaitTime,
        jsonEncode(stats.sectionAverageDepartureDelayList),
        stats.maxLandingDelay,
        stats.maxDepartureDelay,
        stats.maxInboundQueue,
        stats.maxOutboundQueue,
        stats.totalCancellations,
        stats.totalDiversions,
        stats.totalLandingAircraft,
        stats.totalDepartingAircraft,
        stats.runwayUtilisation,
        stats.totalAircraft,
        toUtcText(createdAt),
      ],
    );
  }

  /// Loads summaries for all runs under [scenarioId], newest first.
  @override
  Future<List<MetricsSummaryRecord>> listSummariesByScenario(String scenarioId) async {
    final rows = databaseAccessor.database.select(
      '''
      SELECT metrics_summaries.id, metrics_summaries.run_id, runs.scenario_id,
             average_landing_delay, average_hold_time, section_average_landing_delay_list,
             average_departure_delay, average_wait_time, section_average_departure_delay_list,
             max_landing_delay, max_departure_delay, max_inbound_queue,
             max_outbound_queue, total_cancellations, total_diversions,
             total_landing_aircraft, total_departing_aircraft, runway_utilisation,
             total_aircrafts, metrics_summaries.created_at
      FROM metrics_summaries
      INNER JOIN runs ON runs.id = metrics_summaries.run_id
      WHERE runs.scenario_id = ?
      ORDER BY metrics_summaries.created_at DESC
      ''',
      [scenarioId],
    );

    return rows.map(toMetricsSummaryRecord).toList(growable: false);
  }

  /// Loads the summary for a specific run.
  @override
  Future<MetricsSummaryRecord?> getSummaryByRun(int runId) async {
    final rows = databaseAccessor.database.select(
      '''
      SELECT metrics_summaries.id, metrics_summaries.run_id, runs.scenario_id,
             average_landing_delay, average_hold_time, section_average_landing_delay_list,
             average_departure_delay, average_wait_time, section_average_departure_delay_list,
             max_landing_delay, max_departure_delay, max_inbound_queue,
             max_outbound_queue, total_cancellations, total_diversions,
             total_landing_aircraft, total_departing_aircraft, runway_utilisation,
             total_aircrafts, metrics_summaries.created_at
      FROM metrics_summaries
      INNER JOIN runs ON runs.id = metrics_summaries.run_id
      WHERE metrics_summaries.run_id = ?
      ''',
      [runId],
    );

    if (rows.isEmpty) {
      return null;
    }

    return toMetricsSummaryRecord(rows.first);
  }
}
