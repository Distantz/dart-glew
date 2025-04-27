import 'package:glew/src/trackables/trackable_state.dart';
import 'package:glew/src/trackables/trackable_value.dart';
import 'package:glew/src/trackables/tracking_context_consumer.dart';
import 'package:glew/src/trackables/tracking_context.dart';
import 'package:sane_uuid/uuid.dart';

class TrackableStateReference<T extends TrackableState>
    implements TrackableValue<T?>, TrackingContextConsumer {
  /// Maintain a UUID reference to support direct serialization and lookup.
  final TrackableValue<Uuid> _stateID;

  TrackingContext context = EmptyTrackingContext();

  TrackableStateReference(T? state)
    : _stateID = TrackableValue(state?.stateID ?? Uuid.v4());

  @override
  T? get value {
    return context.lookupObject(_stateID.value);
  }

  /// Sets the value. Will apply a delta.
  @override
  set value(T? newValue) {
    // A null reference is just a UUID that doesn't exist.
    _stateID.value = newValue?.stateID ?? Uuid.v4();
  }

  @override
  void applyIncomingDelta(Map<String, dynamic> delta) {
    _stateID.applyIncomingDelta(delta);
  }

  @override
  Map<String, dynamic> getOutgoingDelta() {
    return _stateID.getOutgoingDelta();
  }

  @override
  bool hasOutgoingDelta() {
    return _stateID.hasOutgoingDelta();
  }

  @override
  Map<String, dynamic> toJson() {
    return _stateID.toJson();
  }

  @override
  void clearOutgoingDelta() {
    _stateID.clearOutgoingDelta();
  }

  @override
  void onNewContext(TrackingContext newContext) {
    context = newContext;
  }
}
