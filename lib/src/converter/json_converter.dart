/// Small converter class used to convert a type between json and back.
abstract class JsonConverter<T> {
  const JsonConverter();

  T fromJson(dynamic json);
  dynamic toJson(T from);
}
