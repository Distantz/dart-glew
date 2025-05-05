import 'dart:collection';
import 'package:glew/glew.dart';

enum TrackableMapOperation { setKey, removeKey, clear }

class TrackableMap<K, V> extends MapBase<K, V> implements Trackable {
  final Map<K, V> _inner = {};
  final List<Map<String, dynamic>> _delta = [];

  final JsonConverter keyConverter;
  final JsonConverter valueConverter;

  static const String opKey = "o";
  static const String keyKey = "k"; // do you love me?
  static const String valueKey = "v";

  TrackableMap({
    this.keyConverter = const DefaultConverter(),
    this.valueConverter = const DefaultConverter(),
  });

  void _addDelta(TrackableMapOperation op, {K? key, V? value}) {
    Map<String, dynamic> delta = {opKey: op.index};
    if (key != null) delta[keyKey] = keyConverter.toJson(key);
    if (value != null) delta[valueKey] = valueConverter.toJson(value);
    _delta.add(delta);
  }

  @override
  V? operator [](Object? key) {
    return _inner[key];
  }

  @override
  void operator []=(K key, V value) {
    _addDelta(TrackableMapOperation.setKey, key: key, value: value);
    _inner[key] = value;
  }

  @override
  Iterable<K> get keys => _inner.keys;

  @override
  void clear() {
    _addDelta(TrackableMapOperation.clear);
    _inner.clear();
  }

  @override
  V? remove(Object? key) {
    _addDelta(TrackableMapOperation.removeKey, key: key as K);
    return _inner.remove(key);
  }

  K getKeyFromDelta(dynamic delta) {
    dynamic valObj = delta[keyKey];
    return valObj != null ? keyConverter.fromJson(valObj) : null;
  }

  V getValueFromDelta(dynamic delta) {
    dynamic valObj = delta[valueKey];
    return valObj != null ? valueConverter.fromJson(valObj) : null;
  }

  @override
  void applyIncomingDelta(delta) {
    for (var change in delta) {
      switch (TrackableMapOperation.values[change[opKey]]) {
        case TrackableMapOperation.setKey:
          _inner[getKeyFromDelta(delta)] = getValueFromDelta(delta);
        case TrackableMapOperation.removeKey:
          _inner.remove(getKeyFromDelta(delta));
        case TrackableMapOperation.clear:
          _inner.clear();
      }
    }
  }

  @override
  void clearOutgoingDelta() {
    _delta.clear();
  }

  @override
  getOutgoingDelta() {
    return _delta;
  }

  @override
  bool hasOutgoingDelta() {
    return _delta.isNotEmpty;
  }

  @override
  getJson() {
    return _inner.map(
      (key, value) =>
          MapEntry(keyConverter.toJson(key), valueConverter.toJson(value)),
    );
  }

  @override
  void setJson(json) {
    _inner
      ..clear()
      ..addAll(
        (json as Map<dynamic, dynamic>).map(
          (key, value) => MapEntry(
            keyConverter.fromJson(key),
            valueConverter.fromJson(value),
          ),
        ),
      );
    clearOutgoingDelta();
  }
}
