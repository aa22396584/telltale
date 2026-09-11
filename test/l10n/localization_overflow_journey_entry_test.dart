// Keeps integration_test/localization_overflow_journey_test.dart honest as
// the #47 320dp overflow bilingual device entry.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File(
    'integration_test/localization_overflow_journey_test.dart',
  ).readAsStringSync();

  test('the named overflow journey file exists and is not an empty stub', () {
    expect(source.length, greaterThan(400));
  });

  test('the journey fails closed without the isolated rig identity', () {
    expect(source.contains("import 'rig_support.dart'"), isTrue);
    expect(source.contains('startCleanRigApp'), isTrue);
    expect(source.contains('connectDemoRig'), isTrue);
    expect(source.contains('requireIsolatedRigIdentity'), isTrue);
    expect(source.contains('markTestSkipped'), isFalse);
  });

  test('the journey pins 320dp and collects RenderFlex overflow', () {
    expect(source.contains('Size(320, 640)'), isTrue);
    expect(source.contains('physicalSize'), isTrue);
    expect(source.contains('FlutterError.onError'), isTrue);
    expect(source.contains('overflowed'), isTrue);
    expect(source.contains('DashboardScreen'), isTrue);
    expect(source.contains('dashboard-workspace-switch'), isTrue);
    expect(source.contains('儀表'), isTrue);
    expect(source.contains('Gauges'), isTrue);
    expect(source.contains('推算數值'), isTrue);
    expect(source.contains('Estimated values'), isTrue);
    expect(source.contains('Instrumente'), isTrue);
    expect(source.contains('Geschätzte Werte'), isTrue);
    expect(source.contains('_revealLazyDashboard'), isTrue);
    expect(source.contains('locale_english'), isTrue);
    expect(source.contains('locale_german'), isTrue);
    expect(source.contains('SettingsScreen'), isTrue);
    expect(source.contains('find.descendant'), isTrue);
    expect(source.contains('pumpUntil'), isTrue);
    final demoAt = source.indexOf('await connectDemoRig');
    final gaugesAt = source.indexOf("_gaugesOnDashboard('儀表')");
    final derivedAt = source.indexOf("_revealLazyDashboard(tester, '推算數值')");
    final englishAt = source.indexOf('locale_english');
    final englishDerivedAt = source.indexOf(
      "_revealLazyDashboard(tester, 'Estimated values')",
    );
    final overflowAt = source.lastIndexOf('overflowed');
    expect(demoAt, greaterThan(0));
    expect(gaugesAt, greaterThan(demoAt));
    expect(derivedAt, greaterThan(gaugesAt));
    expect(englishAt, greaterThan(derivedAt));
    expect(englishDerivedAt, greaterThan(englishAt));
    expect(overflowAt, greaterThan(englishDerivedAt));
  });

  test('the journey does not replace ObdSession with a pre-solved mock', () {
    expect(source.contains('obdSessionProvider.overrideWith'), isFalse);
    expect(source.contains('_FastDemoSession'), isFalse);
    expect(source.contains('_IdleSession'), isFalse);
  });
}
