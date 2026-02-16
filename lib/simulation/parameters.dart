// parameters.dart

import 'dart:collection';

import 'package:air_traffic_sim/simulation/interfaces/interface_real_param.dart';
import 'package:air_traffic_sim/simulation/interfaces/interface_runway.dart';
import 'package:air_traffic_sim/simulation/interfaces/interface_runway_event.dart';

class Parameters implements IRealParamaters {
  List<IRunway> _runways;
  int _outboundFlow;
  int _inboundFlow;
  double _emergencyProbability;
  Queue<IRunwayEvent> _events;

  // Constructors
  
  Parameters({
    required List<IRunway> runways,
    required int outboundFlow,
    required int inboundFlow,
    required double emergencyProbability,
    required Queue<IRunwayEvent> events
  }) : _runways = runways, 
  _outboundFlow = outboundFlow,
  _inboundFlow = inboundFlow,
  _emergencyProbability = emergencyProbability,
  _events = events;

  // Getters and Setters - TODO: are these necessary?

  @override
  List<IRunway> get runways => _runways;
  @override
  int get outboundFlow => _outboundFlow;
  @override
  int get inboundFlow => _inboundFlow;
  @override
  double get emergencyProbability => _emergencyProbability;
  @override
  Queue<IRunwayEvent> get events => _events;
}