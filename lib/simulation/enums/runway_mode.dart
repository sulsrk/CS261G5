/// Represents mode of runways.
/// Note that [RunwayMode.mixed] is ONLY to be used upon instantiation of runways
/// and should not be used during the simulation run.
enum RunwayMode {
  landing,
  takeOff,
  mixed
}