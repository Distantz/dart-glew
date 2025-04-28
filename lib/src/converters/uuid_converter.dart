import 'package:glew/src/converters/json_converter.dart';
import 'package:sane_uuid/uuid.dart';

/// Should be used for values that are directly translatable, like literals or containers.
class UuidConverter extends JsonConverter<Uuid> {
  const UuidConverter();
  @override
  Uuid fromJson(dynamic json) {
    return Uuid.fromString(json as String);
  }

  @override
  String toJson(Uuid from) {
    return from.toString();
  }
}
