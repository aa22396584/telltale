// The guard for the failure PR #100 removed from the transports, in the two
// places it survived: a Chinese string literal written by one layer and
// compared with `==` by another.
//
// `ble_scan_permissions.dart` set `deniedLabel: '藍牙'` / `'位置'` and the wear
// shell asked `deniedLabel == '位置'` to choose between two ARB entries.
// `recommended_purchases.dart` set `storeLabel: '蝦皮'` and the purchase panel
// asked `'蝦皮' => l10n.recommendedPurchaseStoreShopee`. Both are enums the
// compiler cannot check — a typo, a full-width character, a variant hanzi, and
// the comparison silently takes the other branch — and both are translations
// stored in engine code, which is how 「藍牙」 reached an English reader.
//
// Both are enums now. What an enum cannot stop is somebody adding a third
// entry the old way, so this reads the two files and refuses Chinese inside
// their string literals.
//
// Inside their string literals, and nowhere else. This repo writes its
// comments in Chinese — both guarded files still do, and the scan below is
// green with them there, which is the whole point. A guard that flagged
// comments would be switched off within a week, and then it would be
// protecting nothing while still looking like protection.
//
// The reader is `test/support/dart_source_regions.dart`, the one
// `transport_issue_guard_test.dart` uses. Three naive scanners is exactly the
// pattern `test/support/cjk.dart` exists to end: nine waves each wrote their
// own detector, eight matched Han characters only, and a real defect shipped
// through all of them.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/core/ble_scan_permissions.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/ui/wear/wear_permission_copy.dart';

import '../support/cjk.dart';
import '../support/dart_source_regions.dart';

/// The files whose string literals must stay free of Chinese.
///
/// Named one by one rather than by directory. `lib/core` at large is not ready
/// for this — `lib/core/theme` and the export helpers carry Chinese copy on
/// purpose — and a guard that fails on the day somebody touches an unrelated
/// file is one that gets its list trimmed rather than its cause fixed. These
/// two are the pair that held a string-as-enum; adding a third is a decision
/// somebody makes here, on purpose.
const _guarded = <String>[
  'lib/core/ble_scan_permissions.dart',
  'lib/core/affiliate/recommended_purchases.dart',
];

/// Every `file:line  offending characters  line text` in [source]'s string
/// literals, using the shared reader so a comment cannot be mistaken for one.
List<String> _chineseLiterals(String path, String source) {
  final strings = stringLiteralsOnly(source);
  final masked = strings.split('\n');
  final original = source.split('\n');
  final offenders = <String>[];
  for (var i = 0; i < masked.length; i++) {
    if (!chinese.hasMatch(masked[i])) continue;
    offenders.add(
      '$path:${i + 1}  ${chineseIn(masked[i])}  in  ${original[i].trim()}',
    );
  }
  return offenders;
}

