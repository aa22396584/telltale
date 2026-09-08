/// Drives [AvailabilityPolicy] — the shipped USABILITY-R2 decision surface.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/availability.dart';
import 'package:torque_obd/obd/physics/vehicle_profile.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/pid/pid_csv.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/powertrain_battery/powertrain_battery_profile.dart';
import 'package:torque_obd/obd/telemetry.dart';
import 'package:torque_obd/state/vehicle_identity.dart';

void main() {
  group('該能用的沒有被錯誤阻擋', () {
    test('no VIN, no catalog, unknown year still enters generic OBD', () {
      final status = AvailabilityPolicy.genericObdSession(
        identity: const VehicleIdentity.unavailable(),
      );
      expect(status.availability, FeatureAvailability.usableWithNotice);
      expect(status.isNumericSuccess, isTrue);
      expect(status.evidence, isNot(EvidenceKind.fieldVerified));
      expect(status.nextStep, DatumNextStep.genericObdContinues);
      expect(status.gaps, contains(DatumGap.vinNotRead));
      expect(status.gaps, isNot(contains(DatumGap.noCatalogMatch)));
      expect(status.reason, contains('VIN'));
      expect(status.reason, isNot(contains('型錄無匹配')));
      expect(status.reason, isNot(contains('年式未知')));
      final miss = AvailabilityPolicy.genericObdSession(
        identity: const VehicleIdentity.unavailable(),
        catalogMatched: false,
      );
      expect(miss.reason, contains('型錄無匹配'));
      expect(miss.gaps, contains(DatumGap.noCatalogMatch));
    });

    test('community and experimental bounded-read profiles may install', () {
      expect(
        AvailabilityPolicy.canInstallBoundedReadProfile(
          status: PowertrainProfileStatus.community,
          modeAndIdentifiers: const ['22B046'],
          validatorIssuesEmpty: true,
        ),
        isTrue,
      );
      expect(
        AvailabilityPolicy.canInstallBoundedReadProfile(
          status: PowertrainProfileStatus.experimental,
          modeAndIdentifiers: const ['221F5B'],
          validatorIssuesEmpty: true,
        ),
        isTrue,
      );
      expect(
        AvailabilityPolicy.canInstallBoundedReadProfile(
          status: PowertrainProfileStatus.community,
          modeAndIdentifiers: const ['2161'],
          validatorIssuesEmpty: true,
        ),
        isFalse,
      );
    });

    test('user CSV import is usable and labelled 使用者提供', () {
      const columns =
          'Name,ShortName,ModeAndPID,Equation,Min Value,Max Value,'
          'Units,Header\r\n';
      final result = PidCsv.parse(
        '${columns}User coolant,ECT,0105,A-40,-40,215,C,7E0\r\n',
      );
      expect(result.errors, isEmpty);
      final pid = result.pids.single;
      expect(pid.isCustom, isTrue);
      final status = AvailabilityPolicy.forPid(
        pid: pid,
        reading: Reading(
          pid: pid,
          value: 90,
          rawBytes: const [0x41, 0x05, 0x82],
          timestamp: DateTime.now(),
        ),
      );
      expect(status.isNumericSuccess, isTrue);
      expect(status.origin, DatumOrigin.ecuReported);
      expect(status.evidence, EvidenceKind.userSupplied);
      expect(status.badges, contains(DatumBadge.userSupplied));
    });

    test('one PID fault does not veto sibling readings', () {
      const rpm = PidLibrary.engineRpm;
      const speed = PidLibrary.vehicleSpeed;
      final snapshot = TelemetrySnapshot(
        readings: {
          rpm.id: Reading(
            pid: rpm,
            value: 2000,
            rawBytes: const [],
            timestamp: DateTime.now(),
          ),
        },
        faults: {speed.id: PidFault.noAnswer},
        capturedAt: DateTime.now(),
      );
      final rpmStatus = AvailabilityPolicy.forPid(
        pid: rpm,
        reading: snapshot[rpm.id],
      );
      final speedStatus = AvailabilityPolicy.forPid(
        pid: speed,
        fault: snapshot.faults[speed.id],
      );
      expect(rpmStatus.isNumericSuccess, isTrue);
      expect(snapshot.valueOf(rpm), 2000);
      expect(speedStatus.quality, DatumQuality.partial);
      expect(speedStatus.nextStep, DatumNextStep.otherReadingsUnaffected);
    });

    test('estimates are shown as 估算, never 實測', () {
      const profile = VehicleProfile(massKg: 1280, isConfirmed: false);
      final status = AvailabilityPolicy.forEstimate(
        profile: profile,
        value: 145,
        formula: AvailabilityPolicy.horsepowerFormula,
        kind: EstimateKind.horsepower,
      );
      expect(status.isNumericSuccess, isTrue);
      expect(status.origin, DatumOrigin.calculated);
      expect(status.badges, contains(DatumBadge.estimated));
      expect(status.badges, isNot(contains(DatumBadge.fieldVerified)));
      expect(status.formula, AvailabilityPolicy.horsepowerFormula);
      expect(status.assumptions, anyOf(contains('手動輸入'), contains('通用預設')));
      expect(status.assumptions, contains('1280'));
      expect(status.assumptions, contains('迎風面積'));
      expect(status.assumptions, contains('傳動效率'));
      expect(status.assumptions, isNot(contains('VE ')));
      final fuel = AvailabilityPolicy.forEstimate(
        profile: const VehicleProfile(massKg: 1280, isConfirmed: false),
        value: 4.2,
        formula: AvailabilityPolicy.fuelEstimateFormula,
        kind: EstimateKind.fuel,
      );
      expect(fuel.assumptions, contains('AFR'));
      expect(fuel.assumptions, contains('密度'));
      expect(fuel.assumptions, contains('排氣量'));
      expect(fuel.assumptions, contains('VE'));
      expect(fuel.formula, contains('speed-density'));
      expect(fuel.formula, contains('/ T_K'));
      expect(fuel.formula, isNot(contains('×IAT')));
      expect(fuel.assumptions, isNot(contains('車重')));
      expect(fuel.quality, DatumQuality.valid);
      final fuelOutlier = AvailabilityPolicy.forEstimate(
        profile: profile,
        value: 150,
        formula: AvailabilityPolicy.fuelEstimateFormula,
        kind: EstimateKind.fuel,
      );
      expect(fuelOutlier.quality, DatumQuality.outOfReferenceRange);
      expect(fuelOutlier.badges, contains(DatumBadge.outOfReferenceRange));
      final hpInRange = AvailabilityPolicy.forEstimate(
        profile: profile,
        value: 1500,
        formula: AvailabilityPolicy.horsepowerFormula,
        kind: EstimateKind.horsepower,
      );
      expect(hpInRange.quality, DatumQuality.valid);
      final hpOutlier = AvailabilityPolicy.forEstimate(
        profile: profile,
        value: 2500,
        formula: AvailabilityPolicy.horsepowerFormula,
        kind: EstimateKind.horsepower,
      );
      expect(hpOutlier.quality, DatumQuality.outOfReferenceRange);
    });

    test('an estimate with no inputs names its own quantity in the export', () {
      // The one word in this sentence a caller used to choose. `forEstimate`
      // took a `quantity` string and all three call sites were in `lib/ui`;
      // it is now derived from [EstimateKind] inside the policy, which is
      // where export wording has to be decided. Nothing pinned the result of
      // that switch, and two arms of the same shape transpose silently: a fuel
      // estimate would write `馬力缺少必要輸入` into the evidence file, and two
      // people comparing that file would read a precise, plausible, wrong
      // sentence.
      //
      // Typed out here rather than read back from the switch under test. A
      // test that asks the code what it says agrees with the code however
      // wrong it is — the same reason `test/l10n/l04_status_l10n_test.dart`
      // refuses to compare an ARB entry against itself.
      const expected = {
        EstimateKind.horsepower: (
          '馬力缺少必要輸入',
          DatumReason.horsepowerEstimateMissingInputs,
        ),
        EstimateKind.fuel: (
          '油耗缺少必要輸入',
          DatumReason.fuelEstimateMissingInputs,
        ),
      };
      // A third kind must fail here rather than be quietly skipped by a loop
      // over a map that no longer covers the enum.
      expect(expected.keys.toSet(), EstimateKind.values.toSet());
      for (final entry in expected.entries) {
        final (sentence, code) = entry.value;
        final status = AvailabilityPolicy.forEstimate(
          profile: const VehicleProfile(massKg: 1280, isConfirmed: false),
          value: null,
          formula: AvailabilityPolicy.horsepowerFormula,
          kind: entry.key,
        );
        expect(status.reason, sentence, reason: '${entry.key}');
        expect(status.reasonCode, code, reason: '${entry.key}');
        expect(status.exportFields['reason'], sentence, reason: '${entry.key}');
        expect(status.availability, FeatureAvailability.unavailable);
        expect(status.isNumericSuccess, isFalse);
        expect(
          status.nextStep,
          DatumNextStep.estimateOnlyOtherReadingsUnaffected,
        );
      }
      // And the two quantities are not the same sentence, so a transposition
      // is a change rather than a no-op.
      expect(
        expected[EstimateKind.horsepower]!.$1,
        isNot(expected[EstimateKind.fuel]!.$1),
      );
    });

    test('finite out-of-range coolant is kept as 異常', () {
      const pid = PidLibrary.coolantTemp;
      final status = AvailabilityPolicy.decodedValue(
        structurallyValid: true,
        value: 999,
        min: pid.minValue,
        max: pid.maxValue,
      );
      expect(status.isNumericSuccess, isTrue);
      expect(status.quality, DatumQuality.outOfReferenceRange);
      expect(status.badges, contains(DatumBadge.outOfReferenceRange));
    });

    test('stale badges are not doubled', () {
      const pid = PidLibrary.engineRpm;
      final status = AvailabilityPolicy.forPid(
        pid: pid,
        reading: Reading(
          pid: pid,
          value: 2000,
          rawBytes: const [],
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        isStale: true,
      );
      expect(status.badges.where((b) => b == DatumBadge.stale).length, 1);
    });

    test('installed community PID is labelled 社群解碼', () {
      const pid = Pid(
        name: 'SOC',
        shortName: 'SOC',
        modeAndPid: '22B046',
        equation: 'A',
        minValue: 0,
        maxValue: 100,
        units: '%',
        evidenceKind: 'community',
      );
      final status = AvailabilityPolicy.forPid(
        pid: pid,
        reading: Reading(
          pid: pid,
          value: 67,
          rawBytes: const [],
          timestamp: DateTime.now(),
        ),
      );
      expect(status.evidence, EvidenceKind.community);
      expect(status.badges, contains(DatumBadge.communityDecode));
    });

    test('a missing reading is waiting, not 無效', () {
      const pid = PidLibrary.engineRpm;
      final status = AvailabilityPolicy.forPid(pid: pid);
      expect(status.isNumericSuccess, isFalse);
      expect(status.quality, DatumQuality.partial);
      expect(status.reason, '尚無讀值');
      expect(status.badges, isNot(contains(DatumBadge.invalid)));
    });

    test('research-only metadata has no fake numeric reading', () {
      expect(
        AvailabilityPolicy.canInstallBoundedReadProfile(
          status: PowertrainProfileStatus.researchOnly,
          modeAndIdentifiers: const [],
          validatorIssuesEmpty: true,
        ),
        isFalse,
      );
    });
  });

  group('該阻擋的有阻擋', () {
    test('NaN, Infinity, and a structurally bad packet are not numbers', () {
      for (final value in [
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        final status = AvailabilityPolicy.decodedValue(
          structurallyValid: true,
          value: value,
          min: 0,
          max: 100,
        );
        expect(status.isNumericSuccess, isFalse, reason: '$value');
        expect(status.quality, DatumQuality.invalid);
        expect(status.availability, FeatureAvailability.rawOnly);
      }
      final bad = AvailabilityPolicy.decodedValue(
        structurallyValid: false,
        value: 67,
        min: 0,
        max: 100,
      );
      expect(bad.isNumericSuccess, isFalse);
      expect(bad.reason, contains('壞封包'));
    });

    test('Mode 21 experimental is not a gauge poll and does not install', () {
      expect(PollableServices.isPollable('2161'), isFalse);
      expect(
        AvailabilityPolicy.canInstallBoundedReadProfile(
          status: PowertrainProfileStatus.experimental,
          modeAndIdentifiers: const ['2161'],
          validatorIssuesEmpty: true,
        ),
        isFalse,
      );
      expect(AvailabilityPolicy.allowSend(modeAndPid: '2161'), isFalse);
      expect(
        AvailabilityPolicy.allowSend(
          modeAndPid: '2161',
          gate: const OperationGate(oneShotConsent: true),
        ),
        isTrue,
      );
    });

    test('clear, actuate, and program send nothing without their gates', () {
      expect(AvailabilityPolicy.allowSend(modeAndPid: '04'), isFalse);
      expect(AvailabilityPolicy.allowSend(modeAndPid: '2F011203'), isFalse);
      expect(AvailabilityPolicy.allowSend(modeAndPid: '2E1234'), isFalse);
      expect(AvailabilityPolicy.allowSend(modeAndPid: '310112'), isFalse);
      expect(AvailabilityPolicy.allowSend(modeAndPid: '1101'), isFalse);
      expect(
        AvailabilityPolicy.allowSend(
          modeAndPid: '04',
          gate: const OperationGate(
            clearSnapshotReady: true,
            clearConfirmed: true,
          ),
        ),
        isTrue,
      );
      expect(
        AvailabilityPolicy.riskFor('04'),
        isNot(AvailabilityPolicy.riskFor('010C')),
      );
    });

    test('evidence never upgrades a write to allowed', () {
      expect(AvailabilityPolicy.allowSend(modeAndPid: '2F011203'), isFalse);
      expect(PollableServices.isPollable('2F011203'), isFalse);
    });

    test('validator issues still block install', () {
      expect(
        AvailabilityPolicy.canInstallBoundedReadProfile(
          status: PowertrainProfileStatus.community,
          modeAndIdentifiers: const ['22B046'],
          validatorIssuesEmpty: false,
        ),
        isFalse,
      );
    });
  });
}
