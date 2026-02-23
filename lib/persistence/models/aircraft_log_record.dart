class AircraftLogRecord {
  final int id;
  final int runId;
  final String aircraftId;
  final String message;
  final DateTime recordedAt;

  const AircraftLogRecord({
    required this.id,
    required this.runId,
    required this.aircraftId,
    required this.message,
    required this.recordedAt,
  });
}
