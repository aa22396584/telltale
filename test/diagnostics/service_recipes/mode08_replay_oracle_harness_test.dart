/// Tests that the Mode 08 Replay Oracle harness decisively fails (never silently skips)
/// under all failure conditions (server unstarted, missing fixture, hash mismatch, result mismatch, entry mismatch,
/// schema mutations, and subprocess negative controls).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/service_recipes/mode08_codec.dart';
import 'package:torque_obd/diagnostics/service_recipes/mode08_discovery_service.dart';
import 'package:torque_obd/diagnostics/service_recipes/qualification_tier.dart';
import 'package:torque_obd/obd/elm327_client.dart';

import 'mode08_replay_oracle_test.dart';

String resolveFlutterExecutable() {
  final envFlutter = Platform.environment['FLUTTER'];
  if (envFlutter != null && envFlutter.isNotEmpty && File(envFlutter).existsSync()) {
    return envFlutter;
  }
  final dartPath = Platform.resolvedExecutable;
  final dartFile = File(dartPath);
  final candidate = File('${dartFile.parent.parent.parent.parent.path}/bin/flutter');
  if (candidate.existsSync()) {
    return candidate.path;
  }
  final whichResult = Process.runSync('which', ['flutter']);
  if (whichResult.exitCode == 0) {
    final path = whichResult.stdout.toString().trim();
    if (path.isNotEmpty && File(path).existsSync()) {
      return path;
    }
  }
  final home = Platform.environment['HOME'] ?? '';
  final fvmCandidate = File('$home/fvm/versions/3.47.0/bin/flutter');
  if (fvmCandidate.existsSync()) {
    return fvmCandidate.path;
  }
  throw StateError('Cannot locate flutter executable. Set FLUTTER environment variable.');
}

