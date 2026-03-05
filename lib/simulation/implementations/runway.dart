import 'package:air_traffic_sim/simulation/enums/runway_mode.dart';
import 'package:air_traffic_sim/simulation/enums/runway_status.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_aircraft.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway.dart';
import 'package:air_traffic_sim/simulation/concretes/sim_clock.dart';

/// Abstract base class handling shared runway logic.
abstract class AbstractRunway implements IRunway {
  final int _id;
  final int _length;
  final int _bearing;
  
  RunwayStatus _status;
  int _nextAvailable;

  AbstractRunway({
    required int id,
    required int length,
    required int bearing,
  })  : _id = id,
        _length = length,
        _bearing = bearing,
        _status = RunwayStatus.available,
        _nextAvailable = 0;

  @override
  int get id => _id;

  @override
  int get length => _length;

  @override
  int get bearing => _bearing;

  @override
  RunwayStatus get status => _status;

  @override
  int get nextAvailable => _nextAvailable;

  @override
  bool get isAvailable => _status == RunwayStatus.available;

  @override
  void assignAircraft(IAircraft aircraft) {
    _status = RunwayStatus.occupied;
    // Occupation is always exactly 1 minute regardless of speed/length
    _nextAvailable = SimulationClock.time + 1;
  }

  @override
  void closeRunway(int duration, RunwayStatus newStatus) {
    if (duration <= 0) {
      throw ArgumentError("Closure duration must be strictly greater than 0.");
    }
    
    if (newStatus == RunwayStatus.available || newStatus.name == 'occupied') {
      throw ArgumentError(
        "A runway cannot be closed with the status ${newStatus.name}."
      );
    }

    _status = newStatus;
    _nextAvailable = SimulationClock.time + duration;
  }

  @override
  void open() {
    // Only open if the current time has actually reached or passed the next available time
    if (SimulationClock.time >= _nextAvailable) {
      _status = RunwayStatus.available;
    }
  }

  // The mode method is left abstract for the specific subclasses to implement.
  @override
  RunwayMode mode([bool emergency = false]);
}


/// Concrete implementation for a runway dedicated solely to landing.
class LandingRunway extends AbstractRunway {
  LandingRunway({required super.id, required super.length, required super.bearing});

  @override
  RunwayMode mode([bool emergency = false]) => RunwayMode.landing;
}


/// Concrete implementation for a runway dedicated solely to take-offs.
class TakeOffRunway extends AbstractRunway {
  TakeOffRunway({required super.id, required super.length, required super.bearing});

  @override
  RunwayMode mode([bool emergency = false]) => RunwayMode.takeOff;
}


/// Concrete implementation for a mixed-use runway that alternates modes.
class MixedRunway extends AbstractRunway {
  bool _isLandingNext = true; // State toggle for alternation

  MixedRunway({required super.id, required super.length, required super.bearing});

  @override
  RunwayMode mode([bool emergency = false]) {
    // Emergency inbound aircraft always force a mixed runway to prioritize landing
    if (emergency) {
      return RunwayMode.landing;
    }
    // Otherwise, report the current alternating state
    return _isLandingNext ? RunwayMode.landing : RunwayMode.takeOff;
  }

  @override
  void assignAircraft(IAircraft aircraft) {
    super.assignAircraft(aircraft); // Handle the 1-minute occupation logic
    
    // Flip the toggle after a successful assignment so the next check uses the opposite mode
    _isLandingNext = !_isLandingNext;
  }
}