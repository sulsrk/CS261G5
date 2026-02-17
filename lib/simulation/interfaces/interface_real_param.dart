// interface_real_param.dart

import 'package:air_traffic_sim/simulation/interfaces/interface_param.dart';

abstract class IRealParamaters extends IParamaters {
  ///
  int get outboundFlow;
  ///
  int get inboundFlow;
}