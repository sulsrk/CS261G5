// airport.dart

import 'package:collection/collection.dart'; 
import 'enums.dart';
import 'aircraft.dart';
import 'runway.dart';
import 'interfaces.dart';

class Airport implements IAirport {
  
  // Holding pattern: PriorityQueue
  final PriorityQueue<Aircraft> holdingP;
  
  // Take-off queue: Standard Queue
  final QueueList<Aircraft> takeOffQ;
  
  // List of runways
  final List<Runway> runwayList;

  Airport(List<Runway> runways)
      : runwayList = runways,
        takeOffQ = QueueList<Aircraft>(),
        holdingP = PriorityQueue<Aircraft>((a, b) {
          bool aEmergency = a.isEmergency();
          bool bEmergency = b.isEmergency();

          if (aEmergency && !bEmergency) return -1; // Higher priority
          if (!aEmergency && bEmergency) return 1;

          return a.scheduledTime.compareTo(b.scheduledTime);
        });

  @override
  void addToHolding(Aircraft a) {
    holdingP.add(a);
  }

  @override
  void addToTakeOff(Aircraft a) {
    takeOffQ.add(a);
  }

  @override
  bool isHoldingEmpty() => holdingP.isEmpty;

  @override
  bool isTakeOffEmpty() => takeOffQ.isEmpty;

  @override
  Runway getRunway(int id) {
  }

  @override
  List<Runway> getRunways() => runwayList;

  @override
  bool useRunway(int id, bool emergency) {
    Runway r = getRunway(id);
    if (r.status != RunwayStatus.available) return false;
    return true;
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