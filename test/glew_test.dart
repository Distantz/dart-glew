import 'package:glew/glew.dart';
import 'package:glew/src/trackables/trackable_state_manager.dart';
import 'package:glew/src/trackables/tracking_context.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:test/test.dart';

import 'test_referenced_state.dart';
import 'test_twovalue_state.dart';

void main() {
  group('Single int value tests', () {
    TrackableValue<int> value = TrackableValue(0);

    setUp(() {
      value = TrackableValue(0);
    });

    test('No Change No Delta', () {
      expect(value.hasOutgoingDelta(), false);
    });

    test('Change has Delta', () {
      value.value = 1;
      expect(value.hasOutgoingDelta(), true);
    });

    test('Change has proper delta', () {
      value.value = 1;
      Map<String, dynamic> delta = value.getOutgoingDelta();
      expect(delta.isEmpty, false);
      expect(delta.containsKey(TrackableValue.valueKey), true);
      expect(delta[TrackableValue.valueKey] == 1, true);
    });
  });

  group('Trackable State', () {
    TestTwoValueState value = TestTwoValueState(stateID: Uuid.v4());

    setUp(() {
      value = TestTwoValueState(stateID: Uuid.v4());
    });

    test('No Change No Delta', () {
      expect(value.hasOutgoingDelta(), false);
    });

    test('Change has Delta', () {
      value.valueA.value = 1;
      expect(value.hasOutgoingDelta(), true);
      expect(value.valueA.hasOutgoingDelta(), true);
    });

    test('Change has proper delta', () {
      value.valueA.value = 1;
      value.valueB.value = "Hello";
      Map<String, dynamic> delta = value.getOutgoingDelta();

      expect(delta.isEmpty, false);
      expect(delta.containsKey("valueA"), true);
      expect(delta["valueA"][TrackableValue.valueKey] == 1, true);
      expect(delta.containsKey("valueB"), true);
      expect(delta["valueB"][TrackableValue.valueKey] == "Hello", true);
    });

    test('Change compresses delta', () {
      value.valueA.value = 1;
      value.valueB.value = "Hello World";
      Map<String, dynamic> delta = value.getOutgoingDelta();

      expect(delta.isEmpty, false);
      expect(delta.containsKey("valueA"), true);
      expect(delta["valueA"][TrackableValue.valueKey] == 1, true);
      expect(delta.containsKey("valueB"), false);
    });
  });

  group('Lookup', () {
    late TestReferencedState containingObj;
    late TestTwoValueState innerObj;
    late TrackingContext context;

    setUp(() {
      context = TrackableStateManager(deserializationFactories: {});
      innerObj = TestTwoValueState(stateID: Uuid.v4());
      containingObj = TestReferencedState(stateID: Uuid.v4());
      context.trackObject(innerObj);
      context.trackObject(containingObj);
    });

    test('UUID Parsing', () {
      Uuid id = Uuid.v4();
      expect(id == Uuid.fromString(id.toString()), true);
    });

    test('No Change No Delta', () {
      expect(innerObj.hasOutgoingDelta(), false);
      expect(containingObj.hasOutgoingDelta(), false);
    });

    test('Change has Delta', () {
      containingObj.ref.value = innerObj;
      expect(containingObj.hasOutgoingDelta(), true);
      expect(containingObj.ref.value!.hasOutgoingDelta(), false);
    });

    test('Change has proper delta', () {
      // Change the ref and a value inside the ref
      containingObj.ref.value = innerObj;
      innerObj.valueA.value = 1;

      Map<String, dynamic> delta = containingObj.getOutgoingDelta();

      expect(delta.isEmpty, false);
      expect(delta.keys.length, 1); // One key, our ref.
      expect(delta["ref"][TrackableValue.valueKey] == innerObj.stateID, true);

      // Check inner object for changes too
      delta = innerObj.getOutgoingDelta();

      expect(delta.isEmpty, false);
      expect(delta.keys.length, 1);
      expect(delta["valueA"][TrackableValue.valueKey] == 1, true);
    });
  });

  group('State Manager', () {
    late TestTwoValueState innerObj;
    late TrackableStateManager context;

    setUp(() {
      context = TrackableStateManager(deserializationFactories: {});
      innerObj = TestTwoValueState(stateID: Uuid.v4());
    });

    test('No Change No Delta', () {
      expect(context.hasOutgoingDelta(), false);
    });

    test('Change has Delta', () {
      context.trackObject(innerObj);
      expect(context.hasOutgoingDelta(), true);
    });

    test('Delta is compressed on create', () {
      context.trackObject(innerObj);
      expect(context.hasOutgoingDelta(), true);

      // Change inner object, to create a delta there.
      innerObj.valueA.value = 2;
      expect(innerObj.hasOutgoingDelta(), true);

      Map<String, dynamic> contextDelta = context.getOutgoingDelta();

      // Since we haven't cleared the create, the delta should be rolled into
      // the create JSON to save space.
      expect(
        contextDelta.containsKey(TrackableStateManager.changeKey),
        false,
        reason: "There should be no delta change. Actual: $contextDelta",
      );
      expect(
        contextDelta.containsKey(TrackableStateManager.createKey),
        true,
        reason: "There should be a create. Actual: $contextDelta",
      );
    });

    test('Delta is compressed correctly on create', () {
      context.trackObject(innerObj);
      expect(context.hasOutgoingDelta(), true);

      context.clearOutgoingDelta();
      expect(context.hasOutgoingDelta(), false);

      // Change inner object, to create a delta there.
      innerObj.valueA.value = 2;
      expect(innerObj.hasOutgoingDelta(), true);
      expect(context.hasOutgoingDelta(), true);

      Map<String, dynamic> contextDelta = context.getOutgoingDelta();

      // Since we haven't cleared the create, the delta should be rolled into
      // the create JSON to save space.
      expect(
        contextDelta.containsKey(TrackableStateManager.changeKey),
        true,
        reason: "There should be a delta change. Actual: $contextDelta",
      );
      expect(
        contextDelta.containsKey(TrackableStateManager.createKey),
        false,
        reason: "There should not be a create. Actual: $contextDelta",
      );
    });

    test('Delta is compressed on remove', () {
      context.trackObject(innerObj);
      context.clearOutgoingDelta();
      context.untrackObject(innerObj);

      // Change inner object, to create a delta there.
      innerObj.valueA.value = 2;
      expect(innerObj.hasOutgoingDelta(), true);

      Map<String, dynamic> contextDelta = context.getOutgoingDelta();

      // Since we haven't cleared the create, the delta should be rolled into
      // the create JSON to save space.
      expect(
        contextDelta.containsKey(TrackableStateManager.changeKey),
        false,
        reason: "There should be no delta change. Actual: $contextDelta",
      );
      expect(
        contextDelta.containsKey(TrackableStateManager.removeKey),
        true,
        reason: "There should be a remove. Actual: $contextDelta",
      );
    });

    test('Create and Remove on same delta cancels out', () {
      context.trackObject(innerObj);
      expect(
        context.hasOutgoingDelta(),
        true,
        reason: "Should be an outgoing delta.",
      );
      innerObj.valueA.value = 2;
      expect(
        context.hasOutgoingDelta(),
        true,
        reason: "Should be an outgoing delta.",
      );
      context.untrackObject(innerObj);
      expect(
        context.hasOutgoingDelta(),
        false,
        reason:
            "The track and untrack calls should've cancelled out any delta. Actual: ${context.getOutgoingDelta()}",
      );
    });

    test('Remove and Create on same delta cancels out, but leaves change', () {
      context.trackObject(innerObj);
      context.clearOutgoingDelta();

      context.untrackObject(innerObj);
      expect(
        context.hasOutgoingDelta(),
        true,
        reason: "Should be be an outgoing delta.",
      );

      innerObj.valueA.value = 2;
      expect(
        context.hasOutgoingDelta(),
        true,
        reason: "Should be an outgoing delta.",
      );

      context.trackObject(innerObj);
      expect(
        context.hasOutgoingDelta(),
        true,
        reason:
            "The track and untrack calls should've cancelled out any create/remove, but there should still be a change. Actual: ${context.getOutgoingDelta()}",
      );
    });
  });
}
