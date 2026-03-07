import 'dart:collection';

import 'package:air_traffic_sim/simulation/abstracts/generative_controller.dart';
import 'package:air_traffic_sim/simulation/enums/emergency_status.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_aircraft.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway_event.dart';
import 'package:air_traffic_sim/simulation/interfaces/rate_parameters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GenerativeController constructor validation', () {
    test('throws for inRate <= 0 and inRate > 60', () {
      expect(
        () => _TestGenerativeController(
          _FakeRateParameters(inboundRate: 0),
        ),
        _throwsArgumentErrorWith('Inbound rate must be between 1-60 (inclusive).'),
      );

      expect(
        () => _TestGenerativeController(
          _FakeRateParameters(inboundRate: 61),
        ),
        _throwsArgumentErrorWith('Inbound rate must be between 1-60 (inclusive).'),
      );
    });

    test('throws for outRate <= 0 and outRate > 60', () {
      expect(
        () => _TestGenerativeController(
          _FakeRateParameters(outboundRate: 0),
        ),
        _throwsArgumentErrorWith('Outbound rate must be between 1-60 (inclusive).'),
      );

      expect(
        () => _TestGenerativeController(
          _FakeRateParameters(outboundRate: 61),
        ),
        _throwsArgumentErrorWith('Outbound rate must be between 1-60 (inclusive).'),
      );
    });

    test('throws for emergencyProb < 0 and emergencyProb > 1', () {
      expect(
        () => _TestGenerativeController(
          _FakeRateParameters(emergencyProbability: -0.01),
        ),
        _throwsArgumentErrorWith('Emergency probability must be between 0-1 (inclusive).'),
      );

      expect(
        () => _TestGenerativeController(
          _FakeRateParameters(emergencyProbability: 1.01),
        ),
        _throwsArgumentErrorWith('Emergency probability must be between 0-1 (inclusive).'),
      );
    });

    test('throws for maxWaitTime <= 0', () {
      expect(
        () => _TestGenerativeController(
          _FakeRateParameters(maxWaitTime: 0),
        ),
        _throwsArgumentErrorWith('Maximum wait time must be greater than 0 (minutes).'),
      );
    });

    test('accepts valid boundary values', () {
      expect(
        () => _TestGenerativeController(
          _FakeRateParameters(
            inboundRate: 1,
            outboundRate: 60,
            emergencyProbability: 0,
            maxWaitTime: 1,
          ),
        ),
        returnsNormally,
      );

      expect(
        () => _TestGenerativeController(
          _FakeRateParameters(
            inboundRate: 60,
            outboundRate: 1,
            emergencyProbability: 1,
            maxWaitTime: 10,
          ),
        ),
        returnsNormally,
      );
    });
  });
}

Matcher _throwsArgumentErrorWith(String message) {
  return throwsA(isA<ArgumentError>().having((e) => e.message, 'message', message));
}

class _TestGenerativeController extends GenerativeController {
  _TestGenerativeController(super.parameters);

  @override
  IAircraft generateInbound() => _FakeAircraft();

  @override
  IAircraft generateOutbound() => _FakeAircraft();
}

class _FakeRateParameters implements IRateParameters {
  @override
  final int getInboundRate;

  @override
  final int getOutboundRate;

  @override
  final double getEmergencyProbability;

  @override
  final int getMaxWaitTime;

  @override
  final int getDuration;

  @override
  final List<IRunway> getRunways;

  @override
  final Queue<IRunwayEvent> getEvents;

  _FakeRateParameters({
    int inboundRate = 1,
    int outboundRate = 1,
    double emergencyProbability = 0,
    int maxWaitTime = 1,
    int duration = 1,
    List<IRunway>? runways,
    Queue<IRunwayEvent>? events,
  })  : getInboundRate = inboundRate,
        getOutboundRate = outboundRate,
        getEmergencyProbability = emergencyProbability,
        getMaxWaitTime = maxWaitTime,
        getDuration = duration,
        getRunways = runways ?? const <IRunway>[],
        getEvents = events ?? Queue<IRunwayEvent>();
}

class _FakeAircraft implements IAircraft {
  @override
  String get getId => 'TEST';

  @override
  int get getScheduledTime => 0;

  @override
  int get getActualTime => 0;

  @override
  int get getFuelLevel => 100;

  @override
  EmergencyStatus get getStatus => EmergencyStatus.none;

  @override
  String get getOperator => 'TEST';

  @override
  String get getOrigin => 'AAA';

  @override
  String get getDestination => 'BBB';

  @override
  int get getAltitude => 0;

  @override
  bool isEmergency() => false;
}
