import 'dart:convert';

import 'package:air_traffic_sim/persistence/app_persistence.dart';
import 'package:air_traffic_sim/persistence/models/scenario_record.dart';
import 'package:flutter/material.dart';

class ScenarioScreen extends StatelessWidget {
  const ScenarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scenario Comparison")),
      body: FutureBuilder<List<ScenarioRecord>>(
        future: AppPersistence.instance.store.listScenarios(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Failed to load scenarios: ${snapshot.error}"),
            );
          }

          final scenarios = snapshot.data ?? const [];
          if (scenarios.isEmpty) {
            return const Center(
              child: Text("No saved scenarios yet. Run a simulation first."),
            );
          }

          return ListView.separated(
            itemCount: scenarios.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final scenario = scenarios[index];

              return ListTile(
                title: Text(scenario.name),
                subtitle: Text(_decodeDescription(scenario.description)),
                trailing: Text(
                  scenario.createdAt.toLocal().toString(),
                  textAlign: TextAlign.end,
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _decodeDescription(String? description) {
    if (description == null || description.isEmpty) {
      return "No scenario details saved";
    }

    try {
      final decoded = jsonDecode(description);
      if (decoded is Map<String, dynamic>) {
        final runwayCount = decoded["runwayCount"]?.toString() ?? "n/a";
        final duration = decoded["duration"]?.toString() ?? "n/a";
        final inboundFlow = decoded["inboundFlow"]?.toString() ?? "n/a";
        final outboundFlow = decoded["outboundFlow"]?.toString() ?? "n/a";
        return "Runways: $runwayCount | Duration(h): $duration | In: $inboundFlow/h | Out: $outboundFlow/h";
      }
    } catch (_) {
      return description;
    }

    return description;
  }
}
