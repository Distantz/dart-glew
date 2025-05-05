import 'package:glew/src/converters/default_converter.dart';
import 'package:glew/src/converters/json_converter.dart';
import 'package:glew/src/trackables/trackable.dart';

/// Defines a tracked single value.
class TrackableValue<T> implements Trackable {
  /// Tracked value.
  T _value;

  /// Previous value.
  T _prevValue;

  /// Get the currently stored value
  T get value => _value;

  /// The serialization to use for the value
  JsonConverter converter;

  /// Sets the value. Will apply a delta.
  set value(T newValue) {
    if (newValue != _value) {
      _value = newValue;
    }
  }

  /// Creates a trackable value, with a default value, and an optional custom JSON converter.
  TrackableValue(this._value, {this.converter = const DefaultConverter()})
    : _prevValue = _value;

  @override
  void applyIncomingDelta(dynamic delta) {
    setJson(delta);
    _prevValue = _value;
  }

  @override
  dynamic getOutgoingDelta() {
    return getJson();
  }

  @override
  bool hasOutgoingDelta() {
    return _value != _prevValue;
  }

  @override
  void clearOutgoingDelta() {
    _prevValue = _value;
  }

  @override
  dynamic getJson() {
    return converter.toJson(_value);
  }

  @override
  void setJson(dynamic json) {
    _value = converter.fromJson(json);
    clearOutgoingDelta();
  }
}
