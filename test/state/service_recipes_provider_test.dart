/// Tests for ServiceRecipesProvider and Mode08DiscoveryState.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/service_recipes/qualification_tier.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/elm_can_addressing.dart';
import 'package:torque_obd/obd/elm_flow_control.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/service_recipes_provider.dart';

import '../support/fake_elm327.dart';

Map<String, List<int>> _physicsReplies() => {
      '0100': [0x41, 0x00, 0xBE, 0x1F, 0xA8, 0x13],
      '0105': [0x41, 0x05, 0x7B],
      '010C': [0x41, 0x0C, 0x1A, 0xF8],
    };

Future<Elm327Client> _connect(
  ObdTransport transport, {
  Duration commandTimeout = const Duration(milliseconds: 300),
}) async {
  final client = Elm327Client(transport, commandTimeout: commandTimeout);
  final ok = await client.connect();
  expect(ok, isTrue, reason: 'handshake must succeed');
  return client;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('serviceRecipesMatrixProvider & safety report', () {
    test('loads bundled candidate matrix and enforces Zero Live Candidates', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final matrix = await container.read(serviceRecipesMatrixProvider.future);

      expect(matrix.entries, hasLength(3));
      expect(matrix.liveCandidateCount, equals(0));
      expect(matrix.hasLiveCandidates, isFalse);
      expect(matrix.simulationReadyEntries, hasLength(3));

      final safetyReport = container.read(serviceRecipesSafetyReportProvider).value!;
      expect(safetyReport.liveCandidateCount, equals(0));
      expect(safetyReport.hasLiveCandidates, isFalse);
      expect(safetyReport.liveExecutionProhibited, isTrue);
      expect(safetyReport.totalProfilesCount, equals(3));
    });
  });

  group('mode08DiscoveryStateProvider', () {
    test('starts in idle phase', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(mode08DiscoveryStateProvider);
      expect(state.isIdle, isTrue);
      expect(state.phase, equals(Mode08DiscoveryPhase.idle));
    });

    test('refuses discovery when session is not connected', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(mode08DiscoveryStateProvider.notifier).runDiscovery();

      final state = container.read(mode08DiscoveryStateProvider);
      expect(state.isRefused, isTrue);
      expect(state.message, contains('OBD session is not connected'));
    });

    test('runs discovery when connected to CAN OBD-II and completes with supported TIDs', () async {
      final fake = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': ['48 00 80 00 00 00'],
            },
          ),
        ],
      );
      final client = await _connect(fake);

      final container = ProviderContainer(
        overrides: [
          obdSessionProvider.overrideWith(
            () => _ConnectedMockSessionNotifier(client),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(mode08DiscoveryStateProvider.notifier).runDiscovery();

      final state = container.read(mode08DiscoveryStateProvider);
      expect(state.isCompleted, isTrue);
      expect(state.result, isNotNull);
      expect(state.result!.isSupported, isTrue);
      expect(state.result!.supportedTids, equals({0x01}));
      expect(state.result!.supportStatus, equals(EcuSupportStatus.supported));
    });

    test('wipes discovery results when session disconnects', () async {
      final fake = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': ['48 00 80 00 00 00'],
            },
          ),
        ],
      );
      final client = await _connect(fake);

      final sessionNotifier = _ConnectedMockSessionNotifier(client);
      final container = ProviderContainer(
        overrides: [
          obdSessionProvider.overrideWith(() => sessionNotifier),
        ],
      );
      addTearDown(container.dispose);

      // 1. Run discovery and succeed
      await container.read(mode08DiscoveryStateProvider.notifier).runDiscovery();
      expect(container.read(mode08DiscoveryStateProvider).isCompleted, isTrue);

      // 2. Disconnect session
      sessionNotifier.simulateDisconnect();

      // 3. State should reset to idle (not retain stale vehicle results)
      expect(container.read(mode08DiscoveryStateProvider).isIdle, isTrue);
    });

    test('does not leak completed state if session disconnects in-flight', () async {
      final fake = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': ['48 00 80 00 00 00'],
            },
          ),
        ],
      );
      final client = await _connect(fake);

      final sessionNotifier = _ConnectedMockSessionNotifier(client);
      final container = ProviderContainer(
        overrides: [
          obdSessionProvider.overrideWith(() => sessionNotifier),
        ],
      );
      addTearDown(container.dispose);

      // Start discovery future
      final future = container.read(mode08DiscoveryStateProvider.notifier).runDiscovery();
      // Immediately disconnect before discovery completes
      sessionNotifier.simulateDisconnect();
      await future;

      // State must remain idle, not overwrite with completed
      expect(container.read(mode08DiscoveryStateProvider).isIdle, isTrue);
    });

    test('ignores concurrent runDiscovery calls while already discovering', () async {
      final fake = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': ['48 00 80 00 00 00'],
            },
          ),
        ],
      );
      final client = await _connect(fake);

      final sessionNotifier = _ConnectedMockSessionNotifier(client);
      final container = ProviderContainer(
        overrides: [
          obdSessionProvider.overrideWith(() => sessionNotifier),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(mode08DiscoveryStateProvider.notifier);
      final f1 = notifier.runDiscovery();
      final f2 = notifier.runDiscovery();
      await Future.wait([f1, f2]);

      expect(container.read(mode08DiscoveryStateProvider).isCompleted, isTrue);
    });

    test('old task A completing after new task B does not overwrite B state (deterministic reconnect race)', () async {
      final completerA = Completer<void>();
      final fakeA = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM_A',
            requestId: '7E0',
            responseId: '7E8',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': ['48 00 80 00 00 00'], // TID 0x01
            },
          ),
        ],
      );
      final clientA = _DelayedTransactedClient(fakeA, completer: completerA);
      final okA = await clientA.connect();
      expect(okA, isTrue);

      // Fake B returns immediately with different TID
      final fakeB = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM_B',
            requestId: '7E0',
            responseId: '7E8',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': ['48 00 40 00 00 00'], // TID 0x02
            },
          ),
        ],
      );
      final clientB = await _connect(fakeB);

      final sessionNotifier = _ConnectedMockSessionNotifier(clientA);
      final container = ProviderContainer(
        overrides: [
          obdSessionProvider.overrideWith(() => sessionNotifier),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(mode08DiscoveryStateProvider.notifier);

      // Task A starts with client A
      final futureA = notifier.runDiscovery();
      // Ensure Task A has entered discovering phase and is blocked on completerA
      expect(container.read(mode08DiscoveryStateProvider).isDiscovering, isTrue);

      // Disconnect happens while A is in flight
      sessionNotifier.simulateDisconnect();
      expect(container.read(mode08DiscoveryStateProvider).isIdle, isTrue);

      // Reconnect with client B (new session generation)
      sessionNotifier.simulateReconnect(clientB);

      // Task B runs and completes cleanly
      await notifier.runDiscovery();
      final stateB = container.read(mode08DiscoveryStateProvider);
      expect(stateB.isCompleted, isTrue);
      expect(stateB.result!.supportedTids, equals({0x02}));

      // Now release Task A
      completerA.complete();
      await futureA;

      // State must NOT be overwritten by Task A! Must still reflect Task B!
      final finalState = container.read(mode08DiscoveryStateProvider);
      expect(finalState.isCompleted, isTrue);
      expect(finalState.result!.supportedTids, equals({0x02}),
          reason: 'Stale task A completion must be discarded and must not overwrite task B');
    });
  });
}

