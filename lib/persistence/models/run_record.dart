class RunRecord {
  final int id;
  final String scenarioId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String status;

  const RunRecord({
    required this.id,
    required this.scenarioId,
    required this.startedAt,
    this.completedAt,
    required this.status,
  });
}
