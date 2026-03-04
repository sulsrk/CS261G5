import 'package:air_traffic_sim/simulation/abstracts/generative_controller.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_aircraft.dart';

class UniformSimulationController extends GenerativeController{
  static const double _sd = 5.0;
  static const double _thresholdDistance = 6.7 * _sd;

  double lastInboundSchedule = 0.0;
  double lastOutboundSchedule = 0.0;

  UniformSimulationController(super.p);

  @override
  IAircraft generateInbounds() {
    // TODO: implement generateInbounds
    throw UnimplementedError();
  }

  @override
  IAircraft generateOutbounds() {
    // TODO: implement generateOutbound
    throw UnimplementedError();
  }
  
}