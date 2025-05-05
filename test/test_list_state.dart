import 'package:glew/glew.dart';

class TestListState extends TrackableState {
  final TrackableList<int> list = TrackableList();

  @override
  void onRegisterTrackableChildren() {
    registerTrackableChild("list", list);
  }

  TestListState(super.stateID, super.api);
}
