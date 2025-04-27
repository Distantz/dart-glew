import 'package:glew/src/trackables/tracking_context.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A data storage class for defining RPCs.
class GlewRPC {
  final String rpcID;
  final dynamic Function(
    GlewService peer,
    TrackingContext? context,
    Parameters params,
  )
  rpcLogic;
  final bool Function(
    GlewService peer,
    TrackingContext? context,
    Parameters params,
  )?
  authorisationCheck;

  GlewRPC({
    required this.rpcID,
    required this.rpcLogic,
    this.authorisationCheck,
  });
}

/// Object base for a JSONRPC Peer service.
/// Registers provided GlewRPCs on the given channel, with full auth support.
class GlewService extends Peer {
  TrackingContext context;
  final WebSocketChannel channel;

  GlewService(this.channel, List<GlewRPC> rpcs, this.context)
    : super(channel.cast<String>()) {
    for (var rpc in rpcs) {
      registerMethod(rpc.rpcID, (Parameters params) {
        // Authorization if provided
        if (rpc.authorisationCheck != null &&
            !rpc.authorisationCheck!(this, context, params)) {
          throw RpcException.invalidParams('Unauthorized');
        }
        return rpc.rpcLogic(this, context, params);
      });
    }
  }
}
