// The experimental battery laboratory's refusals, in both languages.
//
// `PowertrainExperimentalProbeConsents.authorize` used to answer with a
// Traditional Chinese sentence, which the screen wrapped in a localized frame.
// An English driver who tapped "read once" and was refused got
// `Not authorized: 目錄完整性雜湊無效` — the frame translated, the reason not.
//
// What this file asserts is deliberately NOT "the switch returns what the ARB
// holds". A test that reads its expectation back out of `AppLocalizations` — or
// out of the function under test — agrees with itself: transposing two arms of
// the switch preserves uniqueness, non-emptiness, both-language presence and
// the absence of Chinese in English, so every property that shape can measure
// survives the defect. The table below is typed out by hand, and swapping two
// arms turns it red. That was run, not assumed.
//
// The two scans are the other half. One holds the engine to identifiers: no
// refusal may be constructed from a sentence. The other holds
// `lib/state/powertrain_battery_profiles.dart` to having no Chinese in any
// string literal — through the shared comment- and string-aware reader in
// `test/support/dart_source_reader.dart`, because this repository's Chinese
// *comments* are normal and a naive scan would flag them.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/state/powertrain_battery_profiles.dart';
import 'package:torque_obd/ui/screens/pids/powertrain_battery_copy.dart';

import '../support/cjk.dart';
import '../support/dart_source_reader.dart';

const _profiles = 'lib/state/powertrain_battery_profiles.dart';

/// The attempt cap the hand-typed table below was written against.
///
/// Not `maxAttemptsPerCommand`: reading the constant would let the table agree
/// with whatever the policy currently says, and the placeholder test below
/// exists precisely to prove the number is rendered rather than spelled into
/// the copy.
const _cap = 3;

/// Every refusal, with the sentence it must produce, typed out here by hand.
///
/// Nothing in this map is read back from the ARB, from `AppLocalizations` or
/// from `powertrainProbeRefusalText`. That is the whole point: it is the only
/// assertion in the file that a transposed switch arm cannot survive.
const Map<PowertrainProbeRefusal, (String, String)> _expected = {
  PowertrainProbeRefusal.labClosed: (
    'The experimental battery laboratory was switched off before this read '
        'could be authorized.',
    '在這次讀取取得授權之前，大電池證據實驗室已被關閉。',
  ),
  PowertrainProbeRefusal.catalogHashInvalid: (
    "Not authorized: the catalog's integrity hash is not valid, so nothing in "
        'it can be read.',
    '未授權：目錄的完整性雜湊無效，因此其中任何內容都不能讀取。',
  ),
  PowertrainProbeRefusal.profileNotInCatalog: (
    'Not authorized: this profile is not in the verified catalog.',
    '未授權：這個設定檔不在已驗證的目錄中。',
  ),
  PowertrainProbeRefusal.profileNotProbeable: (
    'Not authorized: this profile is not one that can be read once '
        'experimentally.',
    '未授權：這個設定檔不是可以單次實驗讀取的設定檔。',
  ),
  PowertrainProbeRefusal.profileFailedValidation: (
    'Not authorized: this profile did not pass catalog validation with the '
        'model year you chose.',
    '未授權：這個設定檔沒有通過你所選車輛年份的目錄驗證。',
  ),
  PowertrainProbeRefusal.commandNotInProfile: (
    'Not authorized: that command is not one of this verified profile\'s own '
        'commands.',
    '未授權：這個指令不屬於這份已驗證設定檔本身的指令。',
  ),
  PowertrainProbeRefusal.quarantinedAtAttemptCap: (
    'Quarantined for this connection: the same command has already been tried '
        '3 times. Reconnect before trying again.',
    '本次連線已隔離：同一個指令已經嘗試 3 次。請重新連線後再試。',
  ),
  PowertrainProbeRefusal.quarantinedAfterRejectedRead: (
    'Quarantined for this connection: an earlier one-shot read did not pass '
        'its structural checks. Reconnect before trying again.',
    '本次連線已隔離：先前一次單次讀取沒有通過結構檢查。請重新連線後再試。',
  ),
};

