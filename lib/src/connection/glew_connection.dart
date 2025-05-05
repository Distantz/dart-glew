import 'package:sane_uuid/uuid.dart';

typedef RemoteRPCHandler<T> =
    Future<T> Function(
      GlewConnection fromConnection,
      String rpcID,
      Map<String, dynamic> jsonParams, {
      Uuid? targetObject,
    });

/// Abstract class for Glew connections.
/// This is the expected interface for connections
/// This can be through any protocol.
/// This connection can send and recieve messages.
abstract class GlewConnection {
  /// Returns whether the connection is open
  bool isOpen();

  /// Opens the connection
  Future listen();

  /// Closes the connection
  Future<void> close();

  /// Calls a remote RPC on the other end of this connection.
  /// Returns a future which provides the result of the RPC when done.
  Future<T> callRemoteRPC<T>(
    String rpcID,
    Map<String, dynamic> jsonParams, {
    Uuid? targetObject,
  });

  /// Sets the remote RPC handler for this connection.
  /// This will be the method called when this connection recieves a remote RPC
  /// invocation request.
  void setRemoteRPCHandler(RemoteRPCHandler? callback);
}
