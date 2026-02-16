// airport.dart

import 'package:air_traffic_sim/simulation/enums/runway_status.dart';

import 'package:air_traffic_sim/simulation/interfaces/interface_aircraft.dart';
import 'package:air_traffic_sim/simulation/interfaces/interface_runway.dart';
import 'package:air_traffic_sim/simulation/interfaces/interface_airport.dart';
import 'package:air_traffic_sim/simulation/outbound_aircraft.dart';

import 'package:collection/collection.dart'; 

class Airport implements IAirport {
  
  // Holding pattern: PriorityQueue
  final PriorityQueue<IAircraft> holdingP;
  
  // Take-off queue: Standard Queue
  final QueueList<IAircraft> takeOffQ;
  
  // List of runways
  final List<IRunway> runwayList;

  Airport(List<IRunway> runways)
      : runwayList = runways,
        takeOffQ = QueueList<IAircraft>(),
        holdingP = PriorityQueue<IAircraft>((a, b) {
          bool aEmergency = a.isEmergency();
          bool bEmergency = b.isEmergency();

          if (aEmergency && !bEmergency) return -1; // Higher priority
          if (!aEmergency && bEmergency) return 1;

          return (a as OutboundAircraft).scheduledTime.compareTo((b as OutboundAircraft).scheduledTime);
        });

  @override
  void addToHolding(IAircraft a) {
    holdingP.add(a);
  }

  @override
  void addToTakeOff(IAircraft a) {
    takeOffQ.add(a);
  }

  @override
  bool isHoldingEmpty() => holdingP.isEmpty;

  @override
  bool isTakeOffEmpty() => takeOffQ.isEmpty;

  @override
  IRunway? getRunway(int id) {
    return null;
  }

  @override
  List<IRunway> getRunways() => runwayList;

  @override
  bool useRunway(int id, bool emergency) {
    IRunway? r = getRunway(id);
    if (r == null) return false;
    return r.status == RunwayStatus.available;
  }

  @override
  void closeRunway(int id, int time) {
  }

  @override
  void divert(int fuelThreshold) {
  }

  @override
  void cancel(int waitTime) {
   
  }
}