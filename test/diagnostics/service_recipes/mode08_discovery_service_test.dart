/// Tests for Mode 08 non-actuating capability discovery service.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/service_recipes/mode08_codec.dart';
import 'package:torque_obd/diagnostics/service_recipes/mode08_discovery_service.dart';
import 'package:torque_obd/diagnostics/service_recipes/qualification_tier.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/transcript.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';

import '../../support/fake_elm327.dart';

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
  group('Mode08DiscoveryService', () {
    test('discovers supported TIDs on single block (0800 -> 48 00 80 00 00 00)', () async {
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

      final result = await Mode08DiscoveryService.discoverSupportedTids(
        client: client,
      );

      expect(result.isSupported, isTrue);
      expect(result.supportStatus, equals(EcuSupportStatus.supported));
      expect(result.supportedTids, equals({0x01}));
      expect(result.containsTid(0x01), isTrue);
      expect(result.containsTid(0x02), isFalse);
      expect(result.queriedBlocks, equals([0x00]));
      expect(result.failureReason, isNull);
    });

    test('chains multiple blocks when hasNextBlock is true (0800 -> 0820)', () async {
      final fake = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: _physicsReplies(),
            literalResponses: {
              // Bit 31 (0x01) and Bit 0 (0x20, hasNextBlock)
              '0800': ['48 00 80 00 00 01'],
              // Bit 30 (0x22)
              '0820': ['48 20 40 00 00 00'],
            },
          ),
        ],
      );
      final client = await _connect(fake);

      final result = await Mode08DiscoveryService.discoverSupportedTids(
        client: client,
      );

      expect(result.isSupported, isTrue);
      expect(result.supportStatus, equals(EcuSupportStatus.supported));
      expect(result.supportedTids, equals({0x01, 0x20, 0x22}));
      expect(result.queriedBlocks, equals([0x00, 0x20]));
    });

    test('classifies NRC 0x12 as affirmatively unsupported', () async {
      final fake = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': ['7F 08 12'],
            },
          ),
        ],
      );
      final client = await _connect(fake);

      final result = await Mode08DiscoveryService.discoverSupportedTids(
        client: client,
      );

      expect(result.isSupported, isFalse);
      expect(result.supportStatus, equals(EcuSupportStatus.unsupported));
      expect(result.supportedTids, isEmpty);
      expect(result.nrc, equals(0x12));
      expect(result.failureReason, contains('NRC 0x12'));
    });

    test('classifies NRC 0x22 as unknown support (conditionsNotCorrect)', () async {
      final fake = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': ['7F 08 22'],
            },
          ),
        ],
      );
      final client = await _connect(fake);

      final result = await Mode08DiscoveryService.discoverSupportedTids(
        client: client,
      );

      expect(result.isSupported, isFalse);
      // Environmental refusal means routine may exist: must remain unknown
      expect(result.supportStatus, equals(EcuSupportStatus.unknown));
      expect(result.supportedTids, isEmpty);
      expect(result.nrc, equals(0x22));
    });

    test('refuses immediately without wire commands on non-CAN bus', () async {
      final fake = FakeElm327(
        protocol: BusProtocol.iso9141,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '33',
            responseId: 'F1',
            responses: _physicsReplies(),
          ),
        ],
      );
      final client = await _connect(fake);

      final result = await Mode08DiscoveryService.discoverSupportedTids(
        client: client,
      );

      expect(result.isSupported, isFalse);
      expect(result.supportStatus, equals(EcuSupportStatus.unknown));
      expect(result.failureReason, contains('requires a resolved OBD-II CAN bus'));
      // No 08 queries sent to transport
      expect(
        client.transcript.entries.any(
          (e) => e.direction == TranscriptDirection.out &&
              String.fromCharCodes(e.bytes).startsWith('08'),
        ),
        isFalse,
      );
    });

    test('handles timeout fail-closed as unknown support', () async {
      final fake = FakeElm327(
        protocol: BusProtocol.can11,
        faults: const AdapterFaults(swallowPromptFor: {'0800'}),
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
      final client = await _connect(fake, commandTimeout: const Duration(milliseconds: 50));

      final result = await Mode08DiscoveryService.discoverSupportedTids(
        client: client,
        timeout: const Duration(milliseconds: 50),
        budget: const Duration(milliseconds: 100),
      );

      expect(result.isSupported, isFalse);
      expect(result.supportStatus, equals(EcuSupportStatus.unknown));
      expect(result.failureReason, contains('timed out'));
    });

    test('prohibits runnable TID probing fail-closed', () {
      expect(
        () => Mode08DiscoveryCodec.createSupportedTidCommand(0x01),
        throwsA(isA<ProhibitedActiveProbeException>()),
      );
      expect(
        () => Mode08DiscoveryCodec.createSupportedTidCommand(0x05),
        throwsA(isA<ProhibitedActiveProbeException>()),
      );
    });

    test('aggregates supported TIDs across multiple responding ECUs on CAN broadcast', () async {
      final fake = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': ['48 00 80 00 00 00'], // Supports TID 0x01
            },
          ),
          FakeEcu(
            name: 'TCM',
            requestId: '7E1',
            responseId: '7E9',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': ['48 00 40 00 00 00'], // Supports TID 0x02
            },
          ),
        ],
      );
      final client = await _connect(fake);

      final result = await Mode08DiscoveryService.discoverSupportedTids(
        client: client,
      );

      expect(result.isSupported, isTrue);
      expect(result.supportStatus, equals(EcuSupportStatus.supported));
      expect(result.supportedTids, equals({0x01, 0x02}));
      expect(result.containsTid(0x01), isTrue);
      expect(result.containsTid(0x02), isTrue);
    });

    test('accepts Mode 08 capability when primary ECU answers 48 and secondary ECU answers 7F 08 12', () async {
      final fake = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': ['48 00 80 00 00 00'], // ECM supports EVAP TID 0x01
            },
          ),
          FakeEcu(
            name: 'TCM',
            requestId: '7E1',
            responseId: '7E9',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': ['7F 08 12'], // TCM does not support Mode 08
            },
          ),
        ],
      );
      final client = await _connect(fake);

      final result = await Mode08DiscoveryService.discoverSupportedTids(
        client: client,
      );

      expect(result.isSupported, isTrue);
      expect(result.supportStatus, equals(EcuSupportStatus.supported));
      expect(result.supportedTids, equals({0x01}));
    });

    test('preserves discovered TIDs as partial discovery when subsequent block times out', () async {
      final fake = FakeElm327(
        protocol: BusProtocol.can11,
        faults: const AdapterFaults(swallowPromptFor: {'0820'}),
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': ['48 00 80 00 00 01'], // Has next block (0x20)
            },
          ),
        ],
      );
      final client = await _connect(fake, commandTimeout: const Duration(milliseconds: 50));

      final result = await Mode08DiscoveryService.discoverSupportedTids(
        client: client,
        timeout: const Duration(milliseconds: 50),
        budget: const Duration(milliseconds: 200),
      );

      expect(result.isSupported, isTrue);
      expect(result.supportStatus, equals(EcuSupportStatus.supported));
      expect(result.isComplete, isFalse);
      expect(result.supportedTids, equals({0x01, 0x20}));
      expect(result.unqueriedBlocks, equals([0x20]));
      expect(result.failureReason, contains('0x20'));
    });

    test('preserves discovered TIDs as partial discovery when subsequent block returns NRC 0x22', () async {
      final fake = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: _physicsReplies(),
            literalResponses: {
              '0800': ['48 00 80 00 00 01'], // Has next block (0x20)
              '0820': ['7F 08 22'], // Conditions not correct
            },
          ),
        ],
      );
      final client = await _connect(fake);

      final result = await Mode08DiscoveryService.discoverSupportedTids(
        client: client,
      );

      expect(result.isSupported, isTrue);
      expect(result.supportStatus, equals(EcuSupportStatus.supported));
      expect(result.isComplete, isFalse);
      expect(result.supportedTids, equals({0x01, 0x20}));
      expect(result.unqueriedBlocks, equals([0x20]));
      expect(result.failureReason, contains('NRC 0x22'));
    });
  });
}
