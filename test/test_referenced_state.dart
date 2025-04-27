import 'package:glew/glew.dart';

import 'test_twovalue_state.dart';

class TestReferencedState extends TrackableState {
  TrackableStateReference<TestTwoValueState> ref = TrackableStateReference(
    null,
  );

  @override
  void registerTrackableChildren() {
    registerTrackableChild("ref", ref);
  }

  TestReferencedState({required super.stateID});
}
