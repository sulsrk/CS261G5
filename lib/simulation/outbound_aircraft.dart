// outbound_aircraft.dart

import 'package:air_traffic_sim/simulation/interfaces/interface_aircraft.dart';

/// Represents outbound aircraft (taking off)
class OutboundAircraft implements IAircraft {
  
  final int id;
  final int scheduledTime;
  int? actualTime;

  // Constructors

  OutboundAircraft({
    required this.id,
    required this.scheduledTime,
    this.actualTime,
  });

  // Methods

  @override
  bool isEmergency() => false;
}