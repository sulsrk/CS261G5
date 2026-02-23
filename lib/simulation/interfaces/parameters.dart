import 'dart:collection';

import 'runway.dart';
import 'runway_event.dart';

/// Interface for obtaining entered parameters for a general simulation.
abstract class IParameters {

  /// Getters
  
  List<IRunway> get getRunways;
  double get getEmergencyProbability;
  Queue<IRunwayEvent> get getEvents;
  int get getMaxWaitTime;
  int get getDuration;
}