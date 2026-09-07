// The exported sentence and the code beside it must say the same thing.
//
// `test/l10n/datum_reason_guard_test.dart` checks that a producer which
// exports a `reason:` has SOMETHING screen-readable beside it. That is a
// presence rule, and presence was all it ever checked. Since `reasonCode` is
// now the only thing the details dialog renders, a producer can satisfy that
// guard completely while the two disagree: swap
// `reasonCode: DatumReason.unsafeServiceStopped` for `DatumReason.busError` at
// the refused-service site and the whole suite stays green, while the evidence
// file says the service was not read-only and the driver's dialog says "Bus
// error". Two people comparing the file and the phone read different facts.
//
// So this file pins the pairing. Three legs, none of which reads its expected
// value back from the thing it is testing:
//
//   * [_pairs] is hand-typed: every [DatumReason] and the Traditional Chinese
//     sentence the engine exports beside it.
//   * the ARB leg asserts `datumReasonLabel` in zh-Hant returns exactly that,
//     so the table is pinned to shipped copy rather than to itself.
//   * the producer leg walks every real [AvailabilityPolicy] producer and
//     asserts its `reason` is the sentence [_pairs] gives for its `reasonCode`.
//
// The zh-Hant ARB entries happen to be byte-identical to the exported
// sentences today, which is what makes this cheap. It is not a rule — the two
// are allowed to diverge, and the day they do, [_pairs] gains the exported
// wording and the ARB leg is what says so. The two producers whose reason is
// legitimately NOT a `DatumReason` sentence — a recorded telemetry status and
// the session gap list — are pinned explicitly below rather than skipped.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/availability.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/obd/physics/vehicle_profile.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/telemetry.dart';
import 'package:torque_obd/state/vehicle_identity.dart';
import 'package:torque_obd/telemetry/session/telemetry_session.dart';
import 'package:torque_obd/ui/widgets/status/datum_status_copy.dart';
import 'package:torque_obd/ui/widgets/telemetry/telemetry_status_copy.dart';

/// Every [DatumReason] and the exported sentence that belongs beside it.
///
/// Typed out by hand. Reading either side back from the code under test would
/// produce a table that agrees with any transposition.
const _pairs = <DatumReason, String>{
  DatumReason.malformedPacket: '壞封包，只可查看原文',
  DatumReason.nonFiniteValue: '非有限數值',
  DatumReason.outOfReferenceRangeKept: '超出一般參考範圍，已保留',
  DatumReason.unsafeServiceStopped: '此服務不是唯讀查詢，已停止發送',
  DatumReason.unsafeService: '此服務不是唯讀查詢',
  DatumReason.pidUnsupported: '此車輛不支援這個 PID',
  DatumReason.noAnswer: '無回應，稍後重試',
  DatumReason.busError: '匯流排錯誤',
  DatumReason.formulaError: '公式錯誤',
  DatumReason.headerNotOnThisBus: '標頭不符本車匯流排',
  DatumReason.noReadingYet: '尚無讀值',
  DatumReason.horsepowerEstimateMissingInputs: '馬力缺少必要輸入',
  DatumReason.fuelEstimateMissingInputs: '油耗缺少必要輸入',
  DatumReason.assumptionsUnconfirmed: '假設尚未確認，仍可估算',
};

/// Reachable from no producer, and named here so that stays deliberate.
///
/// `forPid`'s `reading == null` switch maps
/// `PidFault.refusedUnsafeService` to it, but the early return above that
/// switch answers `refusedUnsafeService` first — with
/// [DatumReason.unsafeServiceStopped] — whatever the reading is. It is
/// pre-existing and not this slice's to change; pinned so that a producer
/// gaining or losing it is a failing test rather than a silent drift.
const _unreachable = {DatumReason.unsafeService};

/// One status and a label saying which producer made it.
typedef _Produced = ({String label, DatumStatus status});

const _profile = VehicleProfile(massKg: 1280, isConfirmed: false);
const _confirmed = VehicleProfile(massKg: 1280, isConfirmed: true);

/// A derived (estimate) definition, which is what makes the recorded
/// producers attach an assumptions reason at all.
const _derived = TelemetrySignalDefinition(
  id: '000:00FE#derived-fuel-rate',
  name: 'Fuel rate',
  shortName: 'Fuel',
  request: '',
  header: '',
  unit: 'L/h',
  unitProvenance: UnitProvenance.userDefined,
  minimum: 0,
  maximum: 100,
  isCustom: false,
  variant: '',
  priority: 1,
  equation: 'derived',
  assumptionsConfirmed: false,
);

