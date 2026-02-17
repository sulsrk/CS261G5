// interface_param.dart

import 'dart:collection';

import 'package:air_traffic_sim/simulation/interfaces/interface_runway.dart';
import 'package:air_traffic_sim/simulation/interfaces/interface_runway_event.dart';

abstract class IParamaters {
  ///
  List<IRunway> get runways;
  ///
  double get emergencyProbability;
  ///
  Queue<IRunwayEvent> get events;
}