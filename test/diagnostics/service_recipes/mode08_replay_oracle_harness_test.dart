/// Tests that the Mode 08 Replay Oracle harness decisively fails (never silently skips)
/// under all failure conditions (server unstarted, missing fixture, hash mismatch, result mismatch, entry mismatch).
library;

import 'package:flutter_test/flutter_test.dart';
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
        reason: 'Entry disagreement must throw TestFailure',
      );
    });
  });
}
