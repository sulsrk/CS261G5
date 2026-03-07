import "package:air_traffic_sim/persistence/models/scenario_record.dart";
import "package:air_traffic_sim/ui/widgets/scenario_picker_overlay.dart";
import "package:flutter/material.dart";

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  ScenarioRecord? _loadedScenario;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Results Screen"),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final scenario = await showScenarioPickerOverlay(context);
              if (scenario != null) {
                setState(() => _loadedScenario = scenario);
              }
            },
            icon: const Icon(Icons.folder_open, color: Colors.black),
            label: const Text(
              "Load Scenario",
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
      body: Center(
        child: Text(
          _loadedScenario == null
              ? "No scenario loaded"
              : "Loaded: ${_loadedScenario!.name}",
        ),
      ),
    );
  }
}
