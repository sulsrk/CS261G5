import 'package:air_traffic_sim/simulation/enums/emergency_status.dart';
import 'package:air_traffic_sim/simulation/enums/aircraft_type.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_aircraft.dart';

class Aircraft implements IAircraft {
  final String _id;
  final int _scheduledTime;
  int _actualTime;
  int _fuelLevel;
  EmergencyStatus _status;
  int _altitude;
  final String _operator;
  final String _origin;
  final String _destination;
  final AircraftType _type;

  Aircraft({
    required String id,
    required int scheduledTime,
    int actualTime = 0,
    required int fuelLevel,
    EmergencyStatus status = EmergencyStatus.none, 
    required String flightOperator,
    required String origin,
    required String destination,
    required int altitude,
    required AircraftType type,
  })  : _id = id,
        _scheduledTime = scheduledTime,
        _actualTime = actualTime,
        _fuelLevel = fuelLevel,
        _status = status,
        _operator = flightOperator,
        _origin = origin,
        _destination = destination,
        _altitude = altitude,
        _type = type;

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

  AircraftType get getType => _type;

  void consumeFuel(int amount) => _fuelLevel -= amount;

  void updateActualTime(int time) => _actualTime = time;

  void updateAltitude(int newAltitude) => _altitude = newAltitude;
  
  void setEmergencyStatus(EmergencyStatus newStatus) => _status = newStatus;
}