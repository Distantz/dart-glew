import 'dart:async';

import 'package:glew/src/network/glew_connection.dart';
import 'package:sane_uuid/uuid.dart';

class LocalGlewConnection implements GlewConnection {
  RemoteRPCHandler? handler;
  Completer completer = Completer();

  @override
  Future<T> callRemoteRPC<T>(
    String rpcID,
    Map<String, dynamic> jsonParams, {
    Uuid? targetObject,
  }) async =>
      await handler?.call(this, rpcID, jsonParams, targetObject: targetObject);

  @override
  Future<void> close() {
    completer.complete();
    return completer.future;
  }

  @override
  bool isOpen() => !completer.isCompleted;

  @override
  Future listen() => completer.future;

  @override
  void setRemoteRPCHandler(RemoteRPCHandler? callback) => handler = callback;
}
