import 'package:air_traffic_sim/simulation/enums/emergency_status.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_aircraft.dart';

abstract class RAircraft implements IAircraft {
  final String _id;
  final int _scheduledTime;
  final int _actualTime; 
  int _fuelLevel;
  EmergencyStatus _status;
  final String _operator;
  final String _origin;
  final String _destination;
  int _altitude;

  RAircraft({
    required String id,
    required int scheduledTime,
    required int actualTime, 
    required int fuelLevel,
    EmergencyStatus status = EmergencyStatus.none,
    required String flightOperator,
    required String origin,
    required String destination,
    required int altitude,
  })  : _id = id,
        _scheduledTime = scheduledTime,
        _actualTime = actualTime,
        _fuelLevel = fuelLevel,
        _status = status,
        _operator = flightOperator,
        _origin = origin,
        _destination = destination,
        _altitude = altitude;

  @override
  bool isEmergency() => _status != EmergencyStatus.none;

  @override
  String get getId => _id;

  @override
  int get getScheduledTime => _scheduledTime;

  @override
  int get getActualTime => _actualTime;

  @override
  int get getFuelLevel => _fuelLevel;

  @override
  EmergencyStatus get getStatus => _status;

  @override
  String get getOperator => _operator;

  @override
  String get getOrigin => _origin;

  @override
  String get getDestination => _destination;

  @override
  int get getAltitude => _altitude;

  // Setters for the simulation engine
  void consumeFuel(int amount) => _fuelLevel -= amount;
  void updateAltitude(int newAltitude) => _altitude = newAltitude;
  void setEmergencyStatus(EmergencyStatus newStatus) => _status = newStatus;
}

/// Concrete implementation for an Inbound Aircraft
class InboundAircraft extends RAircraft {
  InboundAircraft({
    required super.id,
    required super.scheduledTime,
    required super.actualTime,
    required super.fuelLevel,
    super.status,
    required super.flightOperator,
    required super.origin,
    required super.destination,
    required super.altitude,
  });
}

/// Concrete implementation for an Outbound Aircraft 
class OutboundAircraft extends RAircraft {
  OutboundAircraft({
    required super.id,
    required super.scheduledTime,
    required super.actualTime,
    required super.fuelLevel,
    super.status,
    required super.flightOperator,
    required super.origin,
    required super.destination,
    super.altitude = 0, // Ground level by default
  });
}