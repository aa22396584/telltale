/// Host leftover for #47: production export stages a local artifact that the
/// session codec can reopen. A capturing share boundary is preparation only —
/// not proof that an OS chooser completed or a recipient received the file.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/core/share/app_share_platform_bridge.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/telemetry.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/app_share_coordinator.dart';
import 'package:torque_obd/state/artifact_operation_gate.dart';
import 'package:torque_obd/state/pid_mutation_lock.dart';
import 'package:torque_obd/state/telemetry_recorder.dart';
import 'package:torque_obd/state/telemetry_runtime.dart';
import 'package:torque_obd/state/telemetry_sessions.dart';
import 'package:torque_obd/telemetry/session/telemetry_recorder.dart';
import 'package:torque_obd/telemetry/session/telemetry_session.dart';
import 'package:torque_obd/telemetry/session/telemetry_session_codec.dart';
import 'package:torque_obd/telemetry/session/telemetry_session_reader.dart';
import 'package:torque_obd/telemetry/session/telemetry_session_store.dart';
import 'package:torque_obd/ui/screens/telemetry/telemetry_export_sheet.dart';

import 'support/localized_app.dart';

Map<String, Object?> _objectMap(Object? raw) {
  if (raw is Map<String, Object?>) return Map<String, Object?>.from(raw);
  if (raw is Map<String, dynamic>) {
    return <String, Object?>{
      for (final entry in raw.entries) entry.key: entry.value,
    };
  }
  fail('expected JSON object, got ${raw.runtimeType}');
}

void _reopenJson({
  required List<int> bytes,
  required String sessionId,
  required TelemetrySessionHeader nativeHeader,
  required TelemetrySessionFooter nativeFooter,
  required double expectedRpm,
}) {
  final map = _objectMap(jsonDecode(utf8.decode(bytes)));
  final headerResult = TelemetrySessionCodec.decodeHeaderObject(
    _objectMap(map['header']),
  );
  expect(headerResult.error, isNull, reason: '${headerResult.error}');
  final header = headerResult.value!;
  expect(header.sessionId, sessionId);
  expect(header.source, TelemetrySource.demo);
  expect(header.transport, TransportKind.demo);
  expect(
    header.signals.map((signal) => signal.fingerprint).toSet(),
    nativeHeader.signals.map((signal) => signal.fingerprint).toSet(),
  );
  for (final signal in header.signals) {
    expect(
      FrozenPidDefinition.freeze(signal.definition).fingerprint,
      signal.fingerprint,
    );
  }

  final events = map['events'] as List<dynamic>;
  expect(events, isNotEmpty);
  var previousElapsedUs = -1;
  var sawRpm = false;
  var valueCount = 0;
  var statusCount = 0;
  for (final raw in events) {
    final eventResult = TelemetrySessionCodec.decodeEventObject(
      _objectMap(raw),
      header,
      previousElapsedUs,
    );
    expect(eventResult.error, isNull, reason: '${eventResult.error}');
    final event = eventResult.value!;
    previousElapsedUs = event.elapsedUs;
    if (event.kind == TelemetryEventKind.value) {
      valueCount++;
      if (event.pidId == PidLibrary.engineRpm.id &&
          event.value == expectedRpm) {
        sawRpm = true;
      }
    } else if (event.kind == TelemetryEventKind.status) {
      statusCount++;
    }
  }
  expect(sawRpm, isTrue);
  expect(valueCount, nativeFooter.valueCount);
  expect(statusCount, nativeFooter.statusCount);

  final footerMap = _objectMap(map['footer']);
  final footerResult = TelemetrySessionCodec.decodeFooterObject(
    footerMap,
    nativeFooter.valueCount,
    nativeFooter.statusCount,
    nativeFooter.gapCount,
    nativeFooter.bytesBeforeFooter,
  );
  expect(footerResult.error, isNull, reason: '${footerResult.error}');
  expect(footerResult.value!.valueCount, nativeFooter.valueCount);
  expect(footerResult.value!.statusCount, nativeFooter.statusCount);
  expect(footerResult.value!.gapCount, nativeFooter.gapCount);
  expect(footerResult.value!.bytesBeforeFooter, nativeFooter.bytesBeforeFooter);
  expect(map['privacyExclusions'], contains('VIN'));
}

