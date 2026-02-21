import 'package:air_traffic_sim/simulation/interfaces/report.dart';

abstract class ISimulation {
  /// Master method for starting the simulation.
  IReport run();
}