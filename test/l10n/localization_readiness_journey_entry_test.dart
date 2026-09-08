// Keeps integration_test/localization_readiness_journey_test.dart honest as
// the #47 readiness bilingual device entry.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File(
    'integration_test/localization_readiness_journey_test.dart',
  ).readAsStringSync();

  test('the named readiness journey file exists and is not an empty stub', () {
    expect(source.length, greaterThan(400));
  });

  test('the journey fails closed without the isolated rig identity', () {
    expect(source.contains("import 'rig_support.dart'"), isTrue);
    expect(source.contains('startCleanRigApp'), isTrue);
    expect(source.contains('connectDemoRig'), isTrue);
    expect(source.contains('requireIsolatedRigIdentity'), isTrue);
    expect(source.contains('markTestSkipped'), isFalse);
  });

  test('the journey scans DTC then asserts readiness copy', () {
    expect(source.contains('DtcScreen'), isTrue);
    expect(source.contains('開始掃描'), isTrue);
    expect(source.contains('排放就緒狀態'), isTrue);
    expect(source.contains('Emissions readiness'), isTrue);
    expect(source.contains('locale_english'), isTrue);
    expect(source.contains('SettingsScreen'), isTrue);
    expect(source.contains('find.descendant'), isTrue);
    expect(source.contains('pumpUntil'), isTrue);
    final demoAt = source.indexOf('await connectDemoRig');
    final scanAt = source.indexOf('開始掃描');
    final readyAt = source.indexOf('排放就緒狀態');
    final englishAt = source.indexOf('locale_english');
    expect(demoAt, greaterThan(0));
    expect(scanAt, greaterThan(demoAt));
    expect(readyAt, greaterThan(scanAt));
    expect(englishAt, greaterThan(readyAt));
  });

  test('the journey does not replace ObdSession with a pre-solved mock', () {
    expect(source.contains('obdSessionProvider.overrideWith'), isFalse);
    expect(source.contains('_FastDemoSession'), isFalse);
    expect(source.contains('_IdleSession'), isFalse);
  });
}
