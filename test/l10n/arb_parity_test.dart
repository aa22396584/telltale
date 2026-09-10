// Guards the ARB files against the failure that no other test can see: a key
// that exists in one language and not in another.
//
// `gen-l10n` does not fail on a missing translation — it falls back to the
// template locale. So a forgotten Traditional Chinese entry ships as English
// inside an otherwise Chinese screen, and every widget test still passes,
// because the widget renders *something*. The suite would agree with itself.
//
// `app_zh.arb` is a byte-for-byte fallback for a plain `zh` device locale that
// carries no script subtag. It is not a second translation and must never
// become one: two Chinese files free to drift are two sources of truth.
//
// German is a machine translation corrected by hand (docs/i18n/README.md). That
// changes what a reviewer can promise about its sentences; it changes nothing
// about what this file checks, because keys, arguments and empty values are
// exactly the failures a translator — human or machine — cannot see and the app
// will not report.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';

Map<String, dynamic> _readArb(String name) {
  final file = File('lib/l10n/$name');
  if (!file.existsSync()) {
    // Thrown, not expect()ed: this runs while the file is being loaded, before
    // any test body exists to own the failure.
    throw StateError('lib/l10n/$name is missing; l10n.yaml still expects it');
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

Set<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

/// ARB placeholder names for one message, or an empty set when it takes none.
Set<String> _placeholders(Map<String, dynamic> arb, String key) {
  final meta = arb['@$key'];
  if (meta is! Map) return <String>{};
  final placeholders = meta['placeholders'];
  if (placeholders is! Map) return <String>{};
  return placeholders.keys.map((k) => k.toString()).toSet();
}

void main() {
  final en = _readArb('app_en.arb');
  final zhHant = _readArb('app_zh_Hant.arb');
  final zh = _readArb('app_zh.arb');
  final de = _readArb('app_de.arb');

  /// Every shipped locale except the template, by file name. `app_zh.arb` is in
  /// here too: it is a copy rather than a translation, but a key missing from a
  /// copy still ships as English on a plain `zh` device.
  final shipped = <String, Map<String, dynamic>>{
    'app_zh_Hant.arb': zhHant,
    'app_zh.arb': zh,
    'app_de.arb': de,
  };

  /// The template and everything that has to agree with it.
  final everyLocale = <String, Map<String, dynamic>>{'app_en.arb': en, ...shipped};

  /// Locales that carry their own copy. `app_zh.arb` is excluded because it is
  /// checked against `app_zh_Hant.arb` further down instead.
  final translations = Map<String, Map<String, dynamic>>.from(shipped)
    ..remove('app_zh.arb');

  test('every locale declares the same message keys', () {
    final enKeys = _messageKeys(en);
    expect(enKeys, isNotEmpty);
    for (final entry in shipped.entries) {
      expect(
        _messageKeys(entry.value),
        enKeys,
        reason: '${entry.key} and app_en.arb disagree on which messages exist',
      );
    }
  });

  test('no message is empty', () {
    for (final key in _messageKeys(en)) {
      for (final entry in everyLocale.entries) {
        final value = entry.value[key];
        expect(
          value,
          isA<String>(),
          reason: '${entry.key} key "$key" is not a string',
        );
        expect(
          (value as String).trim(),
          isNotEmpty,
          reason: '${entry.key} key "$key" is empty',
        );
      }
    }
  });

  test('sentences that exist to contradict each other still do', () {
    // Cheaper than one assertion per sentence, and harder to defeat: for a
    // binary readout, an inverted translation is only visible as a collision
    // with its opposite. A reviewer inverted `dtcMilOff` to 'The fault lamp is
    // lit' and the whole suite stayed green — both branches of
    // `dtc_screen.dart:1072` would have said the same thing about a warning
    // lamp, in an app whose reason for existing is that a plausible wrong
    // statement is worse than none.
    //
    // Each pair is chosen at a site where the code picks one or the other, so
    // collapsing them is always a defect and never a style choice.
    const mustDiffer = <List<String>>[
      // dtc_screen.dart:1072 — `summary.milOn ? … : …`, a physical lamp.
      ['dtcMilOn', 'dtcMilOff'],
      // Two different handshake outcomes: the adapter refused the command, or
      // the vehicle never answered it. Different faults, different next steps.
      ['handshakeNoteEcuSilent', 'handshakeNoteNotAcknowledged'],
      // "only the estimate is affected" is not "only this item is affected".
      ['datumNextStepEstimateOnly', 'datumNextStepOtherReadings'],
      // A datum you may not read as a value, versus one you may.
      ['datumNextStepRawOnly', 'datumNextStepOtherReadings'],
      // Emissions readiness: complete-and-clean is not partially-clean.
      ['dtcCompleteCleanTitle', 'dtcVerdictPartialClean'],
    ];
    final collapsed = <String>[];
    for (final locale in everyLocale.values) {
      for (final pair in mustDiffer) {
        final a = locale[pair[0]];
        final b = locale[pair[1]];
        if (a == null || b == null) {
          collapsed.add('${pair.join(' / ')} — a key is missing');
          continue;
        }
        if (a == b) collapsed.add('${pair.join(' / ')} both say "$a"');
      }
    }
    expect(
      collapsed,
      isEmpty,
      reason:
          'These pairs are chosen from one another at a call site, so a reader '
          'who sees the wrong one is told the opposite of the truth:\n'
          '${collapsed.join('\n')}',
    );
  });

  test('no message is left as its English source in a translation', () {
    // The failure gen-l10n cannot report. It does not fail on a missing
    // translation — it falls back to the template — so a forgotten entry ships
    // as English inside an otherwise Chinese screen, and every widget test
    // still passes because the widget rendered something.
    //
    // A few entries are identical in every language on purpose. They are listed
    // here by name so that adding another is a decision somebody makes rather
    // than a translation somebody forgot.
    const identicalOnPurpose = <String>{
      // A product name is not translated.
      'appTitle',
      // The language control names the languages in their own scripts, so a
      // reader who cannot read the current one can still find their way out.
      'languageSectionTitle',
      // An SAE J1979 term, on docs/i18n/do-not-translate.md. Somebody who has
      // met PIDs knows the acronym, and somebody who has not is not helped by a
      // translation of it that no other tool or datasheet uses.
      'navPid',
      // Placeholders and a unit. Units are not a language: MiB is MiB in both,
      // and translating it would make two exports incomparable.
      'telemetryLibraryBytes',
      // The three transport product names, all on
      // docs/i18n/do-not-translate.md. They are ARB entries rather than
      // literals so that the rule is enforced here — a future translation of
      // "Wi-Fi" fails this test instead of shipping — and the fourth tile,
      // connectTransportDemoTitle, is deliberately NOT on this list because
      // 'Demo 模擬器' is copy and does get translated.
      'connectTransportBleTitle',
      'connectTransportClassicTitle',
      'connectTransportWifiTitle',
      // Engineering symbols in the estimate assumptions. Cd is Cd on every
      // drag chart ever printed; AFR and VE are the abbreviations a J1979
      // datasheet uses. Expanding them into Chinese words would make the
      // details dialog harder to check against the sources it cites, which is
      // the only reason that dialog exists.
      'assumptionFieldDragCoefficient',
      'assumptionFieldStoichAfr',
      'assumptionFieldVolumetricEfficiency',
      // Two placeholders and a space. There is nothing here to translate; the
      // bracketed form, assumptionWithOrigin, is where the punctuation differs
      // and it is NOT on this list.
      'assumptionWithoutOrigin',
      // Arithmetic. The power formula is symbols and identifier names end to
      // end, with no connecting prose to render — unlike datumFormulaFuelRate,
      // which has a sentence in the middle and is therefore not listed here.
      'datumFormulaHorsepower',
    };
    // Some entries land on the English word in one language and not in another,
    // and that is a fact about the language rather than a lapse: German writes
    // Dashboard, Trends, Pause, Diesel and Port, and its separators and
    // placeholder-only strings have nothing in them to translate. Listed per
    // locale so each one is a decision made about that language.
    const coincidental = <String, Set<String>>{
      'app_zh_Hant.arb': <String>{},
      'app_de.arb': <String>{
        // German uses the English word.
        'connectWifiPortLabel',
        'dashboardWorkspaceTrends',
        'navDashboard',
        'performanceSplitsHeading',
        'telemetryPause',
        'dtcKindPermanent',
        'gaugeSkinCluster',
        'gaugeSkinMinimal',
        'fuelTypeDiesel',
        'fuelTypeLpg',
        'pidEditorFieldName',
        // Punctuation, placeholders, and tokens from
        // docs/i18n/do-not-translate.md — nothing in them is language.
        'dtcGroupHeader',
        'dtcReadFailureDetail',
        'pidEditorFieldModeAndPid',
        'wearPermissionBluetooth',
        'recommendedPurchaseStoreShopee',
        'assumptionWithOrigin',
        'assumptionSeparator',
        'dtcListSeparator',
        'pidListSeparator',
        'powertrainFieldListSeparator',
        'semanticsFieldSeparator',
        'settingsListSeparator',
        'telemetryPhraseJoin',
        'telemetrySentenceJoin',
      },
    };
    for (final entry in translations.entries) {
      final allowed = coincidental[entry.key] ?? const <String>{};
      final untranslated = <String>[];
      for (final key in _messageKeys(en)) {
        if (identicalOnPurpose.contains(key)) continue;
        if (allowed.contains(key)) continue;
        if (entry.value[key] == en[key]) untranslated.add(key);
      }
      expect(
        untranslated,
        isEmpty,
        reason:
            '${entry.key} carries the English source verbatim for: '
            '${untranslated.join(", ")}',
      );
      // A stale allowance is its own defect: it silently exempts a key that has
      // since been translated, so the next regression there goes unreported.
      final stale = allowed
          .where((key) => entry.value[key] != en[key])
          .toList();
      expect(
        stale,
        isEmpty,
        reason:
            '${entry.key} no longer matches English for ${stale.join(", ")} — '
            'remove them from coincidental',
      );
    }
  });

  test('placeholders match across locales, by name', () {
    for (final key in _messageKeys(en)) {
      final expected = _placeholders(en, key);
      for (final entry in shipped.entries) {
        final actual = _placeholders(entry.value, key);
        // A translation may omit the metadata block and inherit the template's
        // placeholders; it may not declare a *different* set.
        if (actual.isEmpty && expected.isNotEmpty) continue;
        expect(
          actual,
          expected,
          reason:
              '${entry.key} key "$key" declares placeholders $actual, template declares $expected',
        );
      }
    }
  });

  test('every placeholder named in a message is declared for that message', () {
    // Strip ICU argument blocks before scanning. `{count, plural, other{items}}`
    // contains `{items}`, which is a branch body and not a placeholder; a naive
    // scan reports the first legitimate plural message as interpolating an
    // undeclared `items` and blames the template. gen-l10n accepts the message,
    // so the test would be wrong and the author would edit good data.
    final icuBlock = RegExp(
      r'\{\s*\w+\s*,\s*(?:plural|select|selectordinal)\s*,[\s\S]*\}',
    );
    final reference = RegExp(r'\{(\w+)\}');
    for (final entry in everyLocale.entries) {
      for (final key in _messageKeys(entry.value)) {
        final value = entry.value[key];
        if (value is! String) continue;
        final simpleArguments = value.replaceAll(icuBlock, '');
        final used =
            reference.allMatches(simpleArguments).map((m) => m.group(1)!).toSet();
        if (used.isEmpty) continue;
        final declared = _placeholders(entry.value, key).isEmpty
            ? _placeholders(en, key)
            : _placeholders(entry.value, key);
        expect(
          used.difference(declared),
          isEmpty,
          reason:
              '${entry.key} key "$key" interpolates ${used.difference(declared)} '
              'but declares $declared',
        );
      }
    }
  });

  test('app_zh.arb is a fallback copy of app_zh_Hant.arb, not a translation', () {
    for (final key in _messageKeys(zhHant)) {
      expect(
        zh[key],
        zhHant[key],
        reason:
            'app_zh.arb key "$key" has drifted from app_zh_Hant.arb. The plain-zh '
            'file exists only so a device reporting "zh" with no script subtag '
            'still reads Traditional Chinese; it is not a place to write '
            'different copy, and Simplified Chinese is not shipped.',
      );
    }
  });

  test('every shipped locale resolves to a bundle instead of throwing', () {
    for (final locale in supportedAppLocales) {
      expect(
        () => lookupAppLocalizations(locale),
        returnsNormally,
        reason: '$locale is offered in supportedAppLocales but has no bundle',
      );
    }
    // The picker writes these two, and `resolveAppLocale` can return either.
    for (final preference in LocalePreference.values) {
      final locale = resolveAppLocale(
        preference: preference,
        deviceLocales: const [],
      );
      expect(
        () => lookupAppLocalizations(locale),
        returnsNormally,
        reason: '$preference resolves to $locale, which has no bundle',
      );
    }
  });
}
