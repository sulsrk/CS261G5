import 'package:air_traffic_sim/simulation/enums/emergency_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmergencyStatus enum', () {
    test('contains all emergency types without implying an internal priority order', () {
      expect(EmergencyStatus.values, contains(EmergencyStatus.none));
      expect(EmergencyStatus.values, contains(EmergencyStatus.fuel));
      expect(EmergencyStatus.values, contains(EmergencyStatus.health));
      expect(EmergencyStatus.values, contains(EmergencyStatus.mechanical));
    });
  });
}
