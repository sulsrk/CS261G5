import 'package:air_traffic_sim/simulation/abstracts/simulation.dart';
import 'package:air_traffic_sim/simulation/concretes/uniform_sim_controller.dart';
import 'package:air_traffic_sim/simulation/interfaces/rate_parameters.dart';

class UniformSimulation extends AbstractSimulation{
  UniformSimulation(IRateParameters p) : super(p){
    controller = UniformSimulationController(p); 
  }
}