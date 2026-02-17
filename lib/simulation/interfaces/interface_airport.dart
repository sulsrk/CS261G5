// interface_airport.dart

import 'package:air_traffic_sim/simulation/interfaces/interface_aircraft.dart';
import 'package:air_traffic_sim/simulation/interfaces/interface_runway.dart';

/// Interface defining Airport operations.
abstract class IAirport {
  void addToHolding(IAircraft a); 
  void addToTakeOff(IAircraft a); 
  bool isHoldingEmpty(); 
  bool isTakeOffEmpty(); 
  IRunway? getRunway(int id); 
  List<IRunway> getRunways(); 
  bool useRunway(int id, bool emergency); 
  void closeRunway(int id, int time);
  void divert(int fuelThreshold);
  void cancel(int waitTime);
}