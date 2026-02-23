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
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: FormField<String>(
              initialValue: event.type,
              validator: (value) {
                if (value == null || value.isEmpty) return "Select an event type";
                return null;
              },
              builder: (fieldState) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: event.type,
                      items: const [
                        DropdownMenuItem(value: "Inspection", child: Text("Inspection")),
                        DropdownMenuItem(value: "Obstruction", child: Text("Obstruction")),
                        DropdownMenuItem(value: "Maintenance", child: Text("Maintenance")),
                        DropdownMenuItem(value: "Closure", child: Text("Closure")),
                      ],
                      onChanged: (value) {
                        event.type = value!;
                        fieldState.didChange(value);
                        onChanged();
                      },
                      decoration: const InputDecoration(
                        labelText: "Event Type",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (fieldState.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 5, left: 5),
                        child: Text(
                          fieldState.errorText!,
                          style: const TextStyle(color: Colors.red, fontSize: 10),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              children: [
                TextFormField(
                  controller: event.startController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Start",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "This field is required";
                    final intVal = int.tryParse(value);
                    if (intVal == null || intVal < 0) return "Enter a valid non-negative number";
                    return null;
                  },
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              children: [
                TextFormField(
                  controller: event.durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Duration",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "This field is required";
                    final intVal = int.tryParse(value);
                    if (intVal == null || intVal <= 0) return "Enter a valid positive number";
                    return null;
                  },
                ),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(Icons.remove_circle, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}