import 'package:air_traffic_sim/persistence/database.dart';
import 'package:air_traffic_sim/persistence/models/scenario_record.dart';
import 'package:air_traffic_sim/persistence/repositories/scenario_repository.dart';
import 'package:air_traffic_sim/persistence/repositories/sqlite/sqlite_row_mappers.dart';

class SqliteScenarioRepository implements ScenarioRepository {
  final DatabaseAccessor databaseAccessor;

  const SqliteScenarioRepository(this.databaseAccessor);

  @override
  Future<void> upsertScenario(ScenarioRecord scenario) async {
    databaseAccessor.database.execute(
      '''
      INSERT INTO scenarios (id, name, description, created_at)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
      name = excluded.name,
      description = excluded.description,
      created_at = excluded.created_at
      ''',
      [
        scenario.id,
        scenario.name,
        scenario.description,
        toUtcText(scenario.createdAt),
      ],
    );
  }

  @override
  Future<ScenarioRecord?> getScenarioById(String id) async {
    final rows = databaseAccessor.database.select(
      'SELECT id, name, description, created_at FROM scenarios WHERE id = ?',
      [id],
    );

    if (rows.isEmpty) {
      return null;
    }

    return toScenarioRecord(rows.first);
  }

  @override
  Future<List<ScenarioRecord>> listScenarios() async {
    final rows = databaseAccessor.database.select(
      'SELECT id, name, description, created_at FROM scenarios ORDER BY created_at DESC',
    );

    return rows.map(toScenarioRecord).toList(growable: false);
  }
}
