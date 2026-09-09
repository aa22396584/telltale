/// #47 leftover: after Demo, record, open the exact session, then export
/// through format selection → production exporter/staging → captured local
/// artifact → decoder reopen.
///
/// Sheet titles stay asserted. The captured file is a rig-only preparation
/// sink ([RigAppSharePlatform]); it is not proof that an OS share chooser
/// completed or that a recipient received the file.
///
///     flutter test integration_test/localization_export_journey_test.dart -d <device-id> \
///       --flavor rig --dart-define=TELLTALE_TEST_RIG=true
///
/// Without `--flavor rig` and `TELLTALE_TEST_RIG=true` this fails closed
/// inside [requireIsolatedRigIdentity]. Missing hardware is a failure, not a
/// skip that looks like a pass.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:torque_obd/core/share/rig_app_share_platform.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/telemetry_recorder.dart';
import 'package:torque_obd/telemetry/session/telemetry_recorder.dart';
import 'package:torque_obd/telemetry/session/telemetry_session.dart';
import 'package:torque_obd/telemetry/session/telemetry_session_codec.dart';
import 'package:torque_obd/telemetry/session/telemetry_session_reader.dart';
import 'package:torque_obd/ui/screens/settings/settings_screen.dart';
import 'package:torque_obd/ui/screens/telemetry/telemetry_export_sheet.dart';
import 'package:torque_obd/ui/screens/telemetry/telemetry_session_detail_screen.dart';
import 'package:torque_obd/ui/screens/telemetry/telemetry_sessions_screen.dart';

import 'rig_support.dart';

Finder _navLabel(String text) {
  final navigation = find.byWidgetPredicate(
    (widget) => widget is NavigationBar || widget is NavigationRail,
    description: 'responsive app navigation',
  );
  return find.descendant(of: navigation, matching: find.text(text));
}

Future<void> _tapNav(WidgetTester tester, String text) async {
  final label = _navLabel(text);
  expect(label, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(label), alignment: 0.5);
  await tester.pump(const Duration(milliseconds: 50));
  final target = label.hitTestable();
  expect(target, findsOneWidget);
  await tester.tap(target);
  await tester.pump();
}

Future<void> _openHistory(WidgetTester tester) async {
  final history = find.byKey(const ValueKey('telemetry-history'));
  await tester.pump(const Duration(milliseconds: 300));
  if (history.evaluate().isEmpty || history.hitTestable().evaluate().isEmpty) {
    final dashboard = find.byType(CustomScrollView);
    expect(dashboard, findsWidgets);
    await tester.scrollUntilVisible(
      history,
      400,
      scrollable: find
          .descendant(of: dashboard.first, matching: find.byType(Scrollable))
          .first,
    );
  }
  expect(history, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(history), alignment: 0.5);
  await tester.pump(const Duration(milliseconds: 100));
  final visible = history.hitTestable();
  expect(visible, findsOneWidget);
  await tester.tap(visible);
  await tester.pump();
  expect(
    await pumpUntil(
      tester,
      () => find.byType(TelemetrySessionsScreen).evaluate().isNotEmpty,
    ),
    isTrue,
    reason: 'History route TelemetrySessionsScreen did not open',
  );
}

Future<void> _leaveExportToShell(WidgetTester tester) async {
  if (find.byType(TelemetryExportSheet).evaluate().isNotEmpty) {
    Navigator.of(tester.element(find.byType(TelemetryExportSheet))).pop();
    await tester.pump();
  }
  if (find.byType(TelemetrySessionDetailScreen).evaluate().isNotEmpty) {
    Navigator.of(tester.element(find.byType(TelemetrySessionDetailScreen)))
        .pop();
    await tester.pump();
  }
  if (find.byType(TelemetrySessionsScreen).evaluate().isNotEmpty) {
    Navigator.of(tester.element(find.byType(TelemetrySessionsScreen))).pop();
    await tester.pump();
  }
  expect(
    await pumpUntil(
      tester,
      () =>
          _navLabel('設定').hitTestable().evaluate().isNotEmpty ||
          _navLabel('Settings').hitTestable().evaluate().isNotEmpty,
    ),
    isTrue,
    reason: 'shell navigation did not become hit-testable after leaving Export',
  );
}