void main() {
  final en = lookupAppLocalizations(englishLocale);
  final zh = lookupAppLocalizations(traditionalChineseLocale);

  String text(
    AppLocalizations l10n,
    PowertrainProbeRefusal refusal, {
    int cap = _cap,
  }) => powertrainProbeRefusalText(l10n, refusal, attemptCap: cap);

  group('refusal copy', () {
    test('every refusal is in the hand-typed table', () {
      // A refusal added later cannot pass by being merely non-empty and
      // unique: somebody has to type its sentence out here, in both languages.
      expect(
        _expected.keys.toSet(),
        PowertrainProbeRefusal.values.toSet(),
        reason: 'a refusal identifier was added or removed without a '
            'hand-typed expectation',
      );
    });

    test('each refusal renders exactly the sentence written above', () {
      for (final entry in _expected.entries) {
        expect(
          text(en, entry.key),
          equals(entry.value.$1),
          reason: 'en copy for ${entry.key}',
        );
        expect(
          text(zh, entry.key),
          equals(entry.value.$2),
          reason: 'zh-Hant copy for ${entry.key}',
        );
      }
    });

    test('the attempt cap is rendered, not spelled into the copy', () {
      // The table above uses the real cap, so a hard-coded "3" in all three
      // ARB files would pass every assertion in it.
      for (final l10n in [en, zh]) {
        final five = text(
          l10n,
          PowertrainProbeRefusal.quarantinedAtAttemptCap,
          cap: 5,
        );
        expect(five, contains('5'));
        expect(five, isNot(contains('3')));
      }
    });

    test('the English build renders no Chinese', () {
      for (final refusal in PowertrainProbeRefusal.values) {
        final rendered = text(en, refusal);
        expect(
          chinese.hasMatch(rendered),
          isFalse,
          reason: '$refusal still shows ${chineseIn(rendered)} to an English '
              'reader',
        );
      }
    });

    test('no two refusals claim the same cause', () {
      for (final (name, l10n) in [('en', en), ('zh-Hant', zh)]) {
        final seen = <String, PowertrainProbeRefusal>{};
        for (final refusal in PowertrainProbeRefusal.values) {
          final rendered = text(l10n, refusal);
          final clash = seen[rendered];
          expect(
            clash,
            isNull,
            reason: '$name: $refusal and $clash render the same sentence:\n'
                '$rendered',
          );
          seen[rendered] = refusal;
        }
      }
    });

    test('the two languages actually differ for every refusal', () {
      // Catches a key added to app_en.arb and copied verbatim into the two
      // Chinese files, which passes every other check here.
      for (final refusal in PowertrainProbeRefusal.values) {
        expect(
          text(en, refusal),
          isNot(equals(text(zh, refusal))),
          reason: '$refusal reads identically in both languages',
        );
      }
    });

    test('only the two quarantine arms may be recorded as a quarantine', () {
      // The roster the notifier asserts against. A quarantine outlives the tap
      // that caused it; one saying `labClosed` would survive turning the
      // laboratory back on.
      expect(kPowertrainQuarantineRefusals, {
        PowertrainProbeRefusal.quarantinedAtAttemptCap,
        PowertrainProbeRefusal.quarantinedAfterRejectedRead,
      });
    });
  });

  group('the engine names refusals, it does not word them', () {
    test('every refusal is constructed from an identifier', () {
      // Not redundant with the compiler. `refused` takes a
      // `PowertrainProbeRefusal` today; what the type system cannot refuse is
      // somebody widening it back to `String` and passing a sentence, which is
      // exactly the state this slice found the file in.
      final offenders = <String>[];
      var calls = 0;
      for (final file in _libSources()) {
        final src = file.readAsStringSync();
        final code = codeOnly(src);
        final mask = codeMask(src);
        final regions = sourceRegions(src);
        final pattern = RegExp(
          r'PowertrainExperimentalConsentDecision\.refused\(',
        );
        // Matched against `code`, so a mention in a comment or a string is not
        // a call.
        for (final match in pattern.allMatches(code)) {
          calls++;
          final where = '${file.path}:${_lineAt(src, match.start)}';
          final spans = topLevelArgSpans(src, mask, match.end - 1);
          if (spans == null || spans.isEmpty) {
            // Reported rather than skipped: an unreadable call dropped in
            // silence turns any future desync into a green run.
            offenders.add('$where — could not be read');
            continue;
          }
          final (start, end) = spans.first;
          if (code.substring(start, end).trim().isEmpty) {
            offenders.add('$where — first argument is not code');
            continue;
          }
          for (var i = start; i < end; i++) {
            if (regions[i] == SourceRegion.string) {
              offenders.add(
                '$where — first argument contains a string literal: '
                '${src.substring(start, end).trim()}',
              );
              break;
            }
          }
        }
      }
      expect(calls, greaterThan(0), reason: 'the scan found no refusals at '
          'all; it has stopped looking at anything');
      expect(
        offenders,
        isEmpty,
        reason: 'a refusal reaches the screen carrying a sentence instead of '
            'an identifier the screen can translate:\n${offenders.join('\n')}',
      );
    });

    test('no string literal in the profiles notifier is Chinese', () {
      final src = File(_profiles).readAsStringSync();
      final offenders = _chineseStringLiterals(src)
          .map((hit) => '$_profiles:${_lineAt(src, hit.$1)} — ${hit.$2}')
          .toList();
      expect(
        offenders,
        isEmpty,
        reason: 'these are engine strings that reach a screen through the '
            'refusal path; give the screen an identifier instead:\n'
            '${offenders.join('\n')}',
      );
    });
  });

  group('the reader itself: a comment is not a string', () {
    // The scan above is only worth what this is worth. This repository is
    // written with Chinese comments throughout, and a guard that flagged them
    // would be turned off within the week.
    String found(String src) =>
        _chineseStringLiterals(src).map((hit) => hit.$2).join();

    test('Chinese in a line comment is not flagged', () {
      expect(found('// 目錄完整性雜湊無效\nconst a = 1;'), isEmpty);
    });

    test('Chinese in a block comment is not flagged', () {
      expect(found('/* 本次連線已隔離 */\nconst a = 1;'), isEmpty);
    });

    test('Chinese in a doc comment beside a clean string is not flagged', () {
      expect(found("/// 這個設定檔不在已驗證目錄中\nconst a = 'ok';"), isEmpty);
    });

    test('Chinese in a string literal is flagged', () {
      expect(found("const a = '目錄完整性雜湊無效';"), contains('目'));
    });

    test('Chinese in a string nested inside an interpolation is flagged', () {
      expect(found("final a = '\${f('隔離')}';"), contains('隔'));
    });

    test('CJK punctuation alone is flagged', () {
      // The half eight of nine wave test files missed: every word translated
      // and only the separator left behind.
      expect(found("const a = 'Battery 1、Battery 2';"), contains('、'));
      expect(found("const a = 'Not authorized：x';"), contains('：'));
    });
  });
}

/// Every `(offset, character)` where a string literal in [src] holds CJK.
List<(int, String)> _chineseStringLiterals(String src) {
  final regions = sourceRegions(src);
  final hits = <(int, String)>[];
  for (var i = 0; i < src.length; i++) {
    if (regions[i] != SourceRegion.string) continue;
    if (!chinese.hasMatch(src[i])) continue;
    hits.add((i, src[i]));
  }
  return hits;
}

int _lineAt(String src, int offset) =>
    '\n'.allMatches(src.substring(0, offset)).length + 1;

List<File> _libSources() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();
