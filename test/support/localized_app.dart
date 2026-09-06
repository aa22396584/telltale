import 'package:flutter/material.dart';
import 'package:torque_obd/core/theme/app_theme.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';

/// Traditional Chinese, matching the copy existing widget tests assert.
const testUiLocale = Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');

Widget localizedMaterialApp({
  required Widget home,
  ThemeData? theme,
  Locale locale = testUiLocale,
}) {
  return MaterialApp(
    theme: theme ?? AppTheme.dark(),
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: home,
  );
}

Widget localizedMaterialAppRouter({
  required RouterConfig<Object> routerConfig,
  ThemeData? theme,
  Locale locale = testUiLocale,
}) {
  return MaterialApp.router(
    theme: theme ?? AppTheme.dark(),
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    routerConfig: routerConfig,
  );
}
