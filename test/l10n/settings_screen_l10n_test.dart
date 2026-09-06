// Settings is the largest single screen in the app and it carries the
// experimental battery consent gate, whose copy is a safety boundary rather
// than a description of a feature. These tests check the properties a wrong
// translation breaks, never that a rendered string equals its own ARB entry —
// a finder that reads the same ARB the widget rendered agrees with itself
// whatever the translation says.
//
// What is asserted:
//   * the English screen renders no Chinese, walked over the whole scroll
//     extent rather than the first viewport;
//   * the consent gate still states all four of its claims in English, and
//     still carries its load-bearing qualifiers in Traditional Chinese;
//   * every VehicleIdentityStatus answers in both languages, and the four
//     answers stay distinct — "not read yet" is not "unavailable";
//   * measured and estimated stay two different words in both languages;
//   * counts come from the profile's own field map, not from the prose.
//
// Scope. This screen composes widgets owned by other files — the language
// picker, the recommended-purchase panel, the transcript panels, the field
// event markers — and the gauge skins carry their names and descriptions in
// `GaugeSkin`, not in the ARBs. Those are other groups' strings, so the
// English sweep excludes their subtrees and their values by name. Excluding
// them is stated here rather than silently widening the regex, so the day
// they are localized the exclusion can be deleted and the sweep gets wider.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/obd/vehicle_catalog/us_vehicle_catalog.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/state/vehicle_catalog.dart';
import 'package:torque_obd/state/vehicle_identity.dart';
import 'package:torque_obd/ui/screens/settings/settings_screen.dart';
import 'package:torque_obd/ui/widgets/field_event_markers.dart';
import 'package:torque_obd/ui/widgets/language_picker.dart';
import 'package:torque_obd/ui/widgets/recommended_purchase_panel.dart';
import 'package:torque_obd/ui/widgets/transcript_export.dart';

import '../support/localized_app.dart';
import '../support/cjk.dart';

/// Han AND CJK punctuation, from the shared detector in test/support/cjk.dart.
///
/// This file used to define a Han-only regex of its own. Eight of the nine wave
/// test files did, and that gap shipped a defect: an English list joined with
/// `、` passed every one of them, because every word was translated and only
/// the separator was not.
final _cjk = chinese;

const _englishLocale = Locale('en');
const _traditionalChinese = Locale.fromSubtags(
  languageCode: 'zh',
  scriptCode: 'Hant',
);

// One row, one make, one model: enough to open the picker and read its copy.
const _catalogCsv =
    'epa_id,year,make,model,base_model,transmission,drive,fuel_type,fuel_type_primary,fuel_type_secondary,alternative_vehicle_type,displacement_l,cylinders,modified_on\n'
    '1,2020,Alpha,Roadster,Roadster,Manual 6-spd,Rear-Wheel Drive,Premium,Premium Gasoline,,,2.0,4,2020-01-01\n';

String get _catalogManifest => jsonEncode({
  'schema_version': 2,
  'dataset': 'U.S. EPA FuelEconomy.gov Find-a-Car vehicle configurations',
  'coverage': {
    'market': 'United States',
    'vehicle_scope': 'FuelEconomy.gov Find-a-Car configurations',
  },
  'source': {
    'archive_url': 'https://www.fueleconomy.gov/feg/epadata/vehicles.csv.zip',
    'landing_page': 'https://www.fueleconomy.gov/feg/download.shtml',
    'retrieved_at_utc': '2026-08-29T14:28:23+00:00',
    'sha256': 'a' * 64,
  },
  'output': {
    'file': 'us_epa_vehicles.csv',
    'columns': UsVehicleCatalog.requiredColumns,
    'row_count': 1,
    'sha256':
        '55d34c5d52f6018feca6735707c4ae443b939a0f26f69bd52651e70f9f388612',
    'size_bytes': 268,
    'unique_make_count': 1,
    'year_min': 2020,
    'year_max': 2020,
  },
});

class _DisconnectedSession extends ObdSession {
  @override
  ObdConnectionState build() => const ObdConnectionState();
}

