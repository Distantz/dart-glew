import 'package:glew/glew.dart';
import 'package:glew/src/trackables/tracking_context.dart';
import 'package:sane_uuid/uuid.dart';

/// A context object which manages state objects.
/// It provides its context object to those it tracks, and keeps a reference of
/// each.
/// It also exposes a Trackable API to allow for easy changes.
class TrackableStateManager implements TrackingContext, Trackable {
  /// Used to track objects within the state
  final Map<Uuid, TrackableState> _trackedObjects = {};

  // A map of Type strings to Factory constructors for making state objects
  final Map<String, TrackableState Function(Uuid stateID)> _objectFactory;

  /// Outgoing delta tracking for adding objects
  final List<TrackableState> _deltaOutgoingCreateList = [];

  /// Outgoing delta tracking for removing objects
  final List<TrackableState> _deltaOutgoingRemoveList = [];

  TrackableStateManager(this._objectFactory);

  static const String createKey = "CREATE";
  static const String removeKey = "REMOVE";
  static const String changeKey = "CHANGE";

  ///
  /// Overview of JSON Structure:
  ///
  /// "CREATE": {
  ///   "UUID": {
  ///     // JSON Data
  ///   },
  ///   "UUID": {
  ///     // JSON Data
  ///   },
  ///   ...
  /// },
  /// "REMOVE": [
  ///   "UUID",
  ///   "UUID",
  ///   ...
  /// ],
  /// "DELTA": {
  ///   "UUID": {
  ///     // JSON Data
  ///   },
  ///   "UUID": {
  ///     // JSON Data
  ///   },
  ///   ...
  /// }

  //#region Tracking Context promises

  @override
  bool trackObject(TrackableState object) {
    if (_trackedObjects.containsKey(object.stateID)) {
      return false;
    }

    _trackedObjects[object.stateID] = object;

    // Do delta check
    int found = _deltaOutgoingRemoveList.indexOf(object);
    if (found != -1) {
      _deltaOutgoingRemoveList.removeAt(found);
    } else {
      _deltaOutgoingCreateList.add(object);
    }

    object.onNewContext(this);
    return true;
  }

  @override
  bool untrackObject(TrackableState object) {
    if (!_trackedObjects.containsKey(object.stateID)) {
      return false;
    }

    _trackedObjects.remove(object.stateID);

    // Do delta check
    int found = _deltaOutgoingCreateList.indexOf(object);
    if (found != -1) {
      _deltaOutgoingCreateList.removeAt(found);
    } else {
      _deltaOutgoingRemoveList.add(object);
    }

    object.onNewContext(EmptyTrackingContext());
    return true;
  }

  @override
  T? lookupObject<T extends TrackableState>(Uuid id) {
    return _trackedObjects[id] as T;
  }

  @override
  List<TrackableState> getSpawnedObjects() {
    return List.unmodifiable(_trackedObjects.values);
  }

  //#endregion
  //#region Trackable promises

  void parseCreates(Map<String, dynamic> creates) {
    creates.forEach((key, value) {
      trackObject(
        makeTrackableState(value[TrackableState.typeKey], key, value),
      );
    });
  }

  void parseRemoves(List<String> removes) {
    for (String uuid in removes) {
      untrackObject(lookupObject(Uuid.fromString(uuid))!);
    }
  }

  void parseChanges(Map<String, dynamic> changes) {
    changes.forEach((key, value) {
      _trackedObjects[Uuid.fromString(key)]?.applyIncomingDelta(value);
    });
  }

  @override
  void applyIncomingDelta(dynamic delta) {
    // First, remove
    if (delta.containsKey(removeKey)) {
      parseRemoves(delta[removeKey]);
    }

    // Then, add
    if (delta.containsKey(createKey)) {
      parseCreates(delta[createKey]);
    }

    // Then, deal with deltas
    if (delta.containsKey(changeKey)) {
      parseChanges(delta[changeKey]);
    }
  }

  @override
  void clearOutgoingDelta() {
    _deltaOutgoingCreateList.clear();
    _deltaOutgoingRemoveList.clear();

    for (TrackableState state in _trackedObjects.values) {
      state.clearOutgoingDelta();
    }
  }

  Map<String, dynamic> deltaCreates() {
    Map<String, dynamic> changes = {};

    for (TrackableState state in _deltaOutgoingCreateList) {
      changes[state.stateID.toString()] = state.getJson();
    }

    return changes;
  }

  List<String> deltaRemoves() {
    return _deltaOutgoingRemoveList
        .map((item) => item.stateID.toString())
        .toList();
  }

  @override
  Map<String, dynamic> getOutgoingDelta() {
    // We don't care about the deltas of objects we are adding or removing.
    Set<Uuid> discardDelta =
        _deltaOutgoingCreateList
            .toSet()
            .union(_deltaOutgoingRemoveList.toSet())
            .map((state) => state.stateID)
            .toSet();

    Map<String, dynamic> thisDelta = {};

    if (_deltaOutgoingCreateList.isNotEmpty) {
      thisDelta[createKey] = deltaCreates();
    }

    if (_deltaOutgoingRemoveList.isNotEmpty) {
      thisDelta[removeKey] = deltaRemoves();
    }

    Map<String, dynamic> changes = {};

    // Loop through each state obj
    _trackedObjects.forEach((key, value) {
      if (discardDelta.contains(key)) return;
      if (!value.hasOutgoingDelta()) return;

      changes[key.toString()] = value.getOutgoingDelta();
      value.clearOutgoingDelta();
    });

    if (changes.isNotEmpty) {
      thisDelta[changeKey] = changes;
    }

    return thisDelta;
  }

  @override
  bool hasOutgoingDelta() {
    return _deltaOutgoingCreateList.isNotEmpty ||
        _deltaOutgoingRemoveList.isNotEmpty ||
        _trackedObjects.values.any((val) => val.hasOutgoingDelta());
  }

  TrackableState makeTrackableState(String type, String uuid, dynamic json) {
    TrackableState state = _objectFactory[type]!.call(Uuid.fromString(uuid));
    state.setJson(json);
    return state;
  }

  @override
  Map<String, dynamic> getJson() {
    Map<String, dynamic> children = {};

    _trackedObjects.forEach((key, value) {
      children[key.toString()] = value.getJson();
    });

    return children;
  }

  @override
  void setJson(json) {
    // Somehow construct a bunch of JSON objects...
    Map<String, dynamic> jsonObjects = json as Map<String, dynamic>;

    jsonObjects.forEach((key, value) {
      Uuid id = Uuid.fromString(key);

      // Exists? Deserialise into THAT one.
      if (_trackedObjects.containsKey(id)) {
        _trackedObjects[id]!.setJson(value);
      } else {
        TrackableState state = makeTrackableState(
          value[TrackableState.typeKey],
          key,
          value,
        );
        trackObject(state);
      }
    });
  }

  //#endregion
}
