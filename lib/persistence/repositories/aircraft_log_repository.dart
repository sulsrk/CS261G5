import 'package:air_traffic_sim/persistence/models/aircraft_log_record.dart';
import 'package:sqlite3/sqlite3.dart';

abstract class AircraftLogRepository {
  Future<void> appendLog({
    required Database transaction,
    required int runId,
    required String aircraftId,
    required String message,
    required DateTime recordedAt,
  });

  Future<List<AircraftLogRecord>> listLogsByRun(int runId);
}
