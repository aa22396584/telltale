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

import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/service_recipes/mode08_codec.dart';
import 'package:torque_obd/diagnostics/service_recipes/mode08_discovery_service.dart';
import 'package:torque_obd/diagnostics/service_recipes/qualification_tier.dart';
import 'package:torque_obd/obd/elm327_client.dart';
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

/// Loads and validates the replay fixtures file.
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
  final data = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  final scenarios = data['scenarios'] as List<dynamic>;

  return (
    file: fixtureFile,
    data: data,
    sha256: hash,
    scenarios: scenarios,
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

  final expectedUnqueried = List<int>.from(expected['unqueriedBlocks'] as List<dynamic>);
  expect(
    result.unqueriedBlocks,
    containsAll(expectedUnqueried),
    reason: '[$scenarioId] unqueriedBlocks mismatch',
  );

  final failureReasonSubstring = expected['failureReasonContains'] as String?;
  if (failureReasonSubstring != null) {
    expect(
      result.failureReason,
      contains(failureReasonSubstring),
      reason: '[$scenarioId] failureReason must contain $failureReasonSubstring',
    );
  }

  final trustedEcus = List<String>.from(expected['trustedEcus'] as List<dynamic>? ?? []);
  for (final ecu in trustedEcus) {
    expect(
      result.ecuResults.containsKey(ecu),
      isTrue,
      reason: '[$scenarioId] expected trusted ECU $ecu in results',
    );
  }
}

/// Verifies parser entry consistency across structured frames, observed frames, and raw lines.
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

  expect(
    observedResult.supportStatus,
    equals(structuredResult.supportStatus),
    reason: 'Observed-only entry must match structured entry support status on 0x${expectedBaseTid.toRadixString(16)}',
  );
  expect(
    rawResult.supportStatus,
    equals(structuredResult.supportStatus),
    reason: 'Raw-only entry must match structured entry support status on 0x${expectedBaseTid.toRadixString(16)}',
  );
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
  _OracleSession(this._client);
  final Elm327Client _client;

  @override
  Elm327Client? get client => _client;

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
      fixtureResult = loadReplayFixtures(
        oracleFixturesRelativePath,
        requiredMode: _oracleRequired,
        altPath: oracleFixturesAltPath,
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

    test('lifecycle: Mode08DiscoveryNotifier handles in-flight disconnect and prevents stale completion', () async {
      if (!available || fixtureResult == null) {
        if (_oracleRequired) fail('Replay server or fixtures not available');
        markTestSkipped('Mode 08 replay reference or fixtures not running/available');
        return;
      }

      final client = await _connectClient();
      try {
        final switchResp = await client.send('AT#SCENARIO lifecycle_disconnect_in_flight');
        expect(switchResp.isSuccess, isTrue);

        final session = _OracleSession(client);
        final container = ProviderContainer(
          overrides: [
            obdSessionProvider.overrideWith(() => session),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(mode08DiscoveryStateProvider.notifier);
        expect(container.read(mode08DiscoveryStateProvider).isIdle, isTrue);

        // Run discovery which drops during 0820
        final discoveryFuture = notifier.runDiscovery(
          timeout: const Duration(milliseconds: 500),
          budget: const Duration(seconds: 3),
        );

        // Session disconnect in-flight
        session.triggerDisconnect();
        await discoveryFuture;

        final state = container.read(mode08DiscoveryStateProvider);
        expect(state.isIdle, isTrue,
            reason: 'Disconnected session must reset to idle and never backfill stale completed result');
        expect(state.isCompleted, isFalse);

        // Resetting notifier while idle preserves idle
        notifier.reset();
        expect(container.read(mode08DiscoveryStateProvider).isIdle, isTrue);
      } finally {
        await client.disconnect();
      }
    });
  });
}
