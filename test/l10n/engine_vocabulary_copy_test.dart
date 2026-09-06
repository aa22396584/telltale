// The mappers that turn an engine identifier into a word the reader sees.
//
// Three of them landed in this branch — gauge skins, airflow/fuel provenance,
// telemetry session source — and each exists because shipped copy had been
// living inside a module that has no business holding a language: a
// `ThemeExtension` of dial geometry, the physics engine, and `lib/state`. The
// engine keeps the distinctions; these files keep the words.
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

    test('unavailable is not worded as a reading', () {
      // Neither input set was available. That is not zero air flow, which
      // would mean a stopped engine, and it is not a measurement of nothing.
      for (final l10n in [en, zh]) {
        expect(
          airflowSourceLabel(l10n, AirflowSource.unavailable),
          isNot(anyOf(
            equals(airflowSourceLabel(l10n, AirflowSource.measured)),
            equals(airflowSourceLabel(l10n, AirflowSource.speedDensity)),
          )),
        );
        expect(
          fuelSourceLabel(l10n, FuelSource.unavailable),
          isNot(anyOf(
            equals(fuelSourceLabel(l10n, FuelSource.measured)),
            equals(fuelSourceLabel(l10n, FuelSource.stoichiometricEstimate)),
          )),
        );
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
