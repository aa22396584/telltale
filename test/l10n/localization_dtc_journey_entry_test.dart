// Keeps integration_test/localization_dtc_journey_test.dart honest as the
// #47 DTC bilingual device entry.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File(
    'integration_test/localization_dtc_journey_test.dart',
  ).readAsStringSync();

  test('the named DTC journey file exists and is not an empty stub', () {
    expect(source.length, greaterThan(400));
  });

  test('the journey fails closed without the isolated rig identity', () {
    expect(source.contains("import 'rig_support.dart'"), isTrue);
    expect(source.contains('startCleanRigApp'), isTrue);
    expect(source.contains('connectDemoRig'), isTrue);
    expect(source.contains('requireIsolatedRigIdentity'), isTrue);
    expect(source.contains('markTestSkipped'), isFalse);
  });

  test('the journey opens DTC then switches language', () {
    expect(source.contains('故障碼'), isTrue);
    expect(source.contains('Fault codes'), isTrue);
    expect(source.contains('locale_english'), isTrue);
    final demoAt = source.indexOf('connectDemoRig');
    final dtcAt = source.indexOf('故障碼');
    final englishAt = source.indexOf('locale_english');
    expect(demoAt, greaterThan(0));
    expect(dtcAt, greaterThan(demoAt));
    expect(englishAt, greaterThan(dtcAt));
  });

  test('the journey does not replace ObdSession with a pre-solved mock', () {
    expect(source.contains('obdSessionProvider.overrideWith'), isFalse);
    expect(source.contains('_FastDemoSession'), isFalse);
    expect(source.contains('_IdleSession'), isFalse);
  });
}
