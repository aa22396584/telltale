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
    final exportAt = source.indexOf("_expectSheetTitle(tester, '匯出本機紀錄')");
    final englishAt = source.indexOf('locale_english');
    expect(demoAt, greaterThan(0));
    expect(recordAt, greaterThan(demoAt));
    expect(exportAt, greaterThan(recordAt));
    expect(englishAt, greaterThan(exportAt));
  });

  test('the journey exports a file and reopens that exact session', () {
    expect(source.contains('_openFirstRecording'), isFalse);
    expect(source.contains('find.byType(ListTile).first'), isFalse);
    expect(source.contains('_openExactRecording'), isTrue);
    expect(source.contains('progress.sessionId'), isTrue);
    expect(source.contains('detail.sessionId'), isTrue);
    expect(source.contains('rigShareCaptureDirectory'), isTrue);
    expect(source.contains('decodeHeaderObject'), isTrue);
    expect(source.contains('decodeEventObject'), isTrue);
    expect(source.contains('decodeFooterObject'), isTrue);
    expect(source.contains("tapExportFormat(tester, '匯出 JSON')"), isTrue);
    expect(source.contains("tapExportFormat(tester, '匯出 CSV')"), isTrue);
    expect(source.contains("tapExportFormat(tester, 'Export JSON')"), isTrue);
    expect(source.contains('TelemetrySource.demo'), isTrue);
    expect(source.contains('jsonDecode'), isTrue);
    expect(source.contains('Navigator.of'), isTrue);
    expect(source.contains('not proof that an OS share chooser'), isTrue);
    final cancelAt = source.indexOf(
      'expect(await _capturePaths(captureRoot), isEmpty)',
    );
    final jsonAt = source.indexOf("tapExportFormat(tester, '匯出 JSON')");
    final csvAt = source.indexOf("tapExportFormat(tester, '匯出 CSV')");
    final englishAt = source.indexOf('locale_english');
    final englishJsonAt = source.indexOf(
      "tapExportFormat(tester, 'Export JSON')",
    );
    expect(cancelAt, greaterThan(0));
    expect(jsonAt, greaterThan(cancelAt));
    expect(csvAt, greaterThan(jsonAt));
    expect(englishAt, greaterThan(csvAt));
    expect(englishJsonAt, greaterThan(englishAt));
  });

  test('the journey does not replace ObdSession with a pre-solved mock', () {
    expect(source.contains('obdSessionProvider.overrideWith'), isFalse);
    expect(source.contains('_FastDemoSession'), isFalse);
    expect(source.contains('_IdleSession'), isFalse);
  });
}
