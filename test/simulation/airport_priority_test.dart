import 'package:air_traffic_sim/simulation/enums/aircraft_type.dart';
import 'package:air_traffic_sim/simulation/enums/emergency_status.dart';
import 'package:air_traffic_sim/simulation/implementations/aircraft.dart';
import 'package:air_traffic_sim/simulation/implementations/airport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Airport holding-pattern priority', () {
    // Helper used to keep setup concise in each test.
    Aircraft landingAircraft({
      required String id,
      required int scheduledTime,
      EmergencyStatus status = EmergencyStatus.none,
    }) {
      return Aircraft(
        id: id,
        scheduledTime: scheduledTime,
        fuelLevel: 10,
        status: status,
        flightOperator: 'TEST',
        origin: 'AAA',
        destination: 'BBB',
        altitude: 3000,
        type: AircraftType.landing,
      );
    }

    test('prioritises emergency aircraft over non-emergency aircraft', () {
      final airport = Airport([]);
      final normal = landingAircraft(id: 'N-1', scheduledTime: 1);
      final emergency = landingAircraft(
        id: 'E-1',
        scheduledTime: 5,
        status: EmergencyStatus.fuel,
      );

      airport.addToHolding(normal);
      airport.addToHolding(emergency);

      // Emergency traffic should take precedence, even with a later schedule.
      expect(airport.firstInHolding.getId, emergency.getId);
    });

    test('orders aircraft with same emergency level by earliest scheduled time', () {
      final airport = Airport([]);
      final later = landingAircraft(id: 'L-1', scheduledTime: 10);
      final earlier = landingAircraft(id: 'E-1', scheduledTime: 2);

      airport.addToHolding(later);
      airport.addToHolding(earlier);

      // When emergency status is equal, the earlier schedule should win.
      expect(airport.firstInHolding.getId, earlier.getId);
    });

    test('does not rank different emergency types against each other beyond schedule', () {
      final airport = Airport([]);
      final healthEmergency = landingAircraft(
        id: 'H-1',
        scheduledTime: 8,
        status: EmergencyStatus.health,
      );
      final mechanicalEmergency = landingAircraft(
        id: 'M-1',
        scheduledTime: 3,
        status: EmergencyStatus.mechanical,
      );

      airport.addToHolding(healthEmergency);
      airport.addToHolding(mechanicalEmergency);

      // Different emergency categories are treated equally; schedule breaks the tie.
      expect(airport.firstInHolding.getId, mechanicalEmergency.getId);
    });
  });
}
