import 'package:flutter/material.dart';

class RunwayEventUI {
  String type;
  TextEditingController startController;
  TextEditingController durationController;

  RunwayEventUI({
    String? type,
  })  : type = type ?? "Inspection",
        startController = TextEditingController(),
        durationController = TextEditingController();
}

class RunwayConfigUI {
  String mode;

  TextEditingController lengthController;
  TextEditingController bearingController;
  TextEditingController runwayIdController;

  List<RunwayEventUI> events;

  bool isInvalid = false;

  RunwayConfigUI({
    this.mode = "Landing",
    int? length,
    int bearing = 0,
    String? runwayId,
    List<RunwayEventUI>? events,
  })  : lengthController =
            TextEditingController(text: length?.toString() ?? ""),
        bearingController =
            TextEditingController(text: bearing.toString()),
        runwayIdController =
            TextEditingController(text: runwayId ?? ""),
        events = events ?? [];

  bool isValid() {
    final length = int.tryParse(lengthController.text);
    final bearing = int.tryParse(bearingController.text);
    final runwayId = runwayIdController.text;

    if (length == null || length <= 0) return false;
    if (bearing == null || bearing < 0 || bearing > 360) return false;
    if (!RegExp(r'^\d{2}$').hasMatch(runwayId)) return false;

    for (final event in events) {
      final start = int.tryParse(event.startController.text);
      final duration = int.tryParse(event.durationController.text);

      if (event.type.isEmpty) return false;
      if (start == null || start < 0) return false;
      if (duration == null || duration <= 0) return false;
    }

    return true;
  }

}