// simulation_stats.dart

import 'package:air_traffic_sim/simulation/concretes/temp_stats.dart';

/// stores the metrics of a simulation
class SimulationStats {
  final double averageLandingDelay;
  final double averageHoldTime;
  final double averageDepartureDelay;
  final double averageWaitTime;
  final double maxLandingDelay;
  final double maxDepartureDelay;
  final int maxInboundQueue;
  final int maxOutboundQueue;
  final int totalCancellations;
  final int totalDiversions;
  final int totalAircrafts;

  const SimulationStats({
    required this.averageLandingDelay, 
    required this.averageHoldTime,
    required this.averageDepartureDelay, 
    required this.averageWaitTime,
    required this.maxLandingDelay,
    required this.maxDepartureDelay,
    required this.maxInboundQueue,
    required this.maxOutboundQueue,
    required this.totalCancellations,
    required this.totalDiversions,
    required this.totalAircrafts
  });

  SimulationStats.aggr(TempStats s) :
    this(
      averageLandingDelay: s.totalLandingDelay / (s.landingAircraftCount - s.totalDiversions),
      averageHoldTime: s.totalHoldTime / s.landingAircraftCount,
      averageDepartureDelay: s.totalDepartureDelay / (s.departingAircraftCount - s.totalCancellations),
      averageWaitTime: s.totalWaitTime / s.departingAircraftCount,
      maxLandingDelay: s.maxLandingDelay,
      maxDepartureDelay: s.maxDepartureDelay,
      maxInboundQueue: s.maxInboundQueue,
      maxOutboundQueue: s.maxOutboundQueue,
      totalCancellations: s.totalCancellations,
      totalDiversions: s.totalDiversions,
      totalAircrafts: s.departingAircraftCount + s.landingAircraftCount 
    );
  

  factory SimulationStats.empty() {
    return const SimulationStats(
      averageLandingDelay: 0.0, 
      averageHoldTime: 0.0,
      averageDepartureDelay: 0.0, 
      averageWaitTime: 0.0,
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