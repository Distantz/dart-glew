import 'package:glew/src/network/glew_service.dart';

/// Concrete server-side PeerService.
class GlewServerService extends GlewService {
  // Force definition of a tracking context in the server.
  // Since if you don't have one, wtf are you doing?
  GlewServerService(
    super.channel,
    super.rpcs,
    super.context,
    Function(GlewServerService service) onClose,
  ) {
    // Handle disconnection gracefully
    close().then((_) {
      onClose.call(this);
    });
  }
}
