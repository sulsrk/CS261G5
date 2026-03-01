
import 'package:air_traffic_sim/simulation/concretes/simulation_stats.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_report.dart';

class Report extends IReport {

  final SimulationStats _simulationStats;

  Report({required SimulationStats simulationStats}) : _simulationStats = simulationStats;

  @override
  SimulationStats get getStats => _simulationStats;

  @override
  void printSummary() {
    // TODO: implement printSummary
  }

  @override
  String exportCSV() {
    // TODO: implement exportCSV
    StringBuffer acc;
    
  }

  @override
  void importCSV(String data) {
    // TODO: implement exportCSV
    StringBuffer acc;
  }
}