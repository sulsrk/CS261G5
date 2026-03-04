import 'package:air_traffic_sim/ui/widgets/runway_canvas.dart';
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

  final TextEditingController runwayCountController = TextEditingController(
    text: "1",
  );

  final TextEditingController mechanicalProbController = TextEditingController(
    text: "0",
  );

  final TextEditingController medicalProbController = TextEditingController(
    text: "0",
  );

  final TextEditingController inboundFlowController = TextEditingController();

  final TextEditingController outboundFlowController = TextEditingController();

  final TextEditingController maxWaitController = TextEditingController(
    text: "30",
  );

  final TextEditingController fuelThresholdController = TextEditingController(
    text: "10",
  );

  final TextEditingController durationController = TextEditingController(
    text: "1",
  );

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
              children: [
                const SizedBox(height: 10),

                Column(
                  children: [
                    // Flow
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildNumberField(
                            controller: inboundFlowController,
                            label: "Inbound Flow Rate (aircraft/hour)",
                            min: 0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildNumberField(
                            controller: outboundFlowController,
                            label: "Outbound Flow Rate (aircraft/hour)",
                            min: 0,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Probabilities
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildNumberField(
                            controller: mechanicalProbController,
                            label: "Mechanical Failure Probability (0-100%)",
                            min: 0,
                            max: 100,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildNumberField(
                            controller: medicalProbController,
                            label: "Medical Emergency Probability (0-100%)",
                            min: 0,
                            max: 100,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Operational Limits
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildNumberField(
                            controller: maxWaitController,
                            label: "Max Outbound Wait (minutes)",
                            min: 1,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildNumberField(
                            controller: fuelThresholdController,
                            label: "Fuel Diversion Threshold (minutes)",
                            min: 1,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildNumberField(
                            controller: durationController,
                            label: "Simulation Duration (hours)",
                            min: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: RunwayCanvas(
                    runways: runways,
                    onAdd: _addRunway,
                    onRemove: _removeRunway,
                    onEdit: _editRunway,
                  ),
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

  void _editRunway(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Configure Runway ${index + 1}"),
              content: SizedBox(
                width: 600,
                child: RunwayCard(
                  runway: runways[index],
                  index: index,
                  onChanged: () {
                    setDialogState(() {});
                    runways[index].isInvalid = false;
                    setState(() {});
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _addRunway() {
    if (runways.length < 10) {
      setState(() {
        runways.add(RunwayConfigUI());
      });
    }
  }

  void _removeRunway(int index) {
    if (runways.length > 1) {
      setState(() {
        runways.removeAt(index);
      });
    }
  }

  void _runSimulation() {
    final mainValid = _formKey.currentState!.validate();

    bool allValid = true;

    for (final runway in runways) {
      final valid = runway.isValid();
      runway.isInvalid = !valid;
      if (!valid) allValid = false;
    }

    setState(() {});

    if (!mainValid || !allValid) {
      return;
    }

    Navigator.pushNamed(
      context,
      '/results',
      arguments: {
        "metrics": {
          "maxInboundDelay": 12,
          "maxOutboundDelay": 18,
          "avgInboundQueue": 3.2,
          "maxInboundQueue": 9,
          "avgOutboundQueue": 2.4,
          "maxOutboundQueue": 7,
          "diversions": 1,
          "cancellations": 0,
          "utilisationPct": 73.5,
        },
        "config": {
          "Inbound Flow Rate": inboundFlowController.text,
          "Outbound Flow Rate": outboundFlowController.text,
          "Runway Count": runways.length,
          // add more config fields + runway configs
        },
        // optional later:
        // "series": {...}
      },
    );
  }

  void _realtimeModel() {
    final mainValid = _formKey.currentState!.validate();

    bool allValid = true;

    for (final runway in runways) {
      final valid = runway.isValid();
      runway.isInvalid = !valid;
      if (!valid) allValid = false;
    }

    setState(() {});

    if (!mainValid || !allValid) {
      return;
    }

    Navigator.pushNamed(context, '/realtime');
  }
}
