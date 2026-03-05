import "package:air_traffic_sim/persistence/database.dart";
import "package:air_traffic_sim/persistence/repositories/sqlite/sqlite_persistence_store.dart";

class AppPersistence {
  AppPersistence._();

  static final AppPersistence instance = AppPersistence._();

  final SqlitePersistenceStore store =
      SqlitePersistenceStore(DatabaseProvider("air_traffic_sim.db"));
}
