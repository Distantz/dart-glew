import 'package:glew/src/trackables/trackable_state.dart';
import 'package:sane_uuid/uuid.dart';

/// Context class supplied to all Trackables to allow for general management.
abstract class TrackingContext {
  /// Registers this trackable state with the context.
  bool trackObject(TrackableState object);

  /// Unregisters this trackable state with the context.
  bool untrackObject(TrackableState object);

  /// Looks up an object from it's ID. Can be null, if the object
  /// isn't registered.
  T? lookupObject<T extends TrackableState>(Uuid id);

  /// Returns an unmodifiable list of spawned objects
  List<TrackableState> getSpawnedObjects();
}

class EmptyTrackingContext extends TrackingContext {
  @override
  List<TrackableState> getSpawnedObjects() {
    return List.unmodifiable([]);
  }

  @override
  T? lookupObject<T extends TrackableState>(Uuid id) {
    return null;
  }

  @override
  bool trackObject(TrackableState object) {
    return false;
  }

  @override
  bool untrackObject(TrackableState object) {
    return false;
  }
}
