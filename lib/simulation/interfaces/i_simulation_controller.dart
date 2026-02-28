import 'dart:collection';

import 'i_airport.dart';
import 'i_runway_event.dart';

/// Interface for the Simulation Controller - should aggregate statistics as the simulation plays out.
abstract class ISimulationController {
  /// Adds all arriving and departing aircraft to the holding pattern/take-off queue once there actual
  /// time has been reached by the simulation clock.
  void includeEnteringAircraft(IAirport airport);

  /// Schedules landing/departing aircrafts to available runways
  void assignAircrafts(IAirport airport);

  /// Starts any runway events that begin at the current simulation clock tick.
  void startRunwayEvents(Queue<IRunwayEvent> events, IAirport airport);

  /// Updates the simulation clock - typically via an increment.
  void updateSimClock();

  /// Divert and cancel any aircraft in the holdin pattern/take-off queues if they have too
  /// little fuel or have been delayed for too long.
  void enactFlightChanges();
}