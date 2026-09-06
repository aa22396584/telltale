import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/app.dart';
import 'package:torque_obd/core/form_factor.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/l10n/startup_copy.dart';
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
    },
  );

  test('retryable startup title is not the in-progress loading copy', () {
    final en = lookupAppLocalizations(englishLocale);
    final zh = lookupAppLocalizations(traditionalChineseLocale);

    expect(en.startupCannotComplete, 'Cannot finish startup checks');
    expect(en.startupCannotComplete, isNot(en.startupChecking));
    expect(zh.startupCannotComplete, '目前無法完成啟動檢查');
    expect(zh.startupCannotComplete, isNot(zh.startupChecking));

    expect(
      startupStatusTitle(l10n: en, loading: true, restartRequired: false),
      en.startupChecking,
    );
    expect(
      startupStatusTitle(l10n: en, loading: false, restartRequired: true),
      en.startupRestartRequired,
    );
    expect(
      startupStatusTitle(l10n: en, loading: false, restartRequired: false),
      en.startupCannotComplete,
    );
    expect(
      startupStatusTitle(l10n: zh, loading: false, restartRequired: false),
      '目前無法完成啟動檢查',
    );
    expect(
      startupStatusTitle(l10n: zh, loading: true, restartRequired: false),
      zh.startupChecking,
    );
  });

  testWidgets('retryable startup title renders the failure copy, not loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: englishLocale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) {
            return Text(
              startupStatusTitle(
                l10n: AppLocalizations.of(context),
                loading: false,
                restartRequired: false,
              ),
            );
          },
        ),
      ),
    );
    expect(find.text('Cannot finish startup checks'), findsOneWidget);
    expect(
      find.text('Checking local share cache and telemetry records'),
      findsNothing,
    );
  });
}
