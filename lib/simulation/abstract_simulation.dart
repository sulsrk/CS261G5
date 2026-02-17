// abstract_runaway.dart

import 'dart:collection';

import 'package:air_traffic_sim/simulation/interfaces/interface_airport.dart';
import 'package:air_traffic_sim/simulation/interfaces/interface_report.dart';
import 'package:air_traffic_sim/simulation/interfaces/interface_runway_event.dart';
import 'package:air_traffic_sim/simulation/interfaces/interface_simulation.dart';
import 'package:air_traffic_sim/simulation/interfaces/interface_simulation_controller.dart';
import 'package:flutter/material.dart';

abstract class AbstractSimulation implements ISimulation {
  
  @protected
  Queue<IRunwayEvent> events = Queue<IRunwayEvent>();
  @protected
  IAirport airport;
  @protected
  ISimulationController controller;

  // Constructors

  AbstractSimulation({
    required this.events,
    required this.airport,
    required this.controller
  });

  // Methods

  @override
  IReport run();
}