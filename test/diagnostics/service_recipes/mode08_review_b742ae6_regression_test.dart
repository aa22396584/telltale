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

class _FixedDiscoveryNotifier extends Mode08DiscoveryNotifier {
  _FixedDiscoveryNotifier(this._result);
  final Mode08DiscoveryResult _result;

  @override
  Mode08DiscoveryState build() => Mode08DiscoveryState.completed(result: _result);
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
  });
}
