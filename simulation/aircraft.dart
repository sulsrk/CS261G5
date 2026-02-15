// aircraft.dart

import 'enums.dart';


abstract class Aircraft {
  bool isEmergency();
  int get fuel;
  int get scheduledTime;
  String get id;
}


abstract class RAircraft implements Aircraft {
  final String _id;
  final String operator;
  final String origin;
  final String destination;
  int altitude;

  RAircraft(this._id, this.operator, this.origin, this.destination, this.altitude);

  @override
  String get id => _id;
}

class InboundAircraft extends RAircraft {
  final int _scheduledTime;
  int actualTime; 
  int fuelLevel;
  EmergencyStatus emergencyStatus;

  InboundAircraft(
      super.id,             
      super.operator,
      super.origin,
      super.destination,
      super.altitude,
      this._scheduledTime,
      this.fuelLevel,
      {this.emergencyStatus = EmergencyStatus.none})
      : actualTime = 0; 

  @override
  bool isEmergency() => emergencyStatus != EmergencyStatus.none;

  @override
  int get fuel => fuelLevel;

  @override
  int get scheduledTime => _scheduledTime;
}

/// Represents outbound aircraft (Take-Off)
class OutboundAircraft extends RAircraft {
  final int _scheduledTime;
  int fuelLevel;
  EmergencyStatus emergencyStatus;

  OutboundAircraft(
      String id, 
      String operator, 
      String origin, 
      String destination,
      int altitude, 
      this._scheduledTime,
      this.fuelLevel,
      {this.emergencyStatus = EmergencyStatus.none})
      : super(id, operator, origin, destination, altitude);

  @override
  bool isEmergency() => emergencyStatus != EmergencyStatus.none;

  @override
  int get fuel => fuelLevel;

  @override
  int get scheduledTime => _scheduledTime;
}