/// #47 leftover: after Demo, record, open History, then assert Export copy.
/// Production providers; the session is not replaced with a pre-solved mock.
///
///     flutter test integration_test/localization_export_journey_test.dart -d <device-id> \
///       --flavor rig --dart-define=TELLTALE_TEST_RIG=true
///
/// Without `--flavor rig` and `TELLTALE_TEST_RIG=true` this fails closed
/// inside [requireIsolatedRigIdentity]. Missing hardware is a failure, not a
/// skip that looks like a pass.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/telemetry_recorder.dart';
import 'package:torque_obd/telemetry/session/telemetry_recorder.dart';
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

Future<void> _recordShortDemoSession(WidgetTester tester) async {
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

  await session.disconnect();
  await tester.pump();
}

Future<void> _openFirstRecording(WidgetTester tester) async {
  expect(
    await pumpUntil(
      tester,
      () => find.byType(ListTile).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 20),
    ),
    isTrue,
    reason: 'History did not list a recorded session',
  );
  final tile = find.byType(ListTile).first;
  await Scrollable.ensureVisible(tester.element(tile), alignment: 0.5);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(tile.hitTestable());
  await tester.pump();
  expect(
    await pumpUntil(
      tester,
      () => find.byType(TelemetrySessionDetailScreen).evaluate().isNotEmpty,
    ),
    isTrue,
    reason: 'recording detail TelemetrySessionDetailScreen did not open',
  );
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Export copy follows a language switch after Demo', (
    tester,
  ) async {
    await startCleanRigApp(tester);
    await connectDemoRig(tester);
    await _recordShortDemoSession(tester);

    await _openHistory(tester);
    await _openFirstRecording(tester);
    await _openExportSheet(tester, '匯出');
    final chineseTitle = await pumpUntil(
      tester,
      () => find
          .descendant(
            of: find.byType(TelemetryExportSheet),
            matching: find.text('匯出本機紀錄'),
          )
          .evaluate()
          .isNotEmpty,
    );
    expect(
      chineseTitle,
      isTrue,
      reason: 'Export sheet did not show 匯出本機紀錄 on TelemetryExportSheet',
    );

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
    await _openFirstRecording(tester);
    await _openExportSheet(tester, 'Export');
    final englishTitle = await pumpUntil(
      tester,
      () => find
          .descendant(
            of: find.byType(TelemetryExportSheet),
            matching: find.text('Export a local recording'),
          )
          .evaluate()
          .isNotEmpty,
    );
    expect(
      englishTitle,
      isTrue,
      reason: 'Export sheet did not show Export a local recording on TelemetryExportSheet',
    );
    expect(
      find.descendant(
        of: find.byType(TelemetryExportSheet),
        matching: find.text('匯出本機紀錄'),
      ),
      findsNothing,
    );
  });
}
