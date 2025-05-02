import 'dart:collection';
import 'package:glew/glew.dart';

enum TrackableListOperation { add, insertAt, setAt, removeAt, clear, setLength }

class TrackableList<T> extends ListBase<T> implements Trackable {
  final List<T> _inner = [];
  final List<Map<String, dynamic>> _delta = [];

  final JsonConverter itemConverter;

  TrackableList({this.itemConverter = const DefaultConverter()});

  static const String opKey = "o";
  static const String indexKey = "i";
  static const String valueKey = "v";
  static const String lengthKey = "l";

  @override
  int get length => _inner.length;

  @override
  set length(int newLength) {
    // Custom delta
    _delta.add({
      opKey: TrackableListOperation.setLength.index,
      lengthKey: newLength,
    });
    _inner.length = newLength;
  }

  @override
  T operator [](int index) => _inner[index];

  @override
  void operator []=(int index, T value) {
    _addDelta(TrackableListOperation.setAt, index: index, value: value);
    _inner[index] = value;
  }

  @override
  void add(T element) {
    _addDelta(TrackableListOperation.add, value: element);
    _inner.add(element);
  }

  @override
  T removeAt(int index) {
    _addDelta(TrackableListOperation.removeAt, index: index);
    T removed = _inner.removeAt(index);
    return removed;
  }

  @override
  bool remove(Object? element) {
    if (element is! T) {
      return false;
    }
    int index = _inner.indexOf(element);

    if (index != -1) {
      removeAt(index);
      return true;
    }
    return false;
  }

  @override
  void insert(int index, T element) {
    _addDelta(TrackableListOperation.insertAt, index: index, value: element);
    _inner.insert(index, element);
  }

  @override
  void clear() {
    _addDelta(TrackableListOperation.clear);
    _inner.clear();
  }

  void _addDelta(TrackableListOperation op, {int? index, T? value}) {
    Map<String, dynamic> delta = {opKey: op.index};
    if (index != null) delta[indexKey] = index;
    if (value != null) delta[valueKey] = itemConverter.toJson(value);
    _delta.add(delta);
  }

  @override
  bool hasOutgoingDelta() => _delta.isNotEmpty;

  @override
  dynamic getOutgoingDelta() => List.unmodifiable(_delta);

  T getValFromDelta(dynamic delta) {
    dynamic valObj = delta[valueKey];
    return valObj != null ? itemConverter.fromJson(valObj) : null;
  }

  int getIndexFromDelta(dynamic delta) {
    return delta[indexKey];
  }

  @override
  void applyIncomingDelta(dynamic delta) {
    for (var change in delta) {
      switch (TrackableListOperation.values[change[opKey]]) {
        case TrackableListOperation.add:
          _inner.add(getValFromDelta(delta));
        case TrackableListOperation.insertAt:
          _inner.insert(getIndexFromDelta(delta), getValFromDelta(delta));
        case TrackableListOperation.setAt:
          _inner[getIndexFromDelta(delta)] = getValFromDelta(delta);
        case TrackableListOperation.removeAt:
          _inner.removeAt(getIndexFromDelta(delta));
        case TrackableListOperation.clear:
          _inner.clear();
        case TrackableListOperation.setLength:
          _inner.length = change[lengthKey] as int;
      }
    }
  }

  @override
  void clearOutgoingDelta() {
    _delta.clear();
  }

  @override
  void setJson(dynamic json) {
    _inner
      ..clear()
      ..addAll(
        (json as List<dynamic>).map((json) => itemConverter.fromJson(json)),
      );
    clearOutgoingDelta();
  }

  @override
  dynamic getJson() => _inner.map((obj) => itemConverter.toJson(obj)).toList();
}
