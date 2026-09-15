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

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/service_recipes/mode08_discovery_service.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/transport/wifi_transport.dart';
import 'package:torque_obd/obd/vehicle_catalog/catalog_digest.dart';

const _host = '127.0.0.1';
const _port = int.fromEnvironment(
  'MODE08_ORACLE_PORT',
  defaultValue: 35008,
);
const _oracleRequired = bool.fromEnvironment('MODE08_ORACLE_REQUIRED');
const _identity = 'Telltale Mode 08 Replay Reference';

const _fixturesRelativePath = 'tool/obd_test_rig/mode08_replay_fixtures.json';

Future<bool> _oracleIsMode08ReplayReference() async {
  Socket? socket;
  try {
    socket = await Socket.connect(_host, _port, timeout: const Duration(seconds: 2));
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
    return replies.toString().contains(_identity);
  } on Object {
    return false;
  } finally {
    socket?.destroy();
  }
}

Future<Elm327Client> _connectClient({Duration timeout = const Duration(seconds: 2)}) async {
  final transport = WifiTransport(host: _host, port: _port);
  final client = Elm327Client(transport, commandTimeout: timeout);
  final ok = await client.connect();
  if (!ok) {
    throw StateError('Failed to handshake with Mode 08 replay reference on $_host:$_port');
  }
  return client;
}

void main() {
  late bool available;
  late File fixtureFile;
  late Map<String, dynamic> fixtureData;
  late List<dynamic> scenarios;
  late String localFixtureSha256;

  setUpAll(() async {
    available = await _oracleIsMode08ReplayReference();

    fixtureFile = File(_fixturesRelativePath);
    if (!fixtureFile.existsSync()) {
      // Try from test location
      final alt = File('../../../tool/obd_test_rig/mode08_replay_fixtures.json');
      if (alt.existsSync()) {
        fixtureFile = alt;
      }
    }

    if (!fixtureFile.existsSync()) {
      if (_oracleRequired) {
        fail('MODE08_ORACLE_REQUIRED was set, but fixtures file missing at $_fixturesRelativePath');
      }
      return;
    }

    final bytes = fixtureFile.readAsBytesSync();
    localFixtureSha256 = sha256Hex(bytes);
    fixtureData = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    scenarios = fixtureData['scenarios'] as List<dynamic>;

    if (!available) {
      const msg = 'Mode 08 replay reference not running on $_host:$_port. '
          'Start with: python3 tool/obd_test_rig/mode08_replay_reference.py --port $_port';
      if (_oracleRequired) {
        fail('MODE08_ORACLE_REQUIRED was set, but $msg');
      } else {
        // ignore: avoid_print
        print('SKIPPED: $msg');
      }
    }
  });

  group('Mode 08 Replay Oracle Preflight & Provenance', () {
    test('fixtures file is explicitly labelled synthetic and contains valid SHA-256', () {
      if (!fixtureFile.existsSync()) {
        if (_oracleRequired) fail('Missing fixtures file');
        return;
      }
      expect(fixtureData['provenance'], equals('synthetic'));
      expect(localFixtureSha256, hasLength(64));
      expect(scenarios, isNotEmpty);
    });

    test('replay server matches local fixture SHA-256 and project identity', () async {
      if (!available) {
        if (_oracleRequired) fail('Replay server not available');
        return;
      }
      final client = await _connectClient();
      try {
        final atAt1 = await client.send('AT@1');
        expect(atAt1.rawLines.join(), contains(_identity));

        final atHash = await client.send('AT#HASH');
        final serverHash = atHash.rawLines.first.trim();
        expect(serverHash, equals(localFixtureSha256),
            reason: 'Server fixture hash must match test fixture hash exactly');
      } finally {
        await client.disconnect();
      }
    });
  });

  group('Mode 08 Replay Oracle 6-Dimension Acceptance Matrix', () {
    test('executes all 6 matrix dimensions against independent expected outcomes', () async {
      if (!available || !fixtureFile.existsSync()) {
        if (_oracleRequired) fail('Replay server or fixtures not available');
        return;
      }

      final coveredDimensions = <String>{};

      for (final rawScenario in scenarios) {
        final scenario = rawScenario as Map<String, dynamic>;
        final scenarioId = scenario['id'] as String;
        final dimension = scenario['dimension'] as String;
        final expected = scenario['expected_outcome'] as Map<String, dynamic>;
        coveredDimensions.add(dimension);

        final client = await _connectClient();
        try {
          // Switch active scenario on replay server
          final switchResp = await client.send('AT#SCENARIO $scenarioId');
          expect(switchResp.isSuccess, isTrue,
              reason: 'Server must accept scenario $scenarioId');

          // Configure headers according to scenario specification
          final headersEnabled = scenario['headers'] as bool? ?? true;
          await client.send(headersEnabled ? 'ATH1' : 'ATH0');

          // Execute discovery
          final result = await Mode08DiscoveryService.discoverSupportedTids(
            client: client,
            timeout: const Duration(milliseconds: 500),
            budget: const Duration(seconds: 3),
          );

          // Verify against independently loaded expected outcome (NEVER computed from codec!)
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
        } finally {
          await client.disconnect();
        }
      }

      // Assert that all 6 required matrix dimensions were tested
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
  });
}