Future<({Process process, int port})> startDedicatedReplayServer({required String fixturesPath}) async {
  final proc = await Process.start(
    'python3',
    ['tool/obd_test_rig/mode08_replay_reference.py', '--fixtures', fixturesPath, '--port', '0'],
  );
  final completer = Completer<int>();
  final outLines = <String>[];
  final errLines = <String>[];
  proc.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
    outLines.add(line);
    final match = RegExp(r'listening on 127\.0\.0\.1:(\d+)').firstMatch(line);
    if (match != null && !completer.isCompleted) {
      completer.complete(int.parse(match.group(1)!));
    }
  });
  proc.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
    errLines.add(line);
  });
  unawaited(proc.exitCode.then((code) {
    if (!completer.isCompleted) {
      completer.completeError(StateError('Replay server exited early with code $code: ${errLines.join("\n")}'));
    }
  }));
  final port = await completer.future.timeout(
    const Duration(seconds: 5),
    onTimeout: () {
      proc.kill();
      throw TimeoutException('Timed out waiting for replay server to report listening port. Output: ${outLines.join("\n")}');
    },
  );
  return (process: proc, port: port);
}

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
        throwsA(predicate<TestFailure>((e) =>
          e.message != null &&
          e.message!.contains('Mode 08 replay reference not running on 127.0.0.1:$deadPort')
        )),
        reason: 'Preflight must fail decisively when server is unstarted in required-mode',
      );
    });

    test('harness fails decisively when fixture file is missing and required-mode is set', () {
      const nonExistentPath = 'tool/obd_test_rig/non_existent_fixture_9999.json';

      expect(
        () => loadReplayFixtures(nonExistentPath, requiredMode: true),
        throwsA(predicate<TestFailure>((e) =>
          e.message != null &&
          e.message!.contains('fixtures file missing at $nonExistentPath')
        )),
        reason: 'Loading missing fixture in required-mode must throw TestFailure',
      );
    });

    test('harness fails decisively when fixture SHA-256 hash mismatches server hash', () {
      const serverHash = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      const corruptedLocalHash = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

      expect(
        () => verifyFixtureHash(serverHash: serverHash, localHash: corruptedLocalHash),
        throwsA(predicate<TestFailure>((e) =>
          e.message != null &&
          e.message!.contains('Fixture SHA-256 mismatch')
        )),
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

      final matchingExpected = <String, dynamic>{
        'isSupported': true,
        'supportStatus': 'supported',
        'supportedTids': [1],
        'isComplete': true,
        'unqueriedBlocks': <int>[],
        'trustedEcus': <String>[],
        'hasAnonymous': false,
        'perEcuBlockResults': <String, dynamic>{},
      };

      // 1. Positive control: matching expected passes cleanly
      expect(() => verifyScenarioOutcome(mockResult, matchingExpected, scenarioId: 'harness_match_test'), returnsNormally);

      final tamperedExpected = <String, dynamic>{
        'isSupported': false, // Mismatch!
        'supportStatus': 'supported',
        'supportedTids': [1],
        'isComplete': true,
        'unqueriedBlocks': [],
        'trustedEcus': [],
        'hasAnonymous': false,
        'perEcuBlockResults': <String, dynamic>{},
      };

      // 2. Negative control: tampered isSupported throws specific TestFailure
      expect(
        () => verifyScenarioOutcome(mockResult, tamperedExpected, scenarioId: 'harness_mismatch_test'),
        throwsA(predicate<TestFailure>((e) =>
          e.message != null &&
          e.message!.contains('isSupported mismatch')
        )),
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
        failureReason: 'Block unqueried',
      );

      final matchingExpected = <String, dynamic>{
        'isSupported': true,
        'supportStatus': 'supported',
        'supportedTids': [1, 32],
        'isComplete': false,
        'unqueriedBlocks': [32],
        'failureReasonContains': 'Block unqueried',
        'trustedEcus': <String>[],
        'hasAnonymous': false,
        'perEcuBlockResults': <String, dynamic>{},
      };

      // 1. Positive control: matching expected passes cleanly
      expect(() => verifyScenarioOutcome(mockResult, matchingExpected, scenarioId: 'harness_match_test'), returnsNormally);

      final tamperedExpected = <String, dynamic>{
        'isSupported': true,
        'supportStatus': 'supported',
        'supportedTids': [1, 32],
        'isComplete': true, // Mismatch!
        'unqueriedBlocks': [32],
        'failureReasonContains': 'Block unqueried',
        'trustedEcus': [],
        'hasAnonymous': false,
        'perEcuBlockResults': <String, dynamic>{},
      };

      // 2. Negative control: tampered isComplete throws specific TestFailure
      expect(
        () => verifyScenarioOutcome(mockResult, tamperedExpected, scenarioId: 'harness_mismatch_test'),
        throwsA(predicate<TestFailure>((e) =>
          e.message != null &&
          e.message!.contains('isComplete mismatch')
        )),
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

      // 1. Positive control: consistent responses pass cleanly
      expect(
        () => verifyParserEntryConsistency(
          structuredResponse: structuredResp,
          observedOnlyResponse: structuredResp,
          rawOnlyResponse: structuredResp,
          expectedBaseTid: 0x00,
        ),
        returnsNormally,
      );

      // 2. Negative control: disagreeing response throws specific TestFailure
      expect(
        () => verifyParserEntryConsistency(
          structuredResponse: structuredResp,
          observedOnlyResponse: structuredResp,
          rawOnlyResponse: disagreeingRawResp,
          expectedBaseTid: 0x00,
        ),
        throwsA(predicate<TestFailure>((e) =>
          e.message != null &&
          e.message!.contains('Raw-only entry must match structured entry evidence projection on 0x0')
        )),
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
        throwsA(predicate<TestFailure>((e) =>
          e.message != null &&
          e.message!.contains('supportedTids mismatch') &&
          e.message!.contains('ECU 7E8 block 0x0')
        )),
        reason: 'Swapped ECU data in perEcuBlockResults must throw TestFailure specifically on supportedTids mismatch',
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
        throwsA(predicate<TestFailure>((e) =>
          e.message != null &&
          e.message!.contains('trusted ECUs set exact match failed')
        )),
        reason: 'Fake ECU inserted into trusted set must throw TestFailure specifically on trusted ECUs mismatch',
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
        throwsA(predicate<TestFailure>((e) =>
          e.message != null &&
          e.message!.contains('ECU 7E8 block base TIDs mismatch')
        )),
        reason: 'Missing block evidence in perEcuBlockResults must throw TestFailure specifically on block base TIDs mismatch',
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
        throwsA(predicate<TestFailure>((e) =>
          e.message != null &&
          e.message!.contains('hasAnonymous mismatch')
        )),
        reason: 'Stripped anonymous uncertainty must throw TestFailure specifically on hasAnonymous mismatch',
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
        throwsA(predicate<TestFailure>((e) =>
          e.message != null &&
          e.message!.contains('unqueriedBlocks exact match failed')
        )),
        reason: 'Mismatched uncompleted blocks must throw TestFailure specifically on unqueriedBlocks mismatch',
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
        throwsA(predicate<TestFailure>((e) =>
          e.message != null &&
          e.message!.contains('Raw-only entry must match structured entry evidence projection on 0x0')
        )),
        reason: 'Parser entry divergence on supported TIDs must throw TestFailure specifically on projection mismatch',
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
        throwsA(predicate<TestFailure>((e) =>
          e.message != null &&
          e.message!.contains('Raw-only entry must match structured entry evidence projection on 0x0')
        )),
        reason: 'Parser entry divergence on responding sources must throw TestFailure specifically on projection mismatch',
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
        throwsA(predicate<TestFailure>((e) =>
          e.message != null &&
          e.message!.contains('Raw-only entry must match structured entry evidence projection on 0x0')
        )),
        reason: 'Parser entry divergence on anonymous uncertainty must throw TestFailure specifically on projection mismatch',
      );
    });

    test('harness passes positive control when loading valid fixture file in required and normal mode', () {
      final reqResult = loadReplayFixtures(oracleFixturesRelativePath, requiredMode: true);
      expect(reqResult.scenarios.length, equals(10));
      expect(reqResult.data['version'], equals('1.0.0'));
      expect(reqResult.sha256, isNotEmpty);

      final normalResult = loadReplayFixtures(oracleFixturesRelativePath, requiredMode: false);
      expect(normalResult.scenarios.length, equals(10));
    });

    test('harness fails decisively when fixture schema has unsupported version', () {
      final validRaw = File(oracleFixturesRelativePath).readAsStringSync();
      final validData = jsonDecode(validRaw) as Map<String, dynamic>;
      validData['version'] = '999.0.0';

      final tempDir = Directory.systemTemp.createTempSync('mode08_schema_test_ver_');
      final tempFile = File('${tempDir.path}/fixtures_bad_ver.json');
      try {
        tempFile.writeAsStringSync(jsonEncode(validData));

        expect(
          () => loadReplayFixtures(tempFile.path, requiredMode: true),
          throwsA(predicate<TestFailure>((e) =>
            e.message != null &&
            e.message!.contains('fixtures version 999.0.0 is unsupported')
          )),
          reason: 'Unsupported version in required-mode must throw TestFailure specifically on unsupported version',
        );
        expect(
          () => loadReplayFixtures(tempFile.path, requiredMode: false),
          throwsA(predicate<FormatException>((e) =>
            e.message.contains('Unsupported fixture version: 999.0.0')
          )),
          reason: 'Unsupported version in normal mode must throw FormatException specifically on unsupported version',
        );
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('harness fails decisively when fixture schema has duplicate scenario IDs', () {
      final validRaw = File(oracleFixturesRelativePath).readAsStringSync();
      final validData = jsonDecode(validRaw) as Map<String, dynamic>;
      final scenarios = validData['scenarios'] as List<dynamic>;
      final duplicateScenario = Map<String, dynamic>.from(scenarios[0] as Map<String, dynamic>);
      scenarios.add(duplicateScenario);

      final tempDir = Directory.systemTemp.createTempSync('mode08_schema_test_dup_');
      final tempFile = File('${tempDir.path}/fixtures_dup_id.json');
      try {
        tempFile.writeAsStringSync(jsonEncode(validData));

        expect(
          () => loadReplayFixtures(tempFile.path, requiredMode: true),
          throwsA(predicate<TestFailure>((e) =>
            e.message != null &&
            e.message!.contains('Duplicate scenario ID found in fixtures: normal_headered_single_block')
          )),
          reason: 'Duplicate scenario ID in required-mode must throw TestFailure specifically on duplicate ID',
        );
        expect(
          () => loadReplayFixtures(tempFile.path, requiredMode: false),
          throwsA(predicate<FormatException>((e) =>
            e.message.contains('Duplicate scenario ID: normal_headered_single_block')
          )),
          reason: 'Duplicate scenario ID in normal mode must throw FormatException specifically on duplicate ID',
        );
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('harness fails decisively when fixture schema has invalid chunk_sizes', () {
      final validRaw = File(oracleFixturesRelativePath).readAsStringSync();
      final validData = jsonDecode(validRaw) as Map<String, dynamic>;
      final scenarios = validData['scenarios'] as List<dynamic>;
      final s0 = Map<String, dynamic>.from(scenarios[0] as Map<String, dynamic>);
      final steps = List<dynamic>.from(s0['steps'] as List<dynamic>);
      final step0 = Map<String, dynamic>.from(steps[0] as Map<String, dynamic>);
      step0['chunk_sizes'] = [0, -1];
      steps[0] = step0;
      s0['steps'] = steps;
      scenarios[0] = s0;

      final tempDir = Directory.systemTemp.createTempSync('mode08_schema_test_chunk_');
      final tempFile = File('${tempDir.path}/fixtures_bad_chunk.json');
      try {
        tempFile.writeAsStringSync(jsonEncode(validData));

        expect(
          () => loadReplayFixtures(tempFile.path, requiredMode: true),
          throwsA(predicate<TestFailure>((e) =>
            e.message != null &&
            e.message!.contains('invalid chunk_size: 0')
          )),
          reason: 'Invalid chunk sizes in required-mode must throw TestFailure specifically on invalid chunk_size',
        );
        expect(
          () => loadReplayFixtures(tempFile.path, requiredMode: false),
          throwsA(predicate<FormatException>((e) =>
            e.message.contains('invalid chunk_size: 0')
          )),
          reason: 'Invalid chunk sizes in normal mode must throw FormatException specifically on invalid chunk_size',
        );
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('harness fails decisively when fixture schema is missing perEcuBlockResults field', () {
      final validRaw = File(oracleFixturesRelativePath).readAsStringSync();
      final validData = jsonDecode(validRaw) as Map<String, dynamic>;
      final scenarios = validData['scenarios'] as List<dynamic>;
      final s0 = Map<String, dynamic>.from(scenarios[0] as Map<String, dynamic>);
      final exp = Map<String, dynamic>.from(s0['expected_outcome'] as Map<String, dynamic>);
      exp.remove('perEcuBlockResults');
      s0['expected_outcome'] = exp;
      scenarios[0] = s0;

      final tempDir = Directory.systemTemp.createTempSync('mode08_schema_test_per_ecu_');
      final tempFile = File('${tempDir.path}/fixtures_no_per_ecu.json');
      try {
        tempFile.writeAsStringSync(jsonEncode(validData));

        expect(
          () => loadReplayFixtures(tempFile.path, requiredMode: true),
          throwsA(predicate<TestFailure>((e) =>
            e.message != null &&
            e.message!.contains('missing field: perEcuBlockResults')
          )),
          reason: 'Missing perEcuBlockResults in required-mode must throw TestFailure specifically on missing perEcuBlockResults',
        );
        expect(
          () => loadReplayFixtures(tempFile.path, requiredMode: false),
          throwsA(predicate<FormatException>((e) =>
            e.message.contains('missing field: perEcuBlockResults')
          )),
          reason: 'Missing perEcuBlockResults in normal mode must throw FormatException specifically on missing perEcuBlockResults',
        );
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('harness fails decisively when fixture schema is missing supportedTids in a block', () {
      final validRaw = File(oracleFixturesRelativePath).readAsStringSync();
      final validData = jsonDecode(validRaw) as Map<String, dynamic>;
      final scenarios = validData['scenarios'] as List<dynamic>;
      final s0 = Map<String, dynamic>.from(scenarios[0] as Map<String, dynamic>);
      final exp = Map<String, dynamic>.from(s0['expected_outcome'] as Map<String, dynamic>);
      final perEcu = Map<String, dynamic>.from(exp['perEcuBlockResults'] as Map<String, dynamic>);
      final ecu7E8 = Map<String, dynamic>.from(perEcu['7E8'] as Map<String, dynamic>);
      final block0 = Map<String, dynamic>.from(ecu7E8['0'] as Map<String, dynamic>);
      block0.remove('supportedTids');
      ecu7E8['0'] = block0;
      perEcu['7E8'] = ecu7E8;
      exp['perEcuBlockResults'] = perEcu;
      s0['expected_outcome'] = exp;
      validData['scenarios'] = [s0];

      final tempDir = Directory.systemTemp.createTempSync('mode08_schema_test_no_tids_');
      final tempFile = File('${tempDir.path}/fixtures_no_tids.json');
      try {
        tempFile.writeAsStringSync(jsonEncode(validData));

        expect(
          () => loadReplayFixtures(tempFile.path, requiredMode: true),
          throwsA(predicate<TestFailure>((e) => e.message != null && e.message!.contains('missing supportedTids'))),
          reason: 'Missing supportedTids in required-mode must throw TestFailure with missing supportedTids message',
        );
        expect(
          () => loadReplayFixtures(tempFile.path, requiredMode: false),
          throwsA(predicate<FormatException>((e) => e.message.contains('missing supportedTids'))),
          reason: 'Missing supportedTids in normal mode must throw FormatException with missing supportedTids message',
        );
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('harness fails decisively when fixture schema is missing supportStatus in a block', () {
      final validRaw = File(oracleFixturesRelativePath).readAsStringSync();
      final validData = jsonDecode(validRaw) as Map<String, dynamic>;
      final scenarios = validData['scenarios'] as List<dynamic>;
      final s0 = Map<String, dynamic>.from(scenarios[0] as Map<String, dynamic>);
      final exp = Map<String, dynamic>.from(s0['expected_outcome'] as Map<String, dynamic>);
      final perEcu = Map<String, dynamic>.from(exp['perEcuBlockResults'] as Map<String, dynamic>);
      final ecu7E8 = Map<String, dynamic>.from(perEcu['7E8'] as Map<String, dynamic>);
      final block0 = Map<String, dynamic>.from(ecu7E8['0'] as Map<String, dynamic>);
      block0.remove('supportStatus');
      ecu7E8['0'] = block0;
      perEcu['7E8'] = ecu7E8;
      exp['perEcuBlockResults'] = perEcu;
      s0['expected_outcome'] = exp;
      validData['scenarios'] = [s0];

      final tempDir = Directory.systemTemp.createTempSync('mode08_schema_test_no_status_');
      final tempFile = File('${tempDir.path}/fixtures_no_status.json');
      try {
        tempFile.writeAsStringSync(jsonEncode(validData));

        expect(
          () => loadReplayFixtures(tempFile.path, requiredMode: true),
          throwsA(predicate<TestFailure>((e) => e.message != null && e.message!.contains('missing supportStatus'))),
          reason: 'Missing supportStatus in required-mode must throw TestFailure with missing supportStatus message',
        );
        expect(
          () => loadReplayFixtures(tempFile.path, requiredMode: false),
          throwsA(predicate<FormatException>((e) => e.message.contains('missing supportStatus'))),
          reason: 'Missing supportStatus in normal mode must throw FormatException with missing supportStatus message',
        );
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('harness fails decisively when unexpected NRC is returned on ECU block', () {
      final mockResult = Mode08DiscoveryResult(
        isSupported: false,
        supportStatus: EcuSupportStatus.unknown,
        supportedTids: const {},
        queriedBlocks: const [0],
        discoveredAt: DateTime.now().toUtc(),
        isComplete: false,
        unqueriedBlocks: const [0],
        failureReason: 'Transaction condition not correct (NRC 0x22)',
        ecuResults: {
          '7E8': const Mode08NegativeResponse(originalSid: 0x08, nrc: 0x22),
        },
        perEcuBlockResults: {
          '7E8': {
            0: const Mode08NegativeResponse(originalSid: 0x08, nrc: 0x22),
          },
        },
      );

      // 1. Positive control: when expected outcome includes matching NRC 0x22, it passes cleanly
      final expectedWithNrc = <String, dynamic>{
        'isSupported': false,
        'supportStatus': 'unknown',
        'supportedTids': <int>[],
        'isComplete': false,
        'unqueriedBlocks': [0],
        'failureReasonContains': 'Transaction condition not correct',
        'trustedEcus': ['7E8'],
        'hasAnonymous': false,
        'perEcuBlockResults': {
          '7E8': {
            '0': {
              'supportStatus': 'unknown',
              'supportedTids': <int>[],
              'nrc': 0x22,
            },
          },
        },
      };
      expect(() => verifyScenarioOutcome(mockResult, expectedWithNrc, scenarioId: 'expected_nrc_test'), returnsNormally);

      // 2. Negative control: when expected outcome omits NRC, it fails specifically on NRC mismatch
      final expectedWithoutNrc = <String, dynamic>{
        'isSupported': false,
        'supportStatus': 'unknown',
        'supportedTids': <int>[],
        'isComplete': false,
        'unqueriedBlocks': [0],
        'failureReasonContains': 'Transaction condition not correct',
        'trustedEcus': ['7E8'],
        'hasAnonymous': false,
        'perEcuBlockResults': {
          '7E8': {
            '0': {
              'supportStatus': 'unknown',
              'supportedTids': <int>[],
            },
          },
        },
      };

      expect(
        () => verifyScenarioOutcome(mockResult, expectedWithoutNrc, scenarioId: 'unexpected_nrc_test'),
        throwsA(predicate<TestFailure>((e) =>
          e.message != null &&
          e.message!.contains('NRC mismatch') &&
          e.message!.contains('ECU 7E8 block 0x0')
        )),
        reason: 'Unexpected NRC returned on ECU block must throw TestFailure specifically on NRC mismatch',
      );
    });

    test('subprocess negative control: Python replay server exits code 2 on unsupported fixture version', () {
      final validRaw = File(oracleFixturesRelativePath).readAsStringSync();
      final validData = jsonDecode(validRaw) as Map<String, dynamic>;
      validData['version'] = '999.0.0';

      final tempDir = Directory.systemTemp.createTempSync('mode08_py_ver_test_');
      final tempFile = File('${tempDir.path}/bad_ver.json');
      try {
        tempFile.writeAsStringSync(jsonEncode(validData));

        final result = Process.runSync(
          'python3',
          ['tool/obd_test_rig/mode08_replay_reference.py', '--fixtures', tempFile.path],
        );
        expect(
          result.exitCode,
          equals(2),
          reason: 'Python reference must exit with code 2 on unsupported schema version. stderr: ${result.stderr}',
        );
        expect(
          result.stderr,
          contains("Unsupported fixture schema version: '999.0.0'"),
          reason: 'Python reference stderr must specifically state unsupported fixture schema version: ${result.stderr}',
        );
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('subprocess positive control: Python replay server starts cleanly on valid fixtures', () async {
      final server = await startDedicatedReplayServer(fixturesPath: oracleFixturesRelativePath);
      try {
        expect(server.port, greaterThan(0), reason: 'Replay server must bind to a dynamic port > 0');
      } finally {
        server.process.kill();
      }
    });

    test('subprocess negative control: Python replay server exits code 2 on missing fixture file', () {
      const nonExistentPath = 'tool/obd_test_rig/non_existent_fixture_file_9999.json';
      final result = Process.runSync(
        'python3',
        ['tool/obd_test_rig/mode08_replay_reference.py', '--fixtures', nonExistentPath],
      );
      expect(
        result.exitCode,
        equals(2),
        reason: 'Python reference must exit with code 2 on missing fixture file. stderr: ${result.stderr}',
      );
      expect(
        result.stderr,
        contains('fixtures file not found at'),
        reason: 'Python reference stderr must specifically state fixture file not found. stderr: ${result.stderr}',
      );
    });

    test('subprocess positive control: Flutter test in required-mode passes with exit code 0', () async {
      final server = await startDedicatedReplayServer(fixturesPath: oracleFixturesRelativePath);
      final flutterBin = resolveFlutterExecutable();
      Process? testProc;
      try {
        testProc = await Process.start(
          flutterBin,
          [
            'test',
            '--dart-define=MODE08_ORACLE_REQUIRED=true',
            '--dart-define=MODE08_ORACLE_PORT=${server.port}',
            'test/diagnostics/service_recipes/mode08_replay_oracle_test.dart',
          ],
        );
        final outLines = <String>[];
        final errLines = <String>[];
        testProc.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(outLines.add);
        testProc.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(errLines.add);

        final exitCode = await testProc.exitCode.timeout(
          const Duration(seconds: 45),
          onTimeout: () {
            testProc?.kill();
            throw TimeoutException('Timed out waiting for Flutter positive control test');
          },
        );
        expect(
          exitCode,
          equals(0),
          reason: 'Flutter test in required-mode must pass with exit 0 when server and fixtures are valid.\nstdout: ${outLines.join("\n")}\nstderr: ${errLines.join("\n")}',
        );
      } finally {
        testProc?.kill();
        server.process.kill();
      }
    });

    test('subprocess negative control: Flutter test in required-mode exits non-zero on unsupported fixture version', () async {
      final server = await startDedicatedReplayServer(fixturesPath: oracleFixturesRelativePath);
      final flutterBin = resolveFlutterExecutable();
      final validRaw = File(oracleFixturesRelativePath).readAsStringSync();
      final validData = jsonDecode(validRaw) as Map<String, dynamic>;
      validData['version'] = '999.0.0';

      final tempDir = Directory.systemTemp.createTempSync('mode08_flutter_ver_test_');
      final tempFile = File('${tempDir.path}/bad_ver.json');
      Process? testProc;
      try {
        tempFile.writeAsStringSync(jsonEncode(validData));

        testProc = await Process.start(
          flutterBin,
          [
            'test',
            '--dart-define=MODE08_ORACLE_REQUIRED=true',
            '--dart-define=MODE08_ORACLE_PORT=${server.port}',
            '--dart-define=MODE08_FIXTURES_PATH=${tempFile.path}',
            'test/diagnostics/service_recipes/mode08_replay_oracle_test.dart',
          ],
        );
        final outLines = <String>[];
        final errLines = <String>[];
        testProc.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(outLines.add);
        testProc.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(errLines.add);

        final exitCode = await testProc.exitCode.timeout(
          const Duration(seconds: 45),
          onTimeout: () {
            testProc?.kill();
            throw TimeoutException('Timed out waiting for Flutter unsupported version negative control test');
          },
        );
        final allOutput = '${outLines.join("\n")}\n${errLines.join("\n")}';
        expect(
          exitCode,
          isNot(0),
          reason: 'Flutter test in required-mode must exit non-zero when fixture version is unsupported. Output: $allOutput',
        );
        expect(
          allOutput,
          contains('fixtures version 999.0.0 is unsupported'),
          reason: 'Flutter test must fail specifically on unsupported fixture version. Output: $allOutput',
        );
      } finally {
        testProc?.kill();
        server.process.kill();
        tempDir.deleteSync(recursive: true);
      }
    });

    test('subprocess negative control: Flutter test in required-mode exits non-zero when server is unstarted', () async {
      const deadPort = 35499;
      final flutterBin = resolveFlutterExecutable();
      Process? testProc;
      try {
        testProc = await Process.start(
          flutterBin,
          [
            'test',
            '--dart-define=MODE08_ORACLE_REQUIRED=true',
            '--dart-define=MODE08_ORACLE_PORT=$deadPort',
            'test/diagnostics/service_recipes/mode08_replay_oracle_test.dart',
          ],
        );
        final outLines = <String>[];
        final errLines = <String>[];
        testProc.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(outLines.add);
        testProc.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(errLines.add);

        final exitCode = await testProc.exitCode.timeout(
          const Duration(seconds: 45),
          onTimeout: () {
            testProc?.kill();
            throw TimeoutException('Timed out waiting for Flutter unstarted server negative control test');
          },
        );
        final allOutput = '${outLines.join("\n")}\n${errLines.join("\n")}';
        expect(
          exitCode,
          isNot(0),
          reason: 'Flutter test in required-mode must exit non-zero when server is unstarted. Output: $allOutput',
        );
        expect(
          allOutput,
          contains('Mode 08 replay reference not running on 127.0.0.1:$deadPort'),
          reason: 'Flutter test must fail specifically because server is unstarted. Output: $allOutput',
        );
      } finally {
        testProc?.kill();
      }
    });

    test('subprocess negative control: Flutter test in required-mode exits non-zero when fixture file is missing', () async {
      final server = await startDedicatedReplayServer(fixturesPath: oracleFixturesRelativePath);
      final flutterBin = resolveFlutterExecutable();
      const nonExistentPath = 'tool/obd_test_rig/non_existent_fixture_9999.json';
      Process? testProc;
      try {
        testProc = await Process.start(
          flutterBin,
          [
            'test',
            '--dart-define=MODE08_ORACLE_REQUIRED=true',
            '--dart-define=MODE08_ORACLE_PORT=${server.port}',
            '--dart-define=MODE08_FIXTURES_PATH=$nonExistentPath',
            'test/diagnostics/service_recipes/mode08_replay_oracle_test.dart',
          ],
        );
        final outLines = <String>[];
        final errLines = <String>[];
        testProc.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(outLines.add);
        testProc.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(errLines.add);

        final exitCode = await testProc.exitCode.timeout(
          const Duration(seconds: 45),
          onTimeout: () {
            testProc?.kill();
            throw TimeoutException('Timed out waiting for Flutter missing fixture negative control test');
          },
        );
        final allOutput = '${outLines.join("\n")}\n${errLines.join("\n")}';
        expect(
          exitCode,
          isNot(0),
          reason: 'Flutter test in required-mode must exit non-zero when fixture file is missing. Output: $allOutput',
        );
        expect(
          allOutput,
          contains('fixtures file missing at $nonExistentPath'),
          reason: 'Flutter test must fail specifically because fixture file is missing. Output: $allOutput',
        );
      } finally {
        testProc?.kill();
        server.process.kill();
      }
    });
  });
}
