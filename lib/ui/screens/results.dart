import 'dart:convert';
import 'package:flutter/material.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Expecting route args to include: metrics + config (+ optional series)
    final args = ModalRoute.of(context)?.settings.arguments;
    final data = args is Map<String, dynamic> ? args : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Results"),
        actions: [
          IconButton(
            tooltip: "Save Scenario",
            onPressed: data == null ? null : () => _saveScenario(context, data),
            icon: const Icon(Icons.save),
          ),
          IconButton(
            tooltip: "Load Scenario",
            onPressed: () => _loadScenario(context),
            icon: const Icon(Icons.folder_open),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: data == null
            ? const Center(child: Text("No results were provided."))
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryCards(data: data),
                    const SizedBox(height: 16),

                    _SectionTitle("Simulation Data"),
                    _MetricsTable(metrics: data["metrics"] as Map<String, dynamic>?),
                    const SizedBox(height: 16),

                    _SectionTitle("Input Configuration"),
                    _ConfigPanel(config: data["config"] as Map<String, dynamic>?),
                    const SizedBox(height: 16),

                    _SectionTitle("Exports"),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _exportCsv(context, data),
                          icon: const Icon(Icons.table_view),
                          label: const Text("Export CSV"),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () => _exportJson(context, data),
                          icon: const Icon(Icons.code),
                          label: const Text("Export JSON"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Optional charts (only render if you have series data)
                    if (data["series"] != null) ...[
                      _SectionTitle("Visualisation"),
                      _ChartsPlaceholder(series: data["series"]),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  // ---- Export stubs (hook up to your file saving later) ----

  void _exportJson(BuildContext context, Map<String, dynamic> data) {
    final jsonStr = const JsonEncoder.withIndent("  ").convert(data);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("JSON Preview"),
        content: SizedBox(
          width: 700,
          child: SingleChildScrollView(child: SelectableText(jsonStr)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _exportCsv(BuildContext context, Map<String, dynamic> data) {
    // Minimal CSV preview example (metrics only)
    final metrics = (data["metrics"] as Map<String, dynamic>?) ?? {};
    final rows = <List<String>>[
      ["metric", "value"],
      ...metrics.entries.map((e) => [e.key, "${e.value}"]),
    ];
    final csv = rows.map((r) => r.map(_escapeCsv).join(",")).join("\n");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("CSV Preview"),
        content: SizedBox(
          width: 700,
          child: SingleChildScrollView(child: SelectableText(csv)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  String _escapeCsv(String s) {
    final needsQuotes = s.contains(",") || s.contains("\"") || s.contains("\n");
    if (!needsQuotes) return s;
    return '"${s.replaceAll('"', '""')}"';
  }

  // ---- Save/Load stubs (hook to SQLite later) ----

  void _saveScenario(BuildContext context, Map<String, dynamic> data) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Save Scenario: not wired yet.")),
    );
  }

  void _loadScenario(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Load Scenario: not wired yet.")),
    );
  }
}

// ---------------- UI Pieces ----------------

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final Map<String, dynamic> data;
  const _SummaryCards({required this.data});

  @override
  Widget build(BuildContext context) {
    final metrics = (data["metrics"] as Map<String, dynamic>?) ?? {};

    Widget card(String title, String value, IconData icon) {
      return Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(value, style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        card("Diversions", "${metrics["diversions"] ?? "-"}", Icons.flight_takeoff),
        const SizedBox(width: 10),
        card("Cancellations", "${metrics["cancellations"] ?? "-"}", Icons.cancel),
        const SizedBox(width: 10),
        card("Utilisation", "${metrics["utilisationPct"] ?? "-"}%", Icons.speed),
      ],
    );
  }
}

class _MetricsTable extends StatelessWidget {
  final Map<String, dynamic>? metrics;
  const _MetricsTable({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final m = metrics ?? {};

    final rows = <MapEntry<String, dynamic>>[
      MapEntry("Max Inbound Delay (min)", m["maxInboundDelay"]),
      MapEntry("Max Outbound Delay (min)", m["maxOutboundDelay"]),
      MapEntry("Avg Inbound Queue", m["avgInboundQueue"]),
      MapEntry("Max Inbound Queue", m["maxInboundQueue"]),
      MapEntry("Avg Outbound Queue", m["avgOutboundQueue"]),
      MapEntry("Max Outbound Queue", m["maxOutboundQueue"]),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: rows.map((e) {
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(e.key),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text("${e.value ?? "-"}"),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ConfigPanel extends StatelessWidget {
  final Map<String, dynamic>? config;
  const _ConfigPanel({required this.config});

  @override
  Widget build(BuildContext context) {
    final c = config ?? {};

    // Show config nicely in an expandable panel
    return Card(
      child: ExpansionTile(
        title: const Text("View input configuration"),
        childrenPadding: const EdgeInsets.all(12),
        children: [
          if (c.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("No configuration data found."),
            )
          else
            Table(
              columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
              children: c.entries.map((e) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(e.key),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text("${e.value}"),
                    ),
                  ],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _ChartsPlaceholder extends StatelessWidget {
  final dynamic series;
  const _ChartsPlaceholder({required this.series});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          "Charts not implemented yet.\n"
          "When you have time-series data (queue over time / delay distribution), "
          "we can render charts here.",
        ),
      ),
    );
  }
}