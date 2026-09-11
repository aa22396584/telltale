// Keeps integration_test/localization_gauges_journey_test.dart honest as the
// #47 Gauges bilingual device entry.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File('integration_test/localization_gauges_journey_test.dart')
      .readAsStringSync();

  test('the named Gauges journey file exists and is not an empty stub', () {
    expect(source.length, greaterThan(400));
  });

  test('the journey fails closed without the isolated rig identity', () {
    expect(source.contains("import 'rig_support.dart'"), isTrue);
    expect(source.contains('startCleanRigApp'), isTrue);
    expect(source.contains('connectDemoRig'), isTrue);
    expect(source.contains('requireIsolatedRigIdentity'), isTrue);
    expect(source.contains('markTestSkipped'), isFalse);
  });

  test('the journey opens Dashboard gauges then switches language', () {
    expect(source.contains('DashboardScreen'), isTrue);
    expect(source.contains('dashboard-workspace-switch'), isTrue);
    expect(source.contains('儀表'), isTrue);
    expect(source.contains('Gauges'), isTrue);
    expect(source.contains('Instrumente'), isTrue);
    expect(source.contains('locale_english'), isTrue);
    expect(source.contains('locale_german'), isTrue);
    expect(source.contains('SettingsScreen'), isTrue);
    expect(source.contains('find.descendant'), isTrue);
    expect(source.contains('pumpUntil'), isTrue);
    final demoAt = source.indexOf('await connectDemoRig');
    final gaugesAt = source.indexOf("_gaugesOnDashboard('儀表')");
    final englishAt = source.indexOf('locale_english');
    expect(demoAt, greaterThan(0));
    expect(gaugesAt, greaterThan(demoAt));
    expect(englishAt, greaterThan(gaugesAt));
  });

  test('the journey does not replace ObdSession with a pre-solved mock', () {
    expect(source.contains('obdSessionProvider.overrideWith'), isFalse);
    expect(source.contains('_FastDemoSession'), isFalse);
    expect(source.contains('_IdleSession'), isFalse);
  });
}
