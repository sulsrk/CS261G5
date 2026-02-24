import 'package:flutter/material.dart';
import '../models/runway_config_ui.dart';
import 'runway_event_row.dart';

class RunwayCard extends StatefulWidget {
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
  State<RunwayCard> createState() => _RunwayCardState();
}

class _RunwayCardState extends State<RunwayCard> {
  final _runwayKey = GlobalKey<FormState>();
  bool _isInvalid = false; // track if this runway failed validation

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _isInvalid ? Colors.red.shade50 : null, // highlight invalid runways
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _runwayKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Runway ${widget.index + 1}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              _buildDropdown(
                value: widget.runway.mode,
                label: "Operating Mode",
                items: const ["Landing", "TakeOff", "Mixed"],
                onChanged: (value) {
                  widget.runway.mode = value!;
                  widget.onChanged();
                },
              ),

              const SizedBox(height: 10),

              _buildNumberField(
                controller: widget.runway.lengthController,
                label: "Runway Length (metres)",
                validator: (v) {
                  if (v == null || v.isEmpty) return "Required";
                  final val = int.tryParse(v);
                  if (val == null || val <= 0) return "Must be positive";
                  return null;
                },
              ),

              const SizedBox(height: 10),

              _buildNumberField(
                controller: widget.runway.bearingController,
                label: "Bearing (0-360)",
                validator: (v) {
                  if (v == null || v.isEmpty) return "Required";
                  final val = int.tryParse(v);
                  if (val == null || val < 0 || val > 360) return "0-360";
                  return null;
                },
              ),

              const SizedBox(height: 10),

              _buildNumberField(
                controller: widget.runway.runwayIdController,
                label: "Runway ID",
                validator: (v) {
                  if (v == null || v.isEmpty) return "Required";
                  if (!RegExp(r'^\d{2}$').hasMatch(v)) return "Two digits";
                  return null;
                },
              ),

              const SizedBox(height: 10),

              const Text("Events", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.runway.events.length,
                itemBuilder: (context, i) {
                  final event = widget.runway.events[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RunwayEventRow(
                      event: event,
                      onChanged: widget.onChanged,
                      onDelete: () {
                        widget.runway.events.removeAt(i);
                        widget.onChanged();
                      },
                    ),
                  );
                },
              ),

              TextButton.icon(
                onPressed: () {
                  setState(() {
                    widget.runway.events.add(RunwayEventUI());
                    widget.onChanged();
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text("Add Event"),
              ),

              const SizedBox(height: 10),

              // ✅ Confirm button for this runway
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    final isValid = _runwayKey.currentState!.validate();
                    setState(() => _isInvalid = !isValid);
                  },
                  child: const Text("Confirm Runway"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField({
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

  Widget _buildDropdown({
    required String value,
    required String label,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  bool validateRunway() {
    final valid = _runwayKey.currentState?.validate() ?? false;
    setState(() => _isInvalid = !valid);
    return valid;
  }
}