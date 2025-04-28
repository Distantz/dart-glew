import 'package:glew/src/trackables/trackable.dart';
import 'package:glew/src/trackables/tracking_context.dart';
import 'package:glew/src/trackables/tracking_context_consumer.dart';
import 'package:sane_uuid/uuid.dart';

/// TrackableState is the base class for a collection of one or more Trackables.
/// Networked state objects should implement this class.
abstract class TrackableState implements Trackable, TrackingContextConsumer {
  /// State ID is the UUID used in lookup to find this object. It is also used
  /// directly in Saving, Loading and Network identification.
  final Uuid stateID;

  /// Cache context for easy reuse and access.
  TrackingContext context = EmptyTrackingContext();

  static const String typeKey = "@TYPE";

  TrackableState({required this.stateID}) {
    registerTrackableChildren();
  }

  /// Children that will be tracked as part of this.
  final Map<String, Trackable> _trackedChildren = {};

  /// Tracks a child trackable to this object. If changed,
  /// the delta will propogate up to this.
  bool registerTrackableChild(String id, Trackable child) {
    if (_trackedChildren.containsKey(id)) {
      return false;
    }

    _trackedChildren[id] = child;
    return true;
  }

  /// A helper method to register trackable children in a state object.
  /// This function will be called in the Trackable constructor.
  void registerTrackableChildren() {}

  @override
  void applyIncomingDelta(dynamic delta) {
    delta.forEach((key, value) {
      // Not recognised will simply return out. This could be changed to an
      // error instead.
      if (!_trackedChildren.containsKey(key)) {
        return;
      }

      _trackedChildren[key]!.applyIncomingDelta(value);
    });
  }

  @override
  Map<String, dynamic> getOutgoingDelta() {
    Map<String, dynamic> accumDelta = {};

    _trackedChildren.forEach((key, value) {
      if (value.hasOutgoingDelta()) {
        accumDelta[key] = value.getOutgoingDelta();
      }
    });

    return accumDelta;
  }

  @override
  bool hasOutgoingDelta() {
    for (Trackable trackable in _trackedChildren.values) {
      if (trackable.hasOutgoingDelta()) {
        return true;
      }
    }

    return false;
  }

  @override
  void clearOutgoingDelta() {
    for (Trackable trackable in _trackedChildren.values) {
      trackable.clearOutgoingDelta();
    }
  }

  @override
  Map<String, dynamic> getJson() {
    Map<String, dynamic> json = {};

    // Add special TYPE string to help with deserialization.
    json[typeKey] = runtimeType.toString();

    _trackedChildren.forEach((key, value) {
      json[key] = value.getJson();
    });

    return json;
  }

  @override
  void setJson(dynamic json) {
    _trackedChildren.forEach((key, value) {
      value.setJson(json[key]);
    });
  }

  @override
  void onNewContext(TrackingContext newContext) {
    context = newContext;
    for (Trackable trackable in _trackedChildren.values) {
      if (trackable is TrackingContextConsumer) {
        (trackable as TrackingContextConsumer).onNewContext(newContext);
      }
    }
  }
}
