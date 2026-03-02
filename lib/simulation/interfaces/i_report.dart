import 'package:air_traffic_sim/simulation/concretes/simulation_stats.dart';

/// Interface for reports.
abstract class IReport {
  /// Should in some way output the results from a simulation.
  void printSummary();
  /// Returns the statistics summary in CSV .
  String exportCSV();
  /// Returns the statistics summary in CSV .
  void importCSV(String str);
  /// Returns the statistics as a wrapper object compiled by the simulation.
  SimulationStats get getStats;
}