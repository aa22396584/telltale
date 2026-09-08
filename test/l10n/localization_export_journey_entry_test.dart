// Keeps integration_test/localization_export_journey_test.dart honest as the
// #47 Export bilingual device entry.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File('integration_test/localization_export_journey_test.dart')
      .readAsStringSync();

  test('the named Export journey file exists and is not an empty stub', () {
    expect(source.length, greaterThan(400));
  });

  test('the journey fails closed without the isolated rig identity', () {
    expect(source.contains("import 'rig_support.dart'"), isTrue);
    expect(source.contains('startCleanRigApp'), isTrue);
    expect(source.contains('connectDemoRig'), isTrue);
    expect(source.contains('requireIsolatedRigIdentity'), isTrue);
    expect(source.contains('markTestSkipped'), isFalse);
  });

  test('the journey records, opens Export, then switches language', () {
    expect(source.contains('telemetry-start'), isTrue);
    expect(source.contains('telemetry-stop'), isTrue);
    expect(source.contains('telemetry-history'), isTrue);
    expect(source.contains('telemetry-open-history'), isFalse);
    expect(source.contains('TelemetrySessionDetailScreen'), isTrue);
    expect(source.contains('TelemetryExportSheet'), isTrue);
    expect(source.contains('_leaveExportToShell'), isTrue);
    expect(source.contains('pumpUntil'), isTrue);
    expect(source.contains('匯出本機紀錄'), isTrue);
    expect(source.contains('Export a local recording'), isTrue);
    expect(source.contains('locale_english'), isTrue);
    expect(source.contains('SettingsScreen'), isTrue);
    expect(source.contains('find.descendant'), isTrue);
    final demoAt = source.indexOf('await connectDemoRig');
    final recordAt = source.indexOf('await _recordShortDemoSession');
    final exportAt = source.indexOf("matching: find.text('匯出本機紀錄')");
    final englishAt = source.indexOf('locale_english');
    expect(demoAt, greaterThan(0));
    expect(recordAt, greaterThan(demoAt));
    expect(exportAt, greaterThan(recordAt));
    expect(englishAt, greaterThan(exportAt));
  });

  test('the journey does not replace ObdSession with a pre-solved mock', () {
    expect(source.contains('obdSessionProvider.overrideWith'), isFalse);
    expect(source.contains('_FastDemoSession'), isFalse);
    expect(source.contains('_IdleSession'), isFalse);
  });
}
