import 'package:glew/src/trackables/trackable.dart';

/// Defines a tracked single value.
class TrackableValue<T> implements Trackable {
  /// Tracked value.
  T _value;

  /// Previous value.
  T _prevValue;

  /// Get the currently stored value
  T get value => _value;

  static const String valueKey = "value";

  /// Sets the value. Will apply a delta.
  set value(T newValue) {
    if (newValue != _value) {
      _value = newValue;
    }
  }

  TrackableValue(this._value) : _prevValue = _value;

  @override
  void applyIncomingDelta(Map<String, dynamic> delta) {
    _value = delta[valueKey] as T;
    _prevValue = _value;
  }

  @override
  Map<String, dynamic> getOutgoingDelta() {
    return {valueKey: _value};
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
  Map<String, dynamic> getJson() {
    return {valueKey: _value};
  }

  @override
  void setJson(dynamic json) {
    _value = json[valueKey];
  }
}
