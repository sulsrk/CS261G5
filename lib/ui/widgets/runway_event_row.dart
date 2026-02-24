import 'package:flutter/material.dart';
import '../models/runway_config_ui.dart';

class RunwayEventRow extends StatelessWidget {
  final RunwayEventUI event;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const RunwayEventRow({
    super.key,
    required this.event,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: event.type,
                  items: const [
                    DropdownMenuItem(value: "Inspection", child: Text("Inspection")),
                    DropdownMenuItem(value: "Obstruction", child: Text("Obstruction")),
                    DropdownMenuItem(value: "Maintenance", child: Text("Maintenance")),
                    DropdownMenuItem(value: "Closure", child: Text("Closure")),
                  ],
                  validator: (v) =>
                      v == null || v.isEmpty ? "Select type" : null,
                  onChanged: (v) {
                    event.type = v!;
                    onChanged();
                  },
                  decoration: const InputDecoration(
                    labelText: "Event Type",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: TextFormField(
                  controller: event.startController,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "This field is required";
                    final n = int.tryParse(v);
                    if (n == null || n < 0) return "Value must be greater than 0";
                    return null;
                  },
                  onChanged: (_) => onChanged(),
                  decoration: const InputDecoration(
                    labelText: "Start",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: TextFormField(
                  controller: event.durationController,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "This field is required";
                    final n = int.tryParse(v);
                    if (n == null || n <= 0) return "Valid must be at least 0";
                    return null;
                  },
                  onChanged: (_) => onChanged(),
                  decoration: const InputDecoration(
                    labelText: "Duration",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}