import 'package:glew/src/connection/glew_connection.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Object base for a JSONRPC Peer service.
/// Registers provided GlewRPCs on the given channel, with full auth support.
class SocketGlewConnection extends Peer implements GlewConnection {
  final WebSocketChannel channel;

  static const String remoteRPCRequestID = "RPC";
  static const String calledRPCKey = "name";
  static const String objectRPCKey = "obj";
  static const String paramsRPCKey = "params";

  Future<dynamic> Function(
    GlewConnection fromConnection,
    String rpcID,
    Map<String, dynamic> jsonParams, {
    Uuid? targetObject,
  })?
  rpcHandler;

  SocketGlewConnection(this.channel) : super(channel.cast<String>()) {
    registerMethod(remoteRPCRequestID, (Parameters params) {
      if (rpcHandler == null) return;

      rpcHandler!.call(
        this,
        params[remoteRPCRequestID].asString,
        params[paramsRPCKey].asMap as Map<String, dynamic>,
        targetObject:
            params[objectRPCKey].exists
                ? Uuid.fromString(params[objectRPCKey].asString)
                : null,
      );
    });
  }

  @override
  Future<T> callRemoteRPC<T>(
    String rpcID,
    Map<String, dynamic> jsonParams, {
    Uuid? targetObject,
  }) async {
    Map<String, dynamic> rpcRequest = {
      calledRPCKey: rpcID,
      paramsRPCKey: jsonParams,
    };

    if (targetObject != null) {
      rpcRequest[objectRPCKey] = targetObject.toString();
    }

    return await sendRequest(remoteRPCRequestID, rpcRequest);
  }

  @override
  bool isOpen() => !isClosed;

  @override
  void setRemoteRPCHandler(RemoteRPCHandler? callback) {
    rpcHandler = callback;
  }
}
