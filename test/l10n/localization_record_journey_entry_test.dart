// Keeps integration_test/localization_record_journey_test.dart honest as the
// #47 recorder bilingual device entry.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File(
    'integration_test/localization_record_journey_test.dart',
  ).readAsStringSync();

  test('the named recorder journey file exists and is not an empty stub', () {
    expect(source.length, greaterThan(400));
  });

  test('the journey fails closed without the isolated rig identity', () {
    expect(source.contains("import 'rig_support.dart'"), isTrue);
    expect(source.contains('startCleanRigApp'), isTrue);
    expect(source.contains('connectDemoRig'), isTrue);
    expect(source.contains('requireIsolatedRigIdentity'), isTrue);
    expect(source.contains('markTestSkipped'), isFalse);
  });

  test('the journey shows recorder copy then switches language', () {
    expect(source.contains('開始紀錄'), isTrue);
    expect(source.contains('Start recording'), isTrue);
    expect(source.contains('locale_english'), isTrue);
    expect(source.contains('SettingsScreen'), isTrue);
    expect(source.contains('find.descendant'), isTrue);
    final demoAt = source.indexOf('connectDemoRig');
    final recordAt = source.indexOf('開始紀錄');
    final englishAt = source.indexOf('locale_english');
    expect(demoAt, greaterThan(0));
    expect(recordAt, greaterThan(demoAt));
    expect(englishAt, greaterThan(recordAt));
  });

  test('the journey does not replace ObdSession with a pre-solved mock', () {
    expect(source.contains('obdSessionProvider.overrideWith'), isFalse);
    expect(source.contains('_FastDemoSession'), isFalse);
    expect(source.contains('_IdleSession'), isFalse);
  });
}
