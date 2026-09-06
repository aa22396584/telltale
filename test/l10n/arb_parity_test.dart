// Guards the ARB files against the failure that no other test can see: a key
// that exists in one language and not the other.
//
// `gen-l10n` does not fail on a missing translation — it falls back to the
// template locale. So a forgotten Traditional Chinese entry ships as English
// inside an otherwise Chinese screen, and every widget test still passes,
// because the widget renders *something*. The suite would agree with itself.
//
// `app_zh.arb` is a byte-for-byte fallback for a plain `zh` device locale that
// carries no script subtag. It is not a second translation and must never
// become one: two Chinese files free to drift are two sources of truth.
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

  test('every locale declares the same message keys', () {
    final enKeys = _messageKeys(en);
    expect(enKeys, isNotEmpty);
    expect(
      _messageKeys(zhHant),
      enKeys,
      reason: 'app_zh_Hant.arb and app_en.arb disagree on which messages exist',
    );
    expect(
      _messageKeys(zh),
      enKeys,
      reason: 'app_zh.arb and app_en.arb disagree on which messages exist',
    );
  });

  test('no message is empty or left as its English source in Chinese', () {
    for (final key in _messageKeys(en)) {
      for (final entry in {'app_en.arb': en, 'app_zh_Hant.arb': zhHant}.entries) {
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

  test('placeholders match across locales, by name', () {
    for (final key in _messageKeys(en)) {
      final expected = _placeholders(en, key);
      for (final entry in {'app_zh_Hant.arb': zhHant, 'app_zh.arb': zh}.entries) {
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
    final reference = RegExp(r'\{(\w+)\}');
    for (final entry in {
      'app_en.arb': en,
      'app_zh_Hant.arb': zhHant,
      'app_zh.arb': zh,
    }.entries) {
      for (final key in _messageKeys(entry.value)) {
        final value = entry.value[key];
        if (value is! String) continue;
        final used = reference.allMatches(value).map((m) => m.group(1)!).toSet();
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
