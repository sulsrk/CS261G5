import 'package:air_traffic_sim/persistence/models/simulation_event_record.dart';
import 'package:sqlite3/sqlite3.dart';

abstract class EventRepository {
  Future<void> appendEvent({
    required Database transaction,
    required int runId,
    required String eventType,
    required String payload,
    required DateTime occurredAt,
  });

  Future<List<SimulationEventRecord>> listEventsByRun(int runId);
}
