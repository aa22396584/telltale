// Keeps integration_test/localization_replay_journey_test.dart honest as the
// #47 Replay bilingual device entry.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File(
    'integration_test/localization_replay_journey_test.dart',
  ).readAsStringSync();

  test('the named Replay journey file exists and is not an empty stub', () {
    expect(source.length, greaterThan(400));
  });

  test('the journey fails closed without the isolated rig identity', () {
    expect(source.contains("import 'rig_support.dart'"), isTrue);
    expect(source.contains('startCleanRigApp'), isTrue);
    expect(source.contains('connectDemoRig'), isTrue);
    expect(source.contains('requireIsolatedRigIdentity'), isTrue);
    expect(source.contains('markTestSkipped'), isFalse);
  });

  test('the journey records, opens Replay, then switches language', () {
    expect(source.contains('telemetry-start'), isTrue);
    expect(source.contains('telemetry-stop'), isTrue);
    expect(source.contains('telemetry-history'), isTrue);
    expect(source.contains('telemetry-open-history'), isFalse);
    expect(source.contains('TelemetrySessionDetailScreen'), isTrue);
    expect(source.contains('紀錄回放'), isTrue);
    expect(source.contains('Recording replay'), isTrue);
    expect(source.contains('locale_english'), isTrue);
    expect(source.contains('SettingsScreen'), isTrue);
    expect(source.contains('find.descendant'), isTrue);
    final demoAt = source.indexOf('await connectDemoRig');
    final recordAt = source.indexOf('await _recordShortDemoSession');
    final replayAt = source.indexOf("matching: find.text('紀錄回放')");
    final englishAt = source.indexOf('locale_english');
    expect(demoAt, greaterThan(0));
    expect(recordAt, greaterThan(demoAt));
    expect(replayAt, greaterThan(recordAt));
    expect(englishAt, greaterThan(replayAt));
  });

  test('the journey does not replace ObdSession with a pre-solved mock', () {
    expect(source.contains('obdSessionProvider.overrideWith'), isFalse);
    expect(source.contains('_FastDemoSession'), isFalse);
    expect(source.contains('_IdleSession'), isFalse);
  });
}
