/// #47 leftover: after Demo, assert Dashboard Trends copy, then English.
/// Production providers; the session is not replaced with a pre-solved mock.
///
///     flutter test integration_test/localization_trends_journey_test.dart -d <device-id> \
///       --flavor rig --dart-define=TELLTALE_TEST_RIG=true
///
/// Without `--flavor rig` and `TELLTALE_TEST_RIG=true` this fails closed
/// inside [requireIsolatedRigIdentity]. Missing hardware is a failure, not a
/// skip that looks like a pass.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:torque_obd/ui/screens/dashboard/dashboard_screen.dart';
import 'package:torque_obd/ui/screens/settings/settings_screen.dart';

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

Finder _trendsOnDashboard(String label) {
  return find.descendant(
    of: find.byKey(const ValueKey('dashboard-workspace-switch')),
    matching: find.text(label),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Trends copy follows a language switch after Demo', (
    tester,
  ) async {
    await startCleanRigApp(tester);
    await connectDemoRig(tester);

    expect(
      await pumpUntil(
        tester,
        () => find.byType(DashboardScreen).evaluate().isNotEmpty,
      ),
      isTrue,
      reason: 'DashboardScreen did not open after Demo',
    );
    final chinese = _trendsOnDashboard('趨勢');
    expect(
      await pumpUntil(tester, () => chinese.evaluate().isNotEmpty),
      isTrue,
      reason: 'Dashboard workspace switch did not show 趨勢 after Demo',
    );
    await Scrollable.ensureVisible(tester.element(chinese), alignment: 0.5);
    await tester.pump(const Duration(milliseconds: 50));
    expect(chinese.hitTestable(), findsOneWidget);
    await tester.tap(chinese.hitTestable());
    await tester.pump();

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
    expect(
      await pumpUntil(
        tester,
        () => find.byType(DashboardScreen).evaluate().isNotEmpty,
      ),
      isTrue,
      reason: 'DashboardScreen did not open after language switch',
    );
    final english = _trendsOnDashboard('Trends');
    expect(
      await pumpUntil(tester, () => english.evaluate().isNotEmpty),
      isTrue,
      reason: 'Dashboard workspace switch did not show Trends after language switch',
    );
    await Scrollable.ensureVisible(tester.element(english), alignment: 0.5);
    await tester.pump(const Duration(milliseconds: 50));
    expect(english.hitTestable(), findsOneWidget);
    expect(_trendsOnDashboard('趨勢'), findsNothing);
  });
}
