// real_aircraft.dart

import 'package:air_traffic_sim/simulation/inbound_aircraft.dart';

/// Represents a real aircraft and its information
class RealAircraft extends InboundAircraft {

  String? operator;
  String? origin;
  String? destination;
  int altitude;

  // Constructors

  RealAircraft({
    required super.id,
    required super.scheduledTime,
    super.actualTime,
    required super.fuel,
    super.emergencyStatus,
    this.operator,
    this.origin,
    this.destination,
    required this.altitude
  });
}