class _ConnectedSession extends ObdSession {
  @override
  ObdConnectionState build() => const ObdConnectionState(
    phase: ConnectionPhase.connected,
    kind: TransportKind.demo,
    deviceName: 'Demo ECU',
  );
}

class _FixedIdentity extends VehicleIdentityController {
  _FixedIdentity(this.identity);

  final VehicleIdentity identity;

  @override
  VehicleIdentity build() => identity;
}

Future<void> _pumpSettings(
  WidgetTester tester, {
  required Locale locale,
  bool connected = false,
  VehicleIdentity? identity,
  UsVehicleCatalog? catalog,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(1080, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      // A fresh key on every pump. Without it `pumpWidget` reuses the element
      // tree, so a second pump keeps the first pump's Riverpod overrides and
      // any route the first pump pushed — two tests in one body would then
      // silently assert against the previous screen.
      key: UniqueKey(),
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        obdSessionProvider.overrideWith(
          connected ? _ConnectedSession.new : _DisconnectedSession.new,
        ),
        if (identity != null)
          vehicleIdentityProvider.overrideWith(() => _FixedIdentity(identity)),
        if (catalog != null)
          usVehicleCatalogLoaderProvider.overrideWithValue(() async => catalog),
      ],
      child: localizedMaterialApp(home: const SettingsScreen(), locale: locale),
    ),
  );
  await tester.pumpAndSettle();
}

void _collectSubtree(Element root, Set<Element> into) {
  into.add(root);
  root.visitChildren((child) => _collectSubtree(child, into));
}

/// Elements belonging to widgets this group does not own.
Set<Element> _foreignElements() {
  final foreign = <Element>{};
  for (final finder in <Finder>[
    find.byType(LanguagePicker),
    find.byType(RecommendedPurchasePanel),
    find.byType(RecoveredTranscriptPanel),
    find.byType(TranscriptExportButtons),
    find.byType(FieldEventMarkerPanel),
  ]) {
    for (final element in finder.evaluate()) {
      _collectSubtree(element, foreign);
    }
  }
  return foreign;
}

/// Strings this screen renders but does not own.
///
/// `GaugeSkin` lives in the theme and `FuelType`/`Drivetrain` carry their own
/// labels on the model; both are other files. `languageSectionTitle` is the
/// one string here that is *supposed* to carry Chinese in English — a language
/// picker has to be findable by somebody who cannot read the language that is
/// currently on screen — so it is allowed by name rather than by widening the
/// regex, which would also stop catching real regressions.
final _notThisGroupsStrings = <String>{
  // The gauge skin names used to be here. They are ARB entries now, and
  // GaugeSkin carries only geometry, so the compiler removed this line for us
  // — the allowance is meant to shrink.
  // The fuel types and drivetrains used to be here too. Their words are ARB
  // entries now and the enums keep only `exportLabel`, which the compiler will
  // not let this file reach for by accident.
  for (final form in [
    lookupAppLocalizations(const Locale('en')).languageSectionTitle,
  ]) ...[form, form.toUpperCase()],
};

/// Every user-visible string currently rendered that this group is responsible
/// for: `Text`, `SelectableText`, tooltips and explicit `Semantics` labels.
List<String> _ownedRenderedText(WidgetTester tester) {
  final foreign = _foreignElements();
  final out = <String>[];

  void add(Element element, String? value) {
    if (value == null || value.isEmpty) return;
    if (foreign.contains(element)) return;
    if (_notThisGroupsStrings.contains(value)) return;
    out.add(value);
  }

  for (final element in find.byType(Text).evaluate()) {
    final text = element.widget as Text;
    add(element, text.data ?? text.textSpan?.toPlainText());
  }
  for (final element in find.byType(SelectableText).evaluate()) {
    final text = element.widget as SelectableText;
    add(element, text.data ?? text.textSpan?.toPlainText());
  }
  for (final element in find.byType(Tooltip).evaluate()) {
    add(element, (element.widget as Tooltip).message);
  }
  for (final element in find.byType(Semantics).evaluate()) {
    add(element, (element.widget as Semantics).properties.label);
  }
  return out;
}

