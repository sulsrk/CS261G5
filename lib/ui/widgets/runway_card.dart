import 'package:flutter/material.dart';
import '../models/runway_config_ui.dart';
import 'runway_event_row.dart';

class RunwayCard extends StatelessWidget {
  final RunwayConfigUI runway;
  final int index;
  final VoidCallback onChanged;

  const RunwayCard({
    super.key,
    required this.runway,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Runway ${index + 1}",
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              initialValue: runway.mode,
              items: const [
                DropdownMenuItem(value: "Landing", child: Text("Landing")),
                DropdownMenuItem(value: "TakeOff", child: Text("Take-Off")),
                DropdownMenuItem(value: "Mixed", child: Text("Mixed")),
              ],
              onChanged: (value) {
                runway.mode = value!;
                onChanged();
              },
              decoration: const InputDecoration(
                labelText: "Operating Mode",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            _buildTextField(
              controller: runway.lengthController,
              label: "Runway Length (metres)",
              validator: (value) {
                if (value == null || value.isEmpty) return "This field is required";
                final intVal = int.tryParse(value);
                if (intVal == null || intVal <= 0) return "Enter a valid positive number";
                return null;
              },
            ),

            const SizedBox(height: 10),

            _buildTextField(
              controller: runway.bearingController,
              label: "Bearing (0-360)",
              validator: (value) {
                if (value == null || value.isEmpty) return "This field is required";
                final intVal = int.tryParse(value);
                if (intVal == null || intVal < 0 || intVal > 360) return "Bearing must be between 0 and 360";
                return null;
              },
            ),

            const SizedBox(height: 10),

            _buildTextField(
              controller: runway.runwayIdController,
              label: "Runway ID",
              validator: (value) {
                if (value == null || value.isEmpty) return "This field is required";
                if (!RegExp(r'^\d{2}$').hasMatch(value)) return "ID must be two digits";
                return null;
              },
            ),

            const SizedBox(height: 10),

            _buildTextField(
              controller: runway.mechanicalProbController,
              label: "Mechanical Failure Probability (0-1)",
              validator: (value) {
                if (value == null || value.isEmpty) return "This field is required";
                final doubleVal = double.tryParse(value);
                if (doubleVal == null || doubleVal < 0 || doubleVal > 1) return "Probability must be between 0 and 1";
                return null;
              },
            ),

            const SizedBox(height: 10),

            _buildTextField(
              controller: runway.medicalProbController,
              label: "Medical Emergency Probability (0-1)",
              validator: (value) {
                if (value == null || value.isEmpty) return "This field is required";
                final doubleVal = double.tryParse(value);
                if (doubleVal == null || doubleVal < 0 || doubleVal > 1) return "Probability must be between 0 and 1";
                return null;
              },
            ),

            const SizedBox(height: 10),

            const Text(
              "Events",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            ...runway.events.map((event) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RunwayEventRow(
                  event: event,
                  onChanged: onChanged,
                  onDelete: () {
                    runway.events.remove(event);
                    onChanged();
                  },
                ),
              );
            }),

            TextButton(
              onPressed: () {
                runway.events.add(RunwayEventUI());
                onChanged();
              },
              child: const Text("Add Event"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}