Future<String> _recordShortDemoSession(WidgetTester tester) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
    listen: false,
  );
  final session = container.read(obdSessionProvider.notifier);
  await session.disconnect();
  final reconnect = session.connectDemo();
  expect(
    await pumpUntil(
      tester,
      () =>
          container.read(obdSessionProvider).phase == ConnectionPhase.connected,
      timeout: const Duration(seconds: 30),
      step: const Duration(milliseconds: 25),
    ),
    isTrue,
    reason: 'fresh Demo session did not reconnect for the Start proof',
  );
  expect(await reconnect, isTrue);

  final start = find.byKey(const ValueKey('telemetry-start'));
  await Scrollable.ensureVisible(tester.element(start), alignment: 0.5);
  await tester.pump(const Duration(milliseconds: 50));
  expect(
    await pumpUntil(
      tester,
      () =>
          start.evaluate().isNotEmpty &&
          tester.widget<FilledButton>(start).onPressed != null,
      timeout: const Duration(seconds: 10),
      step: const Duration(milliseconds: 25),
    ),
    isTrue,
    reason: 'fresh Demo idle sample did not enable Start',
  );
  await tester.tap(start.hitTestable());
  await tester.pump();

  final controller = container.read(telemetryRecorderControllerProvider);
  expect(
    await pumpUntil(
      tester,
      () =>
          controller.state.phase == TelemetryRecorderPhase.recording &&
          controller.state.valueCount > 0,
      timeout: const Duration(seconds: 30),
    ),
    isTrue,
    reason: 'Demo telemetry recording never accepted its first value',
  );

  final stop = find.byKey(const ValueKey('telemetry-stop'));
  expect(stop, findsOneWidget);
  await tester.ensureVisible(stop);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(stop.hitTestable());
  await tester.pump();
  expect(
    await pumpUntil(
      tester,
      () => controller.state.phase == TelemetryRecorderPhase.completed,
      timeout: const Duration(seconds: 30),
    ),
    isTrue,
    reason: 'Demo telemetry recording did not finalize',
  );

  final sessionId = controller.progress.sessionId;
  expect(sessionId, isNotNull);
  expect(TelemetrySessionReader.isOpaqueId(sessionId!), isTrue);

  await session.disconnect();
  await tester.pump();
  return sessionId;
}

Future<File> _nativeSessionFile(String sessionId) async {
  final documents = await getApplicationDocumentsDirectory();
  return File('${documents.path}/telltale-telemetry/$sessionId.ndjson');
}

Future<TelemetryReadResult> _readNative(File native) async {
  final result = await const TelemetrySessionReader().read(
    FileTelemetryChunkSource(native),
  );
  expect(
    result.isValid,
    isTrue,
    reason: 'native session failed: ${result.failure}',
  );
  expect(result.sessionHeader, isNotNull);
  expect(result.sessionFooter, isNotNull);
  return result;
}

Future<void> _openExactRecording(WidgetTester tester, String sessionId) async {
  expect(
    await pumpUntil(
      tester,
      () => find.byType(ListTile).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 20),
    ),
    isTrue,
    reason: 'History did not list the recorded session $sessionId',
  );
  await GoRouter.of(tester.element(find.byType(TelemetrySessionsScreen)))
      .push('${TelemetrySessionsScreen.path}/$sessionId');
  await tester.pump();
  expect(
    await pumpUntil(
      tester,
      () => find.byType(TelemetrySessionDetailScreen).evaluate().isNotEmpty,
    ),
    isTrue,
    reason: 'recording detail TelemetrySessionDetailScreen did not open',
  );
  final detail = tester.widget<TelemetrySessionDetailScreen>(
    find.byType(TelemetrySessionDetailScreen),
  );
  expect(detail.sessionId, sessionId);
}

Future<void> _openExportSheet(WidgetTester tester, String label) async {
  final button = find.descendant(
    of: find.byType(TelemetrySessionDetailScreen),
    matching: find.text(label),
  );
  expect(
    await pumpUntil(tester, () => button.evaluate().isNotEmpty),
    isTrue,
    reason:
        'Export control $label did not appear on TelemetrySessionDetailScreen',
  );
  await Scrollable.ensureVisible(tester.element(button), alignment: 0.5);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(button.hitTestable());
  await tester.pump();
  expect(
    await pumpUntil(
      tester,
      () => find.byType(TelemetryExportSheet).evaluate().isNotEmpty,
    ),
    isTrue,
    reason: 'TelemetryExportSheet did not open',
  );
}

Future<void> _expectSheetTitle(WidgetTester tester, String title) async {
  expect(
    await pumpUntil(
      tester,
      () => find
          .descendant(
            of: find.byType(TelemetryExportSheet),
            matching: find.text(title),
          )
          .evaluate()
          .isNotEmpty,
    ),
    isTrue,
    reason: 'Export sheet did not show $title on TelemetryExportSheet',
  );
}

