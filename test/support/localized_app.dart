import 'package:flutter/material.dart';
import 'package:torque_obd/core/theme/app_theme.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';

/// Traditional Chinese, matching the copy existing widget tests assert.
const testUiLocale = Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');

/// A `MaterialApp` that carries the app's localization delegates.
///
/// Widget tests must not pump a bare `MaterialApp`. `l10n.yaml` sets
/// `nullable-getter: false`, so the generated `AppLocalizations.of(context)`
/// ends in `!` — under a bare `MaterialApp` the delegate is absent and the
/// screen *throws* rather than falling back. That failure appears the moment a
/// screen reads its first localized string, which makes it look like the new
/// string broke the test rather than the missing delegate. Routing every pump
/// through here keeps the two apart.
Widget localizedMaterialApp({
  required Widget home,
  ThemeData? theme,
  Locale locale = testUiLocale,
  TransitionBuilder? builder,
  String? title,
}) {
  return MaterialApp(
    theme: theme ?? AppTheme.dark(),
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: builder,
    title: title ?? '',
    home: home,
  );
}

Widget localizedMaterialAppRouter({
  required RouterConfig<Object> routerConfig,
  ThemeData? theme,
  Locale locale = testUiLocale,
  TransitionBuilder? builder,
  String? title,
}) {
  return MaterialApp.router(
    theme: theme ?? AppTheme.dark(),
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: builder,
    title: title ?? '',
    routerConfig: routerConfig,
  );
}
