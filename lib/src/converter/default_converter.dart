import 'package:glew/src/converters/json_converter.dart';

/// A base converter that defaults to explicitly casting from JSON and returning itself for toJson.
/// Should be used for values that are directly translatable, like literals or containers.
class DefaultConverter<T> extends JsonConverter<T> {
  const DefaultConverter();
  @override
  T fromJson(json) {
    return json as T;
  }

  @override
  toJson(T from) {
    return from;
  }
}
