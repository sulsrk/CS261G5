import 'package:air_traffic_sim/persistence/models/metrics_summary_record.dart';
import 'package:air_traffic_sim/simulation/simulation_stats.dart';
import 'package:sqlite3/sqlite3.dart';

abstract class MetricsSummaryRepository {
  /// Inserts or updates one metrics summary for [runId] within [transaction].
  ///
  /// [stats] must contain non-negative delay/queue/counter values that satisfy
  /// database CHECK constraints.
  Future<void> insertSummary({
    required Database transaction,
    required int runId,
    required SimulationStats stats,
    required DateTime createdAt,
  });

  /// Returns all summaries for runs belonging to [scenarioId], newest first.
  Future<List<MetricsSummaryRecord>> listSummariesByScenario(String scenarioId);

  /// Returns the summary for [runId] or null when no summary has been published.
  Future<MetricsSummaryRecord?> getSummaryByRun(int runId);
}
