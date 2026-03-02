import 'package:air_traffic_sim/simulation/concretes/temp_stats.dart';

/// Stores the metrics of a simulation
class SimulationStats {
  final double averageLandingDelay;
  final double averageHoldTime;
  final List<double> sectionAverageLandingDelayList;
  final double averageDepartureDelay;
  final double averageWaitTime;
  final List<double> sectionAverageDepartureDelayList;
  final int maxLandingDelay;
  final int maxDepartureDelay;
  final int maxInboundQueue;
  final int maxOutboundQueue;
  final int totalCancellations;
  final int totalDiversions;
  final int totalAircrafts;

  const SimulationStats({
    required this.averageLandingDelay, 
    required this.averageHoldTime,
    required this. sectionAverageLandingDelayList,
    required this.averageDepartureDelay, 
    required this.averageWaitTime,
    required this.sectionAverageDepartureDelayList,
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
      sectionAverageLandingDelayList: s.sectionAverageLandingDelayList,
      averageDepartureDelay: s.totalDepartureDelay / (s.departingAircraftCount - s.totalCancellations),
      averageWaitTime: s.totalWaitTime / s.departingAircraftCount,
      sectionAverageDepartureDelayList: s.sectionAverageDepartureDelayList,
      maxLandingDelay: s.maxLandingDelay,
      maxDepartureDelay: s.maxDepartureDelay,
      maxInboundQueue: s.maxInboundQueue,
      maxOutboundQueue: s.maxOutboundQueue,
      totalCancellations: s.totalCancellations,
      totalDiversions: s.totalDiversions,
      totalAircrafts: s.departingAircraftCount + s.landingAircraftCount 
    );
  

  factory SimulationStats.empty() {
    return SimulationStats(
      averageLandingDelay: 0.0, 
      averageHoldTime: 0.0,
      sectionAverageLandingDelayList: List<double>.empty(growable: true),
      averageDepartureDelay: 0.0, 
      averageWaitTime: 0.0,
      sectionAverageDepartureDelayList: List<double>.empty(growable: true),
      maxLandingDelay: 0, 
      maxDepartureDelay: 0,
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