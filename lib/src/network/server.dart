import 'dart:async';
import 'dart:io';

import 'package:glew/src/network/glew_server_service.dart';
import 'package:glew/src/network/glew_service.dart';
import 'package:glew/src/trackables/trackable_state_manager.dart';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class GlewServer {
  final List<GlewRPC> rpcs;
  final TrackableStateManager manager;
  final Duration deltaBroadcastInterval;
  final List<GlewServerService> _clients = [];
  late Timer timer;

  /// [rpcs]: RPCs to register for each client.
  /// [deltaProvider]: periodic source of deltas (optional).
  /// [broadcastInterval]: poll interval for deltas (default 1s).
  GlewServer(
    this.rpcs,
    this.manager, {
    this.deltaBroadcastInterval = const Duration(seconds: 1),
  });

  Future<void> run({String address = 'localhost', int port = 8080}) async {
    var handler = webSocketHandler((webSocket, _) {
      _handleNewConnection(webSocket);
    });

    shelf_io.serve(handler, address, port).then((server) {
      print('Serving at ws://${server.address.host}:${server.port}');
    });

    // Start polling deltas if provider exists
    timer = Timer.periodic(deltaBroadcastInterval, (_) => _broadcastDelta());
  }

  void _handleNewConnection(WebSocketChannel wsChannel) {
    final service = GlewServerService(
      wsChannel,
      rpcs,
      manager,
      (service) => _clients.remove(service),
    );
    _clients.add(service);
  }

  void _broadcastDelta() {
    if (manager.hasOutgoingDelta() && _clients.isNotEmpty) {
      Map<String, dynamic> delta = manager.getOutgoingDelta();

      for (var client in List<GlewServerService>.from(_clients)) {
        try {
          client.sendNotification('syncDelta', delta);
        } catch (_) {}
      }
    }
  }

  /// Stops the broadcast timer and clears clients.
  Future<void> shutdown() async {
    timer.cancel();
    _clients.clear();
  }
}