void main() {
  group('no Chinese survives as a cross-layer identifier', () {
    test('the guarded files still exist', () {
      // A guard aimed at a path that has been renamed passes by reading
      // nothing, which is this project's most familiar failure: the check
      // outlives the thing it checks and stays green forever.
      for (final path in _guarded) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason:
              '$path was moved or deleted. Point this guard at wherever the '
              'permission kind and the storefront identifier live now; do not '
              'delete the entry.',
        );
      }
    });

    test('no Chinese inside a string literal in either file', () {
      final offenders = <String>[];
      for (final path in _guarded) {
        offenders.addAll(_chineseLiterals(path, File(path).readAsStringSync()));
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'A Chinese string literal in engine code is a display word the '
            'screen cannot translate, and — if anything compares it — an enum '
            'the compiler cannot check. Add a value to the enum instead and '
            'let the UI name it:\n${offenders.join('\n')}',
      );
    });

    test('the reader: comments are skipped, every string form is not', () {
      // Fixtures rather than the real files. The real files are supposed to be
      // clean, so a green run over them proves the scan found nothing — not
      // that it could have. These are the shapes it has to survive.
      int found(String src) => _chineseLiterals('f.dart', src).length;

      // The half that keeps the guard alive: this repo's comments are Chinese,
      // and both guarded files still contain one.
      expect(found("// 位置\n"), 0, reason: 'a line comment is not a literal');
      expect(found("/// 位置\n"), 0, reason: 'nor a doc comment');
      expect(found("/* 位置 */\n"), 0, reason: 'nor a block comment');
      expect(
        found("/// the old `?? '藍牙'` fallback\n"),
        0,
        reason: 'a literal quoted inside a comment is still a comment — '
            'ble_scan_permissions.dart says exactly this today',
      );
      expect(
        found("const x = 1; // 藍牙\n"),
        0,
        reason: 'a trailing comment after real code',
      );

      // The half that makes it a check.
      expect(found("const a = '測試';"), 1, reason: 'single quotes');
      expect(found('const a = "測試";'), 1, reason: 'double quotes');
      expect(found("const a = r'測試';"), 1, reason: 'a raw string');
      expect(found("const a = '''測試''';"), 1, reason: 'a triple-quoted string');
      expect(found('const a = """測試""";'), 1, reason: 'the double triple form');
      expect(
        found("const a = '\${f('測試')}';"),
        1,
        reason: 'a literal nested inside an interpolation',
      );
      expect(
        found("const a = '// 測試';"),
        1,
        reason: 'a comment marker inside a string does not start a comment',
      );
      expect(
        found("const a = 'https://x.test/測試';"),
        1,
        reason: 'nor does one in a URL',
      );

      // Both halves on one line, which is the arrangement a whole-line scanner
      // gets wrong in each direction.
      expect(
        found("const a = 'ok'; // 藍牙\n"),
        0,
        reason: 'Chinese only in the comment',
      );
      expect(
        found("const a = '藍牙'; // fine\n"),
        1,
        reason: 'Chinese only in the literal',
      );

      // The two bugs the shared reader has actually had. If either regresses,
      // the mask inverts and everything after it in the file stops being read
      // — a guard that silently sees nothing, which is the failure this whole
      // file exists to avoid.
      expect(
        found("const q = 'it\\'s';\nconst a = '測試';"),
        1,
        reason: 'an escaped quote does not close a single-quoted literal',
      );
      expect(
        found("const p = r'C:\\';\nconst a = '測試';"),
        1,
        reason: 'a raw string has no escapes, so its backslash is content',
      );

      // And the line number is the literal's, not the file's first line.
      expect(
        _chineseLiterals('f.dart', "// 位置\nconst a = 1;\nconst b = '測試';"),
        ['f.dart:3  測試  in  const b = \'測試\';'],
      );
    });
  });

  group('the identifiers the two files now carry have copy in both languages', () {
    final en = lookupAppLocalizations(englishLocale);
    final zh = lookupAppLocalizations(traditionalChineseLocale);

    // The storefront half of this lives in
    // test/l10n/l03_shell_l10n_test.dart, next to the panel's other copy
    // assertions and in place of the fallback test the enum superseded.
    test('every BlePermissionKind is named, and no two the same', () {
      final seen = <String, BlePermissionKind>{};
      for (final kind in BlePermissionKind.values) {
        for (final (language, l10n) in [('English', en), ('Chinese', zh)]) {
          expect(
            blePermissionName(l10n, kind).trim(),
            isNotEmpty,
            reason: '$kind has no $language name, so the wear shell would say '
                '"Scanning needs  permission"',
          );
        }
        // The comparison this replaced picked the wrong branch in silence.
        // Two kinds sharing a sentence would restore exactly that: a refusal
        // that names the permission the user did not refuse.
        final name = blePermissionName(en, kind);
        final clash = seen[name];
        expect(clash, isNull, reason: '$kind and $clash both render "$name"');
        seen[name] = kind;
      }
    });

    test('the two names actually differ per language', () {
      for (final (language, l10n) in [('English', en), ('Chinese', zh)]) {
        expect(
          blePermissionName(l10n, BlePermissionKind.bluetooth),
          isNot(equals(blePermissionName(l10n, BlePermissionKind.location))),
          reason: 'in $language the wear shell cannot say which was refused',
        );
      }
    });
  });
}
