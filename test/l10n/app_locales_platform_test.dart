/// AppLocalesPlatform talks to LocaleManager; missing channel is not API 33.
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/core/app_locales_platform.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(kAppLocalesChannelName);

  void mock(Future<Object?> Function(MethodCall call)? handler) {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, handler);
  }

  tearDown(() => mock(null));

  test('an unregistered channel is unsupported, not English', () async {
    final snapshot = await AppLocalesPlatform.get();
    expect(snapshot.apiSupported, isFalse);
    expect(snapshot.followsSystem, isTrue);
    expect(snapshot.overrideTags, isEmpty);
  });

  test('empty override tags mean follow-system', () async {
    mock((call) async {
      expect(call.method, kAppLocalesGetMethod);
      return <String, Object?>{
        'apiSupported': true,
        'sdkInt': 36,
        'followsSystem': true,
        'overrideTags': <String>[],
        'configurationTags': <String>['en-US'],
      };
    });
    final snapshot = await AppLocalesPlatform.get();
    expect(snapshot.apiSupported, isTrue);
    expect(snapshot.followsSystem, isTrue);
    expect(snapshot.overrideTags, isEmpty);
    expect(snapshot.configurationTags, ['en-US']);
  });

  test('configuration tags are not treated as the override', () async {
    mock((call) async {
      return <String, Object?>{
        'apiSupported': true,
        'sdkInt': 36,
        'followsSystem': false,
        'overrideTags': <String>['zh-Hant'],
        'configurationTags': <String>['zh-Hant-TW'],
      };
    });
    final snapshot = await AppLocalesPlatform.get();
    expect(snapshot.followsSystem, isFalse);
    expect(snapshot.overrideTags, ['zh-Hant']);
    expect(snapshot.configurationTags, ['zh-Hant-TW']);
    expect(snapshot.overrideTags, isNot(snapshot.configurationTags));
  });

  test('set sends tags and an empty list is follow-system', () async {
    List<Object?>? seen;
    mock((call) async {
      expect(call.method, kAppLocalesSetMethod);
      seen = (call.arguments as Map)['tags'] as List<Object?>?;
      return <String, Object?>{
        'apiSupported': true,
        'sdkInt': 36,
        'followsSystem': seen!.isEmpty,
        'overrideTags': seen!.cast<String>(),
        'configurationTags': <String>[],
      };
    });
    final cleared = await AppLocalesPlatform.setOverrideTags(const []);
    expect(seen, isEmpty);
    expect(cleared!.followsSystem, isTrue);
    final german = await AppLocalesPlatform.setOverrideTags(const ['de']);
    expect(seen, ['de']);
    expect(german!.overrideTags, ['de']);
  });

  test('a rejected tag list is null, not follow-system', () async {
    mock((call) async {
      throw PlatformException(code: 'unsupported_locale');
    });
    expect(await AppLocalesPlatform.setOverrideTags(const ['ja']), isNull);
  });

  test('MainActivity registers get/set on the app_locales channel', () {
    final android = File(
      'android/app/src/main/kotlin/com/cbstudio/telltale/MainActivity.kt',
    ).readAsStringSync();
    expect(android, contains('APP_LOCALES_CHANNEL'));
    expect(android, contains('com.cbstudio.telltale/app_locales'));
    expect(android, contains('"getAppLocales"'));
    expect(android, contains('"setAppLocales"'));
    expect(android, contains('LocaleManager'));
    expect(android, contains('applicationLocales'));
    expect(android, contains('LocaleList.getEmptyLocaleList()'));
    expect(android, isNot(contains('Locale.getDefault()')));
  });
}
