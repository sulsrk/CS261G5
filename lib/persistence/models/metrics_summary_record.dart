import 'package:air_traffic_sim/simulation/simulation_stats.dart';

class MetricsSummaryRecord {
  final int id;
  final int runId;
  final String scenarioId;
  final SimulationStats stats;
  final DateTime createdAt;

  const MetricsSummaryRecord({
    required this.id,
    required this.runId,
    required this.scenarioId,
    required this.stats,
    required this.createdAt,
  });
}
