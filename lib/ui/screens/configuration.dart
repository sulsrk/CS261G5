import 'dart:convert';

import 'package:air_traffic_sim/persistence/app_persistence.dart';
import 'package:air_traffic_sim/persistence/models/scenario_record.dart';
import 'package:flutter/material.dart';
import '../models/runway_config_ui.dart';
import '../widgets/runway_card.dart';

class ConfigurationScreen extends StatefulWidget {
  const ConfigurationScreen({super.key});

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  final _formKey = GlobalKey<FormState>();

  int runwayCount = 1;
  List<RunwayConfigUI> runways = [RunwayConfigUI()];

  final TextEditingController scenarioNameController = 
      TextEditingController();
      
  final TextEditingController runwayCountController =
      TextEditingController(text: "1");

  final TextEditingController mechanicalProbController =
      TextEditingController(text: "0");

  final TextEditingController medicalProbController =
      TextEditingController(text: "0");

  final TextEditingController inboundFlowController =
      TextEditingController();
  final TextEditingController outboundFlowController =
      TextEditingController();
  final TextEditingController maxWaitController =
      TextEditingController(text: "30");

  final TextEditingController fuelThresholdController =
      TextEditingController(text: "10");

  final TextEditingController durationController = 
      TextEditingController(text: "1");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Simulation Configuration")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                TextFormField(
                  controller: scenarioNameController,
                  decoration: const InputDecoration(
                    labelText: "Scenario Name (optional for real-time)",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Scenario",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: scenarioNameController,
                  decoration: const InputDecoration(
                    labelText: "Scenario Name",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Scenario name is required";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 10),

                const Text(
                  "Runway Configuration",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField(
                        controller: runwayCountController,
                        label: "Number of Runways (1-10)",
                        min: 1,
                        max: 10,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _confirmRunwayCount,
                      child: const Text("Confirm"),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Column(
                  children: List.generate(
                    runways.length,
                    (index) => RunwayCard(
                      runway: runways[index],
                      index: index,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                const Text(
                  "Emergency Probability",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                _buildNumberField(
                  controller: mechanicalProbController,
                  label: "Mechanical Failure Probability (0-100%)",
                  min: 0,
                  max: 100,
                ),
                const SizedBox(height: 10),

                _buildNumberField(
                  controller: medicalProbController,
                  label: "Medical Emergency Probability (0-100%)",
                  min: 0,
                  max: 100,
                ),
                const SizedBox(height: 10),

                const Text(
                  "Aircraft Flow",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                _buildNumberField(
                  controller: inboundFlowController,
                  label: "Inbound Flow Rate (aircraft/hour)",
                  min: 0,
                ),
                const SizedBox(height: 10),

                _buildNumberField(
                  controller: outboundFlowController,
                  label: "Outbound Flow Rate (aircraft/hour)",
                  min: 0,
                ),
                const SizedBox(height: 10),

                const Text(
                  "Operational Limits",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                _buildNumberField(
                  controller: maxWaitController,
                  label: "Max Outbound Wait (minutes)",
                  min: 1,
                ),
                const SizedBox(height: 10),
                _buildNumberField(
                  controller: fuelThresholdController,
                  label: "Fuel Diversion Threshold (minutes)",
                  min: 1,
                ),
                const SizedBox(height: 10),

                _buildNumberField(
                  controller: durationController,
                  label: "Simulation Duration (hours)",
                  min: 1,
                ),
                const SizedBox(height: 10),

                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: _runSimulation,
                        child: const Text("Run Simulation"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _realtimeModel,
                        child: const Text("Real-Time Model"),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    int? min,
    int? max,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "This field is required";
        }

        final number = int.tryParse(value);
        if (number == null) {
          return "Enter a valid number";
        }

        if (min != null && number < min) {
          return "Minimum value is $min";
        }

        if (max != null && number > max) {
          return "Maximum value is $max";
        }

        return null;
      },
      onChanged: onChanged,
    );
  }

  void _updateRunways(int count) {
    setState(() {
      if (runways.length < count) {
        while (runways.length < count) {
          runways.add(RunwayConfigUI());
        }
      } else if (runways.length > count) {
        runways = runways.sublist(0, count);
      }
    });
  }

  void _confirmRunwayCount() {
    final value = runwayCountController.text;
    if (value.isEmpty) return;

    final count = int.tryParse(value);
    if (count == null || count < 1 || count > 10) return;

    _updateRunways(count);
  }

  Future<void> _runSimulation() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final savedScenario = await _persistScenario();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Saved scenario \"${savedScenario.name}\"")),
      );
      Navigator.pushNamed(context, "/results");
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save scenario: $error")),
      );
    }
  }

  void _realtimeModel() {
    if (_formKey.currentState!.validate()) {
      Navigator.pushNamed(context, "/realtime");
    }
  }

  Future<ScenarioRecord> _persistScenario() async {
    final timestamp = DateTime.now();
    final fallbackName = "Scenario ${timestamp.toIso8601String()}";
    final scenarioName = scenarioNameController.text.trim().isEmpty
        ? fallbackName
        : scenarioNameController.text.trim();
    final scenarioId =
        "${timestamp.millisecondsSinceEpoch}-${scenarioName.toLowerCase().replaceAll(RegExp(r"[^a-z0-9]+"), "-")}";

    final metadata = {
      "runwayCount": runwayCountController.text,
      "mechanicalProb": mechanicalProbController.text,
      "medicalProb": medicalProbController.text,
      "inboundFlow": inboundFlowController.text,
      "outboundFlow": outboundFlowController.text,
      "maxWait": maxWaitController.text,
      "fuelThreshold": fuelThresholdController.text,
      "duration": durationController.text,
      "runways": runways
          .map(
            (runway) => {
              "mode": runway.mode,
              "length": runway.lengthController.text,
              "bearing": runway.bearingController.text,
              "runwayId": runway.runwayIdController.text,
              "events": runway.events
                  .map(
                    (event) => {
                      "type": event.type,
                      "start": event.startController.text,
                      "duration": event.durationController.text,
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
    };

    final record = ScenarioRecord(
      id: scenarioId,
      name: scenarioName,
      description: jsonEncode(metadata),
      createdAt: timestamp.toUtc(),
    );

    await AppPersistence.instance.store.upsertScenario(record);
    return record;
  }
}
