// runway.dart

import 'package:air_traffic_sim/simulation/enums/runway_mode.dart';
import 'package:air_traffic_sim/simulation/enums/runway_status.dart';
import 'package:air_traffic_sim/simulation/interfaces/interface_aircraft.dart';
import 'package:air_traffic_sim/simulation/interfaces/interface_runway.dart';

/// Representation of a general runway.
abstract class AbstractRunway implements IRunway {
  
  final int _id;
  final int _length;
  final int _bearing;
  
  RunwayStatus runwayStat;
  int nextAvailableR;

  // Constructors

  AbstractRunway(this._id, this._length, this._bearing)
      : runwayStat = RunwayStatus.available,
        nextAvailableR = 0;

  // Getters and Setters

  @override
  int get id => _id;

  @override
  int get length => _length;

  @override
  int get bearing => _bearing; 

  @override
  RunwayStatus get status => runwayStat;

  @override
  set status(RunwayStatus newStatus) {
    runwayStat = newStatus;
  }

  @override
  int get nextAvailable => nextAvailableR;

  // Methods

  @override
  void assignAircraft(IAircraft a) {
  }
}

/// Represents a runway for landing operations only
class LandingRunway extends AbstractRunway {

  LandingRunway(super.id, super.length, super.bearing);

  @override
  RunwayMode mode(bool emergency) => RunwayMode.landing;
}

/// Represents a runway for take-off operations only
class TakeOffRunway extends AbstractRunway {

  TakeOffRunway(super.id, super.length, super.bearing);

  @override
  RunwayMode mode(bool emergency) => RunwayMode.takeOff;
}

/// Represents a runway for both landing operations and take-off operations
class MixedRunway extends AbstractRunway {
  bool _toggle;

  MixedRunway(super.id, super.length, super.bearing) 
      : _toggle = false;

  @override
  RunwayMode mode(bool emergency) {
    if (emergency) return RunwayMode.landing;
    return _toggle ? RunwayMode.takeOff : RunwayMode.landing;
  }

  void toggleMode() {
    _toggle = !_toggle;
  }
}