/// Tests that the Mode 08 Replay Oracle harness decisively fails (never silently skips)
/// under all failure conditions (server unstarted, missing fixture, hash mismatch, result mismatch, entry mismatch,
/// schema mutations, and subprocess negative controls).
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/service_recipes/mode08_codec.dart';
import 'package:torque_obd/diagnostics/service_recipes/mode08_discovery_service.dart';
import 'package:torque_obd/diagnostics/service_recipes/qualification_tier.dart';
import 'package:torque_obd/obd/elm327_client.dart';

import 'mode08_replay_oracle_test.dart';

void main() {
  group('Mode 08 Replay Oracle Harness Decisive Failure Tests', () {
    test('harness fails decisively when server is unstarted and required-mode is set', () async {
      const deadPort = 35499;

      expect(
        () async => await verifyOraclePreflight(
          host: '127.0.0.1',
          port: deadPort,
          requiredMode: true,
          identity: oracleIdentity,
        ),
        throwsA(isA<TestFailure>()),
        reason: 'Preflight must fail decisively when server is unstarted in required-mode',
      );
    });

    test('harness fails decisively when fixture file is missing and required-mode is set', () {
      const nonExistentPath = 'tool/obd_test_rig/non_existent_fixture_9999.json';

      expect(
        () => loadReplayFixtures(nonExistentPath, requiredMode: true),
        throwsA(isA<TestFailure>()),
        reason: 'Loading missing fixture in required-mode must throw TestFailure',
      );
    });

    test('harness fails decisively when fixture SHA-256 hash mismatches server hash', () {
      const serverHash = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      const corruptedLocalHash = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

      expect(
        () => verifyFixtureHash(serverHash: serverHash, localHash: corruptedLocalHash),
        throwsA(isA<TestFailure>()),
        reason: 'Hash mismatch must throw TestFailure and fail decisively',
      );
    });

    test('harness fails decisively when replay result mismatches expected outcome (isSupported)', () {
      final mockResult = Mode08DiscoveryResult(
        isSupported: true,
        supportStatus: EcuSupportStatus.supported,
        supportedTids: const {1},
        queriedBlocks: const [0],
        discoveredAt: DateTime.now().toUtc(),
        isComplete: true,
        unqueriedBlocks: const [],
      );

      final tamperedExpected = <String, dynamic>{
        'isSupported': false, // Mismatch!
        'supportStatus': 'supported',
        'supportedTids': [1],
        'isComplete': true,
        'unqueriedBlocks': [],
        'trustedEcus': [],
        'hasAnonymous': false,
      };

      expect(
        () => verifyScenarioOutcome(mockResult, tamperedExpected, scenarioId: 'harness_mismatch_test'),
        throwsA(isA<TestFailure>()),
        reason: 'isSupported mismatch must throw TestFailure',
      );
    });

    test('harness fails decisively when replay result mismatches expected outcome (isComplete)', () {
      final mockResult = Mode08DiscoveryResult(
        isSupported: true,
        supportStatus: EcuSupportStatus.supported,
        supportedTids: const {1, 32},
        queriedBlocks: const [0, 32],
        discoveredAt: DateTime.now().toUtc(),
        isComplete: false,
        unqueriedBlocks: const [32],
      );

      final tamperedExpected = <String, dynamic>{
        'isSupported': true,
        'supportStatus': 'supported',
        'supportedTids': [1, 32],
        'isComplete': true, // Mismatch!
        'unqueriedBlocks': [32],
        'trustedEcus': [],
        'hasAnonymous': false,
      };

      expect(
        () => verifyScenarioOutcome(mockResult, tamperedExpected, scenarioId: 'harness_mismatch_test'),
        throwsA(isA<TestFailure>()),
        reason: 'isComplete mismatch must throw TestFailure',
      );
    });

    test('harness fails decisively when parser entries disagree on supportStatus', () {
      // Structured says supported, but raw says unsupported
      const structuredResp = ObdResponse(
        rawLines: ['7E8 06 48 00 80 00 00 00'],
        frames: [
          ObdFrame([0x06, 0x48, 0x00, 0x80, 0x00, 0x00, 0x00], sourceId: '7E8', payload: [0x48, 0x00, 0x80, 0x00, 0x00, 0x00]),
        ],
        observedFrames: [],
        attributedSources: {'7E8'},
      );

      const disagreeingRawResp = ObdResponse(
        rawLines: ['7E8 03 7F 08 11'],
        frames: [],
        observedFrames: [],
        attributedSources: {'7E8'},
      );

      expect(
        () => verifyParserEntryConsistency(
          structuredResponse: structuredResp,
          observedOnlyResponse: structuredResp,
          rawOnlyResponse: disagreeingRawResp,
          expectedBaseTid: 0x00,
        ),
        throwsA(isA<TestFailure>()),
        reason: 'Entry disagreement on supportStatus must throw TestFailure',
      );
    });

    test('harness fails decisively on swapped ECU data in perEcuBlockResults mutation', () {
      final mockResult = Mode08DiscoveryResult(
        isSupported: true,
        supportStatus: EcuSupportStatus.supported,
        supportedTids: const {1, 2},
        queriedBlocks: const [0],
        discoveredAt: DateTime.now().toUtc(),
        isComplete: true,
        unqueriedBlocks: const [],
        ecuResults: {
          '7E8': Mode08SupportSuccess(baseTid: 0, bitmask: 0x80000000, supportedTids: const {1}, hasNextBlock: false),
          '7E9': Mode08SupportSuccess(baseTid: 0, bitmask: 0x40000000, supportedTids: const {2}, hasNextBlock: false),
        },
        perEcuBlockResults: {
          '7E8': {
            0: Mode08SupportSuccess(baseTid: 0, bitmask: 0x80000000, supportedTids: const {1}, hasNextBlock: false),
          },
          '7E9': {
            0: Mode08SupportSuccess(baseTid: 0, bitmask: 0x40000000, supportedTids: const {2}, hasNextBlock: false),
          },
        },
      );

      // Swapped: 7E8 has TIDs [2] and 7E9 has TIDs [1]
      final swappedExpected = <String, dynamic>{
        'isSupported': true,
        'supportStatus': 'supported',
        'supportedTids': [1, 2],
        'isComplete': true,
        'unqueriedBlocks': [],
        'trustedEcus': ['7E8', '7E9'],
        'hasAnonymous': false,
        'perEcuBlockResults': {
          '7E8': {
            '0': {'supportStatus': 'supported', 'supportedTids': [2]},
          },
          '7E9': {
            '0': {'supportStatus': 'supported', 'supportedTids': [1]},
          },
        },
      };

      expect(
        () => verifyScenarioOutcome(mockResult, swappedExpected, scenarioId: 'swapped_ecu_test'),
        throwsA(isA<TestFailure>()),
        reason: 'Swapped ECU data in perEcuBlockResults must throw TestFailure',
      );
    });

    test('harness fails decisively when fake ECU is inserted into trusted set', () {
      final mockResult = Mode08DiscoveryResult(
        isSupported: true,
        supportStatus: EcuSupportStatus.supported,
        supportedTids: const {1},
        queriedBlocks: const [0],
        discoveredAt: DateTime.now().toUtc(),
        isComplete: true,
        unqueriedBlocks: const [],
        ecuResults: {
          '7E8': Mode08SupportSuccess(baseTid: 0, bitmask: 0x80000000, supportedTids: const {1}, hasNextBlock: false),
        },
      );

      final fakeEcuExpected = <String, dynamic>{
        'isSupported': true,
        'supportStatus': 'supported',
        'supportedTids': [1],
        'isComplete': true,
        'unqueriedBlocks': [],
        'trustedEcus': ['7E8', '7EA'], // 7EA is fake
        'hasAnonymous': false,
      };

      expect(
        () => verifyScenarioOutcome(mockResult, fakeEcuExpected, scenarioId: 'fake_ecu_test'),
        throwsA(isA<TestFailure>()),
        reason: 'Fake ECU inserted into trusted set must throw TestFailure',
      );
    });

    test('harness fails decisively when block evidence is missing in perEcuBlockResults', () {
      final mockResult = Mode08DiscoveryResult(
        isSupported: true,
        supportStatus: EcuSupportStatus.supported,
        supportedTids: const {1},
        queriedBlocks: const [0],
        discoveredAt: DateTime.now().toUtc(),
        isComplete: true,
        unqueriedBlocks: const [],
        ecuResults: {
          '7E8': Mode08SupportSuccess(baseTid: 0, bitmask: 0x80000000, supportedTids: const {1}, hasNextBlock: false),
        },
        perEcuBlockResults: {
          '7E8': {
            0: Mode08SupportSuccess(baseTid: 0, bitmask: 0x80000000, supportedTids: const {1}, hasNextBlock: false),
          },
        },
      );

      final missingBlockExpected = <String, dynamic>{
        'isSupported': true,
        'supportStatus': 'supported',
        'supportedTids': [1],
        'isComplete': true,
        'unqueriedBlocks': [],
        'trustedEcus': ['7E8'],
        'hasAnonymous': false,
        'perEcuBlockResults': {
          '7E8': {
            '0': {'supportStatus': 'supported', 'supportedTids': [1]},
            '32': {'supportStatus': 'supported', 'supportedTids': [33]}, // Block 32 missing in result!
          },
        },
      };

      expect(
        () => verifyScenarioOutcome(mockResult, missingBlockExpected, scenarioId: 'missing_block_test'),
        throwsA(isA<TestFailure>()),
        reason: 'Missing block evidence in perEcuBlockResults must throw TestFailure',
      );
    });

    test('harness fails decisively when anonymous uncertainty is stripped', () {
      final mockResult = Mode08DiscoveryResult(
        isSupported: true,
        supportStatus: EcuSupportStatus.supported,
        supportedTids: const {1},
        queriedBlocks: const [0],
        discoveredAt: DateTime.now().toUtc(),
        isComplete: false,
        unqueriedBlocks: const [32],
        failureReason: '來源歸因與覆蓋完整度未確認',
        hasAnonymous: true, // Actual has anonymous uncertainty
      );

      final strippedAnonymousExpected = <String, dynamic>{
        'isSupported': true,
        'supportStatus': 'supported',
        'supportedTids': [1],
        'isComplete': false,
        'unqueriedBlocks': [32],
        'trustedEcus': [],
        'hasAnonymous': false, // Tampered: stripped!
      };

      expect(
        () => verifyScenarioOutcome(mockResult, strippedAnonymousExpected, scenarioId: 'stripped_anonymous_test'),
        throwsA(isA<TestFailure>()),
        reason: 'Stripped anonymous uncertainty must throw TestFailure',
      );
    });

    test('harness fails decisively on extra unexpected uncompleted block', () {
      final mockResult = Mode08DiscoveryResult(
        isSupported: true,
        supportStatus: EcuSupportStatus.supported,
        supportedTids: const {1},
        queriedBlocks: const [0],
        discoveredAt: DateTime.now().toUtc(),
        isComplete: false,
        unqueriedBlocks: const [32],
        failureReason: 'Block unqueried',
      );

      final tamperedUnqueriedExpected = <String, dynamic>{
        'isSupported': true,
        'supportStatus': 'supported',
        'supportedTids': [1],
        'isComplete': false,
        'unqueriedBlocks': [32, 64], // Extra block 64!
        'trustedEcus': [],
        'hasAnonymous': false,
      };

      expect(
        () => verifyScenarioOutcome(mockResult, tamperedUnqueriedExpected, scenarioId: 'extra_uncompleted_block_test'),
        throwsA(isA<TestFailure>()),
        reason: 'Mismatched uncompleted blocks must throw TestFailure',
      );
    });

    test('harness fails decisively when parser entries disagree on supported TIDs', () {
      const structuredResp = ObdResponse(
        rawLines: ['7E8 06 48 00 80 00 00 00'],
        frames: [
          ObdFrame([0x06, 0x48, 0x00, 0x80, 0x00, 0x00, 0x00], sourceId: '7E8', payload: [0x48, 0x00, 0x80, 0x00, 0x00, 0x00]),
        ],
        observedFrames: [],
        attributedSources: {'7E8'},
      );

      // Raw response reports TID 2 instead of TID 1
      const disagreeingRawResp = ObdResponse(
        rawLines: ['7E8 06 48 00 40 00 00 00'],
        frames: [],
        observedFrames: [],
        attributedSources: {'7E8'},
      );

      expect(
        () => verifyParserEntryConsistency(
          structuredResponse: structuredResp,
          observedOnlyResponse: structuredResp,
          rawOnlyResponse: disagreeingRawResp,
          expectedBaseTid: 0x00,
        ),
        throwsA(isA<TestFailure>()),
        reason: 'Parser entry divergence on supported TIDs must throw TestFailure',
      );
    });

    test('harness fails decisively when parser entries disagree on responding sources', () {
      const structuredResp = ObdResponse(
        rawLines: ['7E8 06 48 00 80 00 00 00'],
        frames: [
          ObdFrame([0x06, 0x48, 0x00, 0x80, 0x00, 0x00, 0x00], sourceId: '7E8', payload: [0x48, 0x00, 0x80, 0x00, 0x00, 0x00]),
        ],
        observedFrames: [],
        attributedSources: {'7E8'},
      );

      // Raw response reports from 7E9 instead of 7E8
      const disagreeingRawResp = ObdResponse(
        rawLines: ['7E9 06 48 00 80 00 00 00'],
        frames: [],
        observedFrames: [],
        attributedSources: {'7E9'},
      );

      expect(
        () => verifyParserEntryConsistency(
          structuredResponse: structuredResp,
          observedOnlyResponse: structuredResp,
          rawOnlyResponse: disagreeingRawResp,
          expectedBaseTid: 0x00,
        ),
        throwsA(isA<TestFailure>()),
        reason: 'Parser entry divergence on responding sources must throw TestFailure',
      );
    });

    test('harness fails decisively when parser entries disagree on anonymous uncertainty', () {
      const structuredResp = ObdResponse(
        rawLines: ['7E8 06 48 00 80 00 00 00'],
        frames: [
          ObdFrame([0x06, 0x48, 0x00, 0x80, 0x00, 0x00, 0x00], sourceId: '7E8', payload: [0x48, 0x00, 0x80, 0x00, 0x00, 0x00]),
        ],
        observedFrames: [],
        attributedSources: {'7E8'},
      );

      // Raw response has no header, resulting in anonymous response
      const unheaderedRawResp = ObdResponse(
        rawLines: ['48 00 80 00 00 00'],
        frames: [],
        observedFrames: [],
        attributedSources: {},
      );

      expect(
        () => verifyParserEntryConsistency(
          structuredResponse: structuredResp,
          observedOnlyResponse: structuredResp,
          rawOnlyResponse: unheaderedRawResp,
          expectedBaseTid: 0x00,
        ),
        throwsA(isA<TestFailure>()),
        reason: 'Parser entry divergence on anonymous uncertainty must throw TestFailure',
      );
    });

    test('harness fails decisively when fixture schema has unsupported version', () {
      final tempDir = Directory.systemTemp.createTempSync('mode08_schema_test_ver_');
      final tempFile = File('${tempDir.path}/fixtures_bad_ver.json');
      try {
        tempFile.writeAsStringSync(jsonEncode({
          'version': '999.0.0',
          'name': 'bad',
          'provenance': 'test',
          'description': 'test',
          'scenarios': [
            {
              'id': 's1',
              'dimension': 'd',
              'description': 'desc',
              'steps': [{'command': '0800', 'lines': ['OK']}],
              'expected_outcome': {
                'isSupported': true,
                'supportStatus': 'supported',
                'supportedTids': [1],
                'isComplete': true,
                'unqueriedBlocks': [],
                'trustedEcus': [],
                'hasAnonymous': false,
              },
            },
          ],
        }));

        expect(
          () => loadReplayFixtures(tempFile.path, requiredMode: true),
          throwsA(isA<TestFailure>()),
          reason: 'Unsupported version in required-mode must throw TestFailure',
        );
        expect(
          () => loadReplayFixtures(tempFile.path, requiredMode: false),
          throwsA(isA<FormatException>()),
          reason: 'Unsupported version in normal mode must throw FormatException',
        );
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('harness fails decisively when fixture schema has duplicate scenario IDs', () {
      final tempDir = Directory.systemTemp.createTempSync('mode08_schema_test_dup_');
      final tempFile = File('${tempDir.path}/fixtures_dup_id.json');
      try {
        tempFile.writeAsStringSync(jsonEncode({
          'version': '1.0.0',
          'name': 'bad',
          'provenance': 'test',
          'description': 'test',
          'scenarios': [
            {
              'id': 'duplicate_id',
              'dimension': 'd1',
              'description': 'desc1',
              'steps': [{'command': '0800', 'lines': ['OK']}],
              'expected_outcome': {
                'isSupported': true,
                'supportStatus': 'supported',
                'supportedTids': [1],
                'isComplete': true,
                'unqueriedBlocks': [],
                'trustedEcus': [],
                'hasAnonymous': false,
              },
            },
            {
              'id': 'duplicate_id',
              'dimension': 'd2',
              'description': 'desc2',
              'steps': [{'command': '0800', 'lines': ['OK']}],
              'expected_outcome': {
                'isSupported': true,
                'supportStatus': 'supported',
                'supportedTids': [1],
                'isComplete': true,
                'unqueriedBlocks': [],
                'trustedEcus': [],
                'hasAnonymous': false,
              },
            },
          ],
        }));

        expect(
          () => loadReplayFixtures(tempFile.path, requiredMode: true),
          throwsA(isA<TestFailure>()),
          reason: 'Duplicate scenario ID in required-mode must throw TestFailure',
        );
        expect(
          () => loadReplayFixtures(tempFile.path, requiredMode: false),
          throwsA(isA<FormatException>()),
          reason: 'Duplicate scenario ID in normal mode must throw FormatException',
        );
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('harness fails decisively when fixture schema has invalid chunk_sizes', () {
      final tempDir = Directory.systemTemp.createTempSync('mode08_schema_test_chunk_');
      final tempFile = File('${tempDir.path}/fixtures_bad_chunk.json');
      try {
        tempFile.writeAsStringSync(jsonEncode({
          'version': '1.0.0',
          'name': 'bad',
          'provenance': 'test',
          'description': 'test',
          'scenarios': [
            {
              'id': 's1',
              'dimension': 'd',
              'description': 'desc',
              'steps': [
                {
                  'command': '0800',
                  'lines': ['OK'],
                  'chunk_sizes': [0, -1], // Invalid!
                },
              ],
              'expected_outcome': {
                'isSupported': true,
                'supportStatus': 'supported',
                'supportedTids': [1],
                'isComplete': true,
                'unqueriedBlocks': [],
                'trustedEcus': [],
                'hasAnonymous': false,
              },
            },
          ],
        }));

        expect(
          () => loadReplayFixtures(tempFile.path, requiredMode: true),
          throwsA(isA<TestFailure>()),
          reason: 'Invalid chunk sizes in required-mode must throw TestFailure',
        );
        expect(
          () => loadReplayFixtures(tempFile.path, requiredMode: false),
          throwsA(isA<FormatException>()),
          reason: 'Invalid chunk sizes in normal mode must throw FormatException',
        );
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('subprocess negative control: Python replay server exits code 2 on unsupported fixture version', () {
      final tempDir = Directory.systemTemp.createTempSync('mode08_py_ver_test_');
      final tempFile = File('${tempDir.path}/bad_ver.json');
      try {
        tempFile.writeAsStringSync(jsonEncode({
          'version': '999.0.0',
          'name': 'test',
          'scenarios': [],
        }));

        final result = Process.runSync(
          'python3',
          ['tool/obd_test_rig/mode08_replay_reference.py', '--fixtures', tempFile.path],
        );
        expect(
          result.exitCode,
          equals(2),
          reason: 'Python reference must exit with code 2 on unsupported schema version. stderr: ${result.stderr}',
        );
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('subprocess negative control: Python replay server exits code 2 on missing fixture file', () {
      final result = Process.runSync(
        'python3',
        ['tool/obd_test_rig/mode08_replay_reference.py', '--fixtures', 'tool/obd_test_rig/non_existent_fixture_file_9999.json'],
      );
      expect(
        result.exitCode,
        equals(2),
        reason: 'Python reference must exit with code 2 on missing fixture file. stderr: ${result.stderr}',
      );
    });
  });
}
