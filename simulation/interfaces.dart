// interfaces.dart

import 'aircraft.dart';
import 'runway.dart';

/// Interface defining Airport operations.
abstract class IAirport {
  void addToHolding(Aircraft a); 
  void addToTakeOff(Aircraft a); 
  bool isHoldingEmpty(); 
  bool isTakeOffEmpty(); 
  Runway getRunway(int id); 
  List<Runway> getRunways(); 
  bool useRunway(int id, bool emergency); 
  void closeRunway(int id, int time);
  void divert(int fuelThreshold);
  void cancel(int waitTime);
}