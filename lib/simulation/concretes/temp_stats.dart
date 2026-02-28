/// Wrapper class for temporary aggregation of metrics duration the simulation run.
class TempStats {
  /// 1-1 with [SimulationStats] attributes.
  int maxLandingDelay = 0;
  int maxDepartureDelay = 0;
  int maxInboundQueue = 0;
  int maxOutboundQueue = 0;
  int totalCancellations = 0;
  int totalDiversions = 0;
  /// Distinct from [SimulationStats] attributes.
  int totalLandingDelay = 0;
  int totalHoldTime = 0;
  int totalDepartureDelay = 0;
  int totalWaitTime = 0;
  int landingAircraftCount = 0;
  int departingAircraftCount = 0;
}