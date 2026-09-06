// The mappers that turn an engine identifier into a word the reader sees.
//
// Three of them landed in this branch — gauge skins, airflow/fuel provenance,
// telemetry session source — and each exists because shipped copy had been
// living inside a module that has no business holding a language: a
// `ThemeExtension` of dial geometry, the physics engine, and `lib/state`. The
// engine keeps the distinctions; these files keep the words.
//
// TWO of the three are guarded here. `telemetrySourceLabel` is guarded in
// `test/telemetry_session_library_test.dart`, next to the library that reads
// it, by a stronger test than anything in this file: six literals across two
// languages plus a distinctness property. It is named here because somebody
// adding a fourth `TelemetrySource` will read this header, look for the group,
// find none, and reasonably conclude nobody is watching.
//
// What this file does NOT do is `expect(gaugeSkinName(l10n, skin),
// l10n.gaugeSkinCluster)`. That reads the same ARB entry the mapper reads, so
// it agrees with itself and would go on agreeing if the entry were replaced
// with the wrong sentence. Every assertion below is either a literal or a
// structural property the ARB cannot satisfy on its own.
//
// The provenance labels are the load-bearing ones. A measured air mass and a
// speed-density estimate are the same `double` and are not the same claim, and
// this app exists to keep that difference visible: a plausible number that is
// not real is worse than no number.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/core/theme/gauge_skin.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/physics/physics_engine.dart';
import 'package:torque_obd/ui/screens/dashboard/derived_source_copy.dart';
import 'package:torque_obd/ui/screens/settings/gauge_skin_copy.dart';

import '../support/cjk.dart';

