// The estimate details dialog, and the boundary it sits on.
//
// `DatumStatus.formula` and `.assumptions` are written into telemetry exports,
// and they stay in Traditional Chinese there on purpose: an evidence file whose
// wording follows a phone setting is one that two people cannot compare. That
// argument is about what gets stored. It was quietly applied to what gets
// shown as well, and the result was a block of Chinese in the middle of the
// English build's most prominent dialog.
//
// So there are two claims to hold here, and they pull in opposite directions:
//
//   1. The exported sentence must not change. Not its words, not its
//      punctuation, not its order. A test that only checked "contains 車重"
//      would let the separator or the brackets move and break every consumer
//      that ever parsed one of these files.
//   2. The screen must never show it.
//
// The literals below are therefore not decoration; they are the format.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/availability.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/physics/vehicle_evidence.dart';
import 'package:torque_obd/obd/physics/vehicle_profile.dart';
import 'package:torque_obd/ui/screens/settings/vehicle_profile_copy.dart';
import 'package:torque_obd/ui/widgets/status/datum_status_copy.dart';

import '../support/cjk.dart';

void main() {
  final en = lookupAppLocalizations(englishLocale);
  final zh = lookupAppLocalizations(traditionalChineseLocale);
  const profile = VehicleProfile(massKg: 1280);

  DatumStatus statusFor(EstimateKind kind) => AvailabilityPolicy.forEstimate(
    profile: profile,
    value: 100,
    formula: kind == EstimateKind.horsepower
        ? AvailabilityPolicy.horsepowerFormula
        : AvailabilityPolicy.fuelEstimateFormula,
    kind: kind,
  );

  group('the exported sentence is frozen', () {
    test('horsepower assumptions export exactly as they always have', () {
      expect(
        AvailabilityPolicy.formatAssumptionsForExport(
          profile,
          EstimateKind.horsepower,
        ),
        '車重 1280 kg（通用預設）；Cd 0.30（通用預設）；迎風面積 2.2 m²（通用預設）；'
        '滾動阻力 0.015（通用預設）；傳動效率 85% 前輪驅動（通用預設）',
      );
    });

    test('fuel assumptions export exactly as they always have', () {
      // AFR and density carry no origin: they follow from the fuel type, so
      // there is no separate answer to where they came from. They are written
      // without brackets, and that difference is part of the format.
      expect(
        AvailabilityPolicy.formatAssumptionsForExport(
          profile,
          EstimateKind.fuel,
        ),
        '燃料 汽油（通用預設）；AFR 14.7；密度 740 g/L；排氣量 2.0 L（通用預設）；'
        'VE 85%（通用預設）',
      );
    });

    test('a status still exports the sentence, not the structured form', () {
      for (final kind in EstimateKind.values) {
        final status = statusFor(kind);
        expect(status.exportFields['assumptions'], status.assumptions);
        expect(
          status.exportFields['assumptions'],
          AvailabilityPolicy.formatAssumptionsForExport(profile, kind),
        );
      }
    });

    test('the two renderings cannot disagree about the facts', () {
      // Different words are the point. Different fields, values or origins
      // would mean the evidence file and the screen describe different cars.
      for (final kind in EstimateKind.values) {
        final status = statusFor(kind);
        final exported = status.assumptions!;
        for (final assumption in status.assumptionFields) {
          if (assumption.value.isNotEmpty) {
            expect(
              exported,
              contains(assumption.value),
              reason: '${assumption.field.name} is not in the exported sentence',
            );
          }
        }
        expect(
          status.assumptionFields.map((a) => a.field).toList(),
          AvailabilityPolicy.assumptionsFor(profile, kind)
              .map((a) => a.field)
              .toList(),
        );
      }
    });
  });

  group('the screen shows the reader s language', () {
    test('no Chinese reaches the English dialog', () {
      for (final kind in EstimateKind.values) {
        final status = statusFor(kind);
        final assumptions = assumptionsText(en, status, profile)!;
        final formula = datumFormulaText(en, status)!;
        expect(
          containsChinese(assumptions),
          isFalse,
          reason: 'assumptions still Chinese: ${chineseIn(assumptions)}',
        );
        expect(
          containsChinese(formula),
          isFalse,
          reason: 'formula still Chinese: ${chineseIn(formula)}',
        );
      }
    });

    test('the Chinese dialog keeps the words it shipped with', () {
      final hp = assumptionsText(zh, statusFor(EstimateKind.horsepower), profile)!;
      expect(hp, contains('車重 1280 kg（通用預設）'));
      expect(hp, contains('傳動效率 85% 前輪驅動（通用預設）'));
      final fuel = assumptionsText(zh, statusFor(EstimateKind.fuel), profile)!;
      expect(fuel, contains('燃料 汽油（通用預設）'));
      expect(fuel, contains('AFR 14.7'));
    });

    test('the separator and brackets follow the language, not the code', () {
      // The defect this project has already shipped once: an English list
      // joined with 「、」. Punctuation is translated copy.
      expect(en.assumptionSeparator, '; ');
      expect(zh.assumptionSeparator, '；');
      expect(
        assumptionsText(en, statusFor(EstimateKind.fuel), profile),
        isNot(contains(cjkPunctuation)),
      );
      expect(en.assumptionWithOrigin('Mass', '1280 kg', 'generic default'),
          'Mass 1280 kg (generic default)');
      expect(zh.assumptionWithOrigin('車重', '1280 kg', '通用預設'),
          '車重 1280 kg（通用預設）');
    });

    test('the five origins stay five different words', () {
      // A reader deciding whether to trust a power figure is deciding on
      // exactly this word. Collapsing "generic default" into "official
      // registry" would turn a guess into a record.
      for (final l10n in [en, zh]) {
        expect(
          VehicleFieldOrigin.values
              .map((o) => vehicleFieldOriginLabel(l10n, o))
              .toSet(),
          hasLength(VehicleFieldOrigin.values.length),
        );
      }
      expect(
        vehicleFieldOriginLabel(en, VehicleFieldOrigin.genericDefault),
        'generic default',
      );
      expect(
        vehicleFieldOriginLabel(en, VehicleFieldOrigin.officialRegistry),
        'official registry',
      );
    });

    test('fuels and drivetrains are named, not numbered', () {
      for (final l10n in [en, zh]) {
        expect(
          FuelType.values.map((f) => fuelTypeLabel(l10n, f)).toSet(),
          hasLength(FuelType.values.length),
        );
        expect(
          Drivetrain.values.map((d) => drivetrainLabel(l10n, d)).toSet(),
          hasLength(Drivetrain.values.length),
        );
      }
      expect(fuelTypeLabel(en, FuelType.gasoline), 'Petrol');
      expect(fuelTypeLabel(zh, FuelType.gasoline), '汽油');
      expect(drivetrainLabel(en, Drivetrain.awd), 'All-wheel drive');
    });

    test('a replay with no stored parameters gets the app\'s own sentence', () {
      // The app is speaking here, not quoting, so it speaks the reader's
      // language. The distinction is the whole reason this has a code.
      const note = DatumStatus(
        availability: FeatureAvailability.usableWithNotice,
        origin: DatumOrigin.calculated,
        evidence: EvidenceKind.notTested,
        compatibility: Compatibility.unknown,
        quality: DatumQuality.valid,
        operationRisk: OperationRisk.display,
        assumptions: '估算使用記錄當下的車輛設定',
        assumptionNote: DatumAssumptionNote.recordedVehicleSettings,
      );
      expect(containsChinese(assumptionsText(en, note, null)!), isFalse);
      expect(assumptionsText(zh, note, null), '估算使用記錄當下的車輛設定');
      expect(note.exportFields['assumptions'], '估算使用記錄當下的車輛設定');
    });

    test('a sentence a recording stored is quoted, not translated', () {
      // A file written in Traditional Chinese says what it says. Rendering it
      // in English would be inventing a record rather than reading one, and
      // this app's entire position is that a plausible wrong statement is
      // worse than an awkward true one.
      const recorded = DatumStatus(
        availability: FeatureAvailability.usableWithNotice,
        origin: DatumOrigin.calculated,
        evidence: EvidenceKind.notTested,
        compatibility: Compatibility.unknown,
        quality: DatumQuality.valid,
        operationRisk: OperationRisk.display,
        assumptions: '車重 1450 kg（手動輸入）；Cd 0.31（原廠資料）',
      );
      expect(
        assumptionsText(en, recorded, null),
        '車重 1450 kg（手動輸入）；Cd 0.31（原廠資料）',
      );
    });

    test('a status with no structured form still shows something', () {
      // A producer that has not been given codes yet. A formula in the wrong
      // language is still checkable arithmetic; a blank section is not.
      const legacy = DatumStatus(
        availability: FeatureAvailability.usableWithNotice,
        origin: DatumOrigin.calculated,
        evidence: EvidenceKind.notTested,
        compatibility: Compatibility.unknown,
        quality: DatumQuality.valid,
        operationRisk: OperationRisk.display,
        formula: 'x = y',
        assumptions: '估算使用記錄當下的車輛設定',
      );
      expect(datumFormulaText(en, legacy), 'x = y');
      expect(assumptionsText(en, legacy, null), '估算使用記錄當下的車輛設定');
    });
  });
}
