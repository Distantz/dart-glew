import 'package:glew/src/trackables/trackable_state.dart';
import 'package:glew/src/trackables/trackable_value.dart';

class TestTwoValueState extends TrackableState {
  TrackableValue<int> valueA = TrackableValue(0);
  TrackableValue<String> valueB = TrackableValue("Hello World");

  @override
  void registerTrackableChildren() {
    registerTrackableChild("valueA", valueA);
    registerTrackableChild("valueB", valueB);
  }

  TestTwoValueState({required super.stateID});
}