void main() {
  test(
    'Demo record → JSON/CSV export reopens through the production codec',
    () async {
      final documents = await Directory.systemTemp.createTemp(
        'export-reopen-docs-',
      );
      final shareRoot = await Directory.systemTemp.createTemp(
        'export-reopen-share-',
      );
      addTearDown(() => documents.delete(recursive: true));
      addTearDown(() => shareRoot.delete(recursive: true));

      const sessionId = '00000000000000000000000000000047';
      var now = DateTime.utc(2026, 9, 1, 2);
      var elapsedUs = 1000000;
      final store = TelemetrySessionStore(
        documentsDirectory: () async => documents,
        idSource: () => sessionId,
        nowUtc: () => now,
      );
      final environment = LiveTelemetryStartEnvironment(
        readConnection: () => const TelemetryConnectionSnapshot(
          connected: true,
          foreground: true,
          connectionGeneration: 1,
          foregroundEpoch: 1,
        ),
        utcNow: () => now,
        elapsedUs: () => elapsedUs,
      )..observeTelemetry(_snapshot(now, speed: 0, rpm: 900));
      final recorder = RootTelemetryRecorder(
        environment: environment,
        storage: FileTelemetryRecorderStorage(store),
        startCommandMutex: StartCommandMutex(),
        artifactGate: ArtifactOperationGate(),
        pidMutationLock: PidMutationLock(),
        utcNow: () => now,
        elapsedUs: () => elapsedUs,
      );

      final started = await recorder.start(
        TelemetryStartRequest(
          source: TelemetrySource.demo,
          transport: TransportKind.demo,
          protocol: 'Demo',
          activePids: [PidLibrary.vehicleSpeed, PidLibrary.engineRpm],
        ),
      );
      expect(started.outcome, TelemetryStartOutcome.recording);
      now = now.add(const Duration(milliseconds: 120));
      elapsedUs += 120000;
      recorder.onTelemetry(_snapshot(now, speed: 0, rpm: 1726));
      now = now.add(const Duration(milliseconds: 120));
      elapsedUs += 120000;
      recorder.onTelemetry(_snapshot(now, speed: 28, rpm: 2400));
      recorder.stop();
      await recorder.drainFinalization();
      expect(recorder.progress.state.phase, TelemetryRecorderPhase.completed);
      expect(recorder.progress.sessionId, sessionId);

      final native = File(
        '${documents.path}/telltale-telemetry/$sessionId.ndjson',
      );
      expect(native.existsSync(), isTrue);
      final originalBytes = native.readAsBytesSync();
      final nativeRead = await const TelemetrySessionReader().read(
        FileTelemetryChunkSource(native),
      );
      expect(nativeRead.isValid, isTrue);
      expect(nativeRead.sessionHeader!.sessionId, sessionId);
      expect(nativeRead.sessionHeader!.source, TelemetrySource.demo);
      expect(nativeRead.valueCount, greaterThan(0));

      final platform = _CapturingPlatform();
      final policy = _PermittingPolicy();
      final artifactGate = ArtifactOperationGate();
      var shareId = 0;
      final coordinator = AppShareCoordinator(
        rootDirectory: () async => shareRoot,
        policy: policy,
        artifactGate: artifactGate,
        platform: platform,
        idSource: () => (++shareId).toRadixString(16).padLeft(32, '0'),
        nowUtc: () => now,
        availableBytes: (_) async => 64 * 1024 * 1024,
      );
      expect(
        await coordinator.initialize(),
        AppShareInitializationOutcome.ready,
      );
      final actions = TelemetrySessionActions(
        documentsDirectory: () async => documents,
        store: store,
        shareCoordinator: coordinator,
        artifactGate: artifactGate,
        sharePolicy: policy,
        readRecorderPhase: () => recorder.progress.state.phase,
      );

      expect(
        (await actions.export(sessionId, TelemetryExportFormat.json)).isSuccess,
        isTrue,
      );
      expect(
        (await actions.export(sessionId, TelemetryExportFormat.csv)).isSuccess,
        isTrue,
      );
      expect(platform.subjects, isNotEmpty);
      expect(native.readAsBytesSync(), originalBytes);

      _reopenJson(
        bytes: platform.byExtension['json']!,
        sessionId: sessionId,
        nativeHeader: nativeRead.sessionHeader!,
        nativeFooter: nativeRead.sessionFooter!,
        expectedRpm: 1726,
      );

      final csv = utf8.decode(platform.byExtension['csv']!);
      expect(csv, contains('# source=demo'));
      expect(csv, contains('# transport=demo'));
      expect(csv, contains('# value_count=${nativeRead.valueCount}'));
      for (final signal in nativeRead.sessionHeader!.signals) {
        expect(csv, contains(signal.fingerprint));
        expect(csv, contains(signal.definition.id));
      }
      expect(csv, contains('1726'));
    },
  );

  testWidgets('dismissing the export sheet does not select a format', (
    tester,
  ) async {
    TelemetryExportFormat? selected = TelemetryExportFormat.csv;
    await tester.pumpWidget(
      localizedMaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              selected = await showTelemetryExportSheet(context);
            },
            child: const Text('open-export'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open-export'));
    await tester.pumpAndSettle();
    expect(find.byType(TelemetryExportSheet), findsOneWidget);
    Navigator.of(tester.element(find.byType(TelemetryExportSheet))).pop();
    await tester.pumpAndSettle();
    expect(selected, isNull);
  });

  testWidgets('JSON format selection returns json', (tester) async {
    TelemetryExportFormat? selected;
    await tester.pumpWidget(
      localizedMaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              selected = await showTelemetryExportSheet(context);
            },
            child: const Text('open-export'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open-export'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('匯出 JSON'));
    await tester.pumpAndSettle();
    expect(selected, TelemetryExportFormat.json);
  });
}

TelemetrySnapshot _snapshot(
  DateTime at, {
  required double speed,
  required double rpm,
}) => TelemetrySnapshot(
  readings: {
    PidLibrary.vehicleSpeed.id: Reading(
      pid: PidLibrary.vehicleSpeed,
      value: speed,
      rawBytes: [speed.round()],
      timestamp: at,
    ),
    PidLibrary.engineRpm.id: Reading(
      pid: PidLibrary.engineRpm,
      value: rpm,
      rawBytes: const [0x1a, 0xf8],
      timestamp: at,
    ),
  },
  capturedAt: at,
);

final class _CapturingPlatform implements AppSharePlatform {
  final Map<String, List<int>> byExtension = {};
  final List<String> subjects = [];

  @override
  Future<AppShareResult> share(AppSharePlatformRequest request) async {
    subjects.add(request.subject);
    byExtension[request.fileName.split('.').last] = await File(request.path)
        .readAsBytes();
    return AppShareResult.selected;
  }
}

final class _PermittingPolicy implements AppSharePolicy {
  @override
  SharePreparationPermit? freeze() => const SharePreparationPermit(
    recorderEpoch: 1,
    foregroundEpoch: 1,
    connectionEpoch: 1,
    safetyEpoch: 1,
    connectionClass: ShareConnectionClass.disconnected,
  );

  @override
  SharePermitValidation validate(SharePreparationPermit permit) =>
      const SharePermitValidation.valid();
}
