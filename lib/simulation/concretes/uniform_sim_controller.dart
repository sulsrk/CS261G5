import 'package:air_traffic_sim/simulation/abstracts/generative_controller.dart';
import 'package:air_traffic_sim/simulation/interfaces/aircraft.dart';

class UniformSimulationController extends GenerativeController{

  UniformSimulationController(super.p);

  @override
  IAircraft generateInbound() {
    // TODO: implement generateInbound
    throw UnimplementedError();
  }

  @override
  IAircraft generateOutbound() {
    // TODO: implement generateOutbound
    throw UnimplementedError();
  }
  
}