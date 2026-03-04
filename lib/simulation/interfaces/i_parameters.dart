import 'dart:collection';

import 'i_runway.dart';
import 'i_runway_event.dart';

/// Interface for obtaining entered parameters for a general simulation.
abstract class IParameters {

  /// Getters
  
  List<IRunway> get getRunways;
  double get getEmergencyProbability;
  Queue<IRunwayEvent> get getEvents;
  int get getMaxWaitTime;
  int get getMinFuelThreshold;
  int get getDuration;
}