// Keeps integration_test/localization_disconnect_journey_test.dart honest as
// the #47 Disconnect bilingual device entry.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File(
    'integration_test/localization_disconnect_journey_test.dart',
  ).readAsStringSync();

  test('the named Disconnect journey file exists and is not an empty stub', () {
    expect(source.length, greaterThan(400));
  });

  test('the journey fails closed without the isolated rig identity', () {
    expect(source.contains("import 'rig_support.dart'"), isTrue);
    expect(source.contains('startCleanRigApp'), isTrue);
    expect(source.contains('connectDemoRig'), isTrue);
    expect(source.contains('requireIsolatedRigIdentity'), isTrue);
    expect(source.contains('markTestSkipped'), isFalse);
  });

  test('the journey opens Settings disconnect then switches language', () {
    expect(source.contains('SettingsScreen'), isTrue);
    expect(source.contains('中斷連線'), isTrue);
    expect(source.contains('Disconnect'), isTrue);
    expect(source.contains('locale_english'), isTrue);
    expect(source.contains('find.descendant'), isTrue);
    expect(source.contains('pumpUntil'), isTrue);
    expect(source.contains('scrollUntilVisible'), isTrue);
    expect(source.contains('-400'), isTrue);
    final demoAt = source.indexOf('await connectDemoRig');
    final settingsAt = source.indexOf("await _tapNav(tester, '設定')");
    final chineseAt = source.indexOf("中斷連線");
    final englishAt = source.indexOf('locale_english');
    final scrollBackAt = source.indexOf('-400');
    expect(demoAt, greaterThan(0));
    expect(settingsAt, greaterThan(demoAt));
    expect(chineseAt, greaterThan(settingsAt));
    expect(englishAt, greaterThan(chineseAt));
    expect(scrollBackAt, greaterThan(englishAt));
  });

  test('the journey does not replace ObdSession with a pre-solved mock', () {
    expect(source.contains('obdSessionProvider.overrideWith'), isFalse);
    expect(source.contains('_FastDemoSession'), isFalse);
    expect(source.contains('_IdleSession'), isFalse);
  });
}
