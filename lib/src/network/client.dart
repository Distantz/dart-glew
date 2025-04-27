import 'package:glew/src/network/glew_service.dart';
import 'package:glew/src/trackables/tracking_context.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class GlewClient extends GlewService {
  GlewClient(super.channel, super.rpcs, super.context);

  factory GlewClient.fromWebsocket(
    List<GlewRPC> rpcs,
    TrackingContext context, {
    String websocket = "ws://localhost:8080",
  }) {
    print("Client attempting connection on websocket $websocket");
    final socket = WebSocketChannel.connect(Uri.parse(websocket));

    return GlewClient(socket, rpcs, context);
  }
}
