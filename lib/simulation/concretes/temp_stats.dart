/// Wrapper class for temporary aggregation of metrics duration the simulation run.
class TempStats {
  /// 1-1 with [SimulationStats] attributes.
  double maxLandingDelay = 0.0;
  double maxDepartureDelay = 0.0;
  int maxInboundQueue = 0;
  int maxOutboundQueue = 0;
  int totalCancellations = 0;
  int totalDiversions = 0;
  /// Distinct from [SimulationStats] attributes.
  double totalLandingDelay = 0.0;
  double totalHoldTime = 0.0;
  double totalDepartureDelay = 0.0;
  double totalWaitTime = 0.0;
  int landingAircraftCount = 0;
  int departingAircraftCount = 0;
}