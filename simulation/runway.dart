// runway.dart

import 'enums.dart';
import 'aircraft.dart';


abstract class Runway {
  RunwayMode mode(bool emergency);
  void assignAircraft(Aircraft a);


  int get id;
  int get length;
  int get bearing;
  RunwayStatus get status;
  set status(RunwayStatus newStatus);
  int get nextAvailable;
}


abstract class AbstractRunway implements Runway {
  final int _id;
  final int _length;
  final int _bearing;
  
  RunwayStatus runwayStat;
  int nextAvailableR;

  AbstractRunway(this._id, this._length, this._bearing)
      : runwayStat = RunwayStatus.available,
        nextAvailableR = 0;

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

  @override
  void assignAircraft(Aircraft a) {
  }
}


class LandingRunway extends AbstractRunway {
  LandingRunway(int id, int length, int bearing) : super(id, length, bearing);

  @override
  RunwayMode mode(bool emergency) => RunwayMode.landing;
}

class TakeOffRunway extends AbstractRunway {
  TakeOffRunway(int id, int length, int bearing) : super(id, length, bearing);

  @override
  RunwayMode mode(bool emergency) => RunwayMode.takeOff;
}


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