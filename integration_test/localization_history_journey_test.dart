/// #47 leftover: after Demo, open History in Traditional Chinese then English.
/// Production providers; the session is not replaced with a pre-solved mock.
///
///     flutter test integration_test/localization_history_journey_test.dart -d <device-id> \
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
import 'package:torque_obd/ui/screens/settings/settings_screen.dart';
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

Future<void> _stabilizeHistoryAccess(WidgetTester tester) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
    listen: false,
  );
  await container.read(obdSessionProvider.notifier).disconnect();
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
          .descendant(
            of: dashboard.first,
            matching: find.byType(Scrollable),
          )
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
}

Future<void> _leaveHistory(WidgetTester tester) async {
  expect(find.byType(TelemetrySessionsScreen), findsOneWidget);
  Navigator.of(tester.element(find.byType(TelemetrySessionsScreen))).pop();
  await tester.pump();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('History copy follows a language switch after Demo', (
    tester,
  ) async {
    await startCleanRigApp(tester);
    await connectDemoRig(tester);
    await _stabilizeHistoryAccess(tester);

    await _openHistory(tester);
    final chineseRoute = await pumpUntil(
      tester,
      () => find.byType(TelemetrySessionsScreen).evaluate().isNotEmpty,
    );
    expect(
      chineseRoute,
      isTrue,
      reason: 'History route TelemetrySessionsScreen did not open',
    );
    expect(find.text('本機紀錄'), findsWidgets);

    await _leaveHistory(tester);
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
    final englishRoute = await pumpUntil(
      tester,
      () => find.byType(TelemetrySessionsScreen).evaluate().isNotEmpty,
    );
    expect(
      englishRoute,
      isTrue,
      reason: 'History route TelemetrySessionsScreen did not reopen in English',
    );
    expect(find.text('Local recordings'), findsWidgets);
    expect(find.text('本機紀錄'), findsNothing);
  });
}
