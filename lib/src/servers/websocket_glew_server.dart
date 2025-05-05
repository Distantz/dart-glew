import 'dart:async';

import 'package:glew/src/connection/socket_glew_connection.dart';
import 'package:glew/src/servers/base_glew_server.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebsocketGlewServer extends BaseGlewServer {
  WebsocketGlewServer(
    super.manager, {
    super.timeBetweenTicks = const Duration(
      milliseconds: BaseGlewServer.millis60Tickrate,
    ),
  });

  Future<void> runServer({
    String address = 'localhost',
    int port = 8080,
  }) async {
    var handler = webSocketHandler((webSocket, _) {
      _handleNewConnection(webSocket);
    });

    await shelf_io.serve(handler, address, port).then((server) {
      print('Serving at ws://${server.address.host}:${server.port}');

      // Enable compression by default
      server.autoCompress = true;
    });
  }

  void _handleNewConnection(WebSocketChannel wsChannel) {
    final service = SocketGlewConnection(wsChannel);
    service.listen().then((_) {
      manager.networkManager.removeClientConnection(service);
    });
    manager.networkManager.addClientConnection(service);
  }
}
