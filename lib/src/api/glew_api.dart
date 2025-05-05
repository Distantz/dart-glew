import 'package:glew/src/manager/glew_network_manager.dart';
import 'package:glew/src/manager/glew_state_manager.dart';

abstract class GlewAPI {
  GlewStateManager get stateManager;
  GlewNetworkManager get networkManager;
}