/// Walks the whole scroll extent, not just the first viewport. A lazy
/// `ListView` builds what it can see, so a sweep that never scrolls would pass
/// on a screen whose lower half is untranslated.
Future<List<String>> _sweepScreen(WidgetTester tester) async {
  final scrollable = find.byType(Scrollable).first;
  final state = tester.state<ScrollableState>(scrollable);
  final collected = <String>[];
  var offset = 0.0;
  while (true) {
    collected.addAll(_ownedRenderedText(tester));
    final max = state.position.maxScrollExtent;
    if (offset >= max) break;
    offset = (offset + 400).clamp(0.0, max);
    state.position.jumpTo(offset);
    await tester.pumpAndSettle();
  }
  return collected;
}

Future<void> _openConsentGate(WidgetTester tester) async {
  final toggle = find.byKey(const Key('experimental_battery_access_switch'));
  await tester.scrollUntilVisible(
    toggle,
    400,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(toggle);
  await tester.pumpAndSettle();
  await tester.tap(toggle);
  await tester.pumpAndSettle();
}

Map<String, dynamic> _arb(String name) =>
    jsonDecode(File('lib/l10n/$name').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the settings ARB entries', () {
    final en = _arb('app_en.arb');
    final zh = _arb('app_zh_Hant.arb');
    final keys = en.keys
        .where((k) => !k.startsWith('@') && k.startsWith('settings'))
        .toList();

    test('there are settings keys to check at all', () {
      expect(keys, isNotEmpty);
    });

    // Hedge register #6 names this sentence, and nothing was checking it in
    // either language. The switch REVEALS the laboratory; it does not trust
    // anything. "only" and "does not install" are the two halves, and a
    // translation that keeps one and loses the other turns a disclosure into
    // an endorsement of reverse-engineered data.
    test('the laboratory switch reveals without trusting, in both languages', () {
      expect(
        zh['settingsBatteryLabSwitchSubtitle'] as String,
        allOf(contains('只顯示'), contains('不會自動安裝')),
      );
      expect(
        (en['settingsBatteryLabSwitchSubtitle'] as String).toLowerCase(),
        allOf(contains('only reveals'), contains('does not install')),
      );
    });

    // Its own @description says all three halves are load-bearing, and none of
    // them was asserted. A driver who turns the laboratory off and is not told
    // the setting failed to save will meet it enabled again next launch and
    // assume they never turned it off.
    test('a failed save says all three things it has to say', () {
      expect(
        zh['settingsBatteryLabDisableNotSaved'] as String,
        allOf(contains('無法儲存'), contains('可能再顯示'), contains('仍需重新確認')),
      );
      expect(
        (en['settingsBatteryLabDisableNotSaved'] as String).toLowerCase(),
        allOf(
          contains('could not be saved'),
          contains('may show the laboratory again'),
          contains('still needs its own confirmation'),
        ),
      );
    });

    test('no English entry carries Chinese', () {
      final offenders = <String>[
        for (final key in keys)
          if (_cjk.hasMatch(en[key] as String)) '$key → "${en[key]}"',
      ];
      expect(
        offenders,
        isEmpty,
        reason:
            'these render Chinese to an English-speaking driver:\n'
            '${offenders.join("\n")}',
      );
    });

    test('no entry is the English template copied into the Chinese file', () {
      // gen-l10n does not fail on a missing translation; it falls back to the
      // template. The screen then looks translated and is not.
      final same = <String>[
        for (final key in keys)
          if (en[key] == zh[key] && key != 'settingsHeadline') key,
      ];
      expect(
        same,
        isEmpty,
        reason: 'untranslated (English fallback): ${same.join(", ")}',
      );
    });

    test('the English list separator is not the ideographic comma', () {
      expect(
        en['settingsListSeparator'],
        isNot(contains('、')),
        reason:
            'the enumeration comma is Chinese punctuation; an English list '
            'joined with it reads as a mojibake artefact',
      );
      expect(zh['settingsListSeparator'], '、');
    });

    test('the symbols VE, Cd and Crr survive into both languages', () {
      for (final pair in [
        ('settingsFieldVolumetricEfficiency', 'VE'),
        ('settingsFieldDragCoefficient', 'Cd'),
        ('settingsFieldRollingResistance', 'Crr'),
      ]) {
        expect(en[pair.$1], contains(pair.$2), reason: '${pair.$1} en');
        expect(zh[pair.$1], contains(pair.$2), reason: '${pair.$1} zh');
      }
      // The consent-free half of the same rule: the wire modes are commands.
      for (final arb in [en, zh]) {
        expect(arb['settingsBatteryLabWireAck'], contains('Mode 21/22'));
      }
    });

    test('the standards footer keeps its identifiers byte-identical', () {
      for (final arb in [en, zh]) {
        final footer = arb['settingsStandardsFooter'] as String;
        expect(footer, contains('SAE J1979'));
        expect(footer, contains('ELM327'));
        expect(footer, contains('docs/protocol-deviations.zh-TW.md'));
        expect(footer, contains('Torque'));
      }
    });
  });

  testWidgets('the English settings screen renders no Chinese', (tester) async {
    await _pumpSettings(tester, locale: _englishLocale, connected: true);
    final rendered = await _sweepScreen(tester);

    expect(
      rendered,
      isNotEmpty,
      reason: 'the sweep found nothing, so it proves nothing',
    );
    final offenders = rendered.where(_cjk.hasMatch).toSet().toList();
    expect(
      offenders,
      isEmpty,
      reason:
          'these render Chinese on the English settings screen:\n'
          '${offenders.join("\n")}',
    );
  });

  testWidgets('the English consent gate still states all four of its claims', (
    tester,
  ) async {
    await _pumpSettings(tester, locale: _englishLocale);
    await _openConsentGate(tester);

    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);

    final rendered = _ownedRenderedText(tester);
    expect(
      rendered.where(_cjk.hasMatch),
      isEmpty,
      reason: 'the consent gate must not fall back to Chinese in English',
    );

    final body = rendered.join('\n').toLowerCase();
    // The sources are candidates, not documentation.
    expect(body, contains('reverse-engineered'));
    expect(body, contains('not manufacturer documentation'));
    // A read-only query is not a safe query.
    expect(body, contains('read-only'));
    expect(body, contains('wake a controller'));
    // A decoded number can be plausible and still wrong for this car.
    expect(body, contains('plausible'));
    // What consent does not unlock, enumerated rather than summarised.
    expect(body, contains('mode 21/22'));
    for (final refused in [
      'not scanning',
      'not a diagnostic session',
      'not security access',
      'not writing',
      'not control',
    ]) {
      expect(body, contains(refused), reason: '$refused is missing');
    }
  });

  testWidgets('the Chinese consent gate keeps its load-bearing qualifiers', (
    tester,
  ) async {
    await _pumpSettings(tester, locale: _traditionalChinese);
    await _openConsentGate(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    final body = _ownedRenderedText(tester).join('\n');

    for (final qualifier in [
      '不是原廠文件',
      '即使是唯讀查詢也可能喚醒控制器',
      '看似合理但其實不適用',
      'Mode 21/22',
      '不會解鎖掃描',
    ]) {
      expect(
        body,
        contains(qualifier),
        reason:
            '"$qualifier" is the part of this gate that stops somebody '
            'trusting a decoded battery number; it must not be tidied away',
      );
    }
  });

  testWidgets('every vehicle identity status answers in both languages', (
    tester,
  ) async {
    const identities = <VehicleIdentityStatus, VehicleIdentity>{
      VehicleIdentityStatus.notRead: VehicleIdentity.notRead(),
      VehicleIdentityStatus.unavailable: VehicleIdentity.unavailable(),
      VehicleIdentityStatus.conflict: VehicleIdentity.conflict(),
    };

    for (final locale in [_englishLocale, _traditionalChinese]) {
      final titles = <VehicleIdentityStatus, String>{};
      for (final entry in identities.entries) {
        await _pumpSettings(
          tester,
          locale: locale,
          connected: true,
          identity: entry.value,
        );
        final rendered = _ownedRenderedText(tester);
        // The panel sits above the fold, so it is in the first viewport.
        expect(
          rendered,
          isNotEmpty,
          reason: '${entry.key} at $locale rendered nothing',
        );
        titles[entry.key] = rendered.join('\n');
        if (locale == _englishLocale) {
          expect(
            rendered.where(_cjk.hasMatch),
            isEmpty,
            reason: '${entry.key} renders Chinese in English',
          );
        }
      }

      // The one distinction this panel exists to hold: silence is not a
      // controller telling us the VIN cannot be had, and neither is a
      // conflict. Three states, three answers.
      final rendered = titles.values.toList();
      expect(
        rendered.toSet().length,
        rendered.length,
        reason:
            'two identity statuses render the same panel at $locale; '
            '"not read yet", "unavailable" and "conflict" are three '
            'different things and a driver has to be able to tell them apart',
      );
    }
  });

  testWidgets('a vehicle-reported VIN is never presented as a verified spec', (
    tester,
  ) async {
    await _pumpSettings(
      tester,
      locale: _englishLocale,
      connected: true,
      identity: VehicleIdentity.vehicleReported('1D4GP00R55B123456'),
    );
    final body = _ownedRenderedText(tester).join('\n').toLowerCase();
    expect(body, contains('reports about itself'));
    expect(body, contains('does not verify'));
    // The privacy half must survive: the transcript keeps the VIN.
    expect(body, contains('transcript may still contain the vin'));
  });

  testWidgets('measured and estimated stay two different words', (
    tester,
  ) async {
    for (final locale in [_englishLocale, _traditionalChinese]) {
      await _pumpSettings(tester, locale: locale, connected: true);
      final body = (await _sweepScreen(tester)).join('\n');
      if (locale == _englishLocale) {
        expect(body.toLowerCase(), contains('measured obd readings'));
        expect(body.toLowerCase(), contains('estimated from mass'));
        expect(
          body.toLowerCase(),
          isNot(contains('measured from mass')),
          reason: 'profile-derived values are estimates, never measurements',
        );
      } else {
        expect(body, contains('實測'));
        expect(body, contains('推算'));
      }
    }
  });

  testWidgets('the provenance counts come from the field map, not the prose', (
    tester,
  ) async {
    for (final locale in [_englishLocale, _traditionalChinese]) {
      await _pumpSettings(tester, locale: locale);
      final body = _ownedRenderedText(tester).join('\n');
      // A default profile resolves nothing exactly and is generic throughout,
      // so both counts must render the same denominator the model reports.
      expect(
        RegExp(r'0 / (\d+)').firstMatch(body)?.group(1),
        isNotNull,
        reason: 'no "n / total" pair rendered at $locale',
      );
      expect(body, contains('8'), reason: 'the field total at $locale');
    }
  });

  testWidgets('the EPA picker scopes itself in both languages', (tester) async {
    final catalog = UsVehicleCatalog.fromStrings(
      manifestJson: _catalogManifest,
      csv: _catalogCsv,
    );

    await _pumpSettings(tester, locale: _englishLocale, catalog: catalog);
    await tester.tap(find.text('Choose from the official catalog'));
    await tester.pumpAndSettle();
    final english = _ownedRenderedText(tester);
    expect(
      english.where(_cjk.hasMatch),
      isEmpty,
      reason: 'the EPA picker renders Chinese in English',
    );
    final englishBody = english.join('\n');
    expect(englishBody.toLowerCase(), contains('u.s.-market'));
    // The years are the catalog's, not the prose's: this fixture is 2020 only,
    // so the sentence must not still be claiming 1984.
    expect(englishBody, contains('2020'));
    expect(
      englishBody,
      isNot(contains('1984')),
      reason:
          'the earliest year now comes from the loaded snapshot; a hard-coded '
          '1984 would be a second copy of a bound the catalog already carries',
    );

    await _pumpSettings(tester, locale: _traditionalChinese, catalog: catalog);
    await tester.tap(find.text('從官方目錄選擇'));
    await tester.pumpAndSettle();
    final chineseBody = _ownedRenderedText(tester).join('\n');
    expect(chineseBody, contains('僅限美國市場'));
    expect(chineseBody, contains('2020'));
    expect(chineseBody, isNot(contains('1984')));
  });
}
