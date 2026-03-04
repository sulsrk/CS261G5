import 'package:air_traffic_sim/persistence/database.dart';
import 'package:air_traffic_sim/persistence/models/simulation_event_record.dart';
import 'package:air_traffic_sim/persistence/repositories/event_repository.dart';
import 'package:air_traffic_sim/persistence/repositories/sqlite/sqlite_row_mappers.dart';
import 'package:sqlite3/sqlite3.dart';

class SqliteEventRepository implements EventRepository {
  final DatabaseAccessor databaseAccessor;

  const SqliteEventRepository(this.databaseAccessor);

  @override
  Future<void> appendEvent({
    required Database transaction,
    required int runId,
    required String eventType,
    required String payload,
    required DateTime occurredAt,
  }) async {
    transaction.execute(
      'INSERT INTO events (run_id, event_type, payload, occurred_at) VALUES (?, ?, ?, ?)',
      [runId, eventType, payload, toUtcText(occurredAt)],
    );
  }

  @override
  Future<List<SimulationEventRecord>> listEventsByRun(int runId) async {
    final rows = databaseAccessor.database.select(
      '''
      SELECT id, run_id, event_type, payload, occurred_at
      FROM events
      WHERE run_id = ?
      ORDER BY occurred_at ASC
      ''',
      [runId],
    );

    return rows.map(toSimulationEventRecord).toList(growable: false);
  }
}
