// The fault-code vocabulary in both languages, with no widget tree.
//
// `lib/obd/dtc/dtc.dart` decodes codes; it no longer describes them. What it
// hands out is a [DtcKind], a [DtcCategory], a [PowertrainSubsystem] and a
// five-character code — identifiers that read the same on every phone — and
// `lib/ui/screens/dtc/dtc_copy.dart` turns each into an ARB entry. These
// functions take an `AppLocalizations` parameter, so every arm of every one of
// them can be walked in both locales here without pumping a widget.
//
// What these check is deliberately NOT "does the function return its own ARB
// entry" — an assertion that reads the same ARB the function read agrees with
// itself no matter how wrong the translation is. They check the properties a
// wrong translation breaks:
//
//  * every identifier is answered, in both locales
//  * no English value carries Chinese, so nothing was left behind in the move
//  * the two locales are genuinely different copy, so gen-l10n did not quietly
//    fall back to the template
//  * stored, pending and permanent stay three distinguishable things, and the
//    permanent one never reads as something the Clear button removes
//  * a code with no description gets null, never an invented one
//  * P0411 is secondary air injection and P0441 is evaporative emissions — in
//    both languages. The most-reposted fault-code table on the web has that
//    pair the wrong way round, and copying it sends somebody to check a fuel
//    cap while an air pump fails.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/dtc/dtc.dart';
import 'package:torque_obd/ui/screens/dtc/dtc_copy.dart';

final _cjk = RegExp(r'[㐀-鿿豈-﫿]');

Dtc _dtc(String code) => Dtc(
      code: code,
      category: DtcCategory.powertrain,
      kind: DtcKind.stored,
      isManufacturerSpecific: code[1] == '1' || code[1] == '3',
    );

