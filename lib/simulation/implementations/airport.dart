import 'package:collection/collection.dart';
import 'package:air_traffic_sim/simulation/enums/runway_status.dart';
import 'package:air_traffic_sim/simulation/enums/runway_mode.dart';
import 'package:air_traffic_sim/simulation/enums/aircraft_type.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_aircraft.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_airport.dart';
import 'package:air_traffic_sim/simulation/exceptions/aircraft_incompatibility_exception.dart';
import 'package:air_traffic_sim/simulation/exceptions/runway_not_found_exception.dart';
import 'package:air_traffic_sim/simulation/exceptions/runway_unavailable_exception.dart';
import 'package:air_traffic_sim/simulation/implementations/aircraft.dart';

class Airport implements IAirport {
  final PriorityQueue<IAircraft> _holdingPattern;
  final QueueList<IAircraft> _takeOffQueue;
  final List<IRunway> _runways;
  int _currentTime;

  Airport(this._runways)
      : _takeOffQueue = QueueList<IAircraft>(),
        _currentTime = 0,
        _holdingPattern = PriorityQueue<IAircraft>((a, b) {
          bool aEmergency = a.isEmergency();
          bool bEmergency = b.isEmergency();

          if (aEmergency && !bEmergency) return -1;
          if (!aEmergency && bEmergency) return 1;

          return a.getScheduledTime.compareTo(b.getScheduledTime);
        });

  @override
  void addToHolding(IAircraft aircraft) {
    if ((aircraft as Aircraft).getType != AircraftType.landing) {
      throw AircraftIncompatibilityException(
          aircraft.getScheduledTime, 
          "Attempted to add non-landing aircraft to holding pattern."
      );
    }
    _holdingPattern.add(aircraft);
  }

  @override
  void addToTakeOff(IAircraft aircraft) {
    if ((aircraft as Aircraft).getType != AircraftType.takeOff) {
      throw AircraftIncompatibilityException(
          aircraft.getScheduledTime, 
      );
    }
    _takeOffQueue.add(aircraft);
  }

  @override
  bool isHoldingEmpty() => _holdingPattern.isEmpty;

  @override
  bool isTakeOffEmpty() => _takeOffQueue.isEmpty;

  @override
  int useRunway(int id, bool emergency) {
    IRunway? r = getRunway(id);
    
    if (r == null) {
      throw RunwayNotFoundException(id, "Runway with ID $id does not exist.");
    }
    
    if (r.status != RunwayStatus.available) {
      throw RunwayUnavailableException(id, "Runway with ID $id is not available.");
    }

    RunwayMode mode = r.mode(emergency);
    IAircraft assignedAircraft;

    if (mode == RunwayMode.landing) {
      if (isHoldingEmpty()) return 0;
      assignedAircraft = _holdingPattern.removeFirst();
    } else {
      if (isTakeOffEmpty()) return 0;
      assignedAircraft = _takeOffQueue.removeFirst();
    }

    r.assignAircraft(assignedAircraft);
    return _currentTime - assignedAircraft.getScheduledTime;
  }

  @override
  int divert(int fuelThreshold) {
    int divertedCount = 0;
    List<IAircraft> keptAircraft = [];

    while (_holdingPattern.isNotEmpty) {
      IAircraft a = _holdingPattern.removeFirst();
      if (a.getFuelLevel <= fuelThreshold) {
        divertedCount++;
      } else {
        keptAircraft.add(a);
      }
    }

    _holdingPattern.addAll(keptAircraft);
    return divertedCount;
  }

  @override
  int cancel(int waitTime) {
    int cancelledCount = 0;
    List<IAircraft> keptAircraft = [];

    while (_takeOffQueue.isNotEmpty) {
      IAircraft a = _takeOffQueue.removeFirst();
      if ((_currentTime - a.getScheduledTime) >= waitTime) {
        cancelledCount++;
      } else {
        keptAircraft.add(a);
      }
    }

    _takeOffQueue.addAll(keptAircraft);
    return cancelledCount;
  }

  @override
  void update() {
    _currentTime++;

    List<IAircraft> tempHolding = _holdingPattern.toList();
    _holdingPattern.clear();
    
    for (var a in tempHolding) {
      if (a is Aircraft) {
        a.consumeFuel(1);
        a.updateActualTime(_currentTime);
      }
      _holdingPattern.add(a);
    }

    for (var a in _takeOffQueue) {
      if (a is Aircraft) {
        a.updateActualTime(_currentTime);
      }
    }

    for (var r in _runways) {
      if (r.status != RunwayStatus.available) {
        if (r.nextAvailable <= _currentTime) {
          r.open();
        }
      }
    }
  }

  @override
  IRunway? getRunway(int id) {
    return _runways.firstWhereOrNull((r) => r.id == id);
  }

  @override
  List<IRunway> getRunways() => _runways;
}