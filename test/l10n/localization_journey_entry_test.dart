// Keeps integration_test/localization_journey_test.dart honest as the #47
// device entry. A missing file, a skip-without-device, or a mocked session
// would let `flutter test` stay green while the named journey does not exist.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File(
    'integration_test/localization_journey_test.dart',
  ).readAsStringSync();

  test('the named #47 journey file exists and is not an empty stub', () {
    expect(source.length, greaterThan(400));
  });

  test('the journey fails closed without the isolated rig identity', () {
    expect(source.contains("import 'rig_support.dart'"), isTrue);
    expect(source.contains('startCleanRigApp'), isTrue);
    expect(source.contains('requireIsolatedRigIdentity'), isTrue);
    expect(source.contains('markTestSkipped'), isFalse);
  });

  test('the journey switches language before connecting Demo', () {
    expect(source.contains('connect_language_entry'), isTrue);
    expect(source.contains('locale_english'), isTrue);
    expect(source.contains('locale_traditionalChinese'), isTrue);
    expect(source.contains('Choose a connection'), isTrue);
    expect(source.contains('選擇連線方式'), isTrue);
    expect(source.contains('connectDemoRig'), isTrue);
    expect(source.contains('Navigator.of'), isTrue);
    expect(source.contains('.pop()'), isTrue);
    final selectCall = source.indexOf('_selectLocale(tester');
    final demoCall = source.indexOf('connectDemoRig(tester');
    expect(selectCall, greaterThan(0));
    expect(demoCall, greaterThan(selectCall));
  });

  test('the journey does not replace ObdSession with a pre-solved mock', () {
    expect(source.contains('obdSessionProvider.overrideWith'), isFalse);
    expect(source.contains('_FastDemoSession'), isFalse);
    expect(source.contains('_IdleSession'), isFalse);
  });
}
