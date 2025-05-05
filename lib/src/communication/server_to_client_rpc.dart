import 'package:glew/src/communication/glew_rpc.dart';
import 'package:glew/src/network/glew_connection.dart';

class ServerToClientRPC<T> extends GlewRPC<T> {
  ServerToClientRPC({
    required super.remoteProcedure,
    required super.customParameterConverter,
  });

  @override
  Future<T> callOnConnection(
    GlewConnection onConnection,
    Map<String, dynamic> params,
  ) async {
    // Ensure this is coming from a server
    assert(
      api!.networkManager.isServer,
      "Server to Client RPCs must be called on a server!",
    );

    // Ensure this is being called on a client
    assert(
      api!.networkManager.clients.contains(onConnection),
      "Client to Server RPCs cannot be called without a server!",
    );

    return await super.callOnConnection(onConnection, params);
  }
}
