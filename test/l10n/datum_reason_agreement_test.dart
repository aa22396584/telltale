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
//   * [_exported] and [_screen] are hand-typed: every [DatumReason] with the
//     sentence the engine writes into the file, and the sentence a Traditional
//     Chinese reader sees on the phone.
//   * the ARB leg asserts `datumReasonLabel` in zh-Hant returns [_screen], so
//     the table is pinned to shipped copy rather than to itself.
//   * the producer leg walks every real [AvailabilityPolicy] producer and
//     asserts its `reason` is the sentence [_exported] gives for its
//     `reasonCode`.
//
//   * the wording leg asserts the two tables agree, except where a code is
//     named in [_wordingDivergesOnPurpose].
//
// It used to be one table serving both legs, and the header said the two were
// free to diverge while a single edit turned both of them red. A rewording had
// nowhere to go at all: put the new wording in and the producer leg failed,
// leave it out and the ARB leg did. That is a contract that cannot be met
// rather than one that was broken.
//
// Splitting the table fixed that and, on the first attempt, quietly threw away
// something else. While one table served both legs, `producer.reason ==
// datumReasonLabel(zhHant, code)` came free by transitivity. Two tables removed
// the bridge, and nothing else replaces it: [DatumStatus.exportFields] writes
// `reason` — the sentence — and no code beside it, and nothing anywhere writes
// `reasonCode` into an export. **The sentence is the only join key a person
// comparing an evidence file against a phone has.** Reword
// `lib/diagnostics/availability.dart` and `_exported` together and the file
// would have said 車輛匯流排通訊錯誤 while the phone said 匯流排錯誤, with
// nothing to match them by and every test green.
//
// So the equality is a leg now rather than an accident. It is not the single
// table coming back: `_screen` is still pinned to the shipped ARB and
// `_exported` still to the producers, each against its own source, and a
// wording that is *meant* to diverge has somewhere to go — one entry in
// [_wordingDivergesOnPurpose], which shows up in a diff and has to be argued
// for. That is the difference between a rule with an exception and a rule with
// no way to say no.
//
// The gap-list leg below has asserted exactly this kind of export-to-screen
// equality all along. It has no exception set of its own, and does not need
// one: its exported sentence is three gap labels joined together, so there is
// no per-item wording that could be reworded on its own.
//
// The two producers whose reason is legitimately NOT a `DatumReason` sentence
// — a recorded telemetry status and the session gap list — are pinned
// explicitly below rather than skipped.
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

/// Every [DatumReason] and the sentence the engine writes beside it into an
/// export file.
///
/// Typed out by hand. Reading either side back from the code under test would
/// produce a table that agrees with any transposition.
const _exported = <DatumReason, String>{
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

/// Every [DatumReason] and the sentence a Traditional Chinese reader sees.
///
/// Also typed out by hand, and identical to [_exported] today — the export
/// wording was written first and the ARB took it verbatim. Copying it rather
/// than deriving it is the point: a screen sentence that reworded would be one
/// edit here, and the export sentence beside it would not move.
const _screen = <DatumReason, String>{
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

/// Codes whose screen wording is deliberately not the exported wording.
///
/// Empty today, and an empty set is the honest state rather than a mechanism
/// with no users: the wording leg reads it on every run, so the day one is
/// added the entry is what carries the argument. The single table this file
/// used to have could not offer even that — a rewording had nowhere to go.
///
/// An entry is a decision about two wordings that differ, and the wording leg
/// holds every entry to that: a code named here whose two wordings are equal
/// again fails the run. Without that the reverse path is silent — open an
/// exception, let the wording be brought back into line later, and the entry
/// stays behind exempting that code from the wording leg for good.
const _wordingDivergesOnPurpose = <DatumReason>{};

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

  test('every reason code renders the sentence the screen table names', () {
    // A code with no entry, or an entry for a code that no longer exists, is
    // the table going stale rather than the app being right. Both tables, not
    // one: the coverage check was written when there was only [_exported], and
    // a [_screen] that quietly lost a code would leave that code unpinned on
    // the side this test is named for.
    expect(_exported.keys.toSet(), DatumReason.values.toSet());
    expect(_screen.keys.toSet(), DatumReason.values.toSet());
    for (final entry in _screen.entries) {
      expect(
        datumReasonLabel(zhHant, entry.key),
        entry.value,
        reason: '${entry.key} renders "${entry.value}" to a Traditional '
            'Chinese reader and must not render something else',
      );
    }
  });

  test('a reader sees one sentence in the file and on the phone', () {
    // The export carries no code: [DatumStatus.exportFields] writes `reason`
    // and nothing that says which reason it is. So the sentence itself is the
    // join key — two people comparing an evidence file against a phone have
    // only the wording to match on, and the moment the two wordings differ
    // without a decision behind it, they cannot tell they are looking at the
    // same fact.
    //
    // While one table served both legs this came free by transitivity. It does
    // not any more, so it is written down.
    for (final code in DatumReason.values) {
      if (_wordingDivergesOnPurpose.contains(code)) continue;
      expect(
        _screen[code],
        _exported[code],
        reason: '$code is exported as "${_exported[code]}" and rendered as '
            '"${_screen[code]}"; the export carries nothing else to match '
            'them by, so a reader comparing the two cannot tell it is one '
            'fact. If the difference is deliberate, name the code in '
            '_wordingDivergesOnPurpose.',
      );
    }
    // The exception is held to its own claim. A code named in the set whose
    // wordings have quietly reconverged is not an exception any more, it is a
    // hole: the ARB leg and the producer leg each keep passing against their
    // own table, and the next accidental divergence for that code goes
    // unseen. Whether a name in the set is a real code needs no check — the
    // set is typed, and deleting the enum constant fails at compile time.
    for (final code in _wordingDivergesOnPurpose) {
      expect(
        _screen[code],
        isNot(_exported[code]),
        reason: '$code is named in _wordingDivergesOnPurpose but its screen '
            'and export wordings are equal again; the entry is exempting it '
            'from the wording leg for no reason. Remove it.',
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
        _exported[code],
        reason: '${produced.label} exports "${status.reason}" while the '
            'code beside it is $code — "${_exported[code]}"',
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
