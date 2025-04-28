import 'package:glew/glew.dart';
import 'package:glew/src/converters/uuid_converter.dart';
import 'package:sane_uuid/uuid.dart';

class TestReferencedState extends TrackableState {
  // Make UUID. Use it's converter.
  TrackableValue<Uuid> ref = TrackableValue(
    Uuid.v4(),
    converter: const UuidConverter(),
  );

  @override
  void registerTrackableChildren() {
    registerTrackableChild("ref", ref);
  }

  TestReferencedState({required super.stateID});
}
