/// #47 leftover: after Demo, capture Dashboard screenshots and SHA-256 them.
/// Production providers; the session is not replaced with a pre-solved mock.
///
///     flutter test integration_test/localization_screenshot_journey_test.dart -d <device-id> \
///       --flavor rig --dart-define=TELLTALE_TEST_RIG=true
///
/// Without `--flavor rig` and `TELLTALE_TEST_RIG=true` this fails closed
/// inside [requireIsolatedRigIdentity]. Missing hardware is a failure, not a
/// skip that looks like a pass.
///
/// Full-screen captures still run and must produce a SHA-256. The locale
/// inequality is on the workspace-switch crop: Demo's drive-cycle and the
/// dashboard needles keep moving, so a full-frame hash can change without
/// the labels changing. The switcher is a [RepaintBoundary] whose pixels
/// are the 儀表 / Gauges labels.
///
/// Bytes are hashed with the in-repo SHA-256
/// ([PowertrainBatteryCatalogAsset.sha256Hex]) so this file does not import
/// transitive `package:crypto`. Empty captures and identical switcher hashes
/// across the language switch fail closed.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:torque_obd/obd/powertrain_battery/powertrain_battery_catalog.dart';
import 'package:torque_obd/ui/screens/dashboard/dashboard_screen.dart';
import 'package:torque_obd/ui/screens/settings/settings_screen.dart';

import 'rig_support.dart';

final _digest = RegExp(r'^[0-9a-f]{64}$');

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

Future<String> _dashboardDigest(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  try {
    await binding.convertFlutterSurfaceToImage();
  } on UnimplementedError {
    // Android needs the surface conversion; other platforms do not.
  }
  await tester.pump();
  final bytes = await binding.takeScreenshot(name);
  expect(bytes, isNotEmpty, reason: 'screenshot $name produced no bytes');
  final digest = PowertrainBatteryCatalogAsset.sha256Hex(bytes);
  expect(
    digest,
    matches(_digest),
    reason: 'screenshot $name SHA-256 was not a lowercase digest: $digest',
  );
  return digest;
}

/// Localized crop: workspace-switch labels, not the moving gauge needles.
Future<String> _switchDigest(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('dashboard-workspace-switch')),
  );
  late final String digest;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(
      byteData,
      isNotNull,
      reason: 'workspace switch $name produced no PNG',
    );
    final bytes = byteData!.buffer.asUint8List();
    expect(bytes, isNotEmpty, reason: 'workspace switch $name PNG was empty');
    digest = PowertrainBatteryCatalogAsset.sha256Hex(bytes);
  });
  expect(
    digest,
    matches(_digest),
    reason:
        'workspace switch $name SHA-256 was not a lowercase digest: $digest',
  );
  return digest;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Dashboard screenshots change hash after a language switch', (
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
    final chinese = _gaugesOnDashboard('儀表');
    expect(
      await pumpUntil(tester, () => chinese.evaluate().isNotEmpty),
      isTrue,
      reason: 'Dashboard workspace switch did not show 儀表 after Demo',
    );
    await Scrollable.ensureVisible(tester.element(chinese), alignment: 0.5);
    await tester.pump(const Duration(milliseconds: 50));
    expect(chinese.hitTestable(), findsOneWidget);
    await _dashboardDigest(tester, binding, 'dashboard-zh-Hant');
    final chineseSwitch = await _switchDigest(tester, 'switch-zh-Hant');

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
    await _dashboardDigest(tester, binding, 'dashboard-en');
    final englishSwitch = await _switchDigest(tester, 'switch-en');

    expect(
      englishSwitch,
      isNot(equals(chineseSwitch)),
      reason:
          'language switch left workspace-switch pixels unchanged '
          '(zh-Hant=$chineseSwitch en=$englishSwitch)',
    );
  });
}
