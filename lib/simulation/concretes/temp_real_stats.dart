
import 'package:air_traffic_sim/simulation/concretes/temp_stats.dart';

class TempRealStats extends TempStats {
  final double alpha = 0.1; // Smoothing factor 0<=[alpha]<=1. Higher value increases weighting of new values .
  double? _emAverageLandingDelay;
  double? _emAverageDepatureDelay;

  // Return 0 if null. Used to set first value to the average.
  double get emAverageLandingDelay => _emAverageLandingDelay ?? 0.0;
  double get emAverageDepatureDelay => _emAverageDepatureDelay ?? 0.0;

  @override
  void update({
    required int landingDelay,
    required int holdTime,

    required int departureDelay,
    required int waitTime,

    required int cancellations,
    required int diversions,

    required int landingAircraft,
    required int departingAircraft,

    required int runwaysUsed,
    required int availableRunways,
    }) {
      super.update(
        landingDelay: landingDelay, 
        holdTime: holdTime, 
        departureDelay: departureDelay, 
        waitTime: waitTime, 
        cancellations: cancellations, 
        diversions: diversions, 
        landingAircraft: landingAircraft, 
        departingAircraft: departingAircraft,
        runwaysUsed: runwaysUsed,
        availableRunways: availableRunways,
      );

      // Exponential moving average.
      
      double averageLanding = landingDelay / landingAircraft;
      double averageDeparture = departureDelay / departingAircraft;

      if (_emAverageLandingDelay != null) { // if not the first data point, apply the exponential moving average
        _emAverageLandingDelay = alpha * averageLanding + (1 - alpha) * emAverageLandingDelay;
        _emAverageDepatureDelay = alpha * averageDeparture + (1 - alpha) * emAverageDepatureDelay;
      } else {
        _emAverageLandingDelay = averageLanding;
        _emAverageDepatureDelay = averageDeparture;
      }
  }
}