import 'package:glew/src/trackables/trackable.dart';
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

  factory TrackableStateReference.fromState(T? state) {
    return TrackableStateReference(state?.stateID ?? Uuid.v4());
  }

  TrackableStateReference(Uuid id) : _stateID = TrackableValue(id);

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
  void clearOutgoingDelta() {
    _stateID.clearOutgoingDelta();
  }

  @override
  void onNewContext(TrackingContext newContext) {
    context = newContext;
  }

  @override
  Map<String, dynamic> getJson() {
    return _stateID.getJson();
  }

  @override
  void setJson(json) {
    _stateID.value = Uuid.fromString(json);
  }
}
