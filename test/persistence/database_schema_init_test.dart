/// Integration tests for SQLite database bootstrap and schema constraints.
///
/// These tests verify:
/// 1) `DatabaseProvider` performs correct initialization on open:
///    - foreign key enforcement is enabled via PRAGMA,
///    - schema initialization does not destroy existing data,
///    - reopening the same file preserves rows.
/// 2) Critical schema constraints are enforced by SQLite itself:
///    - `runs.status` is restricted to a known set of allowed values,
///    - metrics summary values cannot be negative (domain invariants).
///
/// Each test uses a fresh temporary database file to avoid shared state.
import 'dart:io';

import 'package:air_traffic_sim/persistence/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Database initialization', () {
    // Verifies that the provider enables SQLite foreign key checks.
    //
    // SQLite requires explicitly enabling FK enforcement per connection.
    // If this PRAGMA is off, invalid rows can be inserted and constraints
    // will silently not apply.
    test('DatabaseProvider enables foreign keys', () {
      final env = _TempDbEnv('sqlite-provider-test-');

      try {
        final provider = DatabaseProvider(env.dbPath);

        // PRAGMA foreign_keys returns 1 when FK enforcement is active.
        expect(
          provider.database.select('PRAGMA foreign_keys').single['foreign_keys'],
          1,
        );

        provider.dispose();
      } finally {
        env.dispose();
      }
    });

    // Verifies that reopening a DatabaseProvider on the same SQLite file
    // preserves existing schema + data.
    //
    // This protects against accidental "drop and recreate" behavior during
    // schema bootstrapping/migrations.
    test('providers preserve existing data on reopen', () {
      final env = _TempDbEnv('sqlite-provider-reopen-test-');

      try {
        // First open: create provider and insert a scenario.
        final firstOpen = DatabaseProvider(env.dbPath);
        firstOpen.database.execute(
          "INSERT INTO scenarios (id, name, description, created_at) "
          "VALUES ('S-1', 'Base', 'desc', '2024-01-01T00:00:00Z')",
        );
        firstOpen.dispose();

        // Second open: verify the scenario row is still present.
        final reopened = DatabaseProvider(env.dbPath);
        expect(
          reopened.database
              .select('SELECT COUNT(*) AS count FROM scenarios')
              .single['count'],
          1,
        );
        reopened.dispose();
      } finally {
        env.dispose();
      }
    });
  });

  group('Database constraints', () {
    // Verifies that the runs.status column only accepts the allowed values.
    //
    // This is typically enforced by a CHECK constraint (or similar) in the schema,
    // preventing invalid run states from being persisted even if a caller is buggy.
    test('runs.status only accepts the allowed values', () {
      final env = _TempDbEnv('sqlite-status-constraint-');

      try {
        final provider = DatabaseProvider(env.dbPath);

        // Seed parent scenario row to satisfy scenario_id FK on runs.
        provider.database.execute(
          "INSERT INTO scenarios (id, name, created_at) "
          "VALUES ('S-1', 'Base', '2024-01-01T00:00:00Z')",
        );

        // Allowed statuses should insert without errors.
        for (final status in ['running', 'completed', 'aborted', 'failed']) {
          provider.database.execute(
            'INSERT INTO runs (scenario_id, started_at, status) VALUES (?, ?, ?)',
            ['S-1', '2024-01-01T00:00:00Z', status],
          );
        }

        // Disallowed statuses should be rejected by the schema constraint.
        expect(
          () => provider.database.execute(
            "INSERT INTO runs (scenario_id, started_at, status) "
            "VALUES ('S-1', '2024-01-01T00:00:00Z', 'unknown')",
          ),
          throwsA(anything),
        );

        provider.dispose();
      } finally {
        env.dispose();
      }
    });

    // Verifies metrics summary values cannot be negative.
    //
    // The schema should enforce domain invariants:
    // - average_landing_delay >= 0
    // - average_departure_delay >= 0
    // - max_landing_delay >= 0
    // - max_departure_delay >= 0
    // - queue maxima >= 0
    // - counters (cancellations, diversions, aircrafts) >= 0
    //
    // This test inserts one valid summary, then attempts a range of invalid summaries,
    // expecting SQLite to reject each one via CHECK constraints.
    test('metrics summary counters cannot be negative', () {
      final env = _TempDbEnv('sqlite-metrics-constraint-');

      try {
        final provider = DatabaseProvider(env.dbPath);

        // Seed required parent rows to satisfy foreign keys.
        provider.database.execute(
          "INSERT INTO scenarios (id, name, created_at) "
          "VALUES ('S-1', 'Base', '2024-01-01T00:00:00Z')",
        );
        provider.database.execute(
          "INSERT INTO runs (id, scenario_id, started_at, status) "
          "VALUES (1, 'S-1', '2024-01-01T00:00:00Z', 'running')",
        );

        // Reusable insert statement for metrics summaries.
        // (created_at is fixed; the varying values are bound via parameters.)
        const validInsert = '''
          INSERT INTO metrics_summaries (
            run_id, average_landing_delay, average_departure_delay,
            max_landing_delay, max_departure_delay, max_inbound_queue,
            max_outbound_queue, total_cancellations, total_diversions,
            total_aircrafts, created_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, '2024-01-01T00:01:00Z')
        ''';

        // Control case: a valid row with all non-negative fields should insert.
        provider.database.execute(validInsert, [1, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 0]);

        // Each entry below introduces exactly one invalid (negative) field.
        // We also create a new run id each time so run_id remains unique if needed.
        final invalidInserts = <List<Object>>[
          [2, -0.1, 0.0, 0.0, 0.0, 0, 0, 0, 0, 0], // invalid average_landing_delay
          [3, 0.0, -0.1, 0.0, 0.0, 0, 0, 0, 0, 0], // invalid average_departure_delay
          [4, 0.0, 0.0, -0.1, 0.0, 0, 0, 0, 0, 0], // invalid max_landing_delay
          [5, 0.0, 0.0, 0.0, -0.1, 0, 0, 0, 0, 0], // invalid max_departure_delay
          [6, 0.0, 0.0, 0.0, 0.0, -1, 0, 0, 0, 0], // invalid max_inbound_queue
          [7, 0.0, 0.0, 0.0, 0.0, 0, -1, 0, 0, 0], // invalid max_outbound_queue
          [8, 0.0, 0.0, 0.0, 0.0, 0, 0, -1, 0, 0], // invalid total_cancellations
          [9, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, -1, 0], // invalid total_diversions
          [10, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, -1], // invalid total_aircrafts
        ];

        for (final values in invalidInserts) {
          // Ensure a parent run exists for this run_id.
          provider.database.execute(
            "INSERT INTO runs (id, scenario_id, started_at, status) "
            "VALUES (?, 'S-1', '2024-01-01T00:00:00Z', 'running')",
            [values.first],
          );

          // The summary insert should fail due to the negative value.
          expect(
            () => provider.database.execute(validInsert, values),
            throwsA(anything),
          );
        }

        provider.dispose();
      } finally {
        env.dispose();
      }
    });
  });
}

/// Minimal test environment helper that provides a unique temporary
/// directory + database path per test, and cleans up afterward.
///
/// The database file is stored at:
///   <tempDir>/repo.db
class _TempDbEnv {
  final Directory dir;

  _TempDbEnv(String prefix) : dir = Directory.systemTemp.createTempSync(prefix);

  String get dbPath => '${dir.path}/repo.db';

  void dispose() {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }
}