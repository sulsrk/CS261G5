// inbound_aircraft.dart

import 'package:air_traffic_sim/simulation/enums/emergency_status.dart';

import 'package:air_traffic_sim/simulation/outbound_aircraft.dart';

/// Represents inbound aircraft (landing)
class InboundAircraft extends OutboundAircraft {

  int _fuel = 0;
  EmergencyStatus emergencyStatus = EmergencyStatus.none;

  // Constructors

  InboundAircraft({
    required super.id, 
    required super.scheduledTime,
    super.actualTime,
    required fuel,
    this.emergencyStatus = EmergencyStatus.none
    }) {
    this.fuel = fuel;
  }

  // Getters and Setters

  int get fuel => _fuel;

  set fuel(int value) {
    if (value >= 0) {
      _fuel = value;
    } else {
      throw Exception("Invalid Fuel Level");
    }
  }

  @override
  bool isEmergency() => emergencyStatus == EmergencyStatus.none;
}