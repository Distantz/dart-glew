import 'package:glew/src/connection/local_glew_connection.dart';
import 'package:glew/src/servers/base_glew_server.dart';

/// A local server.
/// This is not a network server, but rather a simple redirecting server.
/// Will create a local connection for both server and client.
class LocalGlewServer extends BaseGlewServer {
  LocalGlewServer(
    super.manager, {
    super.timeBetweenTicks = const Duration(
      milliseconds: BaseGlewServer.millis60Tickrate,
    ),
  }) {
    LocalGlewConnection locConnection = LocalGlewConnection();
    manager.networkManager.addClientConnection(locConnection);
    manager.networkManager.setServerConnection(locConnection);
  }
}
