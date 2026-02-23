import 'package:air_traffic_sim/persistence/models/scenario_record.dart';

abstract class ScenarioRepository {
  Future<void> upsertScenario(ScenarioRecord scenario);

  Future<ScenarioRecord?> getScenarioById(String id);

  Future<List<ScenarioRecord>> listScenarios();
}
