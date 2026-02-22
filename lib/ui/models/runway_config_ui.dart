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
}