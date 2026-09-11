/// #47 leftover: after Demo, open PID manager in Traditional Chinese then English.
/// Production providers; the session is not replaced with a pre-solved mock.
///
///     flutter test integration_test/localization_pid_journey_test.dart -d <device-id> \
///       --flavor rig --dart-define=TELLTALE_TEST_RIG=true
///
/// Without `--flavor rig` and `TELLTALE_TEST_RIG=true` this fails closed
/// inside [requireIsolatedRigIdentity]. Missing hardware is a failure, not a
/// skip that looks like a pass.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PID copy follows a language switch after Demo', (tester) async {
    await startCleanRigApp(tester);
    await connectDemoRig(tester);

    await _tapNav(tester, 'PID');
    final chineseHeadline = await pumpUntil(
      tester,
      () => find.text('PID 管理').evaluate().isNotEmpty,
    );
    expect(
      chineseHeadline,
      isTrue,
      reason: 'PID screen did not show PID 管理 after Demo connect',
    );

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

    await _tapNav(tester, 'PID');
    final englishHeadline = await pumpUntil(
      tester,
      () => find.text('PID manager').evaluate().isNotEmpty,
    );
    expect(
      englishHeadline,
      isTrue,
      reason: 'PID screen did not show PID manager after switching language',
    );
    expect(find.text('PID 管理'), findsNothing);

    await _tapNav(tester, 'Settings');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.scrollUntilVisible(
      find.byKey(const Key('locale_german')),
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
    await tester.tap(find.byKey(const Key('locale_german')));
    await tester.pump(const Duration(milliseconds: 500));

    await _tapNav(tester, 'PID');
    final germanHeadline = await pumpUntil(
      tester,
      () => find.text('PID-Manager').evaluate().isNotEmpty,
    );
    expect(
      germanHeadline,
      isTrue,
      reason: 'PID screen did not show PID-Manager after switching to German',
    );
    expect(find.text('PID manager'), findsNothing);
    expect(find.text('PID 管理'), findsNothing);
  });
}
