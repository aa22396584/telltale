/// #47 leftover: after Demo, the live Dashboard must not overflow at 320dp.
/// Production providers; the session is not replaced with a pre-solved mock.
///
///     flutter test integration_test/localization_overflow_journey_test.dart -d <device-id> \
///       --flavor rig --dart-define=TELLTALE_TEST_RIG=true
///
/// Without `--flavor rig` and `TELLTALE_TEST_RIG=true` this fails closed
/// inside [requireIsolatedRigIdentity]. Missing hardware is a failure, not a
/// skip that looks like a pass.
///
/// `tester.takeException()` is not the check. A `RenderFlex` reports overflow
/// once per render object; collecting from `FlutterError.onError` is what
/// makes a second pump on the same tree honest.
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

Finder _gaugesOnDashboard(String label) {
  return find.descendant(
    of: find.byKey(const ValueKey('dashboard-workspace-switch')),
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
    'Dashboard does not overflow at 320dp after Demo in both languages',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final overflows = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        final text = details.exceptionAsString();
        if (text.contains('overflowed')) {
          overflows.add(text);
        }
        previous?.call(details);
      };
      addTearDown(() {
        FlutterError.onError = previous;
      });

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
      final chinese = _gaugesOnDashboard('儀表');
      expect(
        await pumpUntil(tester, () => chinese.evaluate().isNotEmpty),
        isTrue,
        reason: 'Dashboard workspace switch did not show 儀表 after Demo',
      );
      await Scrollable.ensureVisible(tester.element(chinese), alignment: 0.5);
      await tester.pump(const Duration(milliseconds: 50));
      expect(chinese.hitTestable(), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));

      await _tapNav(tester, '設定');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.scrollUntilVisible(
        find.byKey(const Key('locale_english')),
        400,
        scrollable: _settingsVerticalScrollable(),
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
      final english = _gaugesOnDashboard('Gauges');
      expect(
        await pumpUntil(tester, () => english.evaluate().isNotEmpty),
        isTrue,
        reason: 'Dashboard workspace switch did not show Gauges after language switch',
      );
      await Scrollable.ensureVisible(tester.element(english), alignment: 0.5);
      await tester.pump(const Duration(milliseconds: 50));
      expect(english.hitTestable(), findsOneWidget);
      expect(_gaugesOnDashboard('儀表'), findsNothing);
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        overflows,
        isEmpty,
        reason:
            'RenderFlex overflowed at 320dp after Demo:\n${overflows.join('\n')}',
      );
    },
  );
}
