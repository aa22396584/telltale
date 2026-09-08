// Keeps integration_test/localization_history_journey_test.dart honest as the
// #47 History bilingual device entry.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File(
    'integration_test/localization_history_journey_test.dart',
  ).readAsStringSync();

  test('the named History journey file exists and is not an empty stub', () {
    expect(source.length, greaterThan(400));
  });

  test('the journey fails closed without the isolated rig identity', () {
    expect(source.contains("import 'rig_support.dart'"), isTrue);
    expect(source.contains('startCleanRigApp'), isTrue);
    expect(source.contains('connectDemoRig'), isTrue);
    expect(source.contains('requireIsolatedRigIdentity'), isTrue);
    expect(source.contains('markTestSkipped'), isFalse);
  });

  test('the journey opens History then switches language', () {
    expect(source.contains('本機紀錄'), isTrue);
    expect(source.contains('Local recordings'), isTrue);
    expect(source.contains('telemetry-history'), isTrue);
    expect(source.contains('telemetry-open-history'), isFalse);
    expect(source.contains('TelemetrySessionsScreen'), isTrue);
    expect(source.contains('find.descendant'), isTrue);
    expect(source.contains('.pop()'), isTrue);
    expect(source.contains('locale_english'), isTrue);
    expect(source.contains('SettingsScreen'), isTrue);
    final demoAt = source.indexOf('await connectDemoRig');
    final historyAt = source.indexOf('await _openHistory');
    final englishAt = source.indexOf('locale_english');
    expect(demoAt, greaterThan(0));
    expect(historyAt, greaterThan(demoAt));
    expect(englishAt, greaterThan(historyAt));
  });

  test('the journey does not replace ObdSession with a pre-solved mock', () {
    expect(source.contains('obdSessionProvider.overrideWith'), isFalse);
    expect(source.contains('_FastDemoSession'), isFalse);
    expect(source.contains('_IdleSession'), isFalse);
  });
}