Future<void> _tapExportFormat(WidgetTester tester, String label) async {
  final button = find.descendant(
    of: find.byType(TelemetryExportSheet),
    matching: find.text(label),
  );
  expect(
    await pumpUntil(tester, () => button.hitTestable().evaluate().isNotEmpty),
    isTrue,
    reason: 'Export format $label was not hit-testable',
  );
  await tester.tap(button.hitTestable());
  await tester.pump();
  expect(
    await pumpUntil(
      tester,
      () => find.byType(TelemetryExportSheet).evaluate().isEmpty,
    ),
    isTrue,
    reason: 'TelemetryExportSheet did not close after selecting $label',
  );
}

Future<List<String>> _capturePaths(Directory root) async {
  if (!await root.exists()) return const [];
  final paths = <String>[];
  await for (final entity in root.list(followLinks: false)) {
    if (entity is File) paths.add(entity.path);
  }
  return paths;
}

Future<File> _waitForNewCapture(
  WidgetTester tester,
  Directory root,
  String extension,
  Set<String> knownPaths,
) async {
  final captured = await pumpUntilValue<File>(tester, () async {
    if (!await root.exists()) return null;
    final matches = <File>[];
    await for (final entity in root.list(followLinks: false)) {
      if (entity is File &&
          entity.path.endsWith('.$extension') &&
          !knownPaths.contains(entity.path)) {
        matches.add(entity);
      }
    }
    return matches.length == 1 ? matches.single : null;
  }, timeout: const Duration(seconds: 30));
  expect(
    captured,
    isNotNull,
    reason: 'rig Share preparation did not capture a new .$extension artifact',
  );
  return captured!;
}

Map<String, Object?> _objectMap(Object? raw) {
  if (raw is Map<String, Object?>) return Map<String, Object?>.from(raw);
  if (raw is Map<String, dynamic>) {
    return <String, Object?>{
      for (final entry in raw.entries) entry.key: entry.value,
    };
  }
  fail('expected JSON object, got ${raw.runtimeType}');
}

Future<void> _reopenJsonArtifact({
  required File jsonFile,
  required String sessionId,
  required TelemetrySessionHeader nativeHeader,
  required int nativeValueCount,
}) async {
  // Preparation only: the rig sink copied the staged export. This is not an
  // OS chooser completion or a recipient handoff.
  expect(await jsonFile.exists(), isTrue);
  expect(await jsonFile.length(), greaterThan(0));
  final decoded = jsonDecode(await jsonFile.readAsString());
  final map = _objectMap(decoded);
  final headerResult = TelemetrySessionCodec.decodeHeaderObject(
    _objectMap(map['header']),
  );
  expect(
    headerResult.error,
    isNull,
    reason: 'exported JSON header did not reopen: ${headerResult.error}',
  );
  final header = headerResult.value!;
  expect(header.sessionId, sessionId);
  expect(header.source, TelemetrySource.demo);
  expect(header.transport, TransportKind.demo);
  expect(header.signals, isNotEmpty);
  expect(
    header.signals.map((signal) => signal.fingerprint).toSet(),
    nativeHeader.signals.map((signal) => signal.fingerprint).toSet(),
  );
  expect(
    header.signals.map((signal) => signal.definition.id).toSet(),
    nativeHeader.signals.map((signal) => signal.definition.id).toSet(),
  );
  for (final signal in header.signals) {
    expect(
      FrozenPidDefinition.freeze(signal.definition).fingerprint,
      signal.fingerprint,
    );
    expect(signal.definition.unitProvenance, isNotNull);
  }

  final events = map['events'];
  expect(events, isA<List<dynamic>>());
  final eventList = events! as List<dynamic>;
  expect(eventList, isNotEmpty);
  var previousElapsedUs = -1;
  var valueCount = 0;
  for (final raw in eventList) {
    final eventResult = TelemetrySessionCodec.decodeEventObject(
      _objectMap(raw),
      header,
      previousElapsedUs,
    );
    expect(
      eventResult.error,
      isNull,
      reason: 'exported JSON event did not reopen: ${eventResult.error}',
    );
    final event = eventResult.value!;
    previousElapsedUs = event.elapsedUs;
    if (event.kind == TelemetryEventKind.value) {
      expect(event.value, isA<double>());
      expect(event.value!.isFinite, isTrue);
      valueCount++;
    }
  }

  final footerMap = _objectMap(map['footer']);
  final footerResult = TelemetrySessionCodec.decodeFooterObject(
    footerMap,
    footerMap['valueCount']! as int,
    footerMap['statusCount']! as int,
    footerMap['gapCount']! as int,
    footerMap['bytesBeforeFooter']! as int,
  );
  expect(
    footerResult.error,
    isNull,
    reason: 'exported JSON footer did not reopen: ${footerResult.error}',
  );
  expect(footerResult.value!.valueCount, nativeValueCount);
  expect(footerResult.value!.valueCount, valueCount);
  expect(footerResult.value!.valueCount, greaterThan(0));
  expect(map['privacyExclusions'], contains('VIN'));
}

