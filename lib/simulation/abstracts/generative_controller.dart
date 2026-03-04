import 'package:air_traffic_sim/simulation/abstracts/abstract_controller.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_aircraft.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_airport.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

int compareAircraftForGen(IAircraft a, IAircraft b) => a.getActualTime.compareTo(b.getActualTime);

/// Abstract controller class defining a template for how to handle a 'generative simulation'
/// i.e, one in which aircraft are dynamically generated as they enter.
/// 
/// Inheriting subclasses should make use of the priority queues and override the generation methods
/// depending on how generation is done.
abstract class GenerativeController extends AbstractController{
  @protected
  late final PriorityQueue<IAircraft> inbounds;
  @protected
  late final PriorityQueue<IAircraft> outbounds;

  GenerativeController(super.p) {
    inbounds = PriorityQueue<IAircraft>(compareAircraftForGen);
    outbounds = PriorityQueue<IAircraft>(compareAircraftForGen);

    generateInbounds();
    generateOutbounds();
  }

  @override
  void addToHolding(IAirport airport, IAircraft aircraft) {
    super.addToHolding(airport, aircraft);
    generateInbounds();
  }

  @override
  void addToTakeOff(IAirport airport, IAircraft aircraft) {
    super.addToTakeOff(airport, aircraft);
    generateOutbounds();
  }

  @override
  IAircraft get nextInbound => inbounds.first;
  @override
  IAircraft get nextOutbound => outbounds.first;

  @override
  IAircraft get getNextInbound => inbounds.removeFirst();
  @override
  IAircraft get getNextOutbound => outbounds.removeFirst();

  @protected
  void generateInbounds();
  @protected
  void generateOutbounds();
}