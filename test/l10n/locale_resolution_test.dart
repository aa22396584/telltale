import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';

void main() {
  test('explicit English wins over device Chinese', () {
    expect(
      resolveAppLocale(
        preference: LocalePreference.english,
        deviceLocales: [
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        ],
      ),
      englishLocale,
    );
  });

  test('explicit Traditional Chinese wins over device English', () {
    expect(
      resolveAppLocale(
        preference: LocalePreference.traditionalChinese,
        deviceLocales: [const Locale('en', 'US')],
      ),
      traditionalChineseLocale,
    );
  });

  test('missing or corrupt stored preference becomes system', () {
    expect(localePreferenceFromStored(null), LocalePreference.system);
    expect(localePreferenceFromStored(1), LocalePreference.system);
    expect(localePreferenceFromStored(''), LocalePreference.system);
    expect(localePreferenceFromStored('zh_Hans'), LocalePreference.system);
    expect(localePreferenceFromStored('system'), LocalePreference.system);
    expect(localePreferenceFromStored('en'), LocalePreference.english);
    expect(
      localePreferenceFromStored('zh_Hant'),
      LocalePreference.traditionalChinese,
    );
  });

  test('system en-US and en-GB map to English', () {
    expect(
      resolveAppLocale(
        preference: LocalePreference.system,
        deviceLocales: [const Locale('en', 'US')],
      ),
      englishLocale,
    );
    expect(
      resolveAppLocale(
        preference: LocalePreference.system,
        deviceLocales: [const Locale('en', 'GB')],
      ),
      englishLocale,
    );
  });

  test('system zh-Hant and zh-Hant-TW map to Traditional Chinese', () {
    expect(
      mapDeviceLocale(
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      ),
      traditionalChineseLocale,
    );
    expect(
      mapDeviceLocale(
        const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'TW',
        ),
      ),
      traditionalChineseLocale,
    );
  });

  test('system zh-TW/HK/MO without script map to Traditional Chinese', () {
    expect(mapDeviceLocale(const Locale('zh', 'TW')), traditionalChineseLocale);
    expect(mapDeviceLocale(const Locale('zh', 'HK')), traditionalChineseLocale);
    expect(mapDeviceLocale(const Locale('zh', 'MO')), traditionalChineseLocale);
  });

  test('explicit zh-Hans is not dressed up as Traditional Chinese', () {
    expect(
      mapDeviceLocale(
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      ),
      isNull,
    );
    expect(
      mapDeviceLocale(
        const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
          countryCode: 'CN',
        ),
      ),
      isNull,
    );
    expect(
      resolveAppLocale(
        preference: LocalePreference.system,
        deviceLocales: [
          const Locale.fromSubtags(
            languageCode: 'zh',
            scriptCode: 'Hans',
            countryCode: 'CN',
          ),
        ],
      ),
      englishLocale,
    );
  });

  test('script beats a conflicting region (zh-Hans-TW stays Hans)', () {
    expect(
      mapDeviceLocale(
        const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
          countryCode: 'TW',
        ),
      ),
      isNull,
    );
  });

  test('generic zh with no script or region maps to Traditional Chinese', () {
    expect(mapDeviceLocale(const Locale('zh')), traditionalChineseLocale);
  });

  test('ja then en in the device list selects English', () {
    expect(
      resolveAppLocale(
        preference: LocalePreference.system,
        deviceLocales: [const Locale('ja'), const Locale('en', 'US')],
      ),
      englishLocale,
    );
  });

  test('empty device list is English', () {
    expect(
      resolveAppLocale(
        preference: LocalePreference.system,
        deviceLocales: const [],
      ),
      englishLocale,
    );
  });

  test('system preference is not replaced by the computed locale id', () {
    expect(localePreferenceToStored(LocalePreference.system), 'system');
    expect(localePreferenceFromStored('system'), LocalePreference.system);
  });
}
