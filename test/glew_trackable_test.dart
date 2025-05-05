import 'dart:convert';
import 'package:test/test.dart';

import 'package:glew/glew.dart';
import 'package:glew/src/api/glew_api.dart';
import 'package:glew/src/manager/glew_manager.dart';
import 'package:glew/src/manager/glew_state_manager.dart';
import 'package:sane_uuid/uuid.dart';

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
      dynamic delta = value.getOutgoingDelta();
      expect(delta != null, true);
      expect(delta == 1, true);
    });
  });

  group('Single list value checks', () {
    late TrackableList<int> value;

    setUp(() {
      value = TrackableList();
    });

    test('No Change No Delta', () {
      expect(value.hasOutgoingDelta(), false);
    });

    test('Change has Delta', () {
      value.add(1);
      expect(value.hasOutgoingDelta(), true);
    });

    test('Change has proper delta', () {
      value.add(1);
      value.add(2);
      value.add(3);
      value.add(4);
      value.add(5);
      value.removeWhere((val) => val < 3);
      dynamic delta = value.getOutgoingDelta();
      expect(delta != null, true);
    });
  });

  group('Single map value checks', () {
    late TrackableMap<int, String> value;

    setUp(() {
      value = TrackableMap();
    });

    test('No Change No Delta', () {
      expect(value.hasOutgoingDelta(), false);
    });

    test('Change has Delta', () {
      value[0] = "Hello World";
      expect(value.hasOutgoingDelta(), true);
    });

    test('Change has proper delta', () {
      value[0] = "Hello World 1";
      value[1] = "Hello World 2";
      value[0] = "Hello World Override";
      dynamic delta = value.getOutgoingDelta();
      expect(delta != null, true);
    });
  });

  group('Single set value checks', () {
    late TrackableSet<int> value;

    setUp(() {
      value = TrackableSet<int>();
    });

    test('No Change No Delta', () {
      expect(value.hasOutgoingDelta(), false);
    });

    test('Change has Delta', () {
      value.add(0);
      expect(value.hasOutgoingDelta(), true);
    });

    test('Change has proper delta', () {
      value.add(0);
      value.add(1);
      value.add(2);
      dynamic delta = value.getOutgoingDelta();
      expect(delta != null, true);
    });
  });

  group('Trackable State', () {
    late GlewAPI context;
    late TestTwoValueState value;

    setUp(() {
      context = GlewManager(GlewStateManager({}));
      value = TestTwoValueState(Uuid.v4(), context);
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
      expect(delta["valueA"] == 1, true);
      expect(delta.containsKey("valueB"), true);
      expect(delta["valueB"] == "Hello", true);
    });

    test('Change compresses delta', () {
      value.valueA.value = 1;
      value.valueB.value = "Hello World";
      Map<String, dynamic> delta = value.getOutgoingDelta();

      expect(delta.isEmpty, false);
      expect(delta.containsKey("valueA"), true);
      expect(delta["valueA"] == 1, true);
      expect(delta.containsKey("valueB"), false);
    });
  });

  group('Lookup', () {
    late TestReferencedState containingObj;
    late TestTwoValueState innerObj;
    late GlewAPI context;

    setUp(() {
      context = GlewManager(GlewStateManager({}));
      innerObj = TestTwoValueState(Uuid.v4(), context);
      containingObj = TestReferencedState(Uuid.v4(), context);
      context.stateManager.registerStateObject(innerObj);
      context.stateManager.registerStateObject(containingObj);
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
      containingObj.ref.value = innerObj.stateID;
      expect(containingObj.hasOutgoingDelta(), true);
      expect(
        context.stateManager
            .lookupStateObject<TestTwoValueState>(containingObj.ref.value)!
            .hasOutgoingDelta(),
        false,
      );
    });

    test('Change has proper delta', () {
      // Change the ref and a value inside the ref
      containingObj.ref.value = innerObj.stateID;
      innerObj.valueA.value = 1;

      Map<String, dynamic> delta = containingObj.getOutgoingDelta();

      delta = jsonDecode(jsonEncode(delta));

      expect(delta.isEmpty, false);
      expect(delta.keys.length, 1); // One key, our ref.
      expect(Uuid.fromString(delta["ref"]) == innerObj.stateID, true);

      // Check inner object for changes too
      delta = innerObj.getOutgoingDelta();

      expect(delta.isEmpty, false);
      expect(delta.keys.length, 1);
      expect(delta["valueA"] == 1, true);
    });
  });

  group('State Manager', () {
    late TestTwoValueState innerObj;
    late GlewAPI context;

    setUp(() {
      context = GlewManager(GlewStateManager({}));
      innerObj = TestTwoValueState(Uuid.v4(), context);
    });

    test('No Change No Delta', () {
      expect(context.stateManager.hasOutgoingDelta(), false);
    });

    test('Change has Delta', () {
      context.stateManager.registerStateObject(innerObj);
      expect(context.stateManager.hasOutgoingDelta(), true);
    });

    test('Delta is compressed on create', () {
      context.stateManager.registerStateObject(innerObj);
      expect(context.stateManager.hasOutgoingDelta(), true);

      // Change inner object, to create a delta there.
      innerObj.valueA.value = 2;
      expect(innerObj.hasOutgoingDelta(), true);

      Map<String, dynamic> contextDelta =
          context.stateManager.getOutgoingDelta();

      // Since we haven't cleared the create, the delta should be rolled into
      // the create JSON to save space.
      expect(
        contextDelta.containsKey(GlewStateManager.changeKey),
        false,
        reason: "There should be no delta change. Actual: $contextDelta",
      );
      expect(
        contextDelta.containsKey(GlewStateManager.createKey),
        true,
        reason: "There should be a create. Actual: $contextDelta",
      );
    });

    test('Delta is compressed correctly on create', () {
      context.stateManager.registerStateObject(innerObj);
      expect(context.stateManager.hasOutgoingDelta(), true);

      context.stateManager.clearOutgoingDelta();
      expect(context.stateManager.hasOutgoingDelta(), false);

      // Change inner object, to create a delta there.
      innerObj.valueA.value = 2;
      expect(innerObj.hasOutgoingDelta(), true);
      expect(context.stateManager.hasOutgoingDelta(), true);

      Map<String, dynamic> contextDelta =
          context.stateManager.getOutgoingDelta();

      // Since we haven't cleared the create, the delta should be rolled into
      // the create JSON to save space.
      expect(
        contextDelta.containsKey(GlewStateManager.changeKey),
        true,
        reason: "There should be a delta change. Actual: $contextDelta",
      );
      expect(
        contextDelta.containsKey(GlewStateManager.createKey),
        false,
        reason: "There should not be a create. Actual: $contextDelta",
      );
    });

    test('Delta is compressed on remove', () {
      context.stateManager.registerStateObject(innerObj);
      context.stateManager.clearOutgoingDelta();
      context.stateManager.unregisterStateObject(innerObj);

      // Change inner object, to create a delta there.
      innerObj.valueA.value = 2;
      expect(innerObj.hasOutgoingDelta(), true);

      Map<String, dynamic> contextDelta =
          context.stateManager.getOutgoingDelta();

      // Since we haven't cleared the create, the delta should be rolled into
      // the create JSON to save space.
      expect(
        contextDelta.containsKey(GlewStateManager.changeKey),
        false,
        reason: "There should be no delta change. Actual: $contextDelta",
      );
      expect(
        contextDelta.containsKey(GlewStateManager.removeKey),
        true,
        reason: "There should be a remove. Actual: $contextDelta",
      );
    });

    test('Create and Remove on same delta cancels out', () {
      context.stateManager.registerStateObject(innerObj);
      expect(
        context.stateManager.hasOutgoingDelta(),
        true,
        reason: "Should be an outgoing delta.",
      );
      innerObj.valueA.value = 2;
      expect(
        context.stateManager.hasOutgoingDelta(),
        true,
        reason: "Should be an outgoing delta.",
      );
      context.stateManager.unregisterStateObject(innerObj);
      expect(
        context.stateManager.hasOutgoingDelta(),
        false,
        reason:
            "The track and untrack calls should've cancelled out any delta. Actual: ${context.stateManager.getOutgoingDelta()}",
      );
    });

    test('Remove and Create on same delta cancels out, but leaves change', () {
      context.stateManager.registerStateObject(innerObj);
      context.stateManager.clearOutgoingDelta();

      context.stateManager.unregisterStateObject(innerObj);
      expect(
        context.stateManager.hasOutgoingDelta(),
        true,
        reason: "Should be be an outgoing delta.",
      );

      innerObj.valueA.value = 2;
      expect(
        context.stateManager.hasOutgoingDelta(),
        true,
        reason: "Should be an outgoing delta.",
      );

      context.stateManager.registerStateObject(innerObj);
      expect(
        context.stateManager.hasOutgoingDelta(),
        true,
        reason:
            "The track and untrack calls should've cancelled out any create/remove, but there should still be a change. Actual: ${context.stateManager.getOutgoingDelta()}",
      );
    });
  });
}
