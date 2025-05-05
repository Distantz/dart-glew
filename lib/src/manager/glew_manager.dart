import 'package:glew/src/api/glew_api.dart';
import 'package:glew/src/communication/glew_rpc.dart';
import 'package:glew/src/communication/glew_rpc_container.dart';
import 'package:glew/src/communication/server_broadcast_rpc.dart';
import 'package:glew/src/communication/server_to_client_rpc.dart';
import 'package:glew/src/manager/glew_network_manager.dart';
import 'package:glew/src/manager/glew_state_manager.dart';
import 'package:glew/src/connection/glew_connection.dart';
import 'package:sane_uuid/uuid.dart';

class GlewManager implements GlewAPI, GlewRPCContainer {
  final GlewStateManager _stateManager;
  late final GlewNetworkManager _networkManager;

  final Map<String, GlewRPC> _staticRPCs = {};

  @override
  GlewStateManager get stateManager => _stateManager;
  @override
  GlewNetworkManager get networkManager => _networkManager;

  /**
   * RPCs
   */

  /// Broadcast delta. Will send new delta to each connection.
  ServerBroadcastRpc<void> broadcastDeltaRPC = ServerBroadcastRpc(
    remoteProcedure: (remoteCaller, api, params) {
      api.stateManager.applyIncomingDelta(params["delta"]);
      return Future.value(null);
    },
    customParameterConverter: {},
  );

  /// Send State RPC. Will send a snapshot of the server at the
  /// current time to the client, who can apply that state.
  ServerToClientRPC<void> sendStateRPC = ServerToClientRPC(
    remoteProcedure: (remoteCaller, api, params) {
      api.stateManager.setJson(params["state"]);
      return Future.value(null);
    },
    customParameterConverter: {},
  );

  GlewManager(this._stateManager) {
    _networkManager = GlewNetworkManager(
      remoteRPCHandler,
      onClientAdded: onClientConnected,
      onClientRemoved: onClientDisconnected,
    );
    onRegisterRPCs();
  }

  void onRegisterRPCs() {
    registerRPC("syncDelta", broadcastDeltaRPC, this);
    registerRPC("sendState", sendStateRPC, this);
  }

  void serverTick(Duration tick) {}

  void onClientConnected(GlewConnection newConn) {
    sendStateRPC.callOnConnection(newConn, {"state": stateManager.getJson()});
  }

  void onClientDisconnected(GlewConnection oldConn) {}

  /// A connection RPC handler.
  Future remoteRPCHandler<T>(
    GlewConnection fromConnection,
    String rpcID,
    Map<String, dynamic> jsonParams, {
    Uuid? targetObject,
  }) async {
    /// If has target object, call on that.
    if (targetObject != null) {
      return await stateManager
          .lookupStateObject(targetObject)!
          .handleRPC(fromConnection, rpcID, jsonParams);
    } else {
      return await handleRPC(fromConnection, rpcID, jsonParams);
    }
  }

  @override
  Future handleRPC<T>(
    GlewConnection fromConnection,
    String rpcID,
    Map<String, dynamic> jsonParams,
  ) async {
    if (_staticRPCs.containsKey(rpcID)) {
      return await _staticRPCs[rpcID]!.handle(fromConnection, this, jsonParams);
    }
  }

  @override
  bool registerRPC(String id, GlewRPC rpc, GlewAPI api) {
    _staticRPCs[id] = rpc;
    return true;
  }
}
