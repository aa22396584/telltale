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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/state/locale_settings.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/telemetry_recorder.dart';
import 'package:torque_obd/telemetry/session/telemetry_recorder.dart';
import 'package:torque_obd/telemetry/session/telemetry_session_reader.dart';
import 'package:torque_obd/ui/screens/dashboard/dashboard_screen.dart';
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

  // History is blocked while Demo is classified moving (speed > 5 km/h).
  // A short recording leaves the simulator in acceleration, so keep the
  // leftover Settings disconnect copy for after History by reconnecting
  // there instead of holding this live session open.
  await session.disconnect();
  await tester.pump();
  expect(
    container.read(obdSessionProvider).phase,
    ConnectionPhase.disconnected,
    reason: 'Demo must disconnect so History can list the recording',
  );
  return sessionId;
}

Finder _dashboardVerticalScrollable() {
  return find.descendant(
    of: find.byType(DashboardScreen),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
      description: 'dashboard vertical Scrollable',
    ),
  );
}

/// Recording scrolls the dashboard down to Stop. The toolbar History control
/// lives in an earlier sliver and can leave the cache, so
/// [WidgetController.scrollUntilVisible] (which only drags toward later
/// slivers) never finds it and then throws `Bad state: No element`.
Future<void> _revealDashboardTop(WidgetTester tester) async {
  final scrollable = _dashboardVerticalScrollable();
  if (scrollable.evaluate().isEmpty) {
    return;
  }
  final position = tester.state<ScrollableState>(scrollable.first).position;
  if (position.pixels == 0) {
    return;
  }
  position.jumpTo(0);
  await tester.pump();
}

