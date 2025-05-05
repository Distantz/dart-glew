import 'package:glew/src/trackable/trackable_state.dart';
import 'package:glew/src/trackable/trackable_value.dart';

class TestTwoValueState extends TrackableState {
  TrackableValue<int> valueA = TrackableValue(0);
  TrackableValue<String> valueB = TrackableValue("Hello World");

  @override
  void onRegisterTrackableChildren() {
    registerTrackableChild("valueA", valueA);
    registerTrackableChild("valueB", valueB);
  }

  TestTwoValueState(super.stateID, super.api);
}
