/// App locale preference and resolution. Pure functions — no Flutter widgets,
/// no OBD, no SharedPreferences.
///
/// Supported UI languages are English, Traditional Chinese and German.
/// Simplified Chinese is not a shipped translation; `zh-Hans` must not be
/// dressed up as 繁體中文.
///
/// German is a machine translation of the English template, corrected by hand
/// and reviewed against docs/i18n/do-not-translate.md, but not by a native
/// speaker reading it on a screen. docs/i18n/README.md records that difference,
/// because it is the difference between a sentence somebody stands behind and
/// one nobody has read in place.
library;

import 'package:flutter/widgets.dart';

enum LocalePreference { system, english, traditionalChinese, german }

const kLocalePreferenceKey = 'locale_preference_v1';

const englishLocale = Locale('en');
const traditionalChineseLocale = Locale.fromSubtags(
  languageCode: 'zh',
  scriptCode: 'Hant',
);
const germanLocale = Locale('de');

const supportedAppLocales = <Locale>[
  englishLocale,
  traditionalChineseLocale,
  germanLocale,
];

/// The stored ids are a format, not an implementation detail: they are written
/// to disk under [kLocalePreferenceKey] and read back by whatever build is
/// installed next. An id this build does not know — one written by a newer
/// build, then downgraded — falls back to [LocalePreference.system] rather than
/// throwing or resolving to some other language.
LocalePreference localePreferenceFromStored(Object? raw) {
  if (raw is! String) return LocalePreference.system;
  return switch (raw) {
    'en' => LocalePreference.english,
    'zh_Hant' => LocalePreference.traditionalChinese,
    'de' => LocalePreference.german,
    'system' => LocalePreference.system,
    _ => LocalePreference.system,
  };
}

String localePreferenceToStored(LocalePreference preference) {
  return switch (preference) {
    LocalePreference.system => 'system',
    LocalePreference.english => 'en',
    LocalePreference.traditionalChinese => 'zh_Hant',
    LocalePreference.german => 'de',
  };
}

/// Resolve the UI locale. An explicit preference wins. [system] walks
/// [deviceLocales] in order and never writes the computed result back.
Locale resolveAppLocale({
  required LocalePreference preference,
  required List<Locale> deviceLocales,
}) {
  return switch (preference) {
    LocalePreference.english => englishLocale,
    LocalePreference.traditionalChinese => traditionalChineseLocale,
    LocalePreference.german => germanLocale,
    LocalePreference.system => resolveSystemLocale(deviceLocales),
  };
}

Locale resolveSystemLocale(List<Locale> deviceLocales) {
  for (final locale in deviceLocales) {
    final mapped = mapDeviceLocale(locale);
    if (mapped != null) return mapped;
  }
  return englishLocale;
}

/// Returns a supported UI locale, or null to try the next device locale.
///
/// Script beats a conflicting region: `zh-Hans-TW` is still Hans.
Locale? mapDeviceLocale(Locale locale) {
  final language = locale.languageCode.toLowerCase();
  if (language == 'en') return englishLocale;
  // Region is deliberately ignored here: de-AT and de-CH read the one German
  // bundle this app ships. A regional variant is a later ARB, not a reason to
  // fall back to English.
  if (language == 'de') return germanLocale;
  if (language != 'zh') return null;

  final script = locale.scriptCode?.toLowerCase();
  if (script == 'hans') return null;
  if (script == 'hant') return traditionalChineseLocale;

  final country = locale.countryCode?.toUpperCase();
  if (country == 'TW' || country == 'HK' || country == 'MO') {
    return traditionalChineseLocale;
  }
  if (country == null || country.isEmpty) {
    // Generic `zh` with no script/region. This release maps it to 繁中.
    return traditionalChineseLocale;
  }
  // zh-CN / zh-SG / other regions without Hans/Hant: not a Traditional match.
  return null;
}
