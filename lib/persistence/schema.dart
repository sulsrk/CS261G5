import 'package:sqlite3/sqlite3.dart';

/// Ensures the SQLite database has all tables/indexes needed by the app.
void initializeDatabase(Database db) {
  db.execute('PRAGMA foreign_keys = ON;');

  db.execute('''
    CREATE TABLE IF NOT EXISTS scenarios (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT,
      created_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS runs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      scenario_id TEXT NOT NULL,
      started_at TEXT NOT NULL,
      completed_at TEXT,
      status TEXT NOT NULL CHECK (status IN ('running', 'completed', 'aborted', 'failed')),
      FOREIGN KEY (scenario_id) REFERENCES scenarios(id)
    );

    CREATE TABLE IF NOT EXISTS events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      run_id INTEGER NOT NULL,
      event_type TEXT NOT NULL,
      payload TEXT NOT NULL,
      occurred_at TEXT NOT NULL,
      FOREIGN KEY (run_id) REFERENCES runs(id)
    );

    CREATE TABLE IF NOT EXISTS aircraft_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      run_id INTEGER NOT NULL,
      aircraft_id TEXT NOT NULL,
      message TEXT NOT NULL,
      recorded_at TEXT NOT NULL,
      FOREIGN KEY (run_id) REFERENCES runs(id)
    );

    CREATE TABLE IF NOT EXISTS metrics_summaries (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      run_id INTEGER NOT NULL UNIQUE,
      average_landing_delay REAL NOT NULL CHECK (average_landing_delay >= 0),
      average_departure_delay REAL NOT NULL CHECK (average_departure_delay >= 0),
      max_landing_delay REAL NOT NULL CHECK (max_landing_delay >= 0),
      max_departure_delay REAL NOT NULL CHECK (max_departure_delay >= 0),
      max_inbound_queue INTEGER NOT NULL CHECK (max_inbound_queue >= 0),
      max_outbound_queue INTEGER NOT NULL CHECK (max_outbound_queue >= 0),
      total_cancellations INTEGER NOT NULL CHECK (total_cancellations >= 0),
      total_diversions INTEGER NOT NULL CHECK (total_diversions >= 0),
      total_aircrafts INTEGER NOT NULL CHECK (total_aircrafts >= 0),
      created_at TEXT NOT NULL,
      FOREIGN KEY (run_id) REFERENCES runs(id)
    );

    CREATE INDEX IF NOT EXISTS idx_runs_scenario_started
      ON runs (scenario_id, started_at);
    CREATE INDEX IF NOT EXISTS idx_events_run_time
      ON events (run_id, occurred_at);
    CREATE INDEX IF NOT EXISTS idx_aircraft_logs_run_aircraft
      ON aircraft_logs (run_id, aircraft_id);
  ''');
}