Future<void> _openHistory(WidgetTester tester) async {
  expect(
    await pumpUntil(
      tester,
      () => find.byType(DashboardScreen).evaluate().isNotEmpty,
    ),
    isTrue,
    reason: 'DashboardScreen is not in the tree after recording',
  );

  final fromOutcome = find.byKey(const ValueKey('telemetry-open-history'));
  final toolbar = find.byKey(const ValueKey('telemetry-history'));

  if (fromOutcome.hitTestable().evaluate().isNotEmpty) {
    await tester.tap(fromOutcome.hitTestable());
  } else {
    await _revealDashboardTop(tester);
    expect(
      await pumpUntil(
        tester,
        () => toolbar.evaluate().isNotEmpty,
        timeout: const Duration(seconds: 10),
      ),
      isTrue,
      reason: 'toolbar History control never re-entered the tree',
    );
    await Scrollable.ensureVisible(tester.element(toolbar), alignment: 0.5);
    await tester.pump(const Duration(milliseconds: 100));
    expect(toolbar.hitTestable(), findsOneWidget);
    await tester.tap(toolbar.hitTestable());
  }
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
    find.byType(TelemetrySessionsScreen),
    findsOneWidget,
    reason: 'History route is not showing TelemetrySessionsScreen',
  );
  expect(
    await pumpUntil(
      tester,
      () => find
          .descendant(
            of: find.byType(TelemetrySessionsScreen),
            matching: find.byType(ListTile),
          )
          .evaluate()
          .isNotEmpty,
      timeout: const Duration(seconds: 20),
    ),
    isTrue,
    reason: 'History did not list the recorded session $sessionId',
  );
  // go_router.push completes only when the pushed route is popped. Awaiting
  // it deadlocks the journey until the widget timeout.
  unawaited(
    GoRouter.of(tester.element(find.byType(TelemetrySessionsScreen)))
        .push('${TelemetrySessionsScreen.path}/$sessionId'),
  );
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
    await tester.pump(const Duration(milliseconds: 50));
  }
  if (find.byType(TelemetrySessionsScreen).evaluate().isNotEmpty) {
    Navigator.of(tester.element(find.byType(TelemetrySessionsScreen))).pop();
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(
    await pumpUntil(
      tester,
      () =>
          _navLabel('設定').hitTestable().evaluate().isNotEmpty ||
          _navLabel('Settings').hitTestable().evaluate().isNotEmpty,
      timeout: const Duration(seconds: 20),
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

Future<void> _revealSettingsTop(WidgetTester tester) async {
  final scrollable = _settingsVerticalScrollable();
  if (scrollable.evaluate().isEmpty) {
    return;
  }
  final position = tester.state<ScrollableState>(scrollable).position;
  if (position.pixels == 0) {
    return;
  }
  position.jumpTo(0);
  await tester.pump();
}

/// [WidgetController.scrollUntilVisible] can leave the locale row under the
/// NavigationBar, so a tap at that offset never invokes onTap.
Future<void> _tapLocaleOnSettings(
  WidgetTester tester,
  Key key,
  LocalePreference expected,
) async {
  final locale = find.descendant(
    of: find.byType(SettingsScreen),
    matching: find.byKey(key),
  );
  await tester.scrollUntilVisible(
    locale,
    400,
    scrollable: _settingsVerticalScrollable(),
  );
  final viewHeight =
      tester.view.physicalSize.height / tester.view.devicePixelRatio;
  final maxY = viewHeight - 140;
  var tapped = false;
  for (var i = 0; i < 10; i++) {
    await Scrollable.ensureVisible(tester.element(locale), alignment: 0.2);
    await tester.pump(const Duration(milliseconds: 80));
    final hittable = locale.hitTestable();
    if (hittable.evaluate().isEmpty) {
      await tester.drag(_settingsVerticalScrollable(), const Offset(0, -160));
      await tester.pump();
      continue;
    }
    final center = tester.getCenter(hittable);
    if (center.dy > maxY) {
      await tester.drag(_settingsVerticalScrollable(), const Offset(0, -160));
      await tester.pump();
      continue;
    }
    await tester.tapAt(center);
    await tester.pump();
    tapped = true;
    break;
  }
  expect(
    tapped,
    isTrue,
    reason: 'locale control $key stayed under the navigation bar',
  );
  final container = ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
    listen: false,
  );
  expect(
    await pumpUntil(
      tester,
      () => container.read(localePreferenceProvider) == expected,
      timeout: const Duration(seconds: 15),
    ),
    isTrue,
    reason:
        'tapping $key on Settings left locale at '
        '${container.read(localePreferenceProvider)}',
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'language switch before connect, then Demo, record, History, disconnect',
    (tester) async {
      debugPrint('JOURNEY startCleanRigApp');
      await startCleanRigApp(tester);
      debugPrint('JOURNEY connect screen');

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

      await _selectLocale(tester, const Key('locale_german'));
      final germanHeadline = await pumpUntil(
        tester,
        () => find
            .text('Wählen Sie eine Verbindung aus')
            .hitTestable()
            .evaluate()
            .isNotEmpty,
      );
      expect(
        germanHeadline,
        isTrue,
        reason: 'switching to German before connect did not retitle the screen',
      );
      expect(find.text('Choose a connection'), findsNothing);
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

      debugPrint('JOURNEY connectDemoRig');
      await connectDemoRig(tester);
      debugPrint('JOURNEY record');
      final sessionId = await _recordShortDemoSession(tester);
      debugPrint('JOURNEY openHistory');
      await _openHistory(tester);
      debugPrint('JOURNEY historyOpened');
      debugPrint('JOURNEY exactRecording');
      await _openExactRecording(tester, sessionId);
      debugPrint('JOURNEY detailOpen');
      expect(find.byType(TelemetrySessionDetailScreen), findsOneWidget);

      debugPrint('JOURNEY leaveReplay');
      await _leaveReplayToShell(tester);
      debugPrint('JOURNEY backOnShell');
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
        listen: false,
      );
      debugPrint('JOURNEY reconnectDemo');
      final reconnect = container
          .read(obdSessionProvider.notifier)
          .connectDemo();
      expect(
        await pumpUntil(
          tester,
          () =>
              container.read(obdSessionProvider).phase ==
              ConnectionPhase.connected,
          timeout: const Duration(seconds: 30),
          step: const Duration(milliseconds: 25),
        ),
        isTrue,
        reason:
            'Demo did not reconnect after History for Settings disconnect copy',
      );
      expect(await reconnect, isTrue);
      debugPrint('JOURNEY tapSettings');
      await _tapNav(tester, '設定');
      debugPrint('JOURNEY settingsOpen');
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

      debugPrint('JOURNEY switchEnglish');
      await _tapLocaleOnSettings(
        tester,
        const Key('locale_english'),
        LocalePreference.english,
      );
      // Scrolling to the locale row can deactivate the connection sliver.
      // Reveal the top before asking for Disconnect, or the finder is empty.
      await _revealSettingsTop(tester);
      final englishDisconnect = _disconnectOnSettings('Disconnect');
      expect(
        await pumpUntil(tester, () => englishDisconnect.evaluate().isNotEmpty),
        isTrue,
        reason: 'Settings did not show Disconnect after language switch',
      );
      debugPrint('JOURNEY englishDisconnect');
      await Scrollable.ensureVisible(
        tester.element(englishDisconnect),
        alignment: 0.5,
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        englishDisconnect.hitTestable(),
        findsOneWidget,
        reason: 'Settings did not show Disconnect after language switch',
      );
      expect(_disconnectOnSettings('中斷連線'), findsNothing);

      debugPrint('JOURNEY switchGerman');
      await _tapLocaleOnSettings(
        tester,
        const Key('locale_german'),
        LocalePreference.german,
      );
      await _revealSettingsTop(tester);
      final germanDisconnect = _disconnectOnSettings('Trennen');
      expect(
        await pumpUntil(tester, () => germanDisconnect.evaluate().isNotEmpty),
        isTrue,
        reason: 'Settings did not show Trennen after language switch',
      );
      expect(_disconnectOnSettings('Disconnect'), findsNothing);
      expect(_disconnectOnSettings('中斷連線'), findsNothing);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
