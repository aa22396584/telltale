/// Mode 08 Replay Oracle & Acceptance Gate 1.
///
/// Validates Mode 08 capability discovery against the independent Python replay reference
/// (tool/obd_test_rig/mode08_replay_reference.py) across all 6 acceptance matrix dimensions:
/// 1. Normal control (headered single-block & multi-block)
/// 2. Parser entry consistency (raw fallback preserves transaction error & uncertainty)
/// 3. Transport chunking (stream fragmentation does not alter decoded outcome)
/// 4. Source attribution (multi-node isolation & unheadered multi-block warning)
/// 5. Deficient evidence (missing declared node / conditionsNotCorrect NRC 0x22)
/// 6. Lifecycle (in-flight disconnection yields partial result with clean UI cleanup)
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/service_recipes/mode08_codec.dart';
import 'package:torque_obd/diagnostics/service_recipes/mode08_discovery_service.dart';
import 'package:torque_obd/diagnostics/service_recipes/qualification_tier.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/obd/transport/wifi_transport.dart';
import 'package:torque_obd/obd/vehicle_catalog/catalog_digest.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/service_recipes_provider.dart';

const oracleHost = '127.0.0.1';
const oracleDefaultPort = 35008;
const oracleIdentity = 'Telltale Mode 08 Replay Reference';
const oracleFixturesRelativePath = 'tool/obd_test_rig/mode08_replay_fixtures.json';
const oracleFixturesAltPath = '../../../tool/obd_test_rig/mode08_replay_fixtures.json';

const _port = int.fromEnvironment(
  'MODE08_ORACLE_PORT',
  defaultValue: oracleDefaultPort,
);
const _customFixturesPath = String.fromEnvironment('MODE08_FIXTURES_PATH');
const _oracleRequired = bool.fromEnvironment('MODE08_ORACLE_REQUIRED');

