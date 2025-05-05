import 'package:glew/src/communication/glew_rpc.dart';

class ClientToServerRPC<T> extends GlewRPC<T> {
  ClientToServerRPC({
    required super.remoteProcedure,
    required super.customParameterConverter,
  });

  /// Calls this RPC on all connections connected to the server.
  void callOnServer(Map<String, dynamic> params) async {
    // Ensure this is a client
    assert(
      api!.networkManager.isClient,
      "Client to Server RPCs must be called on a client!",
    );

    // Ensure there is a server
    assert(api!.networkManager.server != null, "Server was null!");

    callOnConnection(api!.networkManager.server!, params);
  }
}
