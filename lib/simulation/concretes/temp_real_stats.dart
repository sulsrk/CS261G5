
import 'package:air_traffic_sim/simulation/concretes/temp_stats.dart';

class TempRealStats extends TempStats {
  final double alpha = 0.1; // Smoothing factor 0<=[alpha]<=1. Higher value increases weighting of new values .
  double emAverageLandingDelay = 0.0;
  double emAverageDepatureDelay = 0.0;

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
    }) {
      super.update(
        landingDelay: landingDelay, 
        holdTime: holdTime, 
        departureDelay: departureDelay, 
        waitTime: waitTime, 
        cancellations: cancellations, 
        diversions: diversions, 
        landingAircraft: landingAircraft, 
        departingAircraft: departingAircraft
      );

      // Exponential moving average.

      emAverageLandingDelay = alpha * landingDelay + (1 - alpha) * emAverageLandingDelay;
      emAverageDepatureDelay = alpha * departureDelay + (1 - alpha) * emAverageDepatureDelay;
  }
}