class _ConnectedMockSessionNotifier extends Notifier<ObdConnectionState>
    implements ObdSession {
  _ConnectedMockSessionNotifier(this._mockClient);

  Elm327Client _mockClient;
  int _generation = 1;

  @override
  Elm327Client? get client => _mockClient;

  @override
  int get generation => _generation;

  @override
  ObdConnectionState build() => const ObdConnectionState(
        phase: ConnectionPhase.connected,
        protocol: 'ISO 15765-4 (CAN 11/500)',
      );

  void simulateDisconnect() {
    _generation++;
    state = const ObdConnectionState(phase: ConnectionPhase.failed);
  }

  void simulateReconnect(Elm327Client newClient) {
    _generation++;
    _mockClient = newClient;
    state = const ObdConnectionState(
      phase: ConnectionPhase.connected,
      protocol: 'ISO 15765-4 (CAN 11/500)',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DelayedTransactedClient extends Elm327Client {
  _DelayedTransactedClient(super.transport, {required this.completer});
  final Completer<void> completer;

  @override
  Future<ObdResponse> sendTransacted(
    String command, {
    String? header,
    bool restoreHeader = false,
    int? extendedAddressByte,
    int? canPriorityByte,
    ElmCanReceiveFilterConfig? canReceiveFilter,
    ElmFlowControlConfig? flowControl,
    bool hostVisibleIsoTp = false,
    ElmCompositeTransactionConfig? configuration,
    Duration? timeout,
    Duration? budget,
    Duration? drainBudget,
    Duration? cleanupBudget,
    Object? owner,
    DateTime? deadline,
    Stopwatch Function()? stopwatchProvider,
    Duration Function()? elapsedProvider,
  }) async {
    await completer.future;
    return super.sendTransacted(
      command,
      header: header,
      restoreHeader: restoreHeader,
      extendedAddressByte: extendedAddressByte,
      canPriorityByte: canPriorityByte,
      canReceiveFilter: canReceiveFilter,
      flowControl: flowControl,
      hostVisibleIsoTp: hostVisibleIsoTp,
      configuration: configuration,
      timeout: timeout,
      budget: budget,
      drainBudget: drainBudget,
      cleanupBudget: cleanupBudget,
      owner: owner,
      deadline: deadline,
      stopwatchProvider: stopwatchProvider,
      elapsedProvider: elapsedProvider,
    );
  }
}