/// Verifies preflight availability of the Mode 08 replay reference.
Future<bool> verifyOraclePreflight({
  required String host,
  required int port,
  required bool requiredMode,
  required String identity,
}) async {
  Socket? socket;
  try {
    socket = await Socket.connect(host, port, timeout: const Duration(seconds: 2));
    final replies = StringBuffer();
    socket.listen(
      (bytes) => replies.write(String.fromCharCodes(bytes)),
      onError: (_) {},
    );
    socket.write('ATZ\r');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    replies.clear();
    socket.write('AT@1\r');
    for (var i = 0; i < 30; i++) {
      if (replies.toString().contains('>')) break;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    final isIdentified = replies.toString().contains(identity);
    if (!isIdentified && requiredMode) {
      fail('MODE08_ORACLE_REQUIRED was set, but host $host:$port answered without expected identity $identity');
    }
    return isIdentified;
  } on Object catch (e) {
    if (requiredMode) {
      fail('MODE08_ORACLE_REQUIRED was set, but Mode 08 replay reference not running on $host:$port: $e');
    }
    return false;
  } finally {
    socket?.destroy();
  }
}

const supportedFixtureVersions = {'1.0.0'};

/// Loads and validates the replay fixtures file against strict schema.
({File file, Map<String, dynamic> data, String sha256, List<dynamic> scenarios}) loadReplayFixtures(
  String relativePath, {
  required bool requiredMode,
  String? altPath,
}) {
  var fixtureFile = File(relativePath);
  if (!fixtureFile.existsSync() && altPath != null) {
    final alt = File(altPath);
    if (alt.existsSync()) {
      fixtureFile = alt;
    }
  }

  if (!fixtureFile.existsSync()) {
    if (requiredMode) {
      fail('MODE08_ORACLE_REQUIRED was set, but fixtures file missing at $relativePath');
    }
    throw FileSystemException('Fixtures file not found at $relativePath', relativePath);
  }

  final bytes = fixtureFile.readAsBytesSync();
  final hash = sha256Hex(bytes);
  final Object? decoded;
  try {
    decoded = jsonDecode(utf8.decode(bytes));
  } catch (e) {
    if (requiredMode) fail('MODE08_ORACLE_REQUIRED was set, but fixtures JSON malformed: $e');
    throw FormatException('Invalid JSON in fixtures file: $e');
  }

  if (decoded is! Map<String, dynamic>) {
    if (requiredMode) fail('MODE08_ORACLE_REQUIRED was set, but fixtures root is not an object');
    throw const FormatException('Fixtures root must be a JSON object');
  }

  final data = decoded;
  final version = data['version'] as String?;
  if (!supportedFixtureVersions.contains(version)) {
    if (requiredMode) {
      fail('MODE08_ORACLE_REQUIRED was set, but fixtures version $version is unsupported. Supported: $supportedFixtureVersions');
    }
    throw FormatException('Unsupported fixture version: $version');
  }

  for (final reqField in ['version', 'name', 'provenance', 'description', 'scenarios']) {
    if (!data.containsKey(reqField)) {
      if (requiredMode) fail('MODE08_ORACLE_REQUIRED was set, but fixtures missing field: $reqField');
      throw FormatException('Missing required top-level fixture field: $reqField');
    }
  }

  final rawScenarios = data['scenarios'];
  if (rawScenarios is! List<dynamic> || rawScenarios.isEmpty) {
    if (requiredMode) fail('MODE08_ORACLE_REQUIRED was set, but scenarios list is empty or not a list');
    throw const FormatException('Scenarios must be a non-empty list');
  }

  final seenIds = <String>{};
  for (var i = 0; i < rawScenarios.length; i++) {
    final s = rawScenarios[i];
    if (s is! Map<String, dynamic>) {
      if (requiredMode) fail('Scenario at index $i is not an object');
      throw FormatException('Scenario at index $i must be an object');
    }
    final id = s['id'] as String?;
    if (id == null || id.isEmpty) {
      if (requiredMode) fail('Scenario at index $i missing valid id');
      throw FormatException('Scenario at index $i missing id');
    }
    if (!seenIds.add(id)) {
      if (requiredMode) fail('Duplicate scenario ID found in fixtures: $id');
      throw FormatException('Duplicate scenario ID: $id');
    }
    for (final req in ['id', 'dimension', 'description', 'steps', 'expected_outcome']) {
      if (!s.containsKey(req)) {
        if (requiredMode) fail('Scenario $id missing required field: $req');
        throw FormatException('Scenario $id missing field: $req');
      }
    }
    final steps = s['steps'];
    if (steps is! List<dynamic> || steps.isEmpty) {
      if (requiredMode) fail('Scenario $id steps must be a non-empty list');
      throw FormatException('Scenario $id steps must be non-empty list');
    }
    for (var j = 0; j < steps.length; j++) {
      final step = steps[j];
      if (step is! Map<String, dynamic>) {
        if (requiredMode) fail('Scenario $id step $j is not an object');
        throw FormatException('Scenario $id step $j must be an object');
      }
      if (!step.containsKey('command')) {
        if (requiredMode) fail('Scenario $id step $j missing command');
        throw FormatException('Scenario $id step $j missing command');
      }
      if (step['drop_connection'] != true && !step.containsKey('lines')) {
        if (requiredMode) fail('Scenario $id step $j must have lines or drop_connection');
        throw FormatException('Scenario $id step $j must have lines or drop_connection');
      }
      final chunkSizes = step['chunk_sizes'];
      if (chunkSizes != null) {
        if (chunkSizes is! List<dynamic> || chunkSizes.isEmpty) {
          if (requiredMode) fail('Scenario $id step $j chunk_sizes must be non-empty list');
          throw FormatException('Scenario $id step $j chunk_sizes must be non-empty list');
        }
        for (final c in chunkSizes) {
          if (c is! int || c <= 0) {
            if (requiredMode) fail('Scenario $id step $j invalid chunk_size: $c');
            throw FormatException('Scenario $id step $j invalid chunk_size: $c');
          }
        }
      }
    }
    final expected = s['expected_outcome'];
    if (expected is! Map<String, dynamic>) {
      if (requiredMode) fail('Scenario $id expected_outcome must be an object');
      throw FormatException('Scenario $id expected_outcome must be an object');
    }
    for (final expKey in [
      'isSupported',
      'supportStatus',
      'supportedTids',
      'isComplete',
      'unqueriedBlocks',
      'trustedEcus',
      'hasAnonymous',
      'perEcuBlockResults',
    ]) {
      if (!expected.containsKey(expKey)) {
        if (requiredMode) fail('Scenario $id expected_outcome missing field: $expKey');
        throw FormatException('Scenario $id expected_outcome missing field: $expKey');
      }
    }
    if (expected['perEcuBlockResults'] is! Map<String, dynamic>) {
      if (requiredMode) fail('Scenario $id perEcuBlockResults must be an object');
      throw FormatException('Scenario $id perEcuBlockResults must be an object');
    }
  }

  return (
    file: fixtureFile,
    data: data,
    sha256: hash,
    scenarios: rawScenarios,
  );
}

/// Verifies that server fixture SHA-256 hash matches local fixture hash.
void verifyFixtureHash({
  required String serverHash,
  required String localHash,
}) {
  if (serverHash != localHash) {
    fail('Fixture SHA-256 mismatch! Server: $serverHash, Local: $localHash');
  }
}

/// Normalizes a [Mode08ParseResult] into a deterministic, canonical representation
/// covering status, TIDs, block chaining, negative response codes, sources, and anonymous uncertainty.
Map<String, dynamic> normalizeMode08ParseResult(Mode08ParseResult result) {
  return {
    'supportStatus': result.supportStatus.name,
    'supportedTids': result is Mode08SupportSuccess
        ? (result.supportedTids.toList()..sort())
        : <int>[],
    'hasNextBlock': result is Mode08SupportSuccess ? result.hasNextBlock : false,
    'nrc': result is Mode08NegativeResponse ? result.nrc : null,
    'hasAnonymous': result.anonymousResponses.isNotEmpty,
    'anonymousCount': result.anonymousResponses.length,
    'ecuResults': {
      for (final entry in (result.ecuResults.entries.toList()..sort((a, b) => a.key.compareTo(b.key))))
        entry.key: {
          'supportStatus': entry.value.supportStatus.name,
          'supportedTids': entry.value is Mode08SupportSuccess
              ? ((entry.value as Mode08SupportSuccess).supportedTids.toList()..sort())
              : <int>[],
          'hasNextBlock': entry.value is Mode08SupportSuccess
              ? (entry.value as Mode08SupportSuccess).hasNextBlock
              : false,
          'nrc': entry.value is Mode08NegativeResponse
              ? (entry.value as Mode08NegativeResponse).nrc
              : null,
        }
    },
  };
}

/// Normalizes a [Mode08DiscoveryResult] into an exhaustive canonical projection.
Map<String, dynamic> normalizeOutcomeProjection(Mode08DiscoveryResult result) {
  return {
    'isSupported': result.isSupported,
    'supportStatus': result.supportStatus.name,
    'supportedTids': result.supportedTids.toList()..sort(),
    'isComplete': result.isComplete,
    'unqueriedBlocks': result.unqueriedBlocks.toList()..sort(),
    'trustedEcus': result.ecuResults.keys.toList()..sort(),
    'hasAnonymous': result.hasAnonymous,
    'perEcuBlockResults': {
      for (final ecu in (result.perEcuBlockResults.keys.toList()..sort()))
        ecu: {
          for (final block in (result.perEcuBlockResults[ecu]!.keys.toList()..sort()))
            block.toString(): {
              'supportStatus': result.perEcuBlockResults[ecu]![block]!.supportStatus.name,
              'supportedTids': result.perEcuBlockResults[ecu]![block]! is Mode08SupportSuccess
                  ? ((result.perEcuBlockResults[ecu]![block]! as Mode08SupportSuccess).supportedTids.toList()..sort())
                  : <int>[],
              if (result.perEcuBlockResults[ecu]![block]! is Mode08NegativeResponse)
                'nrc': (result.perEcuBlockResults[ecu]![block]! as Mode08NegativeResponse).nrc,
            }
        }
    },
  };
}

/// Verifies discovery result against independently stored expected outcome.
void verifyScenarioOutcome(
  Mode08DiscoveryResult result,
  Map<String, dynamic> expected, {
  required String scenarioId,
}) {
  expect(
    result.isSupported,
    equals(expected['isSupported']),
    reason: '[$scenarioId] isSupported mismatch',
  );

  final expectedSupportStatus = expected['supportStatus'] as String;
  expect(
    result.supportStatus.name,
    equals(expectedSupportStatus),
    reason: '[$scenarioId] supportStatus mismatch',
  );

  final expectedTids = Set<int>.from(expected['supportedTids'] as List<dynamic>);
  expect(
    result.supportedTids,
    equals(expectedTids),
    reason: '[$scenarioId] supportedTids mismatch',
  );

  expect(
    result.isComplete,
    equals(expected['isComplete']),
    reason: '[$scenarioId] isComplete mismatch',
  );

  final expectedUnqueried = List<int>.from(expected['unqueriedBlocks'] as List<dynamic>)..sort();
  final actualUnqueried = List<int>.from(result.unqueriedBlocks)..sort();
  expect(
    actualUnqueried,
    equals(expectedUnqueried),
    reason: '[$scenarioId] unqueriedBlocks exact match failed',
  );

  final failureReasonSubstring = expected['failureReasonContains'] as String?;
  if (failureReasonSubstring != null) {
    expect(
      result.failureReason,
      contains(failureReasonSubstring),
      reason: '[$scenarioId] failureReason must contain $failureReasonSubstring',
    );
  } else if (result.isComplete) {
    expect(
      result.failureReason,
      isNull,
      reason: '[$scenarioId] failureReason must be null when outcome isComplete',
    );
  } else {
    expect(
      result.failureReason,
      isNotNull,
      reason: '[$scenarioId] failureReason must be non-null when outcome is incomplete',
    );
  }

  final expectedTrustedEcus = Set<String>.from(expected['trustedEcus'] as List<dynamic>? ?? []);
  expect(
    result.ecuResults.keys.toSet(),
    equals(expectedTrustedEcus),
    reason: '[$scenarioId] trusted ECUs set exact match failed (expected: $expectedTrustedEcus, actual: ${result.ecuResults.keys.toSet()})',
  );

  final expectedHasAnonymous = expected['hasAnonymous'] as bool? ?? false;
  expect(
    result.hasAnonymous,
    equals(expectedHasAnonymous),
    reason: '[$scenarioId] hasAnonymous mismatch',
  );

  final expectedPerEcu = expected['perEcuBlockResults'] as Map<String, dynamic>;
  expect(
    result.perEcuBlockResults.keys.toSet(),
    equals(expectedPerEcu.keys.toSet()),
    reason: '[$scenarioId] perEcuBlockResults ECU keys mismatch',
  );
  for (final ecuId in expectedPerEcu.keys) {
    final expectedBlocks = expectedPerEcu[ecuId] as Map<String, dynamic>;
    final actualBlocks = result.perEcuBlockResults[ecuId] ?? {};
    final expectedBlockInts = expectedBlocks.keys.map(int.parse).toSet();
    expect(
      actualBlocks.keys.toSet(),
      equals(expectedBlockInts),
      reason: '[$scenarioId] ECU $ecuId block base TIDs mismatch',
    );
    for (final blockKey in expectedBlocks.keys) {
      final blockInt = int.parse(blockKey);
      final expBlock = expectedBlocks[blockKey] as Map<String, dynamic>;
      final actualBlock = actualBlocks[blockInt]!;

      expect(
        actualBlock.supportStatus.name,
        equals(expBlock['supportStatus']),
        reason: '[$scenarioId] ECU $ecuId block 0x${blockInt.toRadixString(16)} supportStatus mismatch',
      );

      if (expBlock.containsKey('supportedTids')) {
        final expTids = Set<int>.from(expBlock['supportedTids'] as List<dynamic>);
        final actualTids = actualBlock is Mode08SupportSuccess ? actualBlock.supportedTids : <int>{};
        expect(
          actualTids,
          equals(expTids),
          reason: '[$scenarioId] ECU $ecuId block 0x${blockInt.toRadixString(16)} supportedTids mismatch',
        );
      }

      final expNrc = expBlock['nrc'] as int?;
      final actualNrc = actualBlock is Mode08NegativeResponse ? actualBlock.nrc : null;
      expect(
        actualNrc,
        equals(expNrc),
        reason: '[$scenarioId] ECU $ecuId block 0x${blockInt.toRadixString(16)} NRC mismatch (expected: $expNrc, actual: $actualNrc)',
      );
    }
  }
}

/// Verifies parser entry consistency across structured frames, observed frames, and raw lines
/// using normalized full evidence projections.
void verifyParserEntryConsistency({
  required ObdResponse structuredResponse,
  required ObdResponse observedOnlyResponse,
  required ObdResponse rawOnlyResponse,
  required int expectedBaseTid,
}) {
  final structuredResult = Mode08DiscoveryCodec.parseObdResponse(
    structuredResponse,
    expectedBaseTid: expectedBaseTid,
  );
  final observedResult = Mode08DiscoveryCodec.parseObdResponse(
    observedOnlyResponse,
    expectedBaseTid: expectedBaseTid,
  );
  final rawResult = Mode08DiscoveryCodec.parseObdResponse(
    rawOnlyResponse,
    expectedBaseTid: expectedBaseTid,
  );

  final structuredNorm = normalizeMode08ParseResult(structuredResult);
  final observedNorm = normalizeMode08ParseResult(observedResult);
  final rawNorm = normalizeMode08ParseResult(rawResult);

  expect(
    observedNorm,
    equals(structuredNorm),
    reason: 'Observed-only entry must match structured entry evidence projection on 0x${expectedBaseTid.toRadixString(16)}',
  );
  expect(
    rawNorm,
    equals(structuredNorm),
    reason: 'Raw-only entry must match structured entry evidence projection on 0x${expectedBaseTid.toRadixString(16)}',
  );
}

/// Controllable transport decorator for observing wire events and establishing causal lifecycle barriers.
class WireBarrierWifiTransport implements ObdTransport {
  WireBarrierWifiTransport(this._inner);

  final WifiTransport _inner;
  final List<String> observedEvents = [];
  Completer<void>? wireCommandBarrier;
  String? targetCommand;
  Completer<void>? delayIncomingCompleter;
  bool isTargetCommandInFlight = false;

  @override
  TransportKind get kind => _inner.kind;

  @override
  String get displayName => _inner.displayName;

  @override
  Map<String, Object> get diagnosticMetadata => _inner.diagnosticMetadata;

  @override
  bool get isConnected => _inner.isConnected;

  @override
  Stream<bool> get connectionChanges => _inner.connectionChanges;

  @override
  Future<void> connect() => _inner.connect();

  @override
  Future<void> disconnect() {
    observedEvents.add('disconnect()');
    return _inner.disconnect();
  }

  @override
  Future<void> write(List<int> data) async {
    final text = String.fromCharCodes(data).trim();
    observedEvents.add('write: $text');
    if (targetCommand != null && text.contains(targetCommand!)) {
      isTargetCommandInFlight = true;
      if (wireCommandBarrier != null && !wireCommandBarrier!.isCompleted) {
        observedEvents.add('barrier_reached: $targetCommand');
        wireCommandBarrier!.complete();
      }
    }
    await _inner.write(data);
  }

  @override
  Stream<List<int>> get incoming => _inner.incoming.asyncMap((bytes) async {
    final text = String.fromCharCodes(bytes);
    observedEvents.add('incoming: $text');
    if (isTargetCommandInFlight && delayIncomingCompleter != null) {
      observedEvents.add('delaying incoming bytes for in-flight target');
      await delayIncomingCompleter!.future;
      observedEvents.add('released incoming bytes for in-flight target');
    }
    return bytes;
  });
}

Future<Elm327Client> _connectClient({
  String host = oracleHost,
  int port = _port,
  Duration timeout = const Duration(seconds: 2),
}) async {
  final transport = WifiTransport(host: host, port: port);
  final client = Elm327Client(transport, commandTimeout: timeout);
  final ok = await client.connect();
  if (!ok) {
    throw StateError('Failed to handshake with Mode 08 replay reference on $host:$port');
  }
  return client;
}

class _OracleSession extends ObdSession {
  _OracleSession(this._client, {this.generation = 1});
  Elm327Client? _client;

  @override
  int generation;

  @override
  Elm327Client? get client => _client;

  @override
  ObdConnectionState build() => _client != null
      ? const ObdConnectionState(
          phase: ConnectionPhase.connected,
          protocol: 'ISO 15765-4 (CAN 11/500)',
        )
      : const ObdConnectionState(
          phase: ConnectionPhase.disconnected,
          protocol: '',
        );

  void triggerDisconnect() {
    generation++;
    _client = null;
    state = const ObdConnectionState(
      phase: ConnectionPhase.disconnected,
      protocol: '',
    );
  }

  void triggerReconnect(Elm327Client newClient) {
    generation++;
    _client = newClient;
    state = const ObdConnectionState(
      phase: ConnectionPhase.connected,
      protocol: 'ISO 15765-4 (CAN 11/500)',
    );
  }
}

void main() {
  late bool available;
  ({File file, Map<String, dynamic> data, String sha256, List<dynamic> scenarios})? fixtureResult;

  setUpAll(() async {
    available = await verifyOraclePreflight(
      host: oracleHost,
      port: _port,
      requiredMode: _oracleRequired,
      identity: oracleIdentity,
    );

    try {
      final fixturesPath = _customFixturesPath.isNotEmpty ? _customFixturesPath : oracleFixturesRelativePath;
      fixtureResult = loadReplayFixtures(
        fixturesPath,
        requiredMode: _oracleRequired,
        altPath: _customFixturesPath.isNotEmpty ? null : oracleFixturesAltPath,
      );
    } catch (_) {
      if (_oracleRequired) rethrow;
    }
  });

  group('Mode 08 Replay Oracle Preflight & Provenance', () {
    test('fixtures file is explicitly labelled synthetic and contains valid SHA-256', () {
      if (fixtureResult == null) {
        if (_oracleRequired) fail('Missing fixtures file');
        markTestSkipped('Fixtures file not available');
        return;
      }
      expect(fixtureResult!.data['provenance'], equals('synthetic'));
      expect(fixtureResult!.sha256, hasLength(64));
      expect(fixtureResult!.scenarios, isNotEmpty);
    });

    test('replay server matches local fixture SHA-256 and project identity', () async {
      if (!available || fixtureResult == null) {
        if (_oracleRequired) fail('Replay server not available');
        markTestSkipped('Mode 08 replay reference or fixtures not running/available');
        return;
      }
      final client = await _connectClient();
      try {
        final atAt1 = await client.send('AT@1');
        expect(atAt1.rawLines.join(), contains(oracleIdentity));

        final atHash = await client.send('AT#HASH');
        final serverHash = atHash.rawLines.first.trim();
        verifyFixtureHash(
          serverHash: serverHash,
          localHash: fixtureResult!.sha256,
        );
      } finally {
        await client.disconnect();
      }
    });
  });

  group('Mode 08 Replay Oracle 6-Dimension Acceptance Matrix', () {
    test('executes all 6 matrix dimensions against independent expected outcomes', () async {
      if (!available || fixtureResult == null) {
        if (_oracleRequired) fail('Replay server or fixtures not available');
        markTestSkipped('Mode 08 replay reference or fixtures not running/available');
        return;
      }

      final coveredDimensions = <String>{};

      for (final rawScenario in fixtureResult!.scenarios) {
        final scenario = rawScenario as Map<String, dynamic>;
        final scenarioId = scenario['id'] as String;
        final dimension = scenario['dimension'] as String;
        final expected = scenario['expected_outcome'] as Map<String, dynamic>;
        coveredDimensions.add(dimension);

        final client = await _connectClient();
        try {
          final switchResp = await client.send('AT#SCENARIO $scenarioId');
          expect(switchResp.isSuccess, isTrue,
              reason: 'Server must accept scenario $scenarioId');

          final headersEnabled = scenario['headers'] as bool? ?? true;
          await client.send(headersEnabled ? 'ATH1' : 'ATH0');

          final result = await Mode08DiscoveryService.discoverSupportedTids(
            client: client,
            timeout: const Duration(milliseconds: 500),
            budget: const Duration(seconds: 3),
          );

          verifyScenarioOutcome(result, expected, scenarioId: scenarioId);
        } finally {
          await client.disconnect();
        }
      }

      expect(
        coveredDimensions,
        containsAll([
          'normal_control',
          'parser_entry_consistency',
          'transport_chunking',
          'source_attribution',
          'deficient_evidence',
          'lifecycle',
        ]),
        reason: 'All 6 acceptance matrix dimensions must be represented and verified',
      );
    });

    test('parser entry consistency: structured, observed, and raw-only entries preserve errors and uncertainties', () {
      // Direct parity cross-validation across all 3 ObdResponse parser entries:
      // Probe A: Raw lines fallback with peer NO DATA
      const structuredProbe = ObdResponse(
        errorCode: Elm327ErrorCode.noData,
        rawLines: ['7E8 03 7F 08 11', 'NO DATA'],
        frames: [
          ObdFrame([0x03, 0x7F, 0x08, 0x11], sourceId: '7E8', payload: [0x7F, 0x08, 0x11]),
        ],
        observedFrames: [],
        attributedSources: {'7E8'},
      );

      const observedProbe = ObdResponse(
        errorCode: Elm327ErrorCode.noData,
        rawLines: ['7E8 03 7F 08 11', 'NO DATA'],
        frames: [],
        observedFrames: [
          ObdFrame([0x03, 0x7F, 0x08, 0x11], sourceId: '7E8', payload: [0x7F, 0x08, 0x11]),
        ],
        attributedSources: {'7E8'},
      );

      const rawProbe = ObdResponse(
        errorCode: Elm327ErrorCode.noData,
        rawLines: ['7E8 03 7F 08 11', 'NO DATA'],
        frames: [],
        observedFrames: [],
        attributedSources: {'7E8'},
      );

      verifyParserEntryConsistency(
        structuredResponse: structuredProbe,
        observedOnlyResponse: observedProbe,
        rawOnlyResponse: rawProbe,
        expectedBaseTid: 0x00,
      );

      final r1 = Mode08DiscoveryCodec.parseObdResponse(structuredProbe, expectedBaseTid: 0x00);
      final r2 = Mode08DiscoveryCodec.parseObdResponse(observedProbe, expectedBaseTid: 0x00);
      final r3 = Mode08DiscoveryCodec.parseObdResponse(rawProbe, expectedBaseTid: 0x00);

      expect(r1.supportStatus, equals(EcuSupportStatus.unknown));
      expect(r2.supportStatus, equals(EcuSupportStatus.unknown));
      expect(r3.supportStatus, equals(EcuSupportStatus.unknown));
    });

    test('lifecycle: wire-bound flight barrier, session disconnect race, and stale completion rejection', () async {
      if (!available || fixtureResult == null) {
        if (_oracleRequired) fail('Replay server or fixtures not available');
        markTestSkipped('Mode 08 replay reference or fixtures not running/available');
        return;
      }

      final wifiTransportA = WifiTransport(host: oracleHost, port: _port);
      final barrierTransportA = WireBarrierWifiTransport(wifiTransportA);
      final clientA = Elm327Client(barrierTransportA, commandTimeout: const Duration(seconds: 2));
      final connectedA = await clientA.connect();
      expect(connectedA, isTrue, reason: 'Client A must connect to replay reference');

      Elm327Client? clientB;
      final barrierA = Completer<void>();
      final delayA = Completer<void>();

      try {
        final switchRespA = await clientA.send('AT#SCENARIO normal_headered_multi_block');
        expect(switchRespA.isSuccess, isTrue);
        await clientA.send('ATH1');

        final session = _OracleSession(clientA, generation: 1);
        final container = ProviderContainer(
          overrides: [
            obdSessionProvider.overrideWith(() => session),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(mode08DiscoveryStateProvider.notifier);
        expect(container.read(mode08DiscoveryStateProvider).isIdle, isTrue);

        barrierTransportA.targetCommand = '0800';
        barrierTransportA.wireCommandBarrier = barrierA;
        barrierTransportA.delayIncomingCompleter = delayA;

        // Run discovery which will write 0800 on wire then be held by delayA
        final discoveryFutureA = notifier.runDiscovery(
          timeout: const Duration(seconds: 1),
          budget: const Duration(seconds: 4),
        );

        try {
          await barrierA.future.timeout(const Duration(seconds: 2));
        } catch (e) {
          fail('Flight A did not reach wire within budget: flight=0800, session=${session.generation}, events: ${barrierTransportA.observedEvents}');
        }

        expect(container.read(mode08DiscoveryStateProvider).isDiscovering, isTrue,
            reason: 'Task A must be in discovering state while in-flight on wire');

        // Session disconnect in-flight while A is held
        session.triggerDisconnect();
        expect(container.read(mode08DiscoveryStateProvider).isIdle, isTrue,
            reason: 'Disconnected session must reset to idle immediately');

        // Client B connects and establishes new session generation
        final wifiTransportB = WifiTransport(host: oracleHost, port: _port);
        clientB = Elm327Client(wifiTransportB, commandTimeout: const Duration(seconds: 2));
        final connectedB = await clientB.connect();
        expect(connectedB, isTrue, reason: 'Client B must connect to replay reference');

        final switchRespB = await clientB.send('AT#SCENARIO normal_headered_single_block');
        expect(switchRespB.isSuccess, isTrue);
        await clientB.send('ATH1');

        session.triggerReconnect(clientB);
        expect(session.generation, equals(3));
        expect(session.client, isNotNull);

        // Discovery on Session B runs to completion
        await notifier.runDiscovery(
          timeout: const Duration(seconds: 1),
          budget: const Duration(seconds: 3),
        );

        final stateB = container.read(mode08DiscoveryStateProvider);
        expect(stateB.isCompleted, isTrue, reason: 'Session B discovery must complete successfully');
        expect(stateB.result!.supportedTids, equals({1}),
            reason: 'Session B result must reflect single block TID {1}');

        // Now release late-arriving completion of superseded task A
        delayA.complete();
        await discoveryFutureA;

        final stateAfterLateA = container.read(mode08DiscoveryStateProvider);
        expect(stateAfterLateA.isCompleted, isTrue);
        expect(stateAfterLateA.result!.supportedTids, equals({1}),
            reason: 'Late completion of superseded task A must not overwrite session B result');

        // Resetting notifier restores idle
        notifier.reset();
        expect(container.read(mode08DiscoveryStateProvider).isIdle, isTrue);

        // Reset while in-flight test:
        final barrierReset = Completer<void>();
        final delayReset = Completer<void>();
        barrierTransportA.isTargetCommandInFlight = false;
        barrierTransportA.targetCommand = '0800';
        barrierTransportA.wireCommandBarrier = barrierReset;
        barrierTransportA.delayIncomingCompleter = delayReset;

        session.triggerReconnect(clientA);
        final futureReset = notifier.runDiscovery(
          timeout: const Duration(seconds: 1),
          budget: const Duration(seconds: 3),
        );
        try {
          await barrierReset.future.timeout(const Duration(seconds: 2));
        } catch (e) {
          fail('Reset probe did not reach wire: ${barrierTransportA.observedEvents}');
        }
        expect(container.read(mode08DiscoveryStateProvider).isDiscovering, isTrue);

        notifier.reset();
        expect(container.read(mode08DiscoveryStateProvider).isIdle, isTrue,
            reason: 'Calling reset() while in-flight must immediately restore idle');

        delayReset.complete();
        await futureReset;
        expect(container.read(mode08DiscoveryStateProvider).isIdle, isTrue,
            reason: 'Aborted in-flight query completing after reset must remain idle');
      } finally {
        if (!delayA.isCompleted) delayA.complete();
        await clientA.disconnect();
        if (clientB != null) await clientB.disconnect();
      }
    });

    test('lifecycle: container disposal while query is in-flight cleans up safely', () async {
      if (!available || fixtureResult == null) {
        if (_oracleRequired) fail('Replay server or fixtures not available');
        markTestSkipped('Mode 08 replay reference or fixtures not running/available');
        return;
      }

      final wifiTransport = WifiTransport(host: oracleHost, port: _port);
      final barrierTransport = WireBarrierWifiTransport(wifiTransport);
      final client = Elm327Client(barrierTransport, commandTimeout: const Duration(seconds: 2));
      final connected = await client.connect();
      expect(connected, isTrue);

      final barrier = Completer<void>();
      final delay = Completer<void>();
      final session = _OracleSession(client);
      final container = ProviderContainer(
        overrides: [obdSessionProvider.overrideWith(() => session)],
      );

      try {
        final resp = await client.send('AT#SCENARIO normal_headered_multi_block');
        expect(resp.isSuccess, isTrue);
        await client.send('ATH1');

        barrierTransport.targetCommand = '0800';
        barrierTransport.wireCommandBarrier = barrier;
        barrierTransport.delayIncomingCompleter = delay;

        final future = container.read(mode08DiscoveryStateProvider.notifier).runDiscovery(
          timeout: const Duration(seconds: 1),
          budget: const Duration(seconds: 3),
        );

        try {
          await barrier.future.timeout(const Duration(seconds: 2));
        } catch (e) {
          fail('Dispose probe did not reach wire: ${barrierTransport.observedEvents}');
        }

        // Dispose container while 0800 is held in flight
        container.dispose();

        // Release delayed wire response
        delay.complete();
        await future;
      } finally {
        if (!delay.isCompleted) delay.complete();
        await client.disconnect();
      }
    });
  });
}
