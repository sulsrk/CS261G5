// interface_simulation_controller.dart

import 'dart:collection';

import 'package:air_traffic_sim/simulation/interfaces/interface_airport.dart';
import 'package:air_traffic_sim/simulation/interfaces/interface_runway_event.dart';

abstract class ISimulationController {
  ///
  void update();
  ///
  void includeEnteringAircraft(IAirport airport);
  ///
  void startRunwayEvents(Queue<IRunwayEvent> events, IAirport airport);
}