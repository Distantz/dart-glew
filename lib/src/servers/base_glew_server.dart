import 'dart:async';
import 'package:glew/src/manager/glew_manager.dart';

/// A base glew server
/// Provides the basic ticking capabilities that all servers must do.
class BaseGlewServer {
  final GlewManager manager;
  final Duration timeBetweenTicks;
  late Timer timer;

  static const int millis60Tickrate = 1000 ~/ 60;

  BaseGlewServer(
    this.manager, {
    this.timeBetweenTicks = const Duration(milliseconds: millis60Tickrate),
  });

  Future<void> run() async {
    // Start ticking the server
    timer = Timer.periodic(timeBetweenTicks, _tickServer);
  }

  /// Ticks the server
  void _tickServer(_) {
    manager.serverTick(timeBetweenTicks);
  }

  /// Stops the broadcast timer and clears clients.
  Future<void> shutdown() async {
    timer.cancel();
    manager.networkManager.clients.clear();
    manager.networkManager.setServerConnection(null);
  }
}
