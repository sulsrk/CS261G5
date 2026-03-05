import 'package:air_traffic_sim/simulation/enums/runway_status.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway_event.dart'; 

class RunwayEvent implements IRunwayEvent {
  final int _runwayId;
  final int _startTime;
  final int _duration;
  final RunwayStatus _eventType;

  RunwayEvent({
    required int runwayId,
    required int startTime,
    required int duration,
    required RunwayStatus eventType,
  })  : _runwayId = runwayId,
        _startTime = startTime,
        _duration = duration,
        _eventType = eventType {
    
    // Enforce the interface constraint: cannot be available or occupied
    if (_eventType == RunwayStatus.available || _eventType.name == 'occupied') {
      throw ArgumentError(
        'A RunwayEvent cannot have a status of ${_eventType.name}. '
        'Must be an event like inspection, snow clearance, closure, etc.'
      );
    }
  }

  @override
  int get getRunwayId => _runwayId;

  @override
  int get getStartTime => _startTime;

  @override
  int get getDuration => _duration;

  @override
  RunwayStatus get getEventType => _eventType;
}