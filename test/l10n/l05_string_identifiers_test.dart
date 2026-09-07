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
// pattern `test/support/cjk.dart` exists to end — nine waves each wrote their
// own detector, eight matched Han characters only, and a real defect shipped
// through all of them.
//
// That sentence described an intention rather than a state when this file was
// written: three line-prefix strippers were still in the tree, each blind to a
// trailing comment and to a `//` inside a literal. They are gone.
// `no_cjk_punctuation_in_ui_source_test.dart`,
// `export_labels_stay_off_screen_test.dart` and `l04_status_l10n_test.dart`
// now read through `withoutComments` in the shared reader, and each of them
// changed verdict when they did: the first two had been missing a real symbol
// hidden behind the `//` of a URL, and the third had been accusing any engine
// file that named `AppLocalizations` in a trailing comment.
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

/// What each [BlePermissionKind] is called on screen, typed out by hand.
///
/// Every character on the right of this map was written here, and nothing on
/// that side may ever be read back from [AppLocalizations], from an ARB file,
/// or from `blePermissionName` itself. That is not fastidiousness: the test
/// this table replaced walked the switch and asserted only that each name was
/// non-empty and that no two kinds shared one, and a reviewer swapped the two
/// arms of `blePermissionName` —
///
///     BlePermissionKind.bluetooth => l10n.wearPermissionLocation,
///     BlePermissionKind.location  => l10n.wearPermissionBluetooth,
///
/// — and the whole suite stayed green, because a transposition preserves both
/// of those properties exactly. An expected value derived from the production
/// switch transposes with it; only one written down independently does not.
///
/// The storefront half of the branch has this shape already, by accident:
/// `find.textContaining('Shopee')` and `find.textContaining('蝦皮')` in
/// test/l10n/l03_shell_l10n_test.dart are literals nobody generated, so
/// mutating a `RecommendedStore` arm goes red in nine tests. This is the same
/// anchoring on the permission side, on purpose.
const _expectedPermissionName =
    <BlePermissionKind, ({String english, String chinese})>{
  BlePermissionKind.bluetooth: (english: 'Bluetooth', chinese: '藍牙'),
  BlePermissionKind.location: (english: 'Location', chinese: '位置'),
};

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

    // A row per kind, checked before the loop that reads them. A kind added
    // to the enum without a row here would otherwise be tested by nothing:
    // the loop below iterates the table, so the new kind simply would not
    // appear, and the suite would report success for a build whose wear shell
    // names an untested permission. The set comparison also catches the other
    // direction — a row left behind for a kind that has been removed.
    test('every BlePermissionKind has a row in the expected-name table', () {
      expect(
        _expectedPermissionName.keys.toSet(),
        BlePermissionKind.values.toSet(),
        reason: 'the table and the enum have drifted. Write the new kind\'s '
            'two sentences out by hand; do not read them from '
            'AppLocalizations, or the row transposes with the switch it is '
            'supposed to be checking.',
      );
    });

    test('each BlePermissionKind renders the sentence written down here', () {
      _expectedPermissionName.forEach((kind, want) {
        expect(
          blePermissionName(en, kind),
          want.english,
          reason: '$kind renders the wrong English name. If the arms of '
              'blePermissionName are transposed, the wear shell tells a user '
              'who refused one permission to go and grant the other.',
        );
        expect(
          blePermissionName(zh, kind),
          want.chinese,
          reason: '$kind renders the wrong Chinese name',
        );
      });
    });

    // The storefront half of this lives in
    // test/l10n/l03_shell_l10n_test.dart, next to the panel's other copy
    // assertions and in place of the fallback test the enum superseded.
    test('every BlePermissionKind is named, and no two the same', () {
      // Vacuity first: this whole test is a loop over the enum, so an enum
      // with nothing in it would satisfy every assertion below by having no
      // kind to check, and report success for a build whose wear shell can no
      // longer say which permission was refused.
      expect(
        BlePermissionKind.values,
        isNotEmpty,
        reason: 'with no kinds the loop below asserts nothing',
      );
      // A map per language, not one keyed on the English name. The clash this
      // is looking for is between two kinds, and two kinds can collide in one
      // language while staying distinct in the other — 「藍牙」 and 「位置」 are
      // separate ARB entries and either could be edited alone. Checking
      // English only would leave a Chinese reader being told they refused the
      // permission they did not, which is the exact failure the string
      // comparison used to produce.
      //
      // This also covers what a sibling test used to assert separately: that
      // bluetooth and location differ in each language. That is this map with
      // two entries, so it is not written twice —
      // test/l10n/l03_performance_wear_l10n_test.dart still holds the ARB-level
      // form of it (`wearPermissionBluetooth` vs `wearPermissionLocation`, and
      // the `wearScanPermissionNeeded` sentences they compose into), which is a
      // different layer: this one goes through the `blePermissionName` switch.
      final seen = <String, Map<String, BlePermissionKind>>{
        'English': {},
        'Chinese': {},
      };
      for (final kind in BlePermissionKind.values) {
        for (final (language, l10n) in [('English', en), ('Chinese', zh)]) {
          final name = blePermissionName(l10n, kind);
          expect(
            name.trim(),
            isNotEmpty,
            reason: '$kind has no $language name, so the wear shell would say '
                '"Scanning needs  permission"',
          );
          // The comparison this replaced picked the wrong branch in silence.
          // Two kinds sharing a sentence would restore exactly that: a refusal
          // that names the permission the user did not refuse.
          final clash = seen[language]![name];
          expect(
            clash,
            isNull,
            reason: '$kind and $clash both render "$name" in $language',
          );
          seen[language]![name] = kind;
        }
      }
    });
  });
}
