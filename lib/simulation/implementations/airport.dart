import 'package:collection/collection.dart';
import 'package:air_traffic_sim/simulation/enums/runway_status.dart';
import 'package:air_traffic_sim/simulation/enums/runway_mode.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_aircraft.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_airport.dart';
import 'package:air_traffic_sim/simulation/exceptions/aircraft_incompatibility_exception.dart';
import 'package:air_traffic_sim/simulation/exceptions/runway_not_found_exception.dart';
import 'package:air_traffic_sim/simulation/exceptions/runway_unavailable_exception.dart';
import 'package:air_traffic_sim/simulation/implementations/aircraft.dart'; 
import 'package:air_traffic_sim/simulation/concretes/sim_clock.dart'; 

class Airport implements IAirport {
  final PriorityQueue<IAircraft> _holdingPattern;
  final QueueList<IAircraft> _takeOffQueue;
  final List<IRunway> _runways;

  Airport(this._runways)
      : _takeOffQueue = QueueList<IAircraft>(),
        _holdingPattern = PriorityQueue<IAircraft>((a, b) {
          bool aEmergency = a.isEmergency();
          bool bEmergency = b.isEmergency();

          if (aEmergency && !bEmergency) return -1;
          if (!aEmergency && bEmergency) return 1;

          return a.getScheduledTime.compareTo(b.getScheduledTime);
        });

  @override
  void addToHolding(IAircraft aircraft) {
    if (aircraft is! InboundAircraft) {
      throw AircraftIncompatibilityException(
          aircraft.getScheduledTime, 
          "Attempted to add a non-landing aircraft to the holding pattern."
      );
    }
    _holdingPattern.add(aircraft);
  }

  @override
  void addToTakeOff(IAircraft aircraft) {
    if (aircraft is! OutboundAircraft) {
      throw AircraftIncompatibilityException(
          aircraft.getScheduledTime, 
          "Attempted to add a non-takeOff aircraft to the take-off queue."
      );
    }
    _takeOffQueue.add(aircraft);
  }

  @override
  bool get isHoldingEmpty => _holdingPattern.isEmpty;

  @override
  bool get isTakeOffEmpty => _takeOffQueue.isEmpty;

  @override
  IAircraft get firstInHolding => _holdingPattern.first;

  @override
  IAircraft get firstInTakeOff => _takeOffQueue.first;

  @override
  int get getHoldingCount => _holdingPattern.length;

  @override
  int get getTakeOffCount => _takeOffQueue.length;

  @override
  bool get hasEmergency {
    if (_holdingPattern.isEmpty) return false;
    return _holdingPattern.first.isEmergency();
  }

  @override
  int useRunway(int id, [bool emergency = false]) {
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
      if (isHoldingEmpty) return 0; 
      assignedAircraft = _holdingPattern.removeFirst();
    } else {
      if (isTakeOffEmpty) return 0; 
      assignedAircraft = _takeOffQueue.removeFirst();
    }

    r.assignAircraft(assignedAircraft);
    // Delay calculation
    return SimulationClock.time - assignedAircraft.getScheduledTime; 
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
      if ((SimulationClock.time - a.getScheduledTime) >= waitTime) {
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
    // Update Holding Pattern (Fuel consumption)
    List<IAircraft> tempHolding = _holdingPattern.toList();
    _holdingPattern.clear();
    
    for (var a in tempHolding) {
      if (a is RAircraft) {
        a.consumeFuel(1);
      }
      _holdingPattern.add(a);
    }


    // Update Runways (Check for expired closures/maintenance)
    for (var r in _runways) {
      if (r.status != RunwayStatus.available) {
        if (r.nextAvailable <= SimulationClock.time) {
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
  List<IRunway> get getRunways => _runways;
}