import 'package:glew/glew.dart';

class TestListState extends TrackableState {
  final TrackableList<int> list = TrackableList();

  @override
  void registerTrackableChildren() {
    registerTrackableChild("list", list);
  }

  TestListState({required super.stateID});
}
