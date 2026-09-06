// Makes the platform-locale pin in test/flutter_test_config.dart load-bearing.
//
// Most widget tests pump through localizedMaterialApp, which passes an explicit
// locale, so the pin does not decide their language and deleting it would not
// fail them. This file is the one place that resolves *through* the platform,
// which is what the pin actually governs — and what
// LocalePreference.system does in the shipped app.
//
// Without the pin, flutter_test hands over an empty locale list, resolveSystemLocale
// falls off the end of the loop and answers English, and this file fails. That is
// the point: a guard nobody can break is not a guard.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';

void main() {
  test('the test binding reports a platform locale at all', () {
    // An empty list is the default. If this is empty the pin is gone, and every
    // system-resolution assertion below would be answering a different question.
    expect(
      WidgetsBinding.instance.platformDispatcher.locales,
      isNotEmpty,
      reason:
          'test/flutter_test_config.dart no longer pins localesTestValue, so any '
          'test that resolves LocalePreference.system now depends on the host',
    );
  });

  test('system preference resolves through the platform to Traditional Chinese', () {
    expect(
      resolveSystemLocale(WidgetsBinding.instance.platformDispatcher.locales),
      traditionalChineseLocale,
    );
    expect(
      resolveAppLocale(
        preference: LocalePreference.system,
        deviceLocales: WidgetsBinding.instance.platformDispatcher.locales,
      ),
      traditionalChineseLocale,
    );
  });

  test('an explicit preference still overrides the platform', () {
    // The pin must not be able to mask a broken picker: choosing English has to
    // win over whatever the device reports.
    expect(
      resolveAppLocale(
        preference: LocalePreference.english,
        deviceLocales: WidgetsBinding.instance.platformDispatcher.locales,
      ),
      englishLocale,
    );
  });
}
