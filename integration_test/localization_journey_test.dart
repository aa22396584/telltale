/// #47 leftover: language switch before connect, Demo, short record,
/// History of that exact session, then Settings disconnect copy.
/// Production providers; the session is not replaced with a pre-solved mock.
/// Export/reopen is a separate leftover.
///
///     flutter test integration_test/localization_journey_test.dart -d <device-id> \
///       --flavor rig --dart-define=TELLTALE_TEST_RIG=true
///
/// Without `--flavor rig` and `TELLTALE_TEST_RIG=true` this fails closed
/// inside [requireIsolatedRigIdentity]. Missing hardware is a failure, not a
/// skip that looks like a pass.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/telemetry_recorder.dart';
import 'package:torque_obd/telemetry/session/telemetry_recorder.dart';
import 'package:torque_obd/telemetry/session/telemetry_session_reader.dart';
import 'package:torque_obd/ui/screens/settings/settings_screen.dart';
import 'package:torque_obd/ui/screens/telemetry/telemetry_session_detail_screen.dart';
import 'package:torque_obd/ui/screens/telemetry/telemetry_sessions_screen.dart';
import 'package:torque_obd/ui/widgets/language_picker.dart';

import 'rig_support.dart';

Future<void> _selectLocale(WidgetTester tester, Key localeKey) async {
  await tester.tap(find.byKey(const Key('connect_language_entry')));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.tap(find.byKey(localeKey));
  await tester.pump();
  final picker = find.byType(LanguagePicker);
  expect(picker, findsOneWidget);
  Navigator.of(tester.element(picker)).pop();
  await tester.pump(const Duration(milliseconds: 500));
}

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

  // Keep Demo connected. Settings disconnect copy is the leftover
  // assertion after History; disconnecting here would retitle the
  // button to Connect and make that wait time out.
  expect(
    container.read(obdSessionProvider).phase,
    ConnectionPhase.connected,
    reason: 'Demo must stay connected after the recorded session',
  );
  return sessionId;
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

Future<void> _leaveReplayToShell(WidgetTester tester) async {
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
    reason: 'shell navigation did not become hit-testable after leaving Replay',
  );
}

Finder _disconnectOnSettings(String label) {
  return find.descendant(
    of: find.byType(SettingsScreen),
    matching: find.text(label),
  );
}

Finder _settingsVerticalScrollable() {
  return find
      .descendant(
        of: find.byType(SettingsScreen),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      )
      .first;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'language switch before connect, then Demo, record, History, disconnect',
    (tester) async {
      await startCleanRigApp(tester);

      expect(find.text('選擇連線方式'), findsOneWidget);
      expect(find.text('Choose a connection'), findsNothing);

      await _selectLocale(tester, const Key('locale_english'));
      final englishHeadline = await pumpUntil(
        tester,
        () => find
            .text('Choose a connection')
            .hitTestable()
            .evaluate()
            .isNotEmpty,
      );
      expect(
        englishHeadline,
        isTrue,
        reason:
            'switching to English before connect did not retitle the screen',
      );
      expect(find.text('選擇連線方式'), findsNothing);

      await _selectLocale(tester, const Key('locale_traditionalChinese'));
      final chineseHeadline = await pumpUntil(
        tester,
        () => find.text('選擇連線方式').hitTestable().evaluate().isNotEmpty,
      );
      expect(
        chineseHeadline,
        isTrue,
        reason:
            'switching back to Traditional Chinese did not retitle the screen',
      );
      expect(find.text('Choose a connection'), findsNothing);

      await connectDemoRig(tester);
      final sessionId = await _recordShortDemoSession(tester);
      await _openHistory(tester);
      await _openExactRecording(tester, sessionId);
      expect(find.byType(TelemetrySessionDetailScreen), findsOneWidget);

      await _leaveReplayToShell(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
        listen: false,
      );
      expect(
        container.read(obdSessionProvider).phase,
        ConnectionPhase.connected,
        reason:
            'Demo must stay connected after History so Settings can show disconnect copy',
      );
      await _tapNav(tester, '設定');
      expect(
        await pumpUntil(
          tester,
          () => find.byType(SettingsScreen).evaluate().isNotEmpty,
        ),
        isTrue,
        reason: 'SettingsScreen did not open after the recorded session',
      );
      final chineseDisconnect = _disconnectOnSettings('中斷連線');
      expect(
        await pumpUntil(tester, () => chineseDisconnect.evaluate().isNotEmpty),
        isTrue,
        reason: 'Settings did not show 中斷連線 after Demo record',
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('locale_english')),
        400,
        scrollable: _settingsVerticalScrollable(),
      );
      await tester.tap(find.byKey(const Key('locale_english')));
      await tester.pump(const Duration(milliseconds: 500));

      final englishDisconnect = _disconnectOnSettings('Disconnect');
      await tester.scrollUntilVisible(
        englishDisconnect,
        -400,
        scrollable: _settingsVerticalScrollable(),
      );
      expect(
        englishDisconnect.hitTestable(),
        findsOneWidget,
        reason: 'Settings did not show Disconnect after language switch',
      );
      expect(_disconnectOnSettings('中斷連線'), findsNothing);
    },
  );
}
