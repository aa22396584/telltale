/// #47 leftover: after Demo, scan DTC, then assert readiness copy.
/// Production providers; the session is not replaced with a pre-solved mock.
///
///     flutter test integration_test/localization_readiness_journey_test.dart -d <device-id> \
///       --flavor rig --dart-define=TELLTALE_TEST_RIG=true
///
/// Without `--flavor rig` and `TELLTALE_TEST_RIG=true` this fails closed
/// inside [requireIsolatedRigIdentity]. Missing hardware is a failure, not a
/// skip that looks like a pass.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:torque_obd/ui/screens/dtc/dtc_screen.dart';
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

Finder _onDtc(String label) {
  return find.descendant(
    of: find.byType(DtcScreen),
    matching: find.text(label),
  );
}

Future<void> _startScanIfNeeded(WidgetTester tester, String startLabel) async {
  final start = _onDtc(startLabel);
  if (start.evaluate().isEmpty) {
    return;
  }
  await Scrollable.ensureVisible(tester.element(start), alignment: 0.5);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(start.hitTestable());
  await tester.pump();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Readiness copy follows a language switch after Demo', (
    tester,
  ) async {
    await startCleanRigApp(tester);
    await connectDemoRig(tester);

    await _tapNav(tester, '故障碼');
    expect(
      await pumpUntil(
        tester,
        () => find.byType(DtcScreen).evaluate().isNotEmpty,
      ),
      isTrue,
      reason: 'DtcScreen did not open after Demo',
    );
    await _startScanIfNeeded(tester, '開始掃描');
    final chinese = _onDtc('排放就緒狀態');
    expect(
      await pumpUntil(
        tester,
        () => chinese.evaluate().isNotEmpty,
        timeout: const Duration(seconds: 30),
      ),
      isTrue,
      reason: 'DtcScreen did not show 排放就緒狀態 after Demo scan',
    );
    await Scrollable.ensureVisible(tester.element(chinese), alignment: 0.5);
    await tester.pump(const Duration(milliseconds: 50));
    expect(chinese.hitTestable(), findsOneWidget);

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

    await _tapNav(tester, 'Fault codes');
    expect(
      await pumpUntil(
        tester,
        () => find.byType(DtcScreen).evaluate().isNotEmpty,
      ),
      isTrue,
      reason: 'DtcScreen did not open after language switch',
    );
    await _startScanIfNeeded(tester, 'Start scan');
    final english = _onDtc('Emissions readiness');
    expect(
      await pumpUntil(
        tester,
        () => english.evaluate().isNotEmpty,
        timeout: const Duration(seconds: 30),
      ),
      isTrue,
      reason:
          'DtcScreen did not show Emissions readiness after language switch',
    );
    await Scrollable.ensureVisible(tester.element(english), alignment: 0.5);
    await tester.pump(const Duration(milliseconds: 50));
    expect(english.hitTestable(), findsOneWidget);
    expect(_onDtc('排放就緒狀態'), findsNothing);
  });
}
