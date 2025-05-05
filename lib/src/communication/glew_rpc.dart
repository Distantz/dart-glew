import 'package:glew/glew.dart';
import 'package:glew/src/api/glew_api.dart';
import 'package:glew/src/connection/glew_connection.dart';
import 'package:sane_uuid/uuid.dart';

class GlewRPC<T> {
  /// Used to translate parameters to and from their respective types. If a parameter is not present here,
  /// a default converter will be used instead.
  final Map<String, JsonConverter> customParameterConverter;
  final DefaultConverter defaultConverter = const DefaultConverter();

  /// Used to transalte the returned value to and from JSON.
  final JsonConverter returnTypeConverter;

  /// The code called remotely as a result of calling this RPC.
  final Future<T> Function(
    GlewConnection remoteCaller,
    GlewAPI api,
    Map<String, dynamic> params,
  )
  remoteProcedure;

  Uuid? _containerUuid;
  String _containerRpcID = "";
  GlewAPI? api;

  GlewRPC({
    required this.remoteProcedure,
    required this.customParameterConverter,
    this.returnTypeConverter = const DefaultConverter(),
  });

  /// Calls this RPC on the connection provided.
  Future<T> callOnConnection(
    GlewConnection onConnection,
    Map<String, dynamic> params,
  ) async {
    return await returnTypeConverter.fromJson(
      await onConnection.callRemoteRPC(
        _containerRpcID,
        params.map(
          (key, val) => MapEntry(
            key,
            (customParameterConverter[key] ?? defaultConverter).toJson(val),
          ),
        ),
        targetObject: _containerUuid,
      ),
    );
  }

  /// Handles an RPC call from a remote source. It is assumed that this RPC is
  /// allowed. In cases it shouldn't be, write an early exit, checking the
  /// remote caller.
  Future<T> handle(
    GlewConnection remoteCaller,
    GlewAPI api,
    Map<String, dynamic> jsonParams,
  ) async {
    final Map<String, dynamic> params = jsonParams.map(
      (key, val) => MapEntry(
        key,
        (customParameterConverter[key] ?? defaultConverter).fromJson(val),
      ),
    );
    return await remoteProcedure.call(remoteCaller, api, params);
  }

  void setRegisterInfo(
    GlewAPI api,
    Uuid? containerUuid,
    String containerRpcID,
  ) {
    this.api = api;
    _containerUuid = containerUuid;
    _containerRpcID = containerRpcID;
  }
}
