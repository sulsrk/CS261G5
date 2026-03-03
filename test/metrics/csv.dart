import 'package:air_traffic_sim/simulation/concretes/simulation_stats.dart';
import 'package:air_traffic_sim/simulation/exceptions/corrupt_csv_exception.dart';
import 'package:air_traffic_sim/simulation/implementations/report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Importing and exporting scenario data', () {
    test('Export valid data to a CSV string', () {
      final stats = SimulationStats(
        averageLandingDelay: 1.1,
        averageDepartureDelay: 1.2,
        averageHoldTime: 1.3,
        averageWaitTime: 1.4,
        sectionAverageDepartureDelayList: List<double>.filled(3,1.5, growable: true),
        sectionAverageLandingDelayList: List.filled(3,1.6, growable: true),
        maxLandingDelay: 1,
        maxDepartureDelay: 2,
        maxInboundQueue: 3,
        maxOutboundQueue: 4,
        totalCancellations: 0,
        totalDiversions: 6,
        totalLandingAircraft: 5,
				totalDepartingAircraft: 7,
      );
      final Report report = Report(simulationStats: stats);
      String csv = report.exportCSV();
      expect(csv, "3,1.6,1.6,1.6,1.5,1.5,1.5,1.1,1.3,1.2,1.4,1,2,3,4,0,6,5,7");
    });

    test('Import valid data from a CSV string', () {
      final String csv = "3,1.6,1.6,1.6,1.5,1.5,1.5,1.1,1.3,1.2,1.4,1,2,3,4,0,6,5,7";
      Report report = Report(simulationStats: SimulationStats.empty())..importCSV(csv);
      expect(report.getStats.averageLandingDelay, 1.1);
      expect(report.getStats.averageDepartureDelay, 1.2);
      expect(report.getStats.averageHoldTime, 1.3);
      expect(report.getStats.averageWaitTime, 1.4);
      expect(report.getStats.sectionAverageDepartureDelayList.length, 3);
      expect(report.getStats.sectionAverageLandingDelayList.length, 3);
      for (int i = 0; i < 3; i++){
        expect(report.getStats.sectionAverageDepartureDelayList[i], 1.5);
        expect(report.getStats.sectionAverageLandingDelayList[i], 1.6);
      } 
      expect(report.getStats.maxLandingDelay, 1);
      expect(report.getStats.maxDepartureDelay, 2);
      expect(report.getStats.maxInboundQueue, 3);
      expect(report.getStats.maxOutboundQueue, 4);
      expect(report.getStats.totalCancellations, 0);
      expect(report.getStats.totalDiversions, 6);
      expect(report.getStats.totalLandingAircraft, 5);
	  	expect(report.getStats.totalDepartingAircraft, 7);

    });

    test('Import invalid data from a CSV string', () {
      final String csv = "3,1.6,1.6,,1.6,1.6,1.5,1.5,1.5,1.1,1.3,1.2,1.4,1,2,3,4,0,6,5,7"; // invalid landing delay list length
      Report report = Report(simulationStats: SimulationStats.empty());
      expect(() => report.importCSV(csv), throwsA(isA<CorruptCsvException>()));
    });
  });
}
