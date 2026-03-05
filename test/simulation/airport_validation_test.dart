import 'package:air_traffic_sim/simulation/enums/aircraft_type.dart';
import 'package:air_traffic_sim/simulation/enums/emergency_status.dart';
import 'package:air_traffic_sim/simulation/enums/runway_mode.dart';
import 'package:air_traffic_sim/simulation/enums/runway_status.dart';
import 'package:air_traffic_sim/simulation/exceptions/aircraft_incompatibility_exception.dart';
import 'package:air_traffic_sim/simulation/exceptions/runway_not_found_exception.dart';
import 'package:air_traffic_sim/simulation/exceptions/runway_unavailable_exception.dart';
import 'package:air_traffic_sim/simulation/implementations/aircraft.dart';
import 'package:air_traffic_sim/simulation/implementations/airport.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_aircraft.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Airport validation and state transitions', () {
    // Builds a deterministic runway so each scenario stays focused.
    _FakeRunway runway({
      int id = 1,
      RunwayStatus status = RunwayStatus.available,
      RunwayMode normalMode = RunwayMode.takeOff,
      int nextAvailable = 0,
    }) {
      return _FakeRunway(
        id: id,
        status: status,
        normalMode: normalMode,
        nextAvailable: nextAvailable,
      );
    }

    // Helper for landing-aircraft test data.
    Aircraft landingAircraft({
      required String id,
      required int scheduledTime,
      int fuelLevel = 10,
      EmergencyStatus status = EmergencyStatus.none,
    }) {
      return Aircraft(
        id: id,
        scheduledTime: scheduledTime,
        fuelLevel: fuelLevel,
        status: status,
        flightOperator: 'TEST',
        origin: 'AAA',
        destination: 'BBB',
        altitude: 3000,
        type: AircraftType.landing,
      );
    }

    // Helper for takeoff-aircraft test data.
    Aircraft takeOffAircraft({
      required String id,
      required int scheduledTime,
    }) {
      return Aircraft(
        id: id,
        scheduledTime: scheduledTime,
        fuelLevel: 100,
        flightOperator: 'TEST',
        origin: 'AAA',
        destination: 'BBB',
        altitude: 0,
        type: AircraftType.takeOff,
      );
    }

    test('rejects incompatible aircraft types for each queue', () {
      final airport = Airport([runway()]);
      final landing = landingAircraft(id: 'L-1', scheduledTime: 0);
      final takeOff = takeOffAircraft(id: 'T-1', scheduledTime: 0);

      // Landing traffic should be rejected from the takeoff queue.
      expect(
        () => airport.addToTakeOff(landing),
        throwsA(isA<AircraftIncompatibilityException>()),
      );

      // Takeoff traffic should be rejected from the landing holding pattern.
      expect(
        () => airport.addToHolding(takeOff),
        throwsA(isA<AircraftIncompatibilityException>()),
      );
    });

    test('throws domain exceptions for missing and unavailable runways', () {
      final unavailableRunway = runway(status: RunwayStatus.inspection);
      final airport = Airport([unavailableRunway]);

      // Unknown runway IDs should return a not-found domain error.
      expect(
        () => airport.useRunway(99, false),
        throwsA(isA<RunwayNotFoundException>()),
      );

      // A real runway that is closed should return an unavailable error.
      expect(
        () => airport.useRunway(unavailableRunway.id, false),
        throwsA(isA<RunwayUnavailableException>()),
      );
    });

    test('returns zero delay when runway mode queue is empty', () {
      final takeoffRunway = runway(normalMode: RunwayMode.takeOff);
      final airport = Airport([takeoffRunway]);

      // If the selected queue is empty, using the runway should be a no-op.
      final delay = airport.useRunway(takeoffRunway.id, false);

      expect(delay, 0);
      expect(takeoffRunway.assignedAircraft, isNull);
    });

    test('assigns aircraft and computes delay from current simulation time', () {
      final landingRunway = runway(normalMode: RunwayMode.landing);
      final airport = Airport([landingRunway]);
      final aircraft = landingAircraft(id: 'L-2', scheduledTime: 2, fuelLevel: 12);
      airport.addToHolding(aircraft);

      // Advance the simulation clock to time=3 before assigning the aircraft.
      airport.update();
      airport.update();
      airport.update();

      final delay = airport.useRunway(landingRunway.id, false);

      // Delay is measured as current time minus scheduled time (3 - 2 = 1).
      expect(delay, 1);
      expect(landingRunway.assignedAircraft?.getId, aircraft.getId);
      expect(airport.getHoldingCount, 0);
    });

    test('divert and cancel only remove aircraft that cross configured thresholds', () {
      final airport = Airport([runway()]);

      // One aircraft is below fuel threshold and should be diverted; one should remain.
      airport.addToHolding(landingAircraft(id: 'L-low', scheduledTime: 0, fuelLevel: 2));
      airport.addToHolding(landingAircraft(id: 'L-safe', scheduledTime: 0, fuelLevel: 8));

      // Only the aircraft that waited long enough should be cancelled.
      airport.addToTakeOff(takeOffAircraft(id: 'T-old', scheduledTime: 0));
      airport.addToTakeOff(takeOffAircraft(id: 'T-new', scheduledTime: 2));

      // Move time to 3: the first aircraft waited 3 ticks, the second waited 1.
      airport.update();
      airport.update();
      airport.update();

      final diverted = airport.divert(3);
      final cancelled = airport.cancel(2);

      expect(diverted, 1);
      expect(cancelled, 1);
      expect(airport.getHoldingCount, 1);
      expect(airport.getTakeOffCount, 1);
    });

    test('update mutates aircraft timing/fuel and reopens runways when due', () {
      final closingRunway = runway(
        status: RunwayStatus.snowClearance,
        normalMode: RunwayMode.landing,
        nextAvailable: 2,
      );
      final airport = Airport([closingRunway]);
      final landing = landingAircraft(id: 'L-3', scheduledTime: 0, fuelLevel: 5);
      final departure = takeOffAircraft(id: 'T-3', scheduledTime: 0);

      airport.addToHolding(landing);
      airport.addToTakeOff(departure);

      // After one tick, aircraft state updates but the runway should still be closed.
      airport.update();
      expect(landing.getFuelLevel, 4);
      expect(landing.getActualTime, 1);
      expect(departure.getActualTime, 1);
      expect(closingRunway.status, RunwayStatus.snowClearance);

      // On the second tick, the runway reaches its reopen time.
      airport.update();
      expect(closingRunway.status, RunwayStatus.available);
      expect(closingRunway.openCallCount, 1);
    });
  });
}

class _FakeRunway implements IRunway {
  @override
  final int id;

  @override
  final int length;

  @override
  final int bearing;

  RunwayStatus _status;

  @override
  int nextAvailable;

  final RunwayMode normalMode;
  IAircraft? assignedAircraft;
  int openCallCount = 0;

  _FakeRunway({
    required this.id,
    this.length = 3000,
    this.bearing = 90,
    required RunwayStatus status,
    required this.normalMode,
    this.nextAvailable = 0,
  }) : _status = status;

  @override
  RunwayStatus get status => _status;

  @override
  bool get isAvailable => _status == RunwayStatus.available;

  @override
  RunwayMode mode([bool emergency = false]) =>
      emergency ? RunwayMode.landing : normalMode;

  @override
  void assignAircraft(IAircraft aircraft) {
    assignedAircraft = aircraft;
    _status = RunwayStatus.occupied;
  }

  @override
  void closeRunway(int duration, RunwayStatus newStatus) {
    nextAvailable += duration;
    _status = newStatus;
  }

  @override
  void open() {
    openCallCount++;
    _status = RunwayStatus.available;
  }
}