List<_Produced> _producers() => [
  (
    label: 'decodedValue(structurallyValid: false)',
    status: AvailabilityPolicy.decodedValue(
      structurallyValid: false,
      value: null,
    ),
  ),
  (
    label: 'decodedValue(value: null)',
    status: AvailabilityPolicy.decodedValue(
      structurallyValid: true,
      value: null,
    ),
  ),
  (
    label: 'decodedValue(value: double.nan)',
    status: AvailabilityPolicy.decodedValue(
      structurallyValid: true,
      value: double.nan,
    ),
  ),
  (
    label: 'decodedValue(out of range)',
    status: AvailabilityPolicy.decodedValue(
      structurallyValid: true,
      value: 999,
      min: 0,
      max: 100,
    ),
  ),
  (
    label: 'decodedValue(in range)',
    status: AvailabilityPolicy.decodedValue(
      structurallyValid: true,
      value: 50,
      min: 0,
      max: 100,
    ),
  ),
  for (final fault in [...PidFault.values, null])
    (
      label: 'forPid(fault: $fault)',
      status: AvailabilityPolicy.forPid(pid: PidLibrary.engineRpm, fault: fault),
    ),
  (
    label: 'forPid(reading)',
    status: AvailabilityPolicy.forPid(
      pid: PidLibrary.engineRpm,
      reading: Reading(
        pid: PidLibrary.engineRpm,
        value: 2000,
        rawBytes: const [0x41, 0x0C, 0x1F, 0x40],
        timestamp: DateTime.utc(2026),
      ),
    ),
  ),
  for (final kind in EstimateKind.values) ...[
    (
      label: 'forEstimate(value: null, kind: $kind)',
      status: AvailabilityPolicy.forEstimate(
        profile: _profile,
        value: null,
        formula: AvailabilityPolicy.horsepowerFormula,
        kind: kind,
      ),
    ),
    (
      label: 'forEstimate(unconfirmed, kind: $kind)',
      status: AvailabilityPolicy.forEstimate(
        profile: _profile,
        value: 10,
        formula: AvailabilityPolicy.horsepowerFormula,
        kind: kind,
      ),
    ),
    (
      label: 'forEstimate(confirmed, kind: $kind)',
      status: AvailabilityPolicy.forEstimate(
        profile: _confirmed,
        value: 10,
        formula: AvailabilityPolicy.horsepowerFormula,
        kind: kind,
      ),
    ),
  ],
  (
    label: 'forRecordedDefinition(derived, assumptions unconfirmed)',
    status: AvailabilityPolicy.forRecordedDefinition(definition: _derived),
  ),
  (
    label: 'forRecordedEvent(derived value, assumptions unconfirmed)',
    status: AvailabilityPolicy.forRecordedEvent(
      definition: _derived,
      event: TelemetryEvent.value(
        observedAtUtc: DateTime.utc(2026),
        sourceTimestampUtc: DateTime.utc(2026),
        elapsedUs: 0,
        pidId: _derived.id,
        value: 4.2,
      ),
    ),
  ),
];

void main() {
  final zhHant = lookupAppLocalizations(traditionalChineseLocale);

  test('every reason code renders the sentence it is exported beside', () {
    // A code with no entry, or an entry for a code that no longer exists, is
    // the table going stale rather than the app being right.
    expect(_pairs.keys.toSet(), DatumReason.values.toSet());
    for (final entry in _pairs.entries) {
      expect(
        datumReasonLabel(zhHant, entry.key),
        entry.value,
        reason: '${entry.key} exports "${entry.value}" and must not render '
            'something else to a Traditional Chinese reader',
      );
    }
  });

  test('every producer pairs its sentence with the matching code', () {
    final covered = <DatumReason>{};
    var paired = 0;
    for (final produced in _producers()) {
      final status = produced.status;
      final code = status.reasonCode;
      if (code == null) continue;
      covered.add(code);
      paired++;
      expect(
        status.reason,
        isNotNull,
        reason: '${produced.label} sets a code with no exported sentence',
      );
      expect(
        status.reason,
        _pairs[code],
        reason: '${produced.label} exports "${status.reason}" while the '
            'screen shows $code — "${_pairs[code]}"',
      );
    }
    // The walk seeing nothing must not read as success.
    expect(paired, greaterThan(0), reason: 'no producer set a reason code');
    expect(
      covered,
      DatumReason.values.toSet().difference(_unreachable),
      reason: 'the producers no longer cover the codes they used to; a code '
          'that nothing produces cannot be checked by this test',
    );
  });

  test('the two reasons that are not DatumReason sentences, pinned', () {
    // A recorded telemetry status. The export carries the wire name — an
    // identifier, not prose — and the screen reads `statusReason` through the
    // table that already names those. There is no `reasonCode` to agree with,
    // so what is pinned is that the pair is the wire name and the status.
    for (final status in TelemetryStatus.values) {
      final produced = AvailabilityPolicy.forRecordedEvent(
        definition: _derived,
        event: TelemetryEvent.status(
          observedAtUtc: DateTime.utc(2026),
          elapsedUs: 0,
          pidId: _derived.id,
          status: status,
        ),
      );
      expect(produced.reasonCode, isNull, reason: '$status');
      expect(produced.reason, status.wireName, reason: '$status');
      expect(produced.statusReason, status, reason: '$status');
      expect(
        datumReasonText(zhHant, produced),
        telemetryStatusLabel(zhHant, status),
        reason: '$status',
      );
    }

    // The session chip. The export joins the gap wording; the screen names
    // each gap from the same list. Byte-identical in zh-Hant today, so the
    // agreement is assertable rather than merely intended.
    final session = AvailabilityPolicy.genericObdSession(
      identity: const VehicleIdentity.unavailable(),
      catalogMatched: false,
    );
    expect(session.reasonCode, isNull);
    expect(session.gaps, isNotEmpty);
    expect(session.reason, 'VIN 未讀到 · 年式未知 · 型錄無匹配');
    expect(datumReasonText(zhHant, session), session.reason);
    expect(datumGapLabel(zhHant, DatumGap.vinNotRead), 'VIN 未讀到');
    expect(datumGapLabel(zhHant, DatumGap.modelYearUnknown), '年式未知');
    expect(datumGapLabel(zhHant, DatumGap.noCatalogMatch), '型錄無匹配');
  });
}
