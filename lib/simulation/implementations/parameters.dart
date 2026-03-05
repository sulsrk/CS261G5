import 'dart:collection';
import 'package:air_traffic_sim/simulation/interfaces/i_runway.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway_event.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_parameters.dart'; 


class Parameters implements IParameters {
  final List<IRunway> _runways;
  final double _emergencyProbability;
  final Queue<IRunwayEvent> _events;
  final int _maxWaitTime;
  final int _duration;

  Parameters({
    required List<IRunway> runways,
    required double emergencyProbability,
    required Queue<IRunwayEvent> events,
    required int maxWaitTime,
    required int duration,
  })  : _runways = runways,
        _emergencyProbability = emergencyProbability,
        _events = events,
        _maxWaitTime = maxWaitTime,
        _duration = duration;

  @override
  List<IRunway> get getRunways => _runways;

  @override
  double get getEmergencyProbability => _emergencyProbability;

  @override
  Queue<IRunwayEvent> get getEvents => _events;

  @override
  int get getMaxWaitTime => _maxWaitTime;

  @override
  int get getDuration => _duration;
}