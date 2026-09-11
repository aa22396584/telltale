// Keeps integration_test/localization_pid_journey_test.dart honest as the
// #47 PID bilingual device entry.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File(
    'integration_test/localization_pid_journey_test.dart',
  ).readAsStringSync();

  test('the named PID journey file exists and is not an empty stub', () {
    expect(source.length, greaterThan(400));
  });

  test('the journey fails closed without the isolated rig identity', () {
    expect(source.contains("import 'rig_support.dart'"), isTrue);
    expect(source.contains('startCleanRigApp'), isTrue);
    expect(source.contains('connectDemoRig'), isTrue);
    expect(source.contains('requireIsolatedRigIdentity'), isTrue);
    expect(source.contains('markTestSkipped'), isFalse);
  });

  test('the journey opens PID then switches language', () {
    expect(source.contains('PID 管理'), isTrue);
    expect(source.contains('PID manager'), isTrue);
    expect(source.contains('PID-Manager'), isTrue);
    expect(source.contains('locale_english'), isTrue);
    expect(source.contains('locale_german'), isTrue);
    expect(source.contains('SettingsScreen'), isTrue);
    expect(source.contains('find.descendant'), isTrue);
    final demoAt = source.indexOf('connectDemoRig');
    final pidAt = source.indexOf('PID 管理');
    final englishAt = source.indexOf('locale_english');
    expect(demoAt, greaterThan(0));
    expect(pidAt, greaterThan(demoAt));
    expect(englishAt, greaterThan(pidAt));
  });

  test('the journey does not replace ObdSession with a pre-solved mock', () {
    expect(source.contains('obdSessionProvider.overrideWith'), isFalse);
    expect(source.contains('_FastDemoSession'), isFalse);
    expect(source.contains('_IdleSession'), isFalse);
  });
}
