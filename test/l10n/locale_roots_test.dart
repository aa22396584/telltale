import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/app.dart';
import 'package:torque_obd/core/form_factor.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/ui/wear/wear_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpTorqueApp(
    WidgetTester tester, {
    required Map<String, Object> prefs,
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final stored = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(stored)],
        child: const TorqueApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> expectLocalizedMaterialApps(
    WidgetTester tester,
    Locale expected,
  ) async {
    final apps = tester.widgetList<MaterialApp>(find.byType(MaterialApp));
    expect(apps, isNotEmpty);
    for (final app in apps) {
      expect(app.supportedLocales, containsAll(supportedAppLocales));
      expect(app.localizationsDelegates, contains(AppLocalizations.delegate));
      expect(app.locale, expected);
    }
  }

  testWidgets('watch root uses the same delegates and resolved locale', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    FormFactor.debugIsWatch = true;
    try {
      await pumpTorqueApp(tester, prefs: {kLocalePreferenceKey: 'en'});
      expect(find.byType(WearShell), findsOneWidget);
      await expectLocalizedMaterialApps(tester, englishLocale);
    } finally {
      FormFactor.debugIsWatch = false;
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('phone startup root is English when preference is en', (
    tester,
  ) async {
    await pumpTorqueApp(tester, prefs: {kLocalePreferenceKey: 'en'});
    await expectLocalizedMaterialApps(tester, englishLocale);
  });

  testWidgets(
    'phone startup root is Traditional Chinese when preference is zh_Hant',
    (tester) async {
      await pumpTorqueApp(tester, prefs: {kLocalePreferenceKey: 'zh_Hant'});
      await expectLocalizedMaterialApps(tester, traditionalChineseLocale);
      expect(find.textContaining('正在檢查'), findsWidgets);
    },
  );
}
