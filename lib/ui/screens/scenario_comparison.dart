import 'package:air_traffic_sim/persistence/models/scenario_record.dart';
import 'package:flutter/material.dart';
import 'package:air_traffic_sim/ui/widgets/scenario_picker_overlay.dart';


class ScenarioScreen extends StatefulWidget {
  const ScenarioScreen({super.key});

  @override
  State<ScenarioScreen> createState() => _ScenarioScreenState();
}

class _ScenarioScreenState extends State<ScenarioScreen> {
  ScenarioRecord? _scenarioA;
  ScenarioRecord? _scenarioB;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scenario Comparison")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _selectionCard(
                  title: "Scenario A",
                  selected: _scenarioA,
                  onSelect: (scenario) => setState(() => _scenarioA = scenario),
                ),
                const SizedBox(height: 16),
                _selectionCard(
                  title: "Scenario B",
                  selected: _scenarioB,
                  onSelect: (scenario) => setState(() => _scenarioB = scenario),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectionCard({
    required String title,
    required ScenarioRecord? selected,
    required ValueChanged<ScenarioRecord?> onSelect,
  }) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(selected?.name ?? "No scenario selected"),
        trailing: ElevatedButton(
          onPressed: () async {
            final scenario = await showScenarioPickerOverlay(context);
            if (scenario != null) {
              onSelect(scenario);
            }
          },
          child: const Text("Load Scenario"),
        ),
      ),
    );
  }
}
