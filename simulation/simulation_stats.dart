// simulation_stats.dart

class SimulationStats {
  final double averageDelay;
  final int maxInboundQueue;
  final int maxOutboundQueue;
  final int totalCancellations;
  final int totalDiversions;
  final int totalAircrafts;

  const SimulationStats({
    required this.averageDelay,
    required this.maxInboundQueue,
    required this.maxOutboundQueue,
    required this.totalCancellations,
    required this.totalDiversions,
    required this.totalAircrafts,
  });

  factory SimulationStats.empty() {
    return const SimulationStats(
      averageDelay: 0.0,
      maxInboundQueue: 0,
      maxOutboundQueue: 0,
      totalCancellations: 0,
      totalDiversions: 0,
      totalAircrafts: 0,
    );
  }

  @override
  String toString() {
    return "";
  }
}