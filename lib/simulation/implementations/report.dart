
import 'package:air_traffic_sim/simulation/concretes/simulation_stats.dart';
import 'package:air_traffic_sim/simulation/exceptions/corrupt_csv_exception.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_report.dart';

class Report extends IReport {

  SimulationStats _simulationStats;

  Report({required SimulationStats simulationStats}) : _simulationStats = simulationStats;

  @override
  SimulationStats get getStats => _simulationStats ;

  @override
  void printSummary() {
    // TODO: implement printSummary
  }

  @override
  String exportCSV() {
    return [
		_simulationStats.sectionAverageLandingDelayList.length, // Same length for both lists so only need to store one length.
		..._simulationStats.sectionAverageLandingDelayList,
		..._simulationStats.sectionAverageDepartureDelayList,
		_simulationStats.averageLandingDelay,
		_simulationStats.averageHoldTime,
		_simulationStats.averageDepartureDelay,
		_simulationStats.averageWaitTime,
		_simulationStats.maxLandingDelay,
		_simulationStats.maxDepartureDelay,
		_simulationStats.maxInboundQueue,
		_simulationStats.maxOutboundQueue,
		_simulationStats.totalCancellations,
		_simulationStats.totalDiversions,
		_simulationStats.totalAircrafts,
    ].join(',');
  }

  @override
void importCSV(String str) {
		int i = 0; // Current element index. Outside of try to report the location of any failures.
		try {
			List<String> data = str.split(',');

			// Construct lists of section averages.

			int length = int.parse(data[i++]);
			// Section averages for landing delays.
			List<double> sectionAverageLandingDelayList = List<double>.empty(growable: true);
			for (var j = 0; j < length; j++) {
				sectionAverageLandingDelayList.add(double.parse(data[i++]));
			}
			// Section averages for departure delays.
			List<double> sectionAverageDepartureDelayList = List<double>.empty(growable: true);
			for (var j = 0; j < length; j++) {
				sectionAverageDepartureDelayList.add(double.parse(data[i++]));
			}
			// Reinitialise simulation statistics.

			_simulationStats = SimulationStats(
				averageLandingDelay: double.parse(data[i++]), 
				averageHoldTime: double.parse(data[i++]), 
				averageDepartureDelay: double.parse(data[i++]), 
				averageWaitTime: double.parse(data[i++]), 
				maxLandingDelay: int.parse(data[i++]), 
				maxDepartureDelay: int.parse(data[i++]), 
				maxInboundQueue: int.parse(data[i++]), 
				maxOutboundQueue: int.parse(data[i++]), 
				totalCancellations: int.parse(data[i++]),
				totalDiversions: int.parse(data[i++]), 
				totalAircrafts: int.parse(data[i++]),
				sectionAverageLandingDelayList: sectionAverageLandingDelayList,
				sectionAverageDepartureDelayList: sectionAverageDepartureDelayList,  
			);
			
			if (i != data.length) throw Exception("Excess data in csv"); // Checks that CSV data was the correct length.

		} catch (e) {
			throw CorruptCsvException(i, "CSV file is corrupted. Failed at index $i");
		}
  }
}