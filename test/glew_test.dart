import 'dart:async';
import 'dart:convert';

import 'package:glew/glew.dart';
import 'package:glew/src/network/client.dart';
import 'package:glew/src/network/glew_service.dart';
import 'package:glew/src/network/server.dart';
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
      context = TrackableStateManager({});
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
      context = TrackableStateManager({});
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

  group('Communication between two StateManagers', () {
    late TrackableStateManager serverContext;
    late TrackableStateManager clientContext;

    late TestTwoValueState serverInner;

    setUp(() {
      final Map<String, TrackableState Function(Uuid stateID)> objectFactory = {
        "TestTwoValueState": (state) => TestTwoValueState(stateID: state),
      };

      serverContext = TrackableStateManager(objectFactory);
      clientContext = TrackableStateManager(objectFactory);
      serverInner = TestTwoValueState(stateID: Uuid.v4());
    });

    test('Add object to server, reflects on client', () {
      expect(serverContext.hasOutgoingDelta(), false);
      expect(clientContext.hasOutgoingDelta(), false);

      serverContext.trackObject(serverInner);
      expect(serverContext.hasOutgoingDelta(), true);
      expect(clientContext.hasOutgoingDelta(), false);

      // Send delta to client
      clientContext.applyIncomingDelta(serverContext.getOutgoingDelta());
      clientContext.clearOutgoingDelta();
      serverContext.clearOutgoingDelta();

      expect(serverContext.hasOutgoingDelta(), false);
      expect(clientContext.hasOutgoingDelta(), false);

      var spawnedServer = serverContext.getSpawnedObjects();
      var spawnedClient = clientContext.getSpawnedObjects();

      // Both client and server should have ONE object, with the same UUID, but not the same hashcode.
      expect(spawnedServer.length == 1, true);
      expect(spawnedClient.length == 1, true);
      expect(spawnedServer[0].stateID == spawnedClient[0].stateID, true);
      expect(spawnedServer[0] != spawnedClient[0], true);
    });

    test('Change object on server, see delta on client', () {
      serverContext.trackObject(serverInner);
      clientContext.applyIncomingDelta(serverContext.getOutgoingDelta());
      clientContext.clearOutgoingDelta();
      serverContext.clearOutgoingDelta();

      TestTwoValueState clientInner =
          clientContext.getSpawnedObjects()[0] as TestTwoValueState;

      // Change the inner.
      serverInner.valueA.value = 2;
      expect(
        serverInner.valueA.value == 2,
        true,
        reason:
            "Server inner has changed to two. Actual: ${serverInner.getJson()}",
      );
      expect(
        clientInner.valueA.value == 0,
        true,
        reason: "Client inner hasn't changed. Actual: ${clientInner.getJson()}",
      );

      Map<String, dynamic> getDelta = serverContext.getOutgoingDelta();

      // Delta should only be a change
      expect(
        getDelta[TrackableStateManager.changeKey] != null,
        true,
        reason: "Should only be a change delta: $getDelta",
      );

      expect(
        getDelta[TrackableStateManager.createKey] == null,
        true,
        reason: "Should only be a change delta: $getDelta",
      );

      expect(
        getDelta[TrackableStateManager.removeKey] == null,
        true,
        reason: "Should only be a change delta: $getDelta",
      );

      // Encode to JSON
      // Then decode back
      String json = jsonEncode(getDelta);
      print(json);
      Map<String, dynamic> convertedDelta = jsonDecode(json);

      clientContext.applyIncomingDelta(convertedDelta);
      clientContext.clearOutgoingDelta();
      serverContext.clearOutgoingDelta();

      expect(serverInner.valueA.value == 2, true);
      expect(clientInner.valueA.value == 2, true);
    });
  });

  group('GlewRPC system', () {
    late GlewServer server;
    late GlewClient client;
    late TrackableStateManager serverContext;
    late TestTwoValueState serverInner;
    late TrackableStateManager clientContext;

    setUp(() async {
      List<GlewRPC> rpcs = [
        GlewRPC(
          rpcID: "requestSyncState",
          rpcLogic: (peer, context, params) {
            return (context as TrackableStateManager).getJson();
          },
        ),
        GlewRPC(
          rpcID: "syncState",
          rpcLogic: (peer, context, params) {
            // Contexts are managers.
            TrackableStateManager manager = context as TrackableStateManager;
            manager.setJson(params.asMap as Map<String, dynamic>);
          },
        ),
        GlewRPC(
          rpcID: "syncDelta",
          rpcLogic: (peer, context, params) {
            // Contexts are managers.
            TrackableStateManager manager = context as TrackableStateManager;
            print(
              "INCOMING DELTA: ${params.asMap as Map<String, dynamic>} IS SERVER? ${context == serverContext}",
            );
            manager.applyIncomingDelta(params.asMap as Map<String, dynamic>);
          },
        ),
      ];

      final Map<String, TrackableState Function(Uuid stateID)> objectFactory = {
        "TestTwoValueState": (state) => TestTwoValueState(stateID: state),
      };

      serverContext = TrackableStateManager(objectFactory);
      clientContext = TrackableStateManager(objectFactory);

      serverInner = TestTwoValueState(stateID: Uuid.v4());
      serverContext.trackObject(serverInner);

      server = GlewServer(rpcs, serverContext);
      unawaited(server.run());

      client = GlewClient.fromWebsocket(rpcs, clientContext);
      client.listen();
    });

    tearDown(() async {
      await server.shutdown();
    });

    test('Client can sync', () async {
      Map<String, dynamic> json = await client.sendRequest("requestSyncState");

      print(json);
      expect(json.isNotEmpty, true);
      clientContext.setJson(json);
      expect(clientContext.getSpawnedObjects().isNotEmpty, true);
    });

    test('Client can sync AND get deltas', () async {
      Map<String, dynamic> json = await client.sendRequest("requestSyncState");
      clientContext.setJson(json);
      expect(clientContext.getSpawnedObjects().isNotEmpty, true);

      serverInner.valueA.value = 35;
      serverInner.valueB.value = "Str";

      // Sync every 1 second so we should have a sync by 2
      await Future.delayed(Duration(milliseconds: 2000));

      expect(clientContext.getSpawnedObjects().isNotEmpty, true);
      TestTwoValueState clientInner =
          clientContext.getSpawnedObjects()[0] as TestTwoValueState;

      expect(
        serverInner.valueA.value == clientInner.valueA.value,
        true,
        reason:
            "Server inner and client inner should match: ${serverInner.getJson()} vs ${clientInner.getJson()}",
      );
      expect(
        serverInner.valueB.value == clientInner.valueB.value,
        true,
        reason:
            "Server inner and client inner should match: ${serverInner.getJson()} vs ${clientInner.getJson()}",
      );
      expect(
        serverInner == clientInner,
        false,
        reason: "Server inner and client inner shouldn't be the same object.",
      );
    });
  });
}
