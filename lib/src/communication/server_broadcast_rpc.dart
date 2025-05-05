import 'package:glew/src/communication/glew_rpc.dart';
import 'package:glew/src/network/glew_connection.dart';

class ServerBroadcastRpc<T> extends GlewRPC<T> {
  ServerBroadcastRpc({
    required super.remoteProcedure,
    required super.customParameterConverter,
  });

  /// Calls this RPC on all connections connected to the server.
  void broadcast(Map<String, dynamic> params) async {
    // Ensure this is a server
    assert(
      api!.networkManager.isServer,
      "Server RPCs cannot be called without a server!",
    );

    for (GlewConnection connection in api!.networkManager.clients) {
      callOnConnection(connection, params);
    }
  }
}