void main() {
  final en = lookupAppLocalizations(englishLocale);
  final zh = lookupAppLocalizations(traditionalChineseLocale);
  final locales = {'en': en, 'zh': zh};

  // ---------------------------------------------------------------------
  group('every identifier is answered in both languages', () {
    test('DtcKind label and explanation', () {
      for (final entry in locales.entries) {
        for (final kind in DtcKind.values) {
          expect(dtcKindLabel(entry.value, kind).trim(), isNotEmpty,
              reason: '$kind ${entry.key}');
          expect(dtcKindExplanation(entry.value, kind).trim(), isNotEmpty,
              reason: '$kind ${entry.key}');
        }
      }
    });

    test('DtcCategory', () {
      for (final entry in locales.entries) {
        for (final category in DtcCategory.values) {
          expect(dtcSystemLabel(entry.value, category).trim(), isNotEmpty,
              reason: '$category ${entry.key}');
        }
      }
    });

    test('PowertrainSubsystem', () {
      for (final entry in locales.entries) {
        for (final subsystem in PowertrainSubsystem.values) {
          expect(dtcSubsystemLabel(entry.value, subsystem).trim(), isNotEmpty,
              reason: '$subsystem ${entry.key}');
        }
      }
    });

    test('every described code has a description in both languages', () {
      // The set in the engine and the switch in the mapper are two lists that
      // have to agree. This is what makes them agree: a code added to one and
      // forgotten in the other fails here rather than rendering the raw code
      // to somebody who could have been told what it means.
      for (final entry in locales.entries) {
        for (final code in DtcDecoder.describedCodes) {
          final described = dtcCodeDescription(entry.value, _dtc(code));
          expect(described, isNotNull, reason: '$code ${entry.key}');
          expect(described!.trim(), isNotEmpty, reason: '$code ${entry.key}');
        }
      }
    });
  });

  // ---------------------------------------------------------------------
  group('English is English and Chinese is Chinese', () {
    test('no English value carries a Chinese character', () {
      final offenders = <String>[];
      void check(String what, String value) {
        if (_cjk.hasMatch(value)) offenders.add('$what → "$value"');
      }

      for (final kind in DtcKind.values) {
        check('$kind label', dtcKindLabel(en, kind));
        check('$kind explanation', dtcKindExplanation(en, kind));
      }
      for (final category in DtcCategory.values) {
        check('$category', dtcSystemLabel(en, category));
      }
      for (final subsystem in PowertrainSubsystem.values) {
        check('$subsystem', dtcSubsystemLabel(en, subsystem));
      }
      for (final code in DtcDecoder.describedCodes) {
        check(code, dtcCodeDescription(en, _dtc(code))!);
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('the two locales are actually different copy', () {
      // Catches gen-l10n falling back to the template, which it does silently:
      // a key missing from app_zh_Hant.arb ships English inside an otherwise
      // Chinese screen and every widget test still passes, because the widget
      // rendered something.
      final same = <String>[];
      for (final kind in DtcKind.values) {
        if (dtcKindLabel(en, kind) == dtcKindLabel(zh, kind)) {
          same.add('$kind label');
        }
        if (dtcKindExplanation(en, kind) == dtcKindExplanation(zh, kind)) {
          same.add('$kind explanation');
        }
      }
      for (final category in DtcCategory.values) {
        if (dtcSystemLabel(en, category) == dtcSystemLabel(zh, category)) {
          same.add('$category');
        }
      }
      for (final subsystem in PowertrainSubsystem.values) {
        if (dtcSubsystemLabel(en, subsystem) ==
            dtcSubsystemLabel(zh, subsystem)) {
          same.add('$subsystem');
        }
      }
      for (final code in DtcDecoder.describedCodes) {
        if (dtcCodeDescription(en, _dtc(code)) ==
            dtcCodeDescription(zh, _dtc(code))) {
          same.add(code);
        }
      }
      expect(same, isEmpty, reason: same.join(', '));
    });

    test('nothing translated the letters, modes or codes themselves', () {
      // `P`, `C`, `B`, `U`, `03`, `07`, `0A` and the five-character codes are
      // what the standard, the service manual and the vehicle all say. They
      // are identity, not language.
      for (final category in DtcCategory.values) {
        expect(category.letter.length, 1);
        expect('PCBU', contains(category.letter));
      }
      expect(DtcKind.values.map((k) => k.mode), ['03', '07', '0A']);
      // A description that restates its own code says nothing, and would make
      // the "described" set a lie about coverage.
      for (final entry in locales.entries) {
        for (final code in DtcDecoder.describedCodes) {
          expect(dtcCodeDescription(entry.value, _dtc(code))!, isNot(contains(code)),
              reason: '$code ${entry.key} restates itself instead of describing');
        }
      }
    });
  });

  // ---------------------------------------------------------------------
  group('the distinctions a wrong translation would blur', () {
    test('stored, pending and permanent stay three things', () {
      for (final entry in locales.entries) {
        final labels = {
          for (final kind in DtcKind.values) dtcKindLabel(entry.value, kind),
        };
        expect(labels, hasLength(DtcKind.values.length),
            reason: '${entry.key}: two classes share a label');
        final explanations = {
          for (final kind in DtcKind.values)
            dtcKindExplanation(entry.value, kind),
        };
        expect(explanations, hasLength(DtcKind.values.length),
            reason: '${entry.key}: two classes share an explanation');
      }
    });

    test('a permanent code never reads as something Clear removes', () {
      // #45 names this mistranslation specifically. Somebody who believes a
      // Mode 0A code is clearable presses Clear, watches stored and pending
      // disappear, concludes the car is fixed, and takes it to an inspection
      // it cannot pass — having also destroyed the freeze frame that would
      // have explained the fault.
      final zhPermanent = dtcKindExplanation(zh, DtcKind.permanent);
      expect(zhPermanent, contains('無法用診斷儀清除'));
      expect(zhPermanent, contains('ECU'));

      final enPermanent =
          dtcKindExplanation(en, DtcKind.permanent).toLowerCase();
      expect(enPermanent, contains('cannot be cleared'));
      // The second half is load-bearing too: it is the ECU that clears it, and
      // only after the repair. Without that the sentence is a dead end rather
      // than an instruction.
      expect(enPermanent, contains('ecu'));
      expect(enPermanent, anyOf(contains('repair'), contains('fix')));
      // And it must not read like the other two, which Clear does remove.
      expect(enPermanent, isNot(contains('scan tool can clear')));
    });

    test('pending is not confirmed and stored is not certain', () {
      // "Detected once" is not "confirmed"; "usually lit" is not "lit".
      final enPending = dtcKindExplanation(en, DtcKind.pending).toLowerCase();
      expect(enPending, contains('threshold'));
      expect(enPending, isNot(contains('confirmed fault')));
      expect(dtcKindExplanation(zh, DtcKind.pending), contains('尚未'));

      final enStored = dtcKindExplanation(en, DtcKind.stored).toLowerCase();
      expect(enStored, contains('confirmed'));
      expect(enStored, contains('usually'),
          reason: 'a stored code does not guarantee the lamp is lit');
      expect(dtcKindExplanation(zh, DtcKind.stored), contains('通常'));
    });

    test('P0411 is secondary air and P0441 is EVAP, in both languages', () {
      expect(dtcCodeDescription(zh, _dtc('P0411'))!, contains('二次空氣'));
      expect(dtcCodeDescription(zh, _dtc('P0411'))!, isNot(contains('蒸發')));
      expect(dtcCodeDescription(zh, _dtc('P0441'))!, contains('蒸發'));
      expect(dtcCodeDescription(zh, _dtc('P0441'))!, isNot(contains('二次空氣')));

      final enP0411 = dtcCodeDescription(en, _dtc('P0411'))!.toLowerCase();
      final enP0441 = dtcCodeDescription(en, _dtc('P0441'))!.toLowerCase();
      expect(enP0411, contains('secondary air'));
      expect(enP0411, isNot(contains('evaporative')));
      expect(enP0441, contains('evaporative'));
      expect(enP0441, isNot(contains('secondary air')));
    });

    test('the misfire codes name their own cylinder', () {
      // Off-by-one here sends somebody to pull the wrong coil pack.
      const misfires = {
        'P0301': 1,
        'P0302': 2,
        'P0303': 3,
        'P0304': 4,
        'P0305': 5,
        'P0306': 6,
        'P0307': 7,
        'P0308': 8,
      };
      for (final entry in misfires.entries) {
        expect(dtcCodeDescription(en, _dtc(entry.key))!.toLowerCase(),
            allOf(contains('cylinder ${entry.value}'), contains('misfire')),
            reason: entry.key);
        expect(dtcCodeDescription(zh, _dtc(entry.key))!,
            allOf(contains('第 ${entry.value} 缸'), contains('失火')),
            reason: entry.key);
      }
      // And the random/multiple one must not read as a specific cylinder.
      expect(dtcCodeDescription(en, _dtc('P0300'))!.toLowerCase(),
          contains('random'));
      expect(dtcCodeDescription(en, _dtc('P0300'))!.toLowerCase(),
          isNot(matches(RegExp(r'cylinder \d'))));
    });

    test('P0700 still says the real code is in another module', () {
      // P0700 is a pointer, not a fault: the transmission module set something
      // and this is the powertrain module relaying it. Dropping the clause
      // leaves a driver with a code and nowhere to look.
      expect(dtcCodeDescription(en, _dtc('P0700'))!.toLowerCase(),
          contains('separately'));
      expect(dtcCodeDescription(zh, _dtc('P0700'))!, contains('另外讀取'));
    });

    test('block 9 names control-module signals and nothing else', () {
      // An earlier wording invented a transmission clause so it would read
      // like its neighbours. The published block table does not say that.
      final label =
          dtcSubsystemLabel(en, PowertrainSubsystem.controlModuleSignals)
              .toLowerCase();
      expect(label, contains('control module'));
      expect(label, isNot(contains('transmission')));
      expect(
        dtcSubsystemLabel(zh, PowertrainSubsystem.controlModuleSignals),
        '控制模組輸入／輸出訊號',
      );
    });
  });

  // ---------------------------------------------------------------------
  group('a code with no description shows the raw code', () {
    test('a manufacturer-specific code gets null, never a guess', () {
      // A P1xxx means whatever the manufacturer says it means. Both ranges,
      // because the decoder marks `1` and `3`.
      for (final entry in locales.entries) {
        expect(dtcCodeDescription(entry.value, _dtc('P1128')), isNull,
            reason: entry.key);
        expect(dtcCodeDescription(entry.value, _dtc('P3400')), isNull,
            reason: entry.key);
      }
    });

    test('an SAE code this app has never heard of gets null', () {
      for (final entry in locales.entries) {
        expect(dtcCodeDescription(entry.value, _dtc('P0999')), isNull,
            reason: entry.key);
        expect(dtcCodeDescription(entry.value, _dtc('C0561')), isNull,
            reason: entry.key);
      }
    });

    test('the subsystem fallback narrows, and never claims a description', () {
      // The fallback sentence is what an undescribed P0 code falls back to. It
      // must read as "no detailed description" plus a subsystem, not as a
      // description of the fault.
      final subsystem =
          dtcSubsystemLabel(en, PowertrainSubsystem.auxiliaryEmissionControls);
      final sentence = en.dtcNoDescriptionForSubsystem(subsystem);
      expect(sentence, contains(subsystem));
      expect(sentence.toLowerCase(), contains('no detailed description'));
      expect(zh.dtcNoDescriptionForSubsystem('輔助排放控制'),
          contains('沒有這一碼的詳細說明'));
    });
  });
}
