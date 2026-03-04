import 'dart:collection';
import 'dart:math';

import 'package:air_traffic_sim/simulation/concretes/sim_clock.dart';
import 'package:air_traffic_sim/simulation/concretes/simulation_stats.dart';
import 'package:air_traffic_sim/simulation/concretes/temp_stats.dart';
import 'package:air_traffic_sim/simulation/enums/runway_mode.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_aircraft.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_airport.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_parameters.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway_event.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_simulation_controller.dart';
import 'package:flutter/material.dart';

abstract class AbstractController implements ISimulationController{
  late final TempStats _stats;

  @protected late final double emergencyProb;

  late final int _maxWaitTime;
  late final int _minFuelThreshold; 

  /// Basic constructor which initialises all constants.
  /// 
  /// [p] represents the parameters entered for a 'rate-controlled' simulation.
  AbstractController(IParameters p){
    _stats = TempStats(); // Initialises with all values set to 0.

    emergencyProb = p.getEmergencyProbability;
    if (emergencyProb < 0 || emergencyProb > 1) throw ArgumentError("Emergency probability must be between 0-1 (inclusive).");

    _maxWaitTime = p.getMaxWaitTime;
    if(_maxWaitTime <= 0) throw ArgumentError("Maximum wait time must be greater than 0 (minutes).");

    _minFuelThreshold = p.getMinFuelThreshold;
    if (_minFuelThreshold <= 0) throw ArgumentError("Minimum fuel threshold must be greater than 0");
  }

  /// @inheritdoc
  /// 
  /// Continuously generates and adds aircraft to the holding pattern and take off queue
  /// so long as their entering time has been reached.
  /// Updates the maximum inbound/outbound queue size appropriately in the temporary aggregation. 
  @override
  void includeEnteringAircraft(IAirport airport) {
    // Include entering aircraft.
    while (SimulationClock.time >= nextInbound.getActualTime){
      addToHolding(airport, getNextInbound);
    }
    // Include departing aircraft.
    while (SimulationClock.time >= nextOutbound.getActualTime){
      addToTakeOff(airport, getNextOutbound);
    }
    // Update aggregation.
    _stats.maxInboundQueue = max<int>(_stats.maxInboundQueue, airport.getHoldingCount);
    _stats.maxOutboundQueue = max<int>(_stats.maxOutboundQueue, airport.getTakeOffCount);
  }

  @protected
  void addToHolding(IAirport airport, IAircraft aircraft){
    airport.addToHolding(aircraft);
    _stats.landingAircraftCount++;
  }

  @protected
  void addToTakeOff(IAirport airport, IAircraft aircraft){
    airport.addToTakeOff(aircraft);
    _stats.departingAircraftCount++;
  }

  /// @inheritdoc
  /// 
  /// Assumes that the list of runways in [airport] is sorted by their [IRunway.nextAvailable] time
  /// and maintains this sorted order.
  /// 
  /// Updates the maximum and total landing/take-off delays and the total hold/wait times in [_stats].
  @override
  void assignAircrafts(IAirport airport) {
    List<IRunway> r = airport.getRunways;
    int i = 0;
    // Attempt to land aircraft(s)
    while (!airport.isHoldingEmpty && i < r.length && r[i].isAvailable){
      // Assign if runway is available and supports it.
      if (r[i].mode(airport.hasEmergency) == RunwayMode.landing){
        land(r[i],airport.firstInHolding);
        // Re-sort runways (bubble style).
        _sort(r,i);
      } else {
        i++; // Pointer only needs incrementing upon incompatibility.
      }
    }

    i = 0;
    // Attempt to depart aircraft(s)
    while (!airport.isTakeOffEmpty && r[i].isAvailable){
      // Assign if runway is available and supports it.
      if (r[i].mode() == RunwayMode.takeOff){
        depart(r[i],airport.firstInTakeOff);
        // Re-sort runways (bubble style)
        _sort(r,i);
      } else {
        i++; // Pointer only needs incrementing upon incompatibility.
      }
    }
  }

  @protected
  void depart(IRunway runway, IAircraft aircraft){
    // Assign
    runway.assignAircraft(aircraft);
    // Update aggregation.
    int delay = aircraft.getScheduledTime - SimulationClock.time;
    if (delay > 0){
      _stats.maxDepartureDelay = max<int>(_stats.maxDepartureDelay,delay);
      _stats.totalDepartureDelay += delay;
    }
    _stats.totalWaitTime += max<int>(0,aircraft.getActualTime - SimulationClock.time);
  }

  @protected
  void land(IRunway runway, IAircraft aircraft){
    // Assign
    runway.assignAircraft(aircraft);
    // Update aggregation.
    int delay = aircraft.getScheduledTime - SimulationClock.time;
    if (delay > 0){
      _stats.maxLandingDelay = max<int>(_stats.maxLandingDelay,delay);
      _stats.totalLandingDelay += delay;
    }
    _stats.totalHoldTime += max<int>(0,aircraft.getActualTime - SimulationClock.time);
  }

  /// Locally sorts a single out of place runway at index [i].
  void _sort(List<IRunway> runways, int i){
    while (++i < runways.length && runways[i-1].nextAvailable < runways[i].nextAvailable){
      IRunway temp = runways[i];
      runways[i] = runways[i-1];
      runways[i-1] = temp;
    }
  }

  @override
  void startRunwayEvents(Queue<IRunwayEvent> events, IAirport airport){
    if (events.isEmpty) return;

    while (SimulationClock.time >= events.first.getStartTime){
      IRunwayEvent event = events.removeFirst();
      airport.getRunway(event.getRunwayId)?.closeRunway(event.getDuration, event.getEventType);
    }
  }

  @override
  void updateSimClock(){
    SimulationClock.time++; // Simple increment (temporary)
  }

  @override
  void enactFlightChanges(IAirport airport) {
    _stats.totalCancellations += airport.cancel(_maxWaitTime);
    _stats.totalDiversions += airport.divert(_minFuelThreshold);
  }

  @override
  SimulationStats get getCurrStats => SimulationStats.aggr(_stats);

  /// Getters for inspecting the next aircraft (without removal).
  @protected
  IAircraft get nextInbound;
  @protected
  IAircraft get nextOutbound;
  /// Getters for grabbing the next aircraft (with removal).
  @protected
  IAircraft get getNextInbound;
  @protected
  IAircraft get getNextOutbound;
}