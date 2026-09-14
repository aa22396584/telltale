/// Tests for ServiceRecipesProvider and Mode08DiscoveryState.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/service_recipes/qualification_tier.dart';
import 'package:torque_obd/obd/elm327_client.dart';
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
  });
}

class _ConnectedMockSessionNotifier extends Notifier<ObdConnectionState>
    implements ObdSession {
  _ConnectedMockSessionNotifier(this._mockClient);

  final Elm327Client _mockClient;

  @override
  Elm327Client? get client => _mockClient;

  @override
  ObdConnectionState build() => const ObdConnectionState(
        phase: ConnectionPhase.connected,
        protocol: 'ISO 15765-4 (CAN 11/500)',
      );

  void simulateDisconnect() {
    state = const ObdConnectionState(phase: ConnectionPhase.failed);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
