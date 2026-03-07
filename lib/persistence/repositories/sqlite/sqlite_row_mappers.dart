import 'package:air_traffic_sim/persistence/models/aircraft_log_record.dart';
import 'package:air_traffic_sim/persistence/models/metrics_summary_record.dart';
import 'package:air_traffic_sim/persistence/models/run_record.dart';
import 'package:air_traffic_sim/persistence/models/scenario_record.dart';
import 'package:air_traffic_sim/persistence/models/simulation_event_record.dart';
import 'dart:convert';

import 'package:air_traffic_sim/simulation/concretes/simulation_stats.dart';
import 'package:sqlite3/sqlite3.dart';

String toUtcText(DateTime value) => value.toUtc().toIso8601String();

DateTime fromUtcText(String value) => DateTime.parse(value).toUtc();

DateTime? fromNullableUtcText(String? value) {
  if (value == null) {
    return null;
  }
  return fromUtcText(value);
}

ScenarioRecord toScenarioRecord(Row row) => ScenarioRecord(
  id: row['id'] as String,
  name: row['name'] as String,
  description: row['description'] as String?,
  createdAt: fromUtcText(row['created_at'] as String),
);

RunRecord toRunRecord(Row row) => RunRecord(
  id: row['id'] as int,
  scenarioId: row['scenario_id'] as String,
  startedAt: fromUtcText(row['started_at'] as String),
  completedAt: fromNullableUtcText(row['completed_at'] as String?),
  status: row['status'] as String,
);

SimulationEventRecord toSimulationEventRecord(Row row) => SimulationEventRecord(
  id: row['id'] as int,
  runId: row['run_id'] as int,
  eventType: row['event_type'] as String,
  payload: row['payload'] as String,
  occurredAt: fromUtcText(row['occurred_at'] as String),
);

AircraftLogRecord toAircraftLogRecord(Row row) => AircraftLogRecord(
  id: row['id'] as int,
  runId: row['run_id'] as int,
  aircraftId: row['aircraft_id'] as String,
  message: row['message'] as String,
  recordedAt: fromUtcText(row['recorded_at'] as String),
);

MetricsSummaryRecord toMetricsSummaryRecord(Row row) => MetricsSummaryRecord(
  id: row['id'] as int,
  runId: row['run_id'] as int,
  scenarioId: row['scenario_id'] as String,
  stats: SimulationStats(
    averageLandingDelay: (row['average_landing_delay'] as num).toDouble(),
    averageHoldTime: (row['average_hold_time'] as num).toDouble(),
    sectionAverageLandingDelayList: _decodeDelayList(
      row['section_average_landing_delay_list'] as String,
    ),
    averageDepartureDelay: (row['average_departure_delay'] as num).toDouble(),
    averageWaitTime: (row['average_wait_time'] as num).toDouble(),
    sectionAverageDepartureDelayList: _decodeDelayList(
      row['section_average_departure_delay_list'] as String,
    ),
    maxLandingDelay: _asInt(row['max_landing_delay']),
    maxDepartureDelay: _asInt(row['max_departure_delay']),
    maxInboundQueue: row['max_inbound_queue'] as int,
    maxOutboundQueue: row['max_outbound_queue'] as int,
    totalCancellations: row['total_cancellations'] as int,
    totalDiversions: row['total_diversions'] as int,
    totalLandingAircraft: row['total_landing_aircraft'] as int,
    totalDepartingAircraft: row['total_departing_aircraft'] as int,
    runwayUtilisation: (row['runway_utilisation'] as num).toDouble(),
  ),
  createdAt: fromUtcText(row['created_at'] as String),
);

List<double> _decodeDelayList(String jsonText) {
  final decoded = jsonDecode(jsonText) as List<dynamic>;
  return decoded.map((value) => (value as num).toDouble()).toList(growable: false);
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  throw StateError('Expected numeric SQLite value but got: $value');
}
