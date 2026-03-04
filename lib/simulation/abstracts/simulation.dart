import 'dart:collection';

import 'package:air_traffic_sim/simulation/concretes/sim_clock.dart';
import 'package:air_traffic_sim/simulation/implementations/airport.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_airport.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_parameters.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_report.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway_event.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_simulation.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_simulation_controller.dart';
import 'package:air_traffic_sim/simulation/concretes/simulation_stats.dart';
import 'package:flutter/widgets.dart';

/// A basic implementation for a simulation.
/// Different simulations will rely on different instantiations of different controllers.
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

    airport = Airport(param.getRunways);
  }

  /// Public wrapper - only controls the advancing of time steps.
  ///  
  /// TODO:CONVERT STATS TO REPORT
  @override
  IReport run() {
    for (SimulationClock.reset(); SimulationClock.time < duration;){
      step();
    }
    SimulationStats stats = controller.getCurrStats;

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