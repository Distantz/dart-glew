import 'package:glew/src/connection/socket_glew_connection.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebsocketGlewClient extends SocketGlewConnection {
  WebsocketGlewClient(super.channel);

  factory WebsocketGlewClient.fromWebsocket({
    String websocket = "ws://localhost:8080",
  }) {
    print("Client attempting connection on websocket $websocket");
    final socket = WebSocketChannel.connect(Uri.parse(websocket));

    return WebsocketGlewClient(socket);
  }
}
