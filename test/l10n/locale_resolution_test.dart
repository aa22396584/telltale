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
    expect(localePreferenceFromStored('de'), LocalePreference.german);
  });

  test('every preference round-trips through the store', () {
    // The stored ids are a format: they sit on disk under kLocalePreferenceKey
    // while a build is replaced. A rename that touched only one direction would
    // strand somebody on the language they chose, and nothing else would notice.
    for (final preference in LocalePreference.values) {
      expect(
        localePreferenceFromStored(localePreferenceToStored(preference)),
        preference,
      );
    }
  });

  test('a stored id this build does not know is system, not a crash', () {
    // Downgrading is a real path: a preference written by a build that ships a
    // language this one does not must not throw, and must not be quietly read
    // as some other language.
    expect(localePreferenceFromStored('fr'), LocalePreference.system);
    expect(localePreferenceFromStored('de_AT'), LocalePreference.system);
  });

  test('explicit German wins over the device list', () {
    expect(
      resolveAppLocale(
        preference: LocalePreference.german,
        deviceLocales: [
          const Locale('en', 'US'),
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        ],
      ),
      germanLocale,
    );
  });

  test('regional German maps to the one German bundle', () {
    // Region is not a translation. de-AT and de-CH read the ARB this app ships;
    // a regional variant would be a later file, not a fall back to English.
    expect(mapDeviceLocale(const Locale('de')), germanLocale);
    expect(mapDeviceLocale(const Locale('de', 'DE')), germanLocale);
    expect(mapDeviceLocale(const Locale('de', 'AT')), germanLocale);
    expect(mapDeviceLocale(const Locale('de', 'CH')), germanLocale);
  });

  test('an unshipped language still falls through to the next device locale', () {
    expect(mapDeviceLocale(const Locale('fr')), isNull);
    expect(
      resolveAppLocale(
        preference: LocalePreference.system,
        deviceLocales: [const Locale('fr', 'FR'), const Locale('de', 'DE')],
      ),
      germanLocale,
    );
  });

  test('every preference resolves to a locale the app ships', () {
    for (final preference in LocalePreference.values) {
      expect(
        supportedAppLocales,
        contains(
          resolveAppLocale(preference: preference, deviceLocales: const []),
        ),
        reason: '$preference resolves outside supportedAppLocales',
      );
    }
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
