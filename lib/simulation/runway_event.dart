// runway_event.dart

import 'package:air_traffic_sim/simulation/enums/runway_status.dart';
import 'package:air_traffic_sim/simulation/interfaces/interface_runway_event.dart';

class RunwayEvent implements IRunwayEvent {
  RunwayStatus type;
  int startTime;
  int duration;

  // Constructors

  RunwayEvent({
    required this.type,
    required this.startTime,
    required this.duration
  });
}