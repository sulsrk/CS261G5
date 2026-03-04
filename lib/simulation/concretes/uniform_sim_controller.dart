import 'package:air_traffic_sim/simulation/abstracts/generative_controller.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_aircraft.dart';
import 'package:air_traffic_sim/simulation/interfaces/rate_parameters.dart';
import 'package:flutter/material.dart';

/// A controller for dynamically generating uniformally scheduled aircraft, 
/// with actual times distributed N(schedule,5).
class UniformSimulationController extends GenerativeController{
  /// Time incrementers for uniform.
  late final double _inb;
  late final double _outb;

  static const int _maxRate = 120;

  static const double _sd = 5.0;
  static const double _thresholdDistance = 6.7 * _sd;

  double _nInboundSchedule = 0.0;
  double _nOutboundSchedule = 0.0;

  UniformSimulationController(IRateParameters p) : super(p){
    _inb = p.getInboundRate as double; 
    if (_inb <= 0 || _inb > _maxRate) throw ArgumentError("Inbound rate must be between 1-$_maxRate (inclusive).");
    _inb /= 60.0;

    _outb = p.getOutboundRate as double;
    if (_outb <= 0 || _outb > _maxRate) throw ArgumentError("Outbound rate must be between 1-$_maxRate (inclusive).");
    _outb /= 60.0;

    generateInbounds();
    generateOutbounds();
  }

  /// Continuously generates inbound aircraft so there are at least 6.7 standard deviations
  /// of difference between the first and last aircraft's scheduled times to enter the holding pattern.
  @override
  void generateInbounds() {
    throw UnimplementedError();
    while (_nInboundSchedule < (_thresholdDistance + inbounds.first.getScheduledTime)){
      // TODO: GENERATE AND ADD AIRCRAFT
      _nInboundSchedule += _inb;
    }
  }
  /// Continuously generates outbound aircraft so there are at least 6.7 standard deviations 
  /// of difference between the first and last aircraft's scheduled times to enter the holding pattern.
  @override
  void generateOutbounds() {
    throw UnimplementedError();
    while (_nOutboundSchedule < (_thresholdDistance + inbounds.first.getScheduledTime)){
      // TODO: GENERATE AND ADD AIRCRAFT
      _nOutboundSchedule += _outb;
    }
  }
  
}