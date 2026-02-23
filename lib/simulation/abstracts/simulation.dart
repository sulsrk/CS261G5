import 'dart:collection';

import 'package:air_traffic_sim/simulation/interfaces/airport.dart';
import 'package:air_traffic_sim/simulation/interfaces/parameters.dart';
import 'package:air_traffic_sim/simulation/interfaces/report.dart';
import 'package:air_traffic_sim/simulation/interfaces/runway_event.dart';
import 'package:air_traffic_sim/simulation/interfaces/simulation.dart';
import 'package:air_traffic_sim/simulation/interfaces/simulation_controller.dart';
import 'package:air_traffic_sim/simulation/simulation_stats.dart';
import 'package:flutter/widgets.dart';

/// A basic implementation for a simulation.
/// Different simulations will rely on different instantiations of the controller.
abstract class AbstractSimulation implements ISimulation{
  @protected
  late final ISimulationController controller;

  @protected
  late final IAirport airport;
  @protected
  late final Queue<IRunwayEvent> events; 

  @protected
  late final int duration;

  AbstractSimulation(IParameters param){
    events = param.getEvents;
    duration = param.getDuration;
  }

  /// Public wrapper - only controls the advancing of time steps.
  /// 
  /// TODO:MAKE TIME RELY ON SIMULATION CLOCK 
  /// TODO:CONVERT STATS TO REPORT
  @override
  IReport run() {
    for (int time = 0; time < duration; time++){
      step();
    }
    SimulationStats stats = SimulationStats.aggr(controller.getAggregation);


    throw UnimplementedError(); 
  }

  @protected
  void step(){
    controller.includeEnteringAircraft(airport);
    controller.startRunwayEvents(events, airport);
    controller.assignAircrafts(airport);
    controller.updateSimClock();
    controller.enactFlightChanges(airport);
  }
}