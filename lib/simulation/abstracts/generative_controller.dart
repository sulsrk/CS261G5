import 'dart:collection';
import 'dart:math';

import 'package:air_traffic_sim/simulation/concretes/sim_clock.dart';
import 'package:air_traffic_sim/simulation/concretes/simulation_stats.dart';
import 'package:air_traffic_sim/simulation/concretes/temp_stats.dart';
import 'package:air_traffic_sim/simulation/enums/runway_mode.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_aircraft.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_airport.dart';
import 'package:air_traffic_sim/simulation/interfaces/rate_parameters.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway_event.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_simulation_controller.dart';
import 'package:flutter/material.dart';



abstract class GenerativeController implements ISimulationController{
  late final TempStats _stats;

  @protected late final int inRate;
  @protected late final int outRate;
  @protected late final double emergencyProb;
  late final int _maxWaitTime;
  static const int _minFuelThreshold = 10; 

  @protected late IAircraft nextInbound;
  @protected late IAircraft nextOutbound;

  /// Basic constructor which initialises all constants.
  /// 
  /// [p] represents the parameters entered for a 'rate-controlled' simulation.
  GenerativeController(IRateParameters p){
    _stats = TempStats(); // Initialises with all values set to 0.

    inRate = p.getInboundRate; 
    if (inRate <= 0 || inRate > 60) throw ArgumentError("Inbound rate must be between 1-60 (inclusive).");

    outRate = p.getOutboundRate;
    if (outRate <= 0 || outRate > 60) throw ArgumentError("Outbound rate must be between 1-60 (inclusive).");

    emergencyProb = p.getEmergencyProbability;
    if (emergencyProb < 0 || emergencyProb > 1) throw ArgumentError("Emergency probability must be between 0-1 (inclusive).");

    _maxWaitTime = p.getMaxWaitTime;
    if(_maxWaitTime <= 0) throw ArgumentError("Maximum wait time must be greater than 0 (minutes).");

    nextInbound = generateInbound();
    nextOutbound = generateOutbound();
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
      airport.addToHolding(nextInbound);
      _stats.landingAircraftCount++;
      nextInbound = generateInbound();
    }
    // Include departing aircraft.
    while (SimulationClock.time >= nextOutbound.getActualTime){
      airport.addToTakeOff(nextOutbound);
      _stats.departingAircraftCount++;
      nextOutbound = generateOutbound();
    }
    // Update aggregation.
    _stats.maxInboundQueue = max<int>(_stats.maxInboundQueue, airport.getHoldingCount);
    _stats.maxOutboundQueue = max<int>(_stats.maxOutboundQueue, airport.getTakeOffCount);
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
    while (!airport.isHoldingEmpty && r[i].isAvailable){
      // Assign if runway is available and supports it.
      if (r[i].mode(airport.hasEmergency) == RunwayMode.landing){
        IAircraft aircraft = airport.firstInHolding;
        int delay = max<int>(0,aircraft.getScheduledTime - SimulationClock.time);
        // Update aggregation.
        _stats.maxLandingDelay = max<int>(_stats.maxLandingDelay,delay);
        _stats.totalLandingDelay += delay;
        _stats.totalHoldTime += max<int>(0,aircraft.getActualTime - SimulationClock.time);
        // Assign
        r[i].assignAircraft(aircraft);

        // Re-sort runways (bubble style).
        int j = i;
        while (++j < r.length && r[j-1].nextAvailable < r[j].nextAvailable){
          IRunway temp = r[j];
          r[j] = r[j-1];
          r[j-1] = temp;
        }
      } else {
        i++; // Pointer only needs incrementing upon incompatibility.
      }
    }

    i = 0;
    // Attempt to depart aircraft(s)
    while (!airport.isTakeOffEmpty && r[i].isAvailable){
      // Assign if runway is available and supports it.
      if (r[i].mode() == RunwayMode.takeOff){
        IAircraft aircraft = airport.firstInTakeOff;
        int delay = max<int>(0,aircraft.getScheduledTime - SimulationClock.time);
        // Update aggregation.
        _stats.maxDepartureDelay = max<int>(_stats.maxDepartureDelay,delay);
        _stats.totalDepartureDelay += delay;
        _stats.totalWaitTime += max<int>(0,aircraft.getActualTime - SimulationClock.time);
        // Assign
        r[i].assignAircraft(aircraft);

        // Re-sort runways (bubble style)
        int j = i;
        while (++j < r.length && r[j-1].nextAvailable < r[j].nextAvailable){
          IRunway temp = r[j];
          r[j] = r[j-1];
          r[j-1] = temp;
        }
      } else {
        i++; // Pointer only needs incrementing upon incompatibility.
      }
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

  @protected
  IAircraft generateInbound();
  @protected
  IAircraft generateOutbound();
}