// interface_runway.dart

import 'package:air_traffic_sim/simulation/enums/runway_mode.dart';
import 'package:air_traffic_sim/simulation/enums/runway_status.dart';

import 'package:air_traffic_sim/simulation/interfaces/interface_aircraft.dart';

/// Interface for runways.
abstract class IRunway {
  int get id;
  int get length;
  int get bearing;
  RunwayStatus get status;
  set status(RunwayStatus newStatus);
  int get nextAvailable;

  /// Returns the mode of the runway when an emergency is present
  RunwayMode mode(bool emergency);
  /// Assigns an aircraft to the runway.
  void assignAircraft(IAircraft a);
}