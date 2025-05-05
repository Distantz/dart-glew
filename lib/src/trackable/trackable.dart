/// Base interface for a trackable object, which provides and takes in a "delta", as well as allowing direct JSONification.
abstract class Trackable {
  /**
   * Trackable Promises
   * Trackables track their deltas.
   * They should be able to update from a delta as well.
   */

  /// Whether there is an outgoing delta on this object.
  bool hasOutgoingDelta();

  /// Returns the outgoing delta of the object.
  dynamic getOutgoingDelta();

  /// Applies an incoming delta to the object.
  void applyIncomingDelta(dynamic delta);

  // Clears the outgoing delta on the object.
  void clearOutgoingDelta();

  /**
   * JSON Promises
   * All trackable fields NEED to be able to convert to/from JSON.
   */

  /// Create this object from a complete JSON definition.
  void setJson(dynamic json);

  /// Convert this object to a complete JSON definition.
  dynamic getJson();
}
