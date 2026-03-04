import 'package:air_traffic_sim/persistence/database.dart';
import 'package:air_traffic_sim/persistence/models/run_record.dart';
import 'package:air_traffic_sim/persistence/repositories/run_repository.dart';
import 'package:air_traffic_sim/persistence/repositories/sqlite/sqlite_row_mappers.dart';
import 'package:sqlite3/sqlite3.dart';

class SqliteRunRepository implements RunRepository {
  final DatabaseAccessor databaseAccessor;

  const SqliteRunRepository(this.databaseAccessor);

  Database get _db => databaseAccessor.database;

  @override
  Future<T> inTransaction<T>(Future<T> Function(Database transaction) operation) async {
    _db.execute('BEGIN TRANSACTION');

    try {
      final result = await operation(_db);
      _db.execute('COMMIT');
      return result;
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  @override
  Future<int> createRun({
    required Database transaction,
    required String scenarioId,
    required DateTime startedAt,
  }) async {
    transaction.execute(
      'INSERT INTO runs (scenario_id, started_at, status) VALUES (?, ?, ?)',
      [scenarioId, toUtcText(startedAt), 'running'],
    );

    return transaction.select('SELECT last_insert_rowid() AS id').first['id'] as int;
  }

  @override
  Future<void> finalizeRun({
    required Database transaction,
    required int runId,
    required DateTime completedAt,
    required String status,
  }) async {
    transaction.execute(
      'UPDATE runs SET completed_at = ?, status = ? WHERE id = ?',
      [toUtcText(completedAt), status, runId],
    );
  }

  @override
  Future<List<RunRecord>> listRunsByScenario(String scenarioId) async {
    final rows = _db.select(
      '''
      SELECT id, scenario_id, started_at, completed_at, status
      FROM runs
      WHERE scenario_id = ?
      ORDER BY started_at DESC
      ''',
      [scenarioId],
    );

    return rows.map(toRunRecord).toList(growable: false);
  }
}
