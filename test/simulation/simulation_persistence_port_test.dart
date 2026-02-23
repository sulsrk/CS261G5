import 'package:air_traffic_sim/simulation/interfaces/interface_simulation_persistence_port.dart';
import 'package:air_traffic_sim/simulation/simulation_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Simulation persistence payloads', () {
    test('SimulationRunHandle stores run and scenario identifiers', () {
      final handle = SimulationRunHandle(runId: 42, scenarioId: 'scenario-alpha');

      expect(handle.runId, 42);
      expect(handle.scenarioId, 'scenario-alpha');
    });

    test('SummaryMetricsPayload stores stats and timestamp', () {
      final createdAt = DateTime.utc(2026, 1, 4, 9);
      final payload = SummaryMetricsPayload(
        stats: const SimulationStats(
          averageLandingDelay: 1.2,
            averageDepartureDelay: 1.2,
            maxLandingDelay: 1.2,
            maxDepartureDelay: 1.2,
          maxInboundQueue: 3,
          maxOutboundQueue: 4,
          totalCancellations: 0,
          totalDiversions: 1,
          totalAircrafts: 5,
        ),
        createdAt: createdAt,
      );

      expect(payload.stats.averageLandingDelay, 1.2);
      expect(payload.stats.averageDepartureDelay, 1.2);
      expect(payload.stats.maxLandingDelay, 1.2);
      expect(payload.stats.maxDepartureDelay, 1.2);
      expect(payload.stats.totalAircrafts, 5);
      expect(payload.createdAt, createdAt);
    });
  });
}
