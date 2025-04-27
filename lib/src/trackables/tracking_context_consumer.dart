import 'package:glew/src/trackables/tracking_context.dart';

abstract class TrackingContextConsumer {
  /// Called when the context on this object changes.
  /// It is assumed that implementations with children will
  /// pass this context to them.
  void onNewContext(TrackingContext newContext) {}
}