void _reopenCsvArtifact({
  required String csv,
  required TelemetrySessionHeader nativeHeader,
  required int nativeValueCount,
}) {
  expect(csv, contains('# source=demo'));
  expect(csv, contains('# transport=demo'));
  expect(csv, contains('# value_count=$nativeValueCount'));
  for (final signal in nativeHeader.signals) {
    expect(csv, contains(signal.fingerprint));
    expect(csv, contains(signal.definition.id));
  }
}

Future<void> _expectNativeUnchanged(File native, Uint8List original) async {
  expect(await native.exists(), isTrue);
  expect(await native.readAsBytes(), original);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Export copy follows a language switch after Demo', (
    tester,
  ) async {
    await startCleanRigApp(tester);
    await connectDemoRig(tester);
    final sessionId = await _recordShortDemoSession(tester);
    final native = await _nativeSessionFile(sessionId);
    expect(await native.exists(), isTrue);
    final originalBytes = Uint8List.fromList(await native.readAsBytes());
    final nativeRead = await _readNative(native);
    final nativeHeader = nativeRead.sessionHeader!;
    expect(nativeHeader.sessionId, sessionId);
    expect(nativeHeader.source, TelemetrySource.demo);
    final nativeValueCount = nativeRead.valueCount;
    expect(nativeValueCount, greaterThan(0));

    final captureRoot = await rigShareCaptureDirectory();
    expect(await _capturePaths(captureRoot), isEmpty);

    await _openHistory(tester);
    await _openExactRecording(tester, sessionId);
    await _openExportSheet(tester, '匯出');
    await _expectSheetTitle(tester, '匯出本機紀錄');

    Navigator.of(tester.element(find.byType(TelemetryExportSheet))).pop();
    await tester.pump();
    expect(find.byType(TelemetryExportSheet), findsNothing);
    expect(await _capturePaths(captureRoot), isEmpty);
    await _expectNativeUnchanged(native, originalBytes);

    await _openExportSheet(tester, '匯出');
    await _expectSheetTitle(tester, '匯出本機紀錄');
    await _tapExportFormat(tester, '匯出 JSON');
    final jsonFile = await _waitForNewCapture(
      tester,
      captureRoot,
      'json',
      const {},
    );
    await _reopenJsonArtifact(
      jsonFile: jsonFile,
      sessionId: sessionId,
      nativeHeader: nativeHeader,
      nativeValueCount: nativeValueCount,
    );
    await _expectNativeUnchanged(native, originalBytes);

    await _openExportSheet(tester, '匯出');
    await _tapExportFormat(tester, '匯出 CSV');
    final csvFile = await _waitForNewCapture(
      tester,
      captureRoot,
      'csv',
      const {},
    );
    _reopenCsvArtifact(
      csv: await csvFile.readAsString(),
      nativeHeader: nativeHeader,
      nativeValueCount: nativeValueCount,
    );
    await _expectNativeUnchanged(native, originalBytes);

    await _leaveExportToShell(tester);
    await _tapNav(tester, '設定');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.scrollUntilVisible(
      find.byKey(const Key('locale_english')),
      400,
      scrollable: find
          .descendant(
            of: find.byType(SettingsScreen),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            ),
          )
          .first,
    );
    await tester.tap(find.byKey(const Key('locale_english')));
    await tester.pump(const Duration(milliseconds: 500));

    await _tapNav(tester, 'Dashboard');
    await _openHistory(tester);
    await _openExactRecording(tester, sessionId);
    await _openExportSheet(tester, 'Export');
    await _expectSheetTitle(tester, 'Export a local recording');
    expect(
      find.descendant(
        of: find.byType(TelemetryExportSheet),
        matching: find.text('匯出本機紀錄'),
      ),
      findsNothing,
    );

    final knownJson = {jsonFile.path};
    await _tapExportFormat(tester, 'Export JSON');
    final englishJson = await _waitForNewCapture(
      tester,
      captureRoot,
      'json',
      knownJson,
    );
    await _reopenJsonArtifact(
      jsonFile: englishJson,
      sessionId: sessionId,
      nativeHeader: nativeHeader,
      nativeValueCount: nativeValueCount,
    );
    await _expectNativeUnchanged(native, originalBytes);
  });
}
