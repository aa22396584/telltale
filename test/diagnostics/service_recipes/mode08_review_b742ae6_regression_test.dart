/// Mode 08 review regression tests based on review of commit b742ae6.
///
/// Contains:
/// - 2 positive controls:
///   1. Single-block complete discovery.
///   2. Multi-block complete discovery across blocks 0x00 and 0x20.
/// - 5 gap probes:
///   1. Transaction dataError with observedFrames is NOT upgraded to unsupported.
///   2. Successful ECU in same block does not mask unknown/damaged ECU (isComplete: false).
///   3. Multi-block: ECU declaring next block in 0800 missing in 0820 marks isComplete: false.
///   4. Multi-block: ECU evidence is preserved across blocks without overwriting earlier block TIDs.
///   5. Raw codec rejects contradictory DLC/PCI length (e.g. 7E8 1 06 48 00 80 00 00 00).
/// - End-to-end integration: Fake transport -> codec -> service -> UI partial warning displayed.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/diagnostics/service_recipes/candidate_matrix.dart';
import 'package:torque_obd/diagnostics/service_recipes/mode08_codec.dart';
import 'package:torque_obd/diagnostics/service_recipes/mode08_discovery_service.dart';
import 'package:torque_obd/diagnostics/service_recipes/qualification_tier.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/service_recipes_provider.dart';
import 'package:torque_obd/ui/screens/workshop/service_recipes_screen.dart';

import '../../support/fake_elm327.dart';
import '../../support/localized_app.dart';

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

class _ConnectedCanSession extends ObdSession {
  @override
  ObdConnectionState build() => const ObdConnectionState(
        phase: ConnectionPhase.connected,
        protocol: 'ISO 15765-4 (CAN 11/500)',
      );
}

class _TestConnectedCanSession extends ObdSession {
  _TestConnectedCanSession(this._testClient);
  final Elm327Client _testClient;

  @override
  Elm327Client? get client => _testClient;

  @override
  int get generation => 1;

  @override
  ObdConnectionState build() => const ObdConnectionState(
        phase: ConnectionPhase.connected,
        protocol: 'ISO 15765-4 (CAN 11/500)',
      );

  void triggerDisconnect() {
    state = const ObdConnectionState(
      phase: ConnectionPhase.disconnected,
      protocol: '',
    );
  }
}

class _FixedDiscoveryNotifier extends Mode08DiscoveryNotifier {
  _FixedDiscoveryNotifier(this._result);
  final Mode08DiscoveryResult _result;

  @override
  Mode08DiscoveryState build() => Mode08DiscoveryState.completed(result: _result);
}

class _GateableTransport implements ObdTransport {
  _GateableTransport(this._inner);
  final ObdTransport _inner;
  Completer<void>? gate;

  @override
  TransportKind get kind => _inner.kind;

  @override
  String get displayName => _inner.displayName;

  @override
  Map<String, Object> get diagnosticMetadata => _inner.diagnosticMetadata;

  @override
  bool get isConnected => _inner.isConnected;

  @override
  Stream<List<int>> get incoming => _inner.incoming;

  @override
  Stream<bool> get connectionChanges => _inner.connectionChanges;

  @override
  Future<void> connect() => _inner.connect();

  @override
  Future<void> disconnect() => _inner.disconnect();

