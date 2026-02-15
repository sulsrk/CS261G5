// report.dart

import 'simulation_stats.dart';

abstract class IReport {
  void printSummary();

  String exportCSV();
}

class Report implements IReport {
  final SimulationStats _stats;

  Report(this._stats);

  SimulationStats get stats => _stats;

  @override
  void printSummary() {

  }

  @override
  String exportCSV() {
    return "";
  }
}