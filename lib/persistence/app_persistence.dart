import 'package:air_traffic_sim/persistence/database.dart';
import 'package:air_traffic_sim/persistence/repositories/sqlite/sqlite_persistence_store.dart';

/// Shared persistence composition root used by UI/backend layers.
class AppPersistence {
  final DatabaseProvider provider;
  final SqlitePersistenceStore store;

  AppPersistence._({
    required this.provider,
    required this.store,
  });

  static AppPersistence? _instance;

  static AppPersistence get instance {
    return _instance ??= (() {
      final provider = DatabaseProvider('air_traffic_sim.db');
      return AppPersistence._(
        provider: provider,
        store: SqlitePersistenceStore(provider),
      );
    })();
  }

  void close() => provider.close();
}