  @override
  Future<void> write(List<int> data) async {
    final str = String.fromCharCodes(data);
    if (str.contains('0800') && gate != null && !gate!.isCompleted) {
      await gate!.future;
    }
    await _inner.write(data);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Mode 08 Review b742ae6 Regression Tests', () {
    // -------------------------------------------------------------------------
    // Positive Controls
    // -------------------------------------------------------------------------

    test('Control 1: normal single-block discovery completes cleanly', () async {
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
      final result = await Mode08DiscoveryService.discoverSupportedTids(client: client);

      expect(result.isSupported, isTrue);
      expect(result.supportStatus, equals(EcuSupportStatus.supported));
      expect(result.isComplete, isTrue);
      expect(result.supportedTids, equals({0x01}));
      expect(result.queriedBlocks, equals([0x00]));
      expect(result.unqueriedBlocks, isEmpty);
      expect(result.failureReason, isNull);
    });

    test('Control 2: normal multi-block discovery completes cleanly across 0800 and 0820', () async {
      final fake = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': ['48 00 80 00 00 01'],
              '0820': ['48 20 40 00 00 00'],
            },
          ),
        ],
      );
      final client = await _connect(fake);
      final result = await Mode08DiscoveryService.discoverSupportedTids(client: client);

      expect(result.isSupported, isTrue);
      expect(result.supportStatus, equals(EcuSupportStatus.supported));
      expect(result.isComplete, isTrue);
      expect(result.supportedTids, equals({0x01, 0x20, 0x22}));
      expect(result.queriedBlocks, equals([0x00, 0x20]));
      expect(result.unqueriedBlocks, isEmpty);
      expect(result.failureReason, isNull);
    });

    // -------------------------------------------------------------------------
    // Gap Probes
    // -------------------------------------------------------------------------

    test('Probe 1: transaction dataError with negative observedFrame is NOT upgraded to unsupported', () {
      final res = Mode08DiscoveryCodec.parseObdResponse(
        const ObdResponse(
          errorCode: Elm327ErrorCode.dataError,
          rawLines: ['7E8 03 7F 08 11', 'ZZ'],
          frames: [],
          observedFrames: [
            ObdFrame(
              [0x03, 0x7F, 0x08, 0x11],
              sourceId: '7E8',
              payload: [0x7F, 0x08, 0x11],
            ),
          ],
          attributedSources: {'7E8'},
        ),
        expectedBaseTid: 0x00,
      );

      // Must NOT be Mode08NegativeResponse with unsupported!
      expect(res.supportStatus, isNot(equals(EcuSupportStatus.unsupported)));
      expect(res, isA<Mode08MalformedResponse>());
      expect(res.ecuResults.containsKey('7E8'), isTrue);
      expect(res.ecuResults['7E8'], isA<Mode08NegativeResponse>());
    });

    test('Probe 1b: transaction with negative frame but damaged rawLine from another ECU is NOT upgraded to unsupported', () {
      final res = Mode08DiscoveryCodec.parseObdResponse(
        const ObdResponse(
          errorCode: Elm327ErrorCode.none,
          rawLines: ['7E8 03 7F 08 11', '7E9 01 48'],
          frames: [
            ObdFrame(
              [0x03, 0x7F, 0x08, 0x11],
              sourceId: '7E8',
              payload: [0x7F, 0x08, 0x11],
            ),
          ],
          observedFrames: [],
          attributedSources: {'7E8'},
        ),
        expectedBaseTid: 0x00,
      );

      // Must NOT be Mode08NegativeResponse with unsupported!
      expect(res.supportStatus, isNot(equals(EcuSupportStatus.unsupported)));
      expect(res, isA<Mode08MalformedResponse>());
      expect(res.ecuResults.containsKey('7E8'), isTrue);
      expect(res.ecuResults['7E8'], isA<Mode08NegativeResponse>());
      expect(res.ecuResults.containsKey('7E9'), isTrue);
      expect(res.ecuResults['7E9'], isA<Mode08MalformedResponse>());
    });

    test('Probe 1c: transaction with negative frame but DATA ERROR string in rawLines is NOT upgraded to unsupported', () {
      final res = Mode08DiscoveryCodec.parseObdResponse(
        const ObdResponse(
          errorCode: Elm327ErrorCode.none,
          rawLines: ['7E8 03 7F 08 11', 'DATA ERROR'],
          frames: [
            ObdFrame(
              [0x03, 0x7F, 0x08, 0x11],
              sourceId: '7E8',
              payload: [0x7F, 0x08, 0x11],
            ),
          ],
          observedFrames: [],
          attributedSources: {'7E8'},
        ),
        expectedBaseTid: 0x00,
      );

      expect(res.supportStatus, isNot(equals(EcuSupportStatus.unsupported)));
      expect(res, isA<Mode08MalformedResponse>());
      expect(res.ecuResults.containsKey('7E8'), isTrue);
      expect(res.ecuResults.containsKey('unattributed'), isTrue);
    });

    test('Probe 2: successful ECU does not mask unknown/damaged ECU in same block (isComplete must be false)', () async {
      final fake = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': ['48 00 80 00 00 00'], // Supports TID 01
            },
          ),
          FakeEcu(
            name: 'TCM',
            requestId: '7E1',
            responseId: '7E9',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': ['7F 08 22'], // Conditions not correct (unknown)
            },
          ),
        ],
      );
      final client = await _connect(fake);
      final result = await Mode08DiscoveryService.discoverSupportedTids(client: client);

      expect(result.isSupported, isTrue);
      expect(result.supportedTids, equals({0x01}));
      // Crucial check: 7E9 was unknown, so discovery is NOT complete!
      expect(result.isComplete, isFalse);
      expect(result.failureReason, isNotNull);
      expect(result.unqueriedBlocks, equals([0x00]));
    });

    test('Probe 3: ECU declaring next block in 0800 that disappears in 0820 marks isComplete: false', () async {
      final fake = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': ['48 00 80 00 00 01'], // 7E8 has next block
              '0820': ['48 20 40 00 00 00'], // 7E8 completes
            },
          ),
          FakeEcu(
            name: 'TCM',
            requestId: '7E1',
            responseId: '7E9',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': ['48 00 40 00 00 01'], // 7E9 also declared next block
              // In 0820: 7E9 does NOT respond (silence / absent)
            },
          ),
        ],
      );
      final client = await _connect(fake);
      final result = await Mode08DiscoveryService.discoverSupportedTids(client: client);

      expect(result.isSupported, isTrue);
      expect(result.supportedTids, contains(0x01));
      expect(result.supportedTids, contains(0x02));
      // 7E9 owed block 0x20 but never delivered:
      expect(result.isComplete, isFalse);
    });

    test('Probe 4: subsequent block does not overwrite earlier block evidence for the same ECU', () async {
      final fake = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': ['7E8 06 48 00 80 00 00 01'], // TID 0x01
              '0820': ['7E8 06 48 20 40 00 00 00'], // TID 0x22
            },
          ),
        ],
      );
      final client = await _connect(fake);
      expect((await client.send('ATH1')).isSuccess, isTrue);
      final result = await Mode08DiscoveryService.discoverSupportedTids(client: client);
      expect(result.isSupported, isTrue);
      expect(result.isComplete, isTrue);
      // Both blocks must be preserved in 7E8's evidence
      final ecmResult = result.ecuResults['7E8'];
      expect(ecmResult, isA<Mode08SupportSuccess>());
      final ecmSuccess = ecmResult as Mode08SupportSuccess;
      expect(ecmSuccess.supportedTids, contains(0x01), reason: 'Block 0x00 TID 0x01 must not be lost');
      expect(ecmSuccess.supportedTids, contains(0x22), reason: 'Block 0x20 TID 0x22 must be preserved');
    });

    test('Probe 5: raw codec rejects contradictory DLC=1 with declared PCI length 6 as invalid framing', () {
      final res = Mode08DiscoveryCodec.parseResponse(
        '7E8 1 06 48 00 80 00 00 00',
        expectedBaseTid: 0x00,
      );

      // DLC=1 with 06 (6 bytes payload) is contradictory and must NOT parse as success
      expect(res, isNot(isA<Mode08SupportSuccess>()));
      expect(res, isA<Mode08MalformedResponse>());
      expect(res.supportStatus, equals(EcuSupportStatus.unknown));
    });

    test('Probe 6: 3-block discovery with intermittent ECU (declared in 0x00, absent in 0x20, reappears in 0x40)', () async {
      final fake = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': ['7E8 06 48 00 80 00 00 01'], // Declares next
              // 0820: 7E8 is silent / absent
              '0840': ['7E8 06 48 40 20 00 00 00'], // Reappears and finishes
            },
          ),
          FakeEcu(
            name: 'TCM',
            requestId: '7E1',
            responseId: '7E9',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': ['7E9 06 48 00 40 00 00 01'], // Declares next
              '0820': ['7E9 06 48 20 80 00 00 01'], // Declares next
              '0840': ['7E9 06 48 40 10 00 00 00'], // Finishes
            },
          ),
        ],
      );
      final client = await _connect(fake);
      expect((await client.send('ATH1')).isSuccess, isTrue);
      final result = await Mode08DiscoveryService.discoverSupportedTids(client: client);

      expect(result.isSupported, isTrue);
      expect(result.isComplete, isFalse, reason: '7E8 missed block 0x20');
      expect(result.unqueriedBlocks, contains(0x20));
      expect(result.queriedBlocks, equals([0x00, 0x20, 0x40]));

      // TIDs from both ECUs across all successful blocks are preserved in union
      expect(result.supportedTids, contains(0x01));
      expect(result.supportedTids, contains(0x02));
      expect(result.supportedTids, contains(0x21));
      expect(result.supportedTids, contains(0x43));
      expect(result.supportedTids, contains(0x44));

      // perEcuBlockResults preserves all 3 blocks for 7E8 (including the missing outcome on 0x20)
      final ecmBlocks = result.perEcuBlockResults['7E8'];
      expect(ecmBlocks, isNotNull);
      expect(ecmBlocks!.keys, containsAll([0x00, 0x20, 0x40]));
      expect(ecmBlocks[0x00], isA<Mode08SupportSuccess>());
      expect(ecmBlocks[0x20], isA<Mode08NoResponse>());
      expect(ecmBlocks[0x40], isA<Mode08SupportSuccess>());

      // aggregated ecuResults for 7E8 preserves TIDs from 0x00 and 0x40
      final ecmAggregated = result.ecuResults['7E8'] as Mode08SupportSuccess;
      expect(ecmAggregated.supportedTids, containsAll([0x01, 0x43]));
    });

    test('Probe 7: 29-bit CAN and mixed 11/29-bit CAN framing with DLC validation', () {
      // 1. Valid 29-bit CAN frame with DLC
      final res29 = Mode08DiscoveryCodec.parseResponse(
        '18DAF110 8 06 48 00 80 00 00 00',
        expectedBaseTid: 0x00,
      );
      expect(res29, isA<Mode08SupportSuccess>());
      expect((res29 as Mode08SupportSuccess).supportedTids, contains(0x01));
      expect(res29.ecuResults.containsKey('18DAF110'), isTrue);

      // 2. Contradictory DLC on 29-bit CAN frame
      final res29Bad = Mode08DiscoveryCodec.parseResponse(
        '18DAF110 1 06 48 00 80 00 00 00',
        expectedBaseTid: 0x00,
      );
      expect(res29Bad, isA<Mode08MalformedResponse>());

      // 3. Mixed 11-bit and 29-bit CAN responses in one exchange
      final resMixed = Mode08DiscoveryCodec.parseResponse(
        '7E8 8 06 48 00 80 00 00 00\n18DAF110 8 06 48 00 40 00 00 00',
        expectedBaseTid: 0x00,
      );
      expect(resMixed, isA<Mode08SupportSuccess>());
      final mixedSuccess = resMixed as Mode08SupportSuccess;
      expect(mixedSuccess.supportedTids, containsAll([0x01, 0x02]));
      expect(mixedSuccess.ecuResults.keys, containsAll(['7E8', '18DAF110']));
    });

    // -------------------------------------------------------------------------
    // End-to-End Test: Fake Transport -> Codec -> Service -> UI Warning Path
    // -------------------------------------------------------------------------

    testWidgets('E2E: incomplete discovery result renders partial warning banner in UI', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fake = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': ['48 00 80 00 00 00'], // Supports TID 01
            },
          ),
          FakeEcu(
            name: 'TCM',
            requestId: '7E1',
            responseId: '7E9',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': ['7F 08 22'], // Conditions not correct (unknown)
            },
          ),
        ],
      );
      late final Mode08DiscoveryResult discoveryResult;
      await tester.runAsync(() async {
        final client = await _connect(fake);
        discoveryResult = await Mode08DiscoveryService.discoverSupportedTids(client: client);
        await client.disconnect();
      });

      // Verify that service returned incomplete result
      expect(discoveryResult.isSupported, isTrue);
      expect(discoveryResult.isComplete, isFalse);

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            obdSessionProvider.overrideWith(_ConnectedCanSession.new),
            serviceRecipesMatrixProvider.overrideWith(
              (ref) async => CandidateMatrix(entries: const []),
            ),
            mode08DiscoveryStateProvider.overrideWith(
              () => _FixedDiscoveryNotifier(discoveryResult),
            ),
          ],
          child: localizedMaterialApp(
            home: const Scaffold(body: ServiceRecipesScreen()),
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mode08_discovery_partial_warning')), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Additional P1 Probes: Anonymous NO DATA (P1-A) and Anonymous Source (P1-B)
    // -------------------------------------------------------------------------

    test('Probe 8 (P1-A): negative frame with errorCode noData and rawLine NO DATA remains unknown', () {
      final res = Mode08DiscoveryCodec.parseObdResponse(
        const ObdResponse(
          errorCode: Elm327ErrorCode.noData,
          rawLines: ['7E8 03 7F 08 11', 'NO DATA'],
          frames: [
            ObdFrame(
              [0x03, 0x7F, 0x08, 0x11],
              sourceId: '7E8',
              payload: [0x7F, 0x08, 0x11],
            ),
          ],
          observedFrames: [],
          attributedSources: {'7E8'},
        ),
        expectedBaseTid: 0x00,
      );

      // Must NOT be upgraded to unsupported!
      expect(res.supportStatus, equals(EcuSupportStatus.unknown));
      expect(res, isA<Mode08NoResponse>());
      expect(res.ecuResults.containsKey('7E8'), isTrue);
      expect(res.ecuResults['7E8'], isA<Mode08NegativeResponse>());
      expect((res.ecuResults['7E8'] as Mode08NegativeResponse).nrc, equals(0x11));
      expect(res.ecuResults.containsKey('unattributed'), isTrue);
      expect(res.ecuResults['unattributed'], isA<Mode08NoResponse>());
    });

    test('Probe 8b (P1-A): negative frame with errorCode none but rawLine NO DATA remains unknown', () {
      final res = Mode08DiscoveryCodec.parseObdResponse(
        const ObdResponse(
          errorCode: Elm327ErrorCode.none,
          rawLines: ['7E8 03 7F 08 11', 'NO DATA'],
          frames: [
            ObdFrame(
              [0x03, 0x7F, 0x08, 0x11],
              sourceId: '7E8',
              payload: [0x7F, 0x08, 0x11],
            ),
          ],
          observedFrames: [],
          attributedSources: {'7E8'},
        ),
        expectedBaseTid: 0x00,
      );

      expect(res.supportStatus, equals(EcuSupportStatus.unknown));
      expect(res, isA<Mode08NoResponse>());
      expect(res.ecuResults.containsKey('7E8'), isTrue);
      expect(res.ecuResults['7E8'], isA<Mode08NegativeResponse>());
      expect(res.ecuResults.containsKey('unattributed'), isTrue);
      expect(res.ecuResults['unattributed'], isA<Mode08NoResponse>());
    });

    test('Probe 8c (P1-A affirmative): affirmative frame with errorCode noData and rawLine NO DATA retains TIDs but marks isComplete: false', () {
      final res = Mode08DiscoveryCodec.parseObdResponse(
        const ObdResponse(
          errorCode: Elm327ErrorCode.noData,
          rawLines: ['7E8 06 48 00 80 00 00 00', 'NO DATA'],
          frames: [
            ObdFrame(
              [0x06, 0x48, 0x00, 0x80, 0x00, 0x00, 0x00],
              sourceId: '7E8',
              payload: [0x48, 0x00, 0x80, 0x00, 0x00, 0x00],
            ),
          ],
          observedFrames: [],
          attributedSources: {'7E8'},
        ),
        expectedBaseTid: 0x00,
      );

      expect(res.supportStatus, equals(EcuSupportStatus.supported));
      expect(res, isA<Mode08SupportSuccess>());
      final succ = res as Mode08SupportSuccess;
      expect(succ.supportedTids, contains(0x01));
      expect(succ.ecuResults['7E8'], isA<Mode08SupportSuccess>());
      expect(succ.ecuResults.containsKey('unattributed'), isTrue);
      expect(succ.ecuResults['unattributed'], isA<Mode08NoResponse>());
      expect(succ.anonymousResponses, isNotEmpty);
      expect(succ.anonymousResponses.first, isA<Mode08NoResponse>());
    });

    test('Probe 8d (P1-A service): affirmative discovery with anonymous NO DATA preserves TIDs with partial warning', () async {
      final fake = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': [
                '7E8 06 48 00 80 00 00 00',
                'NO DATA',
              ],
            },
          ),
        ],
      );
      final client = await _connect(fake);
      final result = await Mode08DiscoveryService.discoverSupportedTids(client: client);

      expect(result.isSupported, isTrue);
      expect(result.supportedTids, contains(0x01));
      expect(result.isComplete, isFalse);
      expect(result.unqueriedBlocks, contains(0x00));
      expect(result.failureReason, contains('NO DATA'));
      expect(result.perEcuBlockResults.containsKey('7E8'), isTrue);
      expect(result.perEcuBlockResults.containsKey('unattributed'), isFalse);
    });

    test('Probe 8e (P1-A): negative frame with unsupported NRC 0x11 and rawLine anonymous NRC 0x22 remains unknown', () {
      final res = Mode08DiscoveryCodec.parseObdResponse(
        const ObdResponse(
          errorCode: Elm327ErrorCode.none,
          rawLines: ['7E8 03 7F 08 11', '7F 08 22'],
          frames: [
            ObdFrame(
              [0x03, 0x7F, 0x08, 0x11],
              sourceId: '7E8',
              payload: [0x7F, 0x08, 0x11],
            ),
          ],
          observedFrames: [],
          attributedSources: {'7E8'},
        ),
        expectedBaseTid: 0x00,
      );

      // Must NOT be declared unsupported when peer ECU returned conditionsNotCorrect!
      expect(res.supportStatus, equals(EcuSupportStatus.unknown));
      expect(res, isA<Mode08NegativeResponse>());
      expect((res as Mode08NegativeResponse).nrc, equals(0x22));
      expect(res.ecuResults.containsKey('7E8'), isTrue);
      expect(res.ecuResults['7E8'], isA<Mode08NegativeResponse>());
      expect(res.anonymousResponses, isNotEmpty);
      expect(res.anonymousResponses.first, isA<Mode08NegativeResponse>());
      expect((res.anonymousResponses.first as Mode08NegativeResponse).nrc, equals(0x22));
    });

    test('Probe 8f (P1-A): affirmative frame with anonymous NRC 0x22 preserves TIDs with partial warning', () async {
      final fake = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': [
                '7E8 06 48 00 80 00 00 00',
                '7F 08 22',
              ],
            },
          ),
        ],
      );
      final client = await _connect(fake);
      final result = await Mode08DiscoveryService.discoverSupportedTids(client: client);

      expect(result.isSupported, isTrue);
      expect(result.supportedTids, contains(0x01));
      expect(result.isComplete, isFalse);
      expect(result.unqueriedBlocks, contains(0x00));
      expect(result.perEcuBlockResults.containsKey('7E8'), isTrue);
      expect(result.perEcuBlockResults.containsKey('unattributed'), isFalse);
    });

    test('Probe 9 (P1-B absence): anonymous responder in 0800 declaring 0x20 that disappears in 0820 marks isComplete: false', () async {
      final fake = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': [
                '48 00 80 00 00 01',
                '48 00 40 00 00 00',
              ],
              '0820': [
                '48 20 00 00 00 00',
              ],
            },
          ),
        ],
      );
      final client = await _connect(fake);
      final result = await Mode08DiscoveryService.discoverSupportedTids(client: client);

      expect(result.isSupported, isTrue);
      expect(result.supportedTids, contains(0x01));
      expect(result.supportedTids, contains(0x02));
      // Missing responder in 0820 MUST mark isComplete: false!
      expect(result.isComplete, isFalse, reason: 'ECU A missing in block 0x20 must prevent isComplete');
      expect(result.unqueriedBlocks, contains(0x20));
      expect(result.failureReason, contains('來源歸因'));
      // Must NOT fabricate ecu_0 or ecu_1 in perEcuBlockResults!
      expect(result.perEcuBlockResults.containsKey('ecu_0'), isFalse);
      expect(result.perEcuBlockResults.containsKey('ecu_1'), isFalse);
    });

    test('Probe 10 (P1-B order swap): anonymous responses swapping order across blocks does not cross-merge and marks isComplete: false', () async {
      final fake = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': [
                '48 00 80 00 00 01',
                '48 00 40 00 00 01',
              ],
              '0820': [
                '48 20 80 00 00 00',
                '48 20 40 00 00 00',
              ],
            },
          ),
        ],
      );
      final client = await _connect(fake);
      final result = await Mode08DiscoveryService.discoverSupportedTids(client: client);

      expect(result.isSupported, isTrue);
      // Union of TIDs from both blocks and both nodes:
      expect(result.supportedTids, containsAll([0x01, 0x02, 0x21, 0x22]));
      // Multi-node anonymous responses cannot confirm cross-block coverage without headers:
      expect(result.isComplete, isFalse);
      expect(result.unqueriedBlocks, contains(0x20));
      expect(result.failureReason, contains('來源歸因'));
      expect(result.perEcuBlockResults.containsKey('ecu_0'), isFalse);
      expect(result.perEcuBlockResults.containsKey('ecu_1'), isFalse);
    });

    // -------------------------------------------------------------------------
    // True Interactive Flow: Real Mode08DiscoveryNotifier (Section 3)
    // -------------------------------------------------------------------------

    testWidgets('Interactive E2E 1: real Mode08DiscoveryNotifier tap discover -> discovering -> partial warning & TID -> disconnect resets UI', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fake = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': ['48 00 80 00 00 00'], // Supports TID 01
            },
          ),
          FakeEcu(
            name: 'TCM',
            requestId: '7E1',
            responseId: '7E9',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': ['7F 08 22'], // NRC 0x22 (conditionsNotCorrect -> unknown)
            },
          ),
        ],
      );

      final gate = Completer<void>();
      final transport = _GateableTransport(fake)..gate = gate;
      final client = await _connect(transport);

      final sessionController = _TestConnectedCanSession(client);

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            obdSessionProvider.overrideWith(() => sessionController),
            serviceRecipesMatrixProvider.overrideWith(
              (ref) async => CandidateMatrix(entries: const []),
            ),
            // Use real Mode08DiscoveryNotifier!
            mode08DiscoveryStateProvider.overrideWith(Mode08DiscoveryNotifier.new),
          ],
          child: localizedMaterialApp(
            home: const Scaffold(body: ServiceRecipesScreen()),
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify button exists and is clickable
      final discoverButton = find.byKey(const Key('mode08_discovery_button'));
      expect(discoverButton, findsOneWidget);

      // Tap the discover button
      await tester.tap(discoverButton);
      await tester.pump();

      final container = ProviderScope.containerOf(tester.element(find.byType(ServiceRecipesScreen)));
      expect(container.read(mode08DiscoveryStateProvider).isDiscovering, isTrue);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Release gate and wait for discovery execution to complete
      gate.complete();
      await tester.runAsync(() async {
        while (!container.read(mode08DiscoveryStateProvider).isCompleted &&
               !container.read(mode08DiscoveryStateProvider).isFailed &&
               !container.read(mode08DiscoveryStateProvider).isRefused) {
          await Future.delayed(const Duration(milliseconds: 20));
        }
      });
      await tester.pumpAndSettle();

      // Verify partial warning is displayed
      expect(find.byKey(const Key('mode08_discovery_partial_warning')), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      // Verify discovered TID 01 is displayed
      expect(find.byKey(const Key('mode08_discovery_success_container')), findsOneWidget);
      expect(find.textContaining(r'$01'), findsWidgets);

      // Now disconnect the session and verify state is cleared
      sessionController.triggerDisconnect();
      await tester.pumpAndSettle();

      // Verify partial warning and result container are removed
      expect(find.byKey(const Key('mode08_discovery_partial_warning')), findsNothing);
      expect(find.byKey(const Key('mode08_discovery_success_container')), findsNothing);

      await tester.runAsync(() async {
        await client.disconnect();
      });
    });

    testWidgets('Interactive E2E 2: real Mode08DiscoveryNotifier handles transport failure during discovery gracefully', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fake = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': ['BUS ERROR'],
            },
          ),
        ],
      );

      final gate = Completer<void>();
      final transport = _GateableTransport(fake)..gate = gate;
      final client = await _connect(transport);

      final sessionController = _TestConnectedCanSession(client);

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            obdSessionProvider.overrideWith(() => sessionController),
            serviceRecipesMatrixProvider.overrideWith(
              (ref) async => CandidateMatrix(entries: const []),
            ),
            mode08DiscoveryStateProvider.overrideWith(Mode08DiscoveryNotifier.new),
          ],
          child: localizedMaterialApp(
            home: const Scaffold(body: ServiceRecipesScreen()),
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final discoverButton = find.byKey(const Key('mode08_discovery_button'));
      expect(discoverButton, findsOneWidget);

      await tester.tap(discoverButton);
      await tester.pump();

      // Verify "discovering" (探索中) state immediately after tap
      final container = ProviderScope.containerOf(tester.element(find.byType(ServiceRecipesScreen)));
      expect(container.read(mode08DiscoveryStateProvider).isDiscovering, isTrue);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      gate.complete();
      await tester.runAsync(() async {
        while (!container.read(mode08DiscoveryStateProvider).isFailed &&
               !container.read(mode08DiscoveryStateProvider).isCompleted &&
               !container.read(mode08DiscoveryStateProvider).isRefused) {
          await Future.delayed(const Duration(milliseconds: 20));
        }
      });
      await tester.pumpAndSettle();

      // Should transition to failed, rendering failure container with error icon
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      await tester.runAsync(() async {
        await client.disconnect();
      });
    });
  });
}
