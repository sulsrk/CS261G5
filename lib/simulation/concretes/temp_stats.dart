/// Wrapper class for temporary aggregation of metrics duration the simulation run.
class TempStats {
  /// 1-1 with [SimulationStats] attributes.
  int maxLandingDelay = 0;
  int maxDepartureDelay = 0;
  int maxInboundQueue = 0;
  int maxOutboundQueue = 0;
  int totalCancellations = 0;
  int totalDiversions = 0;
  List<double> sectionAverageLandingDelayList = List<double>.empty();
  List<double> sectionAverageDepartureDelayList = List<double>.empty();
  /// Distinct from [SimulationStats] attributes.
  int totalLandingDelay = 0;
  int totalSectionLandingDelay = 0;
  int totalHoldTime = 0;
  int totalSectionDepartureDelay = 0;
  int totalDepartureDelay = 0;
  int totalWaitTime = 0;
  int landingAircraftCount = 0;
  int sectionLandingAircraftCount = 0;
  int departingAircraftCount = 0;
  int sectionDepartingAircraftCount = 0;

  // Variables to handle section delay.
  int _counter = 0;           // Number of intervals in current section.
  final int _sectionSize = 10; // The section size.

  /// Updates the statistics with data from the new interval.
  void update({
    required int landingDelay,
    required int holdTime,

    required int departureDelay,
    required int waitTime,

    required int cancellations,
    required int diversions,

    required int landingAircraft,
    required int departingAircraft,
    }) {

      // Maximums.

      maxLandingDelay = landingDelay > maxLandingDelay ? landingDelay : maxLandingDelay;
      maxDepartureDelay = departureDelay > maxDepartureDelay ? departureDelay : maxDepartureDelay;

      maxInboundQueue = landingAircraft > maxInboundQueue ? landingAircraft : maxInboundQueue;
      maxOutboundQueue = departingAircraft > maxOutboundQueue ? departingAircraft : maxOutboundQueue;

      // Totals.

      totalCancellations += cancellations;
      totalDiversions += diversions;

      totalLandingDelay += landingDelay;
      totalSectionLandingDelay += landingDelay;
      totalDepartureDelay += departureDelay;
      totalSectionDepartureDelay += departureDelay;

      totalWaitTime += waitTime;
      totalHoldTime += holdTime;

      landingAircraftCount += landingAircraft;
      sectionLandingAircraftCount += landingAircraft;
      departingAircraftCount += departingAircraft;
      sectionDepartingAircraftCount += departingAircraft;

      // Section average accumulation.

      if (++_counter >= _sectionSize) { // If end of section has been reached.
        // Add the section's delays to the lists.
        sectionAverageLandingDelayList.add(totalSectionLandingDelay / sectionLandingAircraftCount);
        sectionAverageDepartureDelayList.add(totalSectionDepartureDelay / sectionDepartingAircraftCount);
        // Reset the summations and counts.
        totalSectionDepartureDelay = 0;
        totalSectionLandingDelay = 0;
        sectionDepartingAircraftCount = 0;
        sectionLandingAircraftCount = 0;
        // Reset the counter.
        _counter = 0;
      }

    }
}