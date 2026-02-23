import 'package:air_traffic_sim/persistence/models/run_record.dart';
import 'package:sqlite3/sqlite3.dart';

abstract class RunRepository {
  Future<T> inTransaction<T>(Future<T> Function(Database transaction) operation);

  Future<int> createRun({
    required Database transaction,
    required String scenarioId,
    required DateTime startedAt,
  });

  Future<void> finalizeRun({
    required Database transaction,
    required int runId,
    required DateTime completedAt,
    required String status,
  });

  Future<List<RunRecord>> listRunsByScenario(String scenarioId);
}
