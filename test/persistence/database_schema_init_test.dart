// SQLite schema setup and constraint checks.
import 'dart:io';

import 'package:air_traffic_sim/persistence/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Database initialization', () {
    test('DatabaseProvider enables foreign keys', () {
      final env = _TempDbEnv('sqlite-provider-test-');

      try {
        final provider = DatabaseProvider(env.dbPath);

        // Checks FK enforcement is on.
        expect(
          provider.database.select('PRAGMA foreign_keys').single['foreign_keys'],
          1,
        );

        provider.dispose();
      } finally {
        env.dispose();
      }
    });

    test('providers preserve existing data on reopen', () {
      final env = _TempDbEnv('sqlite-provider-reopen-test-');

      try {
        final firstOpen = DatabaseProvider(env.dbPath);
        firstOpen.database.execute(
          "INSERT INTO scenarios (id, name, description, created_at) "
          "VALUES ('S-1', 'Base', 'desc', '2024-01-01T00:00:00Z')",
        );
        firstOpen.dispose();

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
    test('runs.status only accepts the allowed values', () {
      final env = _TempDbEnv('sqlite-status-constraint-');

      try {
        final provider = DatabaseProvider(env.dbPath);

        // Add parent scenario for the FK.
        provider.database.execute(
          "INSERT INTO scenarios (id, name, created_at) "
          "VALUES ('S-1', 'Base', '2024-01-01T00:00:00Z')",
        );

        for (final status in ['running', 'completed', 'aborted', 'failed']) {
          provider.database.execute(
            'INSERT INTO runs (scenario_id, started_at, status) VALUES (?, ?, ?)',
            ['S-1', '2024-01-01T00:00:00Z', status],
          );
        }

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

    test('metrics summary counters cannot be negative', () {
      final env = _TempDbEnv('sqlite-metrics-constraint-');

      try {
        final provider = DatabaseProvider(env.dbPath);

        // Add required parent rows.
        provider.database.execute(
          "INSERT INTO scenarios (id, name, created_at) "
          "VALUES ('S-1', 'Base', '2024-01-01T00:00:00Z')",
        );
        provider.database.execute(
          "INSERT INTO runs (id, scenario_id, started_at, status) "
          "VALUES (1, 'S-1', '2024-01-01T00:00:00Z', 'running')",
        );

        const validInsert = '''
          INSERT INTO metrics_summaries (
            run_id, average_landing_delay, average_departure_delay,
            max_landing_delay, max_departure_delay, max_inbound_queue,
            max_outbound_queue, total_cancellations, total_diversions,
            total_aircrafts, created_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, '2024-01-01T00:01:00Z')
        ''';

        provider.database.execute(validInsert, [1, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 0]);

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
          provider.database.execute(
            "INSERT INTO runs (id, scenario_id, started_at, status) "
            "VALUES (?, 'S-1', '2024-01-01T00:00:00Z', 'running')",
            [values.first],
          );

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

// Creates an isolated temp db per test.
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
