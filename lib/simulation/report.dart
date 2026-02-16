// report.dart

import 'package:air_traffic_sim/simulation/interfaces/interface_report.dart';
import 'package:air_traffic_sim/simulation/simulation_stats.dart';

/// represents the output of a simulation's execution
class Report implements IReport {
  
  final SimulationStats stats;

  // Constructors

  Report(this.stats);

  // Methods

  @override
  void printSummary() {
  }

  @override
  String exportCSV() {
    return "";
  }
}