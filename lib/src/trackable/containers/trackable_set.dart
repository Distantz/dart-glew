import 'dart:collection';
import 'package:glew/glew.dart';

enum TrackableSetOperation { addItem, removeItem, clear }

class TrackableSet<T> extends SetBase<T> implements Trackable {
  final Set<T> _inner = {};
  final List<Map<String, dynamic>> _delta = [];

  final JsonConverter itemConverter;

  static const String opKey = "o";
  static const String valueKey = "v";

  TrackableSet({this.itemConverter = const DefaultConverter()});

  void _addDelta(TrackableSetOperation op, {T? value}) {
    Map<String, dynamic> delta = {opKey: op.index};
    if (value != null) delta[valueKey] = itemConverter.toJson(value);
    _delta.add(delta);
  }

  @override
  bool add(T value) {
    if (_inner.add(value)) {
      _addDelta(TrackableSetOperation.addItem, value: value);
      return true;
    }

    return false;
  }

  @override
  bool contains(Object? element) {
    return _inner.contains(element);
  }

  @override
  Iterator<T> get iterator => _inner.iterator;

  @override
  int get length => _inner.length;

  @override
  T? lookup(Object? element) {
    return _inner.lookup(element);
  }

  @override
  bool remove(Object? value) {
    if (_inner.remove(value)) {
      _addDelta(TrackableSetOperation.removeItem, value: value as T);
      return true;
    }

    return false;
  }

  @override
  Set<T> toSet() => _inner.toSet();

  T getValueFromDelta(dynamic delta) {
    dynamic valObj = delta[valueKey];
    return valObj != null ? itemConverter.fromJson(valObj) : null;
  }

  @override
  void applyIncomingDelta(delta) {
    for (var change in delta) {
      switch (TrackableSetOperation.values[change[opKey]]) {
        case TrackableSetOperation.addItem:
          _inner.add(getValueFromDelta(delta));
        case TrackableSetOperation.removeItem:
          _inner.remove(getValueFromDelta(delta));
        case TrackableSetOperation.clear:
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
    // In JSON it just looks like a list. Ordering should be preserved in ordered sets then too.
    return _inner.map((value) => itemConverter.toJson(value)).toList();
  }

  @override
  void setJson(json) {
    _inner
      ..clear()
      ..addAll(
        (json as List<dynamic>).map((value) => itemConverter.fromJson(value)),
      );
    clearOutgoingDelta();
  }
}
