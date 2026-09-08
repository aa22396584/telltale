// Keeps integration_test/localization_freeze_journey_test.dart honest as the
// #47 freeze-frame bilingual device entry.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File('integration_test/localization_freeze_journey_test.dart')
      .readAsStringSync();

  test(
    'the named freeze-frame journey file exists and is not an empty stub',
    () {
      expect(source.length, greaterThan(400));
    },
  );

  test('the journey fails closed without the isolated rig identity', () {
    expect(source.contains("import 'rig_support.dart'"), isTrue);
    expect(source.contains('startCleanRigApp'), isTrue);
    expect(source.contains('connectDemoRig'), isTrue);
    expect(source.contains('requireIsolatedRigIdentity'), isTrue);
    expect(source.contains('markTestSkipped'), isFalse);
  });

  test('the journey scans DTC then asserts freeze-frame copy', () {
    expect(source.contains('DtcScreen'), isTrue);
    expect(source.contains('開始掃描'), isTrue);
    expect(source.contains('故障發生當下的車況'), isTrue);
    expect(source.contains('The vehicle at the moment of the fault'), isTrue);
    expect(source.contains('locale_english'), isTrue);
    expect(source.contains('SettingsScreen'), isTrue);
    expect(source.contains('find.descendant'), isTrue);
    expect(source.contains('pumpUntil'), isTrue);
    final demoAt = source.indexOf('await connectDemoRig');
    final scanAt = source.indexOf('開始掃描');
    final freezeAt = source.indexOf('故障發生當下的車況');
    final englishAt = source.indexOf('locale_english');
    expect(demoAt, greaterThan(0));
    expect(scanAt, greaterThan(demoAt));
    expect(freezeAt, greaterThan(scanAt));
    expect(englishAt, greaterThan(freezeAt));
  });

  test('the journey does not replace ObdSession with a pre-solved mock', () {
    expect(source.contains('obdSessionProvider.overrideWith'), isFalse);
    expect(source.contains('_FastDemoSession'), isFalse);
    expect(source.contains('_IdleSession'), isFalse);
  });
}
