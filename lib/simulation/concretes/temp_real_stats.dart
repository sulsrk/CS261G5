
import 'package:air_traffic_sim/simulation/concretes/temp_stats.dart';
import 'package:air_traffic_sim/simulation/enums/aircraft_type.dart';

class TempRealStats extends TempStats {
  final double alpha = 0.1; // Smoothing factor 0<=[alpha]<=1. Higher value increases weighting of new values .
  double? _emAverageLandingDelay;
  double? _emAverageDepatureDelay;

  // Return 0 if null. Used to set first value to the average.
  double get emAverageLandingDelay => _emAverageLandingDelay ?? 0.0;
  double get emAverageDepatureDelay => _emAverageDepatureDelay ?? 0.0;


  /// updates exponential moving average
  void updateMovingAverage({
      required double delay,
      required AircraftType type,
    }) {
    switch (type) {
      case AircraftType.landing:
        if (_emAverageLandingDelay != null) { // if not the first data point, apply the exponential moving average
          _emAverageLandingDelay = alpha * delay + (1 - alpha) * emAverageLandingDelay;
        } else {
          _emAverageLandingDelay = delay;
        }
      case AircraftType.takeOff:
        if (_emAverageDepatureDelay != null) { // if not the first data point, apply the exponential moving average
          _emAverageDepatureDelay = alpha * delay + (1 - alpha) * emAverageDepatureDelay;
        } else {
          _emAverageDepatureDelay = delay;
        }
    }
  }
}