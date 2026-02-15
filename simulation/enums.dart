// enums.dart

// Operational status of runways
enum RunwayStatus {
  available,
  inspection,
  snowClearance,
  equipmentFailure,
  closure
}

// Represents  mode of a runways
enum RunwayMode {
  landing,
  takeOff
}

// Represents emergency status of an aircraft
enum EmergencyStatus {
  none,
  fuel,
  mechanical,
  health
}