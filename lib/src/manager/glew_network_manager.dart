import 'dart:collection';

import 'package:glew/src/connection/glew_connection.dart';
import 'package:sane_uuid/uuid.dart';

/// Class containing information about Glews current network context.
class GlewNetworkManager {
  final List<GlewConnection> _clients = [];
  GlewConnection? _server;

  final Future<dynamic> Function(
    GlewConnection,
    String,
    Map<String, dynamic>, {
    Uuid? targetObject,
  })
  _onConnectionRPCCalled;

  final Function(GlewConnection)? onClientAdded;
  final Function(GlewConnection)? onClientRemoved;

  GlewNetworkManager(
    this._onConnectionRPCCalled, {
    this.onClientAdded,
    this.onClientRemoved,
  });

  void addClientConnection(GlewConnection connection) {
    if (_clients.contains(connection)) {
      return;
    }
    _clients.add(connection);
    connection.setRemoteRPCHandler(_onConnectionRPCCalled);
    onClientAdded?.call(connection);
  }

  void removeClientConnection(GlewConnection connection) {
    _clients.remove(connection);
    connection.setRemoteRPCHandler(null);
    onClientRemoved?.call(connection);
  }

  void setServerConnection(GlewConnection? server) {
    _server = server;
    _server?.setRemoteRPCHandler(_onConnectionRPCCalled);
  }

  /// Returns whether Glew is serving clients.
  bool get isServer => clients.isNotEmpty;

  /// Returns whether Glew is a client.
  bool get isClient => server != null;

  UnmodifiableListView<GlewConnection> get clients =>
      UnmodifiableListView(_clients);

  GlewConnection? get server => _server;
}
