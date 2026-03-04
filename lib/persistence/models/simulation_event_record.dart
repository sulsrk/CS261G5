class SimulationEventRecord {
  final int id;
  final int runId;
  final String eventType;
  final String payload;
  final DateTime occurredAt;

  const SimulationEventRecord({
    required this.id,
    required this.runId,
    required this.eventType,
    required this.payload,
    required this.occurredAt,
  });
}
