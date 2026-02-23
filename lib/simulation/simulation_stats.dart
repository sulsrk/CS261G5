// simulation_stats.dart

/// stores the metrics of a simulation
class SimulationStats {
  /// Mean delay (in minutes) across all processed landing aircraft.
  final double averageLandingDelay;

  /// Mean delay (in minutes) across all processed departing aircraft.
  final double averageDepartureDelay;

  /// Worst single delay (in minutes) observed for landing aircraft.
  final double maxLandingDelay;

  /// Worst single delay (in minutes) observed for departing aircraft.
  final double maxDepartureDelay;

  final int maxInboundQueue;
  final int maxOutboundQueue;
  final int totalCancellations;
  final int totalDiversions;
  final int totalAircrafts;

  const SimulationStats({
    required this.averageLandingDelay,
    required this.averageDepartureDelay,
    required this.maxLandingDelay,
    required this.maxDepartureDelay,
    required this.maxInboundQueue,
    required this.maxOutboundQueue,
    required this.totalCancellations,
    required this.totalDiversions,
    required this.totalAircrafts,
  });

  factory SimulationStats.empty() {
    return const SimulationStats(
      averageLandingDelay: 0.0,
      averageDepartureDelay: 0.0,
      maxLandingDelay: 0.0,
      maxDepartureDelay: 0.0,
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
