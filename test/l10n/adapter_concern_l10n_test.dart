// The three screens a reviewer found still speaking Chinese to an English
// reader, after the release notes had already claimed the interface was English.
//
// None of them was protected by the export exemption, because none of them is
// an export. They are a warning, a sampling notice and a privacy disclosure —
// all three of them screens.
//
// What makes them worth their own file rather than a line in an existing one is
// that each is load-bearing in a way the store listing depends on:
//
//   * The adapter concerns ARE "when it is unsure, it says so" — the short
//     description's whole claim, and what an independent developer on
//     r/CarHacking described as the first rule of an ELM327: half of them
//     report v1.5 and behave like v1.3, so verify what comes back rather than
//     what it calls itself. An English reader with a clone got a ⚠ and a
//     paragraph they could not read, while "no contradictions" was in English.
//   * The replay notice is the only thing saying a chart is sampled. Without
//     it, a reader takes a sampled curve for a complete recording.
//   * The export disclosure is where the app says what leaves the device. The
//     store listing says "no ads, no tracking, no personal data collected";
//     this is the screen that itemises it.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/adapter_identity.dart';
import 'package:torque_obd/ui/screens/settings/adapter_concern_copy.dart';

import '../support/cjk.dart';

void main() {
  final en = lookupAppLocalizations(englishLocale);
  final zh = lookupAppLocalizations(traditionalChineseLocale);

  group('adapter concerns', () {
    const all = [
      AdapterConcern(AdapterConcernKind.firmwareNeverReleased, version: '1.5'),
      AdapterConcern(
        AdapterConcernKind.ppsRefusedDespiteVersion,
        version: '2.1',
      ),
      AdapterConcern(AdapterConcernKind.noIdentityResponse),
    ];

    test('no Chinese reaches the English adapter panel', () {
      for (final concern in all) {
        final summary = adapterConcernSummary(en, concern);
        final detail = adapterConcernDetail(en, concern);
        expect(containsChinese(summary), isFalse,
            reason: 'summary still Chinese: ${chineseIn(summary)}');
        expect(containsChinese(detail), isFalse,
            reason: 'detail still Chinese: ${chineseIn(detail)}');
      }
    });

    test('the claimed version is quoted back, in both languages', () {
      // The number is the evidence. A summary that says "an unreleased
      // firmware version" without naming it gives the reader nothing to check
      // against the sticker on the adapter.
      expect(adapterConcernSummary(en, all[0]), contains('1.5'));
      expect(adapterConcernSummary(zh, all[0]), contains('1.5'));
      expect(adapterConcernSummary(en, all[1]), contains('2.1'));
      expect(adapterConcernSummary(zh, all[1]), contains('2.1'));
    });

    test('the English states a fact and does not pass a verdict', () {
      // Literals, not `l10n.` lookups. A very large share of *working*
      // adapters report v1.5, so copy that reads as a verdict on the hardware
      // would be wrong more often than right — which is why the detail says
      // many of these still work and names Elm Electronics as the authority
      // rather than leaving it as the app's opinion.
      final detail = adapterConcernDetail(en, all[0]);
      expect(detail, contains('Elm Electronics'));
      expect(detail, contains('still work'));
      expect(adapterConcernDetail(zh, all[0]), contains('仍然可用'));
      expect(adapterConcernDetail(zh, all[0]), contains('Elm Electronics'));
    });

    test('each concern says a different thing in both languages', () {
      for (final l10n in [en, zh]) {
        expect(all.map((c) => adapterConcernSummary(l10n, c)).toSet(),
            hasLength(all.length));
        expect(all.map((c) => adapterConcernDetail(l10n, c)).toSet(),
            hasLength(all.length));
      }
    });

    test('the evidence header keeps its Chinese', () {
      // The transcript is compared between two people; its wording does not
      // follow a phone setting. `exportSummary` is the frozen half and must
      // stay Chinese even as the screen becomes English.
      for (final concern in all) {
        expect(containsChinese(concern.exportSummary), isTrue);
      }
      expect(all[0].exportSummary, contains('從未發行'));
    });
  });

  group('the two telemetry notices', () {
    test('the replay notice says the PREVIEW is the sampled half', () {
      // `contains('sampled')` is satisfied by "The preview is complete; the
      // export is sampled" — the same words, the two halves swapped, and the
      // reader now believes the chart is the whole recording and the file is
      // not. Both of those beliefs are wrong and the second is worse.
      //
      // So: preview before export, sampled attached to the preview, and the
      // export described as keeping everything.
      final e = en.telemetryReplaySampled;
      expect(containsChinese(e), isFalse);
      final preview = e.toLowerCase().indexOf('preview');
      final export = e.toLowerCase().indexOf('export');
      final sampled = e.toLowerCase().indexOf('sampled');
      expect(preview, greaterThanOrEqualTo(0));
      expect(export, greaterThan(preview),
          reason: 'the preview is the qualified half and comes first');
      expect(sampled, inInclusiveRange(preview, export),
          reason: '"sampled" must attach to the preview, not to the export');
      expect(e.toLowerCase(), contains('every recorded event'),
          reason: 'and the export has to be described as keeping all of them');

      final z = zh.telemetryReplaySampled;
      final zPreview = z.indexOf('預覽');
      final zExport = z.indexOf('匯出');
      final zSampled = z.indexOf('抽樣');
      expect(zExport, greaterThan(zPreview));
      expect(zSampled, inInclusiveRange(zPreview, zExport));
      expect(z, contains('完整'));
    });

    test('the export disclosure keeps both halves on the right side', () {
      // Presence is not the property. A reviewer wrote this translation, and
      // every `contains` above it passed:
      //
      //   "The export contains the VIN, GPS, an account and the adapter
      //    address. It does not contain signal names, values or formulas."
      //
      // Four "absent" tokens present, three "present" tokens present, "does
      // not contain" present, and the sentence says the opposite of the truth.
      // What matters is which side of the negation each token falls on, so
      // that is what this splits on and checks.
      //
      // The store listing's "no personal data collected" rests on the second
      // half; the first is what makes the second checkable rather than a bare
      // promise, which is why both are asserted rather than only the exclusion.
      void assertSides(
        String text,
        String negation,
        List<String> included,
        List<String> excluded,
      ) {
        final at = text.indexOf(negation);
        expect(at, greaterThan(0),
            reason: '"$negation" is the hinge of this sentence and is missing');
        final before = text.substring(0, at);
        final after = text.substring(at);
        for (final token in included) {
          expect(before, contains(token),
              reason: '$token must be named as something the export DOES '
                  'contain, before "$negation"');
          expect(after, isNot(contains(token)),
              reason: '$token appears after "$negation", which says the '
                  'export does not contain it');
        }
        for (final token in excluded) {
          expect(after, contains(token),
              reason: '$token must be named after "$negation" — this is the '
                  'clause the store listing rests on');
          expect(before, isNot(contains(token)),
              reason: '$token appears before "$negation", which says the '
                  'export contains it');
        }
      }

      final e = en.telemetryExportDisclosure;
      expect(containsChinese(e), isFalse);
      assertSides(
        e,
        'does not contain',
        const ['signal names', 'values', 'formulas'],
        const ['VIN', 'GPS', 'account', 'adapter address'],
      );

      assertSides(
        zh.telemetryExportDisclosure,
        '不含',
        const ['訊號名稱', '數值', '公式'],
        const ['VIN', 'GPS', '帳號', '轉接器位址'],
      );
    });
  });
}