void main() {
  final en = lookupAppLocalizations(englishLocale);
  final zh = lookupAppLocalizations(traditionalChineseLocale);

  group('airflow and fuel provenance', () {
    test('says estimate where it is an estimate, in both languages', () {
      expect(
        airflowSourceLabel(en, AirflowSource.measured),
        'MAF sensor',
        reason: 'the one case that is a sensor reading',
      );
      expect(
        airflowSourceLabel(en, AirflowSource.speedDensity),
        contains('estimate'),
        reason:
            'computed from RPM, MAP and IAT. Dropping the hedge would present '
            'a model output as a measurement.',
      );
      expect(
        fuelSourceLabel(en, FuelSource.stoichiometricEstimate),
        contains('estimate'),
        reason:
            'assumes lambda 1, so a diesel at lambda 2 reads about double. '
            'The word estimate is the only thing that says so.',
      );
      expect(fuelSourceLabel(en, FuelSource.measured), 'ECU reported');

      expect(airflowSourceLabel(zh, AirflowSource.measured), 'MAF 感測器');
      expect(
        airflowSourceLabel(zh, AirflowSource.speedDensity),
        contains('推算'),
      );
      expect(
        fuelSourceLabel(zh, FuelSource.stoichiometricEstimate),
        contains('推算'),
      );
      expect(fuelSourceLabel(zh, FuelSource.measured), 'ECU 回報');
    });

    test('unavailable says unavailable, and never says zero', () {
      // The first version of this test asserted that the unavailable label
      // differed from the other two — which merely repeated the distinctness
      // test below, and let "No air flow" through. A reviewer found it by
      // mutation: the whole suite stayed green on a string that, rendered
      // beside a rev counter reading 3000 rpm, says the engine is not
      // breathing. `physics_engine.dart` says "not the same as zero air flow,
      // which would mean a stopped engine", the ARB @description says it, and
      // the comment above the old assertion said it. Three statements of the
      // rule and nothing checking it.
      //
      // So this checks it positively: the word must be there, and the string
      // must not be readable as a measurement.
      final looksLikeAReading = RegExp(r'^[\d.,\s]*(g/s|L/h|L/100km|kg/h|%)?$');

      expect(airflowSourceLabel(en, AirflowSource.unavailable),
          contains('unavailable'));
      expect(fuelSourceLabel(en, FuelSource.unavailable),
          contains('unavailable'));
      expect(airflowSourceLabel(zh, AirflowSource.unavailable),
          contains('無法取得'));
      expect(fuelSourceLabel(zh, FuelSource.unavailable),
          contains('無法取得'));

      for (final l10n in [en, zh]) {
        for (final label in [
          airflowSourceLabel(l10n, AirflowSource.unavailable),
          fuelSourceLabel(l10n, FuelSource.unavailable),
        ]) {
          expect(
            looksLikeAReading.hasMatch(label),
            isFalse,
            reason: '"$label" reads as a value. An absence rendered as a '
                'number is the defect this app exists to prevent.',
          );
          // Nor may it name the absent quantity as though reporting it: a bare
          // "0" anywhere is the cheapest way back to the same failure.
          expect(RegExp(r'(^|\s)0([.,]0+)?($|\s)').hasMatch(label), isFalse,
              reason: '"$label" contains a zero reading');
        }
      }
    });

    test('every source has its own word in both languages', () {
      for (final l10n in [en, zh]) {
        expect(
          AirflowSource.values.map((s) => airflowSourceLabel(l10n, s)).toSet(),
          hasLength(AirflowSource.values.length),
        );
        expect(
          FuelSource.values.map((s) => fuelSourceLabel(l10n, s)).toSet(),
          hasLength(FuelSource.values.length),
        );
      }
    });

    test('no Chinese survives into the English labels', () {
      // The defect this replaced: 「MAF 感測器」 sitting in the middle of an
      // otherwise English dashboard, and in the store screenshot.
      for (final source in AirflowSource.values) {
        expect(containsChinese(airflowSourceLabel(en, source)), isFalse);
      }
      for (final source in FuelSource.values) {
        expect(containsChinese(fuelSourceLabel(en, source)), isFalse);
      }
    });
  });

  group('gauge skins', () {
    test('every shipped skin is named and described in both languages', () {
      for (final l10n in [en, zh]) {
        for (final skin in GaugeSkin.all) {
          expect(
            gaugeSkinName(l10n, skin),
            isNot(anyOf(isEmpty, equals(skin.id))),
            reason: '${skin.id} fell through to the unknown-skin branch',
          );
          expect(gaugeSkinDescription(l10n, skin), isNotEmpty);
        }
      }
    });

    test('each description belongs to the skin it sits under', () {
      // `isNotEmpty` catches "forgot to fill one in". It does not catch
      // "filled in the wrong one", and a reviewer proved it: pointing
      // Minimal's description at gaugeSkinTrackDescription left the whole
      // suite green, so the picker would describe Minimal as "Segmented bar,
      // no smoothing" — a dial the reader is not looking at. That is the same
      // hazard the unknown-skin fallback below is written to avoid, checked
      // for names and not for the sentences underneath them.
      for (final l10n in [en, zh]) {
        expect(
          GaugeSkin.all.map((skin) => gaugeSkinDescription(l10n, skin)).toSet(),
          hasLength(GaugeSkin.all.length),
          reason: 'two skins share a description, so one of them is wrong',
        );
      }
      // A pairing nothing else pins: each description has to be the one whose
      // ARB key matches the skin id, not merely a distinct string.
      expect(gaugeSkinDescription(en, GaugeSkin.minimal),
          en.gaugeSkinMinimalDescription);
      expect(gaugeSkinDescription(en, GaugeSkin.track),
          en.gaugeSkinTrackDescription);
      expect(gaugeSkinDescription(en, GaugeSkin.cluster),
          en.gaugeSkinClusterDescription);
      expect(gaugeSkinDescription(en, GaugeSkin.classic),
          en.gaugeSkinClassicDescription);
      expect(gaugeSkinDescription(en, GaugeSkin.night),
          en.gaugeSkinNightDescription);
    });

    test('the five names are distinct, so the picker is a choice', () {
      for (final l10n in [en, zh]) {
        expect(
          GaugeSkin.all.map((skin) => gaugeSkinName(l10n, skin)).toSet(),
          hasLength(GaugeSkin.all.length),
        );
      }
    });

    test('a skin the app does not know shows its id, not a guess', () {
      // An id is at least true. Falling back to the first entry, or to the
      // word "Cluster", would tell the reader they are looking at a dial they
      // are not looking at.
      final unknown = GaugeSkin.cluster.copyWith(id: 'not-a-shipped-skin');
      expect(gaugeSkinName(en, unknown), 'not-a-shipped-skin');
      expect(gaugeSkinDescription(en, unknown), isEmpty);
    });

    test('no Chinese survives into the English names', () {
      for (final skin in GaugeSkin.all) {
        expect(containsChinese(gaugeSkinName(en, skin)), isFalse);
        expect(containsChinese(gaugeSkinDescription(en, skin)), isFalse);
      }
    });
  });
}
