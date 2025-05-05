import 'package:glew/src/api/glew_api.dart';
import 'package:glew/src/communication/glew_rpc.dart';
import 'package:glew/src/network/glew_connection.dart';

abstract class GlewRPCContainer {
  /// Calls an RPC on this container.
  Future<dynamic> handleRPC<T>(
    GlewConnection fromConnection,
    String rpcID,
    Map<String, dynamic> jsonParams,
  );

  /// Tracks an RPC to this object. When called on a remote,
  /// the rpc registered here will be looked up and called.
  bool registerRPC(String id, GlewRPC rpc, GlewAPI api);
}
