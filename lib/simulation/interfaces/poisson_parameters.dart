import 'package:air_traffic_sim/simulation/interfaces/parameters.dart';

abstract class IRealParamaters extends IParamaters {
  
  /// Getters
  
  int get getOutboundFlow;
  int get getInboundFlow;
}