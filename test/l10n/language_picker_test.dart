import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/l10n/generated/app_localizations_en.dart';
import 'package:torque_obd/state/language_switch_guard.dart';
import 'package:torque_obd/state/locale_settings.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/ui/screens/connect/connect_screen.dart';
import 'package:torque_obd/ui/screens/settings/settings_screen.dart';
import 'package:torque_obd/ui/widgets/language_picker.dart';

class _IdleSession extends ObdSession {
  int connects = 0;

  @override
  ObdConnectionState build() => const ObdConnectionState();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every option is named in its own language, and named once', () {
    // This picker is the way out for somebody who cannot read the screen they
    // are on, so a duplicate or empty label is not cosmetic: it is a row they
    // cannot identify. The exhaustive switch makes a missing case a compile
    // error; this makes a copy-pasted one a test failure.
    final labels = <LocalePreference, String>{
      for (final preference in LocalePreference.values)
        preference: localePreferenceLabel(preference),
    };
    for (final entry in labels.entries) {
      expect(
        entry.value.trim(),
        isNotEmpty,
        reason: '${entry.key} has no self-name',
      );
    }
    expect(
      labels.values.toSet(),
      hasLength(LocalePreference.values.length),
      reason: 'two options share a label: ${labels.values.join(", ")}',
    );
  });

  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  Widget host({
    required SharedPreferences prefs,
    required Widget home,
    required _IdleSession session,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        obdSessionProvider.overrideWith(_IdleSession.new),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final locale = resolveAppLocale(
            preference: ref.watch(localePreferenceProvider),
            deviceLocales: const [Locale('en', 'US')],
          );
          return MaterialApp(
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: home,
          );
        },
      ),
    );
  }

  testWidgets('Connect language entry works without a vehicle or adapter', (
    tester,
  ) async {
    final prefs = await prefsWith({});
    await tester.pumpWidget(
      host(prefs: prefs, home: const ConnectScreen(), session: _IdleSession()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Choose a connection'), findsOneWidget);
    expect(find.byKey(const Key('connect_language_entry')), findsOneWidget);

    await tester.tap(find.byKey(const Key('connect_language_entry')));
    await tester.pumpAndSettle();

    expect(find.text('English'), findsOneWidget);
    expect(find.text('繁體中文'), findsOneWidget);
    expect(find.text('Deutsch'), findsOneWidget);
    expect(find.text('System default / 跟隨系統'), findsOneWidget);

    await tester.tap(find.byKey(const Key('locale_traditionalChinese')));
    await tester.pumpAndSettle();

    expect(prefs.getString(kLocalePreferenceKey), 'zh_Hant');
    expect(find.text('選擇連線方式'), findsOneWidget);
    expect(find.text('Choose a connection'), findsNothing);
  });

  testWidgets('Settings picker switches back to English', (tester) async {
    final prefs = await prefsWith({kLocalePreferenceKey: 'zh_Hant'});
    await tester.pumpWidget(
      host(prefs: prefs, home: const SettingsScreen(), session: _IdleSession()),
    );
    await tester.pumpAndSettle();

    expect(find.text('設定'), findsWidgets);
    await tester.scrollUntilVisible(
      find.byKey(const Key('locale_english')),
      400,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await tester.tap(find.byKey(const Key('locale_english')));
    await tester.pumpAndSettle();

    expect(prefs.getString(kLocalePreferenceKey), 'en');
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('switching language does not start an OBD session', (
    tester,
  ) async {
    final prefs = await prefsWith({});
    final session = _IdleSession();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          obdSessionProvider.overrideWith(() => session),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final locale = resolveAppLocale(
              preference: ref.watch(localePreferenceProvider),
              deviceLocales: const [Locale('en')],
            );
            return MaterialApp(
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: const ConnectScreen(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('connect_language_entry')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('locale_traditionalChinese')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(session.connects, 0);
    expect(session.state.isConnected, isFalse);
    expect(session.state.isBusy, isFalse);
  });

  testWidgets('a dirty PID editor blocks the picker without writing prefs', (
    tester,
  ) async {
    final prefs = await prefsWith({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          languageSwitchBlockProvider.overrideWithValue(
            LanguageSwitchBlock.pidEditorDirty,
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: LanguagePicker()),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('locale_traditionalChinese')));
    await tester.pump();

    expect(
      find.text(AppLocalizationsEn().pidEditorDiscardBody),
      findsOneWidget,
    );
    expect(prefs.getString(kLocalePreferenceKey), isNull);
  });

  testWidgets('recording blocks the picker without writing prefs', (
    tester,
  ) async {
    final prefs = await prefsWith({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          languageSwitchBlockProvider.overrideWithValue(
            LanguageSwitchBlock.recording,
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: LanguagePicker()),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('locale_german')));
    await tester.pump();

    expect(
      find.text(AppLocalizationsEn().telemetryBlockedByRecorder),
      findsOneWidget,
    );
    expect(prefs.getString(kLocalePreferenceKey), isNull);
  });
}
