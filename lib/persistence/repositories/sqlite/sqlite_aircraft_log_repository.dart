import 'package:air_traffic_sim/persistence/database.dart';
import 'package:air_traffic_sim/persistence/models/aircraft_log_record.dart';
import 'package:air_traffic_sim/persistence/repositories/aircraft_log_repository.dart';
import 'package:air_traffic_sim/persistence/repositories/sqlite/sqlite_row_mappers.dart';
import 'package:sqlite3/sqlite3.dart';

class SqliteAircraftLogRepository implements AircraftLogRepository {
  final DatabaseAccessor databaseAccessor;

  const SqliteAircraftLogRepository(this.databaseAccessor);

  @override
  Future<void> appendLog({
    required Database transaction,
    required int runId,
    required String aircraftId,
    required String message,
    required DateTime recordedAt,
  }) async {
    transaction.execute(
      'INSERT INTO aircraft_logs (run_id, aircraft_id, message, recorded_at) VALUES (?, ?, ?, ?)',
      [runId, aircraftId, message, toUtcText(recordedAt)],
    );
  }

  @override
  Future<List<AircraftLogRecord>> listLogsByRun(int runId) async {
    final rows = databaseAccessor.database.select(
      '''
      SELECT id, run_id, aircraft_id, message, recorded_at
      FROM aircraft_logs
      WHERE run_id = ?
      ORDER BY recorded_at ASC
      ''',
      [runId],
    );

    return rows.map(toAircraftLogRecord).toList(growable: false);
  }
}
