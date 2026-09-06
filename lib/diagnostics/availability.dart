/// USABILITY-R2: availability, evidence, and operation risk are separate.
///
/// Evidence (未驗證 / 已驗證) is a label. It is not a ban on generic OBD,
/// community/experimental bounded reads, user imports, or disclosed estimates.
library;

import '../obd/physics/vehicle_evidence.dart';
import '../obd/physics/vehicle_profile.dart';
import '../obd/pid/pid.dart';
import '../obd/powertrain_battery/powertrain_battery_profile.dart';
import '../obd/telemetry.dart';
import '../state/vehicle_identity.dart';
import '../telemetry/session/telemetry_session.dart';

enum FeatureAvailability { usable, usableWithNotice, rawOnly, unavailable }

enum DatumOrigin { ecuReported, calculated, userEntered, demo }

enum EvidenceKind {
  fieldVerified,
  community,
  experimental,
  userSupplied,
  notTested,
  unknown,
}

enum Compatibility { exact, candidate, userSelected, unknown, knownMismatch }

enum DatumQuality {
  valid,
  tentativeDecode,
  outOfReferenceRange,
  stale,
  invalid,
  partial,
}

enum OperationRisk { display, boundedRead, clear, stateChange, program }

enum EstimateKind { horsepower, fuel }

/// The words that appear under a value, as identifiers rather than prose.
///
/// This is the most safety-loaded vocabulary in the app, so the engine keeps
/// the distinctions and the UI keeps the wording: `estimated` is not measured,
/// `unverified` is neither invalid nor verified, `partial` is not all clear,
/// `stale` is not live, `outOfReferenceRange` says a check was run and failed
/// rather than that a number looked odd, and `demo` has to be unmistakable
/// because a simulated reading that passes for a live one is the worst thing
/// this app can do.
enum DatumBadge {
  estimated,
  userSupplied,
  demo,
  fieldVerified,
  communityDecode,
  unverifiedOnThisVehicle,
  experimental,
  unverified,
  outOfReferenceRange,
  stale,
  partial,
  tentativeDecode,
  invalid,
  justUpdated,
}

/// What is missing from vehicle identification, for the session chip.
///
/// None of these blocks generic OBD; they say which of the optional things is
/// absent. `vinNotRead` is a read outcome, never a claim that the vehicle has
/// no VIN.
enum DatumGap { vinNotRead, modelYearUnknown, noCatalogMatch }

/// Why a datum is in the state it is in, as an identifier.
///
/// [DatumStatus.reason] keeps the Chinese sentence because it is written into
/// telemetry exports, which are compared between readers and across weeks. The
/// screen renders this code instead.
enum DatumReason {
  malformedPacket,
  nonFiniteValue,
  outOfReferenceRangeKept,
  unsafeServiceStopped,
  unsafeService,
  pidUnsupported,
  noAnswer,
  busError,
  formulaError,
  headerNotOnThisBus,
  noReadingYet,
  horsepowerEstimateMissingInputs,
  fuelEstimateMissingInputs,
  assumptionsUnconfirmed,
}

/// What the reader can do next. Never written to a file, so it carries no
/// prose at all.
enum DatumNextStep {
  genericObdContinues,
  rawOnlyNeverANumber,
  otherReadingsUnaffected,
  estimateOnlyOtherReadingsUnaffected,
}

/// One status object for live UI, recorder, replay, and export.
/// One vehicle parameter an estimate rests on.
///
/// The estimates the dashboard shows are only as good as these, and the app's
/// whole claim is that it says so rather than presenting a model output as a
/// measurement. So the details dialog lists them — with, for each one, where
/// the number came from.
///
/// This is the identifier; `lib/ui/widgets/status/datum_status_copy.dart` has
/// the words. It used to be a pre-composed Traditional Chinese sentence, which
/// worked for the telemetry export it was written for and meant an English
/// reader who opened the dialog got a wall of Chinese.
enum AssumptionField {
  mass,
  dragCoefficient,
  frontalArea,
  rollingResistance,
  drivetrainEfficiency,
  fuelType,
  stoichAfr,
  fuelDensity,
  displacement,
  volumetricEfficiency,
}

/// Which formula produced an estimate.
///
/// Same split as [DatumReason] and [DatumStatus.reason]: the identifier is for
/// the screen, and [DatumStatus.formula] stays the exported string.
enum DatumFormula { horsepower, fuelRate }

/// A note shown in place of a parameter list.
///
/// Only one so far, and it exists because a replayed session may have been
/// recorded before assumptions were stored in the file. What the app says then
/// is its own sentence and belongs in the ARBs; what a recording *did* store is
/// a quotation from an evidence file and is shown exactly as written.
enum DatumAssumptionNote { recordedVehicleSettings }

/// A vehicle parameter, its value, and where the value came from.
///
/// [value] is already formatted and carries its unit, because the formatting is
/// the same in both languages — `1500 kg` is `1500 kg`. What differs is the
/// name of the field and the name of the origin, and neither is stored here.
///
/// [origin] is null for a parameter that is not a profile field the user or a
/// catalog can supply — the stoichiometric AFR and the fuel density come from
/// the fuel type, so asking where they came from has no answer beyond "the
/// fuel you picked".
/// [fuelType] and [drivetrain] are the two parameters whose value is a *word*
/// rather than a number, so they cannot be formatted into [value] without
/// choosing a language. They travel here as identifiers instead.
///
/// They were briefly not carried at all: the renderer took a `VehicleProfile?`
/// and read them off it, [value] was `''` for the fuel, and one of the two
/// dashboard call sites did not pass a profile. That screen then read
/// `Fuel  (generic default)` in English and 「燃料 （通用預設）」 in Chinese — an
/// origin claim about a blank, and for a Chinese reader a straight regression
/// from what shipped. A record that needs a second object to be readable is a
/// record with two ways to be wrong.
final class VehicleAssumption {
  const VehicleAssumption({
    required this.field,
    required this.value,
    this.origin,
    this.fuelType,
    this.drivetrain,
  });

  final AssumptionField field;

  /// Already formatted and carrying its unit, because a number with a unit
  /// reads the same in both languages. Never empty.
  final String value;

  final VehicleFieldOrigin? origin;

  /// Set only for [AssumptionField.fuelType].
  final FuelType? fuelType;

  /// Set only for [AssumptionField.drivetrainEfficiency], where [value] is the
  /// efficiency percentage and this names the layout it belongs to.
  final Drivetrain? drivetrain;
}

class DatumStatus {
  const DatumStatus({
    required this.availability,
    required this.origin,
    required this.evidence,
    required this.compatibility,
    required this.quality,
    required this.operationRisk,
    this.reason,
    this.reasonCode,
    this.statusReason,
    this.gaps = const [],
    this.nextStep,
    this.formula,
    this.formulaCode,
    this.assumptions,
    this.assumptionFields = const [],
    this.assumptionNote,
    this.justUpdated = false,
  });

  final FeatureAvailability availability;
  final DatumOrigin origin;
  final EvidenceKind evidence;
  final Compatibility compatibility;
  final DatumQuality quality;
  final OperationRisk operationRisk;

  /// The exported sentence. Written into telemetry JSON by [exportFields], so
  /// it stays in one language on purpose — an evidence file whose wording
  /// depends on a phone setting is one nobody can compare. Issue #46 owns it.
  final String? reason;

  /// The same fact as [reason], as an identifier the UI can translate.
  final DatumReason? reasonCode;

  /// Set instead of [reasonCode] when the reason *is* a recorded telemetry
  /// status, so the screen can reuse the table that already names those.
  final TelemetryStatus? statusReason;

  /// Which parts of vehicle identification are missing. Screen-only.
  final List<DatumGap> gaps;

  final DatumNextStep? nextStep;

  /// The exported formula string, in one language, for the same reason
  /// [reason] is. [formulaCode] is what the screen renders.
  final String? formula;

  /// The same fact as [formula], as an identifier the UI can translate.
  final DatumFormula? formulaCode;

  /// The exported assumptions sentence. Composed from [assumptionFields] by
  /// [AvailabilityPolicy.formatAssumptionsForExport], so the two cannot carry
  /// different facts — only different words, which is the point.
  final String? assumptions;

  /// The same facts as [assumptions], as data the UI can render in either
  /// language.
  final List<VehicleAssumption> assumptionFields;

  /// Set instead of [assumptionFields] when there is no parameter list to show
  /// and the app is speaking for itself rather than quoting a recording.
  final DatumAssumptionNote? assumptionNote;

  /// Whether this value arrived on the most recent poll. Screen-only.
  final bool justUpdated;

  /// Whether this status may be shown as a normal numeric success.
  bool get isNumericSuccess =>
      (availability == FeatureAvailability.usable ||
          availability == FeatureAvailability.usableWithNotice) &&
      quality != DatumQuality.invalid &&
      operationRisk != OperationRisk.stateChange &&
      operationRisk != OperationRisk.program;

  bool get isEstimate => origin == DatumOrigin.calculated;

  bool get isFieldVerified => evidence == EvidenceKind.fieldVerified;

  /// The badges this datum earns, in reading order.
  ///
  /// Identifiers, not words: `lib/diagnostics` and `lib/obd` must stay free of
  /// `AppLocalizations`, so the mapping to shipped copy lives in
  /// `lib/ui/widgets/status/datum_status_copy.dart`.
  List<DatumBadge> get badges {
    final badges = <DatumBadge>[];
    switch (origin) {
      case DatumOrigin.calculated:
        badges.add(DatumBadge.estimated);
      case DatumOrigin.userEntered:
        badges.add(DatumBadge.userSupplied);
      case DatumOrigin.demo:
        badges.add(DatumBadge.demo);
      case DatumOrigin.ecuReported:
        break;
    }
    switch (evidence) {
      case EvidenceKind.fieldVerified:
        badges.add(DatumBadge.fieldVerified);
      case EvidenceKind.community:
        badges.add(DatumBadge.communityDecode);
        badges.add(DatumBadge.unverifiedOnThisVehicle);
      case EvidenceKind.experimental:
        badges.add(DatumBadge.experimental);
        badges.add(DatumBadge.unverifiedOnThisVehicle);
      case EvidenceKind.userSupplied:
        if (!badges.contains(DatumBadge.userSupplied)) {
          badges.add(DatumBadge.userSupplied);
        }
      case EvidenceKind.notTested:
      case EvidenceKind.unknown:
        if (origin != DatumOrigin.demo) badges.add(DatumBadge.unverified);
    }
    switch (quality) {
      case DatumQuality.outOfReferenceRange:
        badges.add(DatumBadge.outOfReferenceRange);
      case DatumQuality.stale:
        badges.add(DatumBadge.stale);
      case DatumQuality.partial:
        badges.add(DatumBadge.partial);
      case DatumQuality.tentativeDecode:
        badges.add(DatumBadge.tentativeDecode);
      case DatumQuality.invalid:
        badges.add(DatumBadge.invalid);
      case DatumQuality.valid:
        break;
    }
    if (justUpdated && !badges.contains(DatumBadge.justUpdated)) {
      badges.add(DatumBadge.justUpdated);
    }
    return badges;
  }

  Map<String, String> get exportFields => {
    'availability': availability.name,
    'origin': origin.name,
    'evidence': evidence.name,
    'compatibility': compatibility.name,
    'quality': quality.name,
    'operation_risk': operationRisk.name,
    if (reason != null && reason!.isNotEmpty) 'reason': reason!,
    if (formula != null && formula!.isNotEmpty) 'formula': formula!,
    if (assumptions != null && assumptions!.isNotEmpty)
      'assumptions': assumptions!,
  };
}

/// Preconditions that are *not* evidence. Unverified data cannot skip these.
class OperationGate {
  const OperationGate({
    this.clearSnapshotReady = false,
    this.clearConfirmed = false,
    this.oneShotConsent = false,
    this.programRecipeAuthorized = false,
  });

  final bool clearSnapshotReady;
  final bool clearConfirmed;
  final bool oneShotConsent;
  final bool programRecipeAuthorized;
}

/// Shared USABILITY-R2 decisions. UI, recorder, and exporters must call this
/// rather than inventing a second `supported` bool.
abstract final class AvailabilityPolicy {
  static const horsepowerFormula =
      'wheelWatts = (m·a + ½ρ·Cd·A·v² + Crr·m·g)·v; '
      'engineHp = wheelHp / drivetrainEfficiency';

  static const fuelEstimateFormula =
      'L/h = (MAF g/s) / (AFR × fuel density g/L) × 3600; '
      'MAF 可為 PID 0110 或 speed-density（RPM×MAP×排氣量×VE / T_K）； '
      'L/100km = (L/h) / speed_kmh × 100';

  /// Horsepower ceiling used by live estimates and the frozen derived PID.
  static const horsepowerRangeMax = 2000.0;

  /// Fuel-rate ceiling in L/h; not the horsepower scale.
  static const fuelRateRangeMax = 100.0;

  /// Generic OBD is available without a catalog match, VIN, or year.
  static DatumStatus genericObdSession({
    required VehicleIdentity identity,
    bool? catalogMatched,
    int? modelYear,
    bool fieldVerified = false,
  }) {
    final missingVin = identity.vin == null;
    final gaps = <DatumGap>[
      if (missingVin) DatumGap.vinNotRead,
      if (modelYear == null && catalogMatched != null) DatumGap.modelYearUnknown,
      if (catalogMatched == false) DatumGap.noCatalogMatch,
    ];
    return DatumStatus(
      availability: FeatureAvailability.usableWithNotice,
      origin: DatumOrigin.ecuReported,
      evidence: fieldVerified
          ? EvidenceKind.fieldVerified
          : EvidenceKind.notTested,
      compatibility: catalogMatched == true
          ? Compatibility.exact
          : Compatibility.unknown,
      quality: DatumQuality.valid,
      operationRisk: OperationRisk.boundedRead,
      reason: gaps.isEmpty ? null : gaps.map(_gapText).join(' · '),
      gaps: gaps,
      nextStep: DatumNextStep.genericObdContinues,
    );
  }

  /// A structurally valid finite value, including out-of-range outliers.
  static DatumStatus decodedValue({
    required bool structurallyValid,
    required double? value,
    double? min,
    double? max,
    DatumOrigin origin = DatumOrigin.ecuReported,
    EvidenceKind evidence = EvidenceKind.notTested,
    Compatibility compatibility = Compatibility.unknown,
    OperationRisk operationRisk = OperationRisk.boundedRead,
    bool isStale = false,
    bool justUpdated = false,
  }) {
    if (!structurallyValid) {
      return DatumStatus(
        availability: FeatureAvailability.rawOnly,
        origin: origin,
        evidence: evidence,
        compatibility: compatibility,
        quality: DatumQuality.invalid,
        operationRisk: operationRisk,
        reason: '壞封包，只可查看原文',
        reasonCode: DatumReason.malformedPacket,
        nextStep: DatumNextStep.rawOnlyNeverANumber,
      );
    }
    if (value == null || !value.isFinite) {
      return DatumStatus(
        availability: FeatureAvailability.rawOnly,
        origin: origin,
        evidence: evidence,
        compatibility: compatibility,
        quality: DatumQuality.invalid,
        operationRisk: operationRisk,
        reason: '非有限數值',
        reasonCode: DatumReason.nonFiniteValue,
        nextStep: DatumNextStep.rawOnlyNeverANumber,
      );
    }
    final outOfRange =
        min != null && max != null && (value < min || value > max);
    return DatumStatus(
      availability: FeatureAvailability.usableWithNotice,
      origin: origin,
      evidence: evidence,
      compatibility: compatibility,
      quality: isStale
          ? DatumQuality.stale
          : outOfRange
          ? DatumQuality.outOfReferenceRange
          : DatumQuality.valid,
      operationRisk: operationRisk,
      reason: outOfRange ? '超出一般參考範圍，已保留' : null,
      reasonCode: outOfRange ? DatumReason.outOfReferenceRangeKept : null,
      justUpdated: justUpdated,
    );
  }

  static DatumStatus forPid({
    required Pid pid,
    Reading? reading,
    PidFault? fault,
    bool isStale = false,
    bool fieldVerified = false,
    PowertrainProfileStatus? catalogStatus,
    bool demo = false,
  }) {
    final origin = demo
        ? DatumOrigin.demo
        : pid.isCustom
        ? DatumOrigin.userEntered
        : DatumOrigin.ecuReported;
    final resolvedCatalog = catalogStatus ?? _statusFromKind(pid.evidenceKind);
    final evidence = fieldVerified
        ? EvidenceKind.fieldVerified
        : pid.isCustom
        ? EvidenceKind.userSupplied
        : switch (resolvedCatalog) {
            PowertrainProfileStatus.community => EvidenceKind.community,
            PowertrainProfileStatus.experimental => EvidenceKind.experimental,
            PowertrainProfileStatus.ready => EvidenceKind.notTested,
            PowertrainProfileStatus.researchOnly => EvidenceKind.notTested,
            null => EvidenceKind.notTested,
          };

    if (fault == PidFault.refusedUnsafeService) {
      return DatumStatus(
        availability: FeatureAvailability.unavailable,
        origin: origin,
        evidence: evidence,
        compatibility: Compatibility.unknown,
        quality: DatumQuality.invalid,
        operationRisk: riskFor(pid.modeAndPid),
        reason: '此服務不是唯讀查詢，已停止發送',
        reasonCode: DatumReason.unsafeServiceStopped,
      );
    }
    if (reading == null) {
      return DatumStatus(
        availability: FeatureAvailability.unavailable,
        origin: origin,
        evidence: evidence,
        compatibility: Compatibility.unknown,
        quality: DatumQuality.partial,
        operationRisk: OperationRisk.boundedRead,
        reason: switch (fault) {
          PidFault.unsupported => '此車輛不支援這個 PID',
          PidFault.noAnswer => '無回應，稍後重試',
          PidFault.busError => '匯流排錯誤',
          PidFault.formulaError => '公式錯誤',
          PidFault.headerNotOnThisBus => '標頭不符本車匯流排',
          PidFault.refusedUnsafeService => '此服務不是唯讀查詢',
          null => '尚無讀值',
        },
        // Silence is not a controller saying it lacks a PID, so these stay
        // seven separate codes rather than one "unavailable".
        reasonCode: switch (fault) {
          PidFault.unsupported => DatumReason.pidUnsupported,
          PidFault.noAnswer => DatumReason.noAnswer,
          PidFault.busError => DatumReason.busError,
          PidFault.formulaError => DatumReason.formulaError,
          PidFault.headerNotOnThisBus => DatumReason.headerNotOnThisBus,
          PidFault.refusedUnsafeService => DatumReason.unsafeService,
          null => DatumReason.noReadingYet,
        },
        nextStep: DatumNextStep.otherReadingsUnaffected,
      );
    }

    return decodedValue(
      structurallyValid: true,
      value: reading.value,
      min: pid.minValue,
      max: pid.maxValue,
      origin: origin,
      evidence: evidence,
      isStale: isStale,
      justUpdated: !isStale,
    );
  }

  static DatumStatus forEstimate({
    required VehicleProfile profile,
    required double? value,
    required String formula,
    String quantity = '估算',
    EstimateKind kind = EstimateKind.horsepower,
  }) {
    final assumptions = formatAssumptionsForExport(profile, kind);
    final assumptionFields = assumptionsFor(profile, kind);
    final formulaCode = switch (kind) {
      EstimateKind.horsepower => DatumFormula.horsepower,
      EstimateKind.fuel => DatumFormula.fuelRate,
    };
    if (value == null || !value.isFinite) {
      return DatumStatus(
        availability: FeatureAvailability.unavailable,
        origin: DatumOrigin.calculated,
        evidence: EvidenceKind.notTested,
        compatibility: Compatibility.unknown,
        quality: DatumQuality.partial,
        operationRisk: OperationRisk.display,
        reason: '$quantity缺少必要輸入',
        reasonCode: switch (kind) {
          EstimateKind.horsepower =>
            DatumReason.horsepowerEstimateMissingInputs,
          EstimateKind.fuel => DatumReason.fuelEstimateMissingInputs,
        },
        nextStep: DatumNextStep.estimateOnlyOtherReadingsUnaffected,
        formula: formula,
        formulaCode: formulaCode,
        assumptions: assumptions,
        assumptionFields: assumptionFields,
      );
    }
    final max = switch (kind) {
      EstimateKind.horsepower => horsepowerRangeMax,
      EstimateKind.fuel => fuelRateRangeMax,
    };
    final outOfRange = value < 0 || value > max;
    return DatumStatus(
      availability: FeatureAvailability.usableWithNotice,
      origin: DatumOrigin.calculated,
      evidence: EvidenceKind.notTested,
      compatibility: Compatibility.userSelected,
      quality: outOfRange
          ? DatumQuality.outOfReferenceRange
          : DatumQuality.valid,
      operationRisk: OperationRisk.display,
      formula: formula,
      formulaCode: formulaCode,
      assumptions: assumptions,
      assumptionFields: assumptionFields,
      reason: profile.isConfirmed ? null : '假設尚未確認，仍可估算',
      reasonCode: profile.isConfirmed
          ? null
          : DatumReason.assumptionsUnconfirmed,
      justUpdated: true,
    );
  }

  /// The parameters an estimate of [kind] rests on, as data.
  ///
  /// One source for both renderings: [formatAssumptionsForExport] composes the
  /// Traditional Chinese sentence that goes into telemetry JSON from this list,
  /// and the details dialog renders the same list through the ARBs. They can
  /// differ in wording — that is what having two of them is for — but they
  /// cannot differ in which fields, which values, or which origins.
  static List<VehicleAssumption> assumptionsFor(
    VehicleProfile profile,
    EstimateKind kind,
  ) => switch (kind) {
    EstimateKind.horsepower => [
      VehicleAssumption(
        field: AssumptionField.mass,
        value: '${profile.massKg.toStringAsFixed(0)} kg',
        origin: profile.massField.origin,
      ),
      VehicleAssumption(
        field: AssumptionField.dragCoefficient,
        value: profile.dragCoefficient.toStringAsFixed(2),
        origin: profile.dragCoefficientField.origin,
      ),
      VehicleAssumption(
        field: AssumptionField.frontalArea,
        value: '${profile.frontalAreaM2.toStringAsFixed(1)} m²',
        origin: profile.frontalAreaField.origin,
      ),
      VehicleAssumption(
        field: AssumptionField.rollingResistance,
        value: profile.rollingResistance.toStringAsFixed(3),
        origin: profile.rollingResistanceField.origin,
      ),
      VehicleAssumption(
        field: AssumptionField.drivetrainEfficiency,
        // The drivetrain's name is not in `value`: it is a word, and words
        // here belong to the caller's language. The UI appends its own.
        value: '${(profile.drivetrainEfficiency * 100).toStringAsFixed(0)}%',
        origin: profile.drivetrainField.origin,
        drivetrain: profile.drivetrain,
      ),
    ],
    EstimateKind.fuel => [
      VehicleAssumption(
        field: AssumptionField.fuelType,
        // The fuel's whole value is its name, so there is no number to format.
        // `value` carries the export wording — the one place the frozen
        // Chinese has to appear for formatAssumptionsForExport to reproduce
        // the sentence byte for byte — and the screen reads `fuelType`.
        value: profile.fuelType.exportLabel,
        origin: profile.fuelTypeField.origin,
        fuelType: profile.fuelType,
      ),
      VehicleAssumption(
        field: AssumptionField.stoichAfr,
        value: profile.stoichAfr.toStringAsFixed(1),
      ),
      VehicleAssumption(
        field: AssumptionField.fuelDensity,
        value: '${profile.fuelDensityGPerL.toStringAsFixed(0)} g/L',
      ),
      VehicleAssumption(
        field: AssumptionField.displacement,
        value: '${profile.displacementL.toStringAsFixed(1)} L',
        origin: profile.displacementField.origin,
      ),
      VehicleAssumption(
        field: AssumptionField.volumetricEfficiency,
        value: '${profile.volumetricEfficiency.toStringAsFixed(0)}%',
        origin: profile.volumetricEfficiencyField.origin,
      ),
    ],
  };

  /// The Traditional Chinese sentence written into telemetry exports.
  ///
  /// Not for a screen. See [FuelType.exportLabel].
  static String formatAssumptionsForExport(
    VehicleProfile profile,
    EstimateKind kind,
  ) => assumptionsFor(profile, kind).map(_exportNote).join('；');

  static String _exportNote(VehicleAssumption a) {
    final name = switch (a.field) {
      AssumptionField.mass => '車重',
      AssumptionField.dragCoefficient => 'Cd',
      AssumptionField.frontalArea => '迎風面積',
      AssumptionField.rollingResistance => '滾動阻力',
      AssumptionField.drivetrainEfficiency => '傳動效率',
      AssumptionField.fuelType => '燃料',
      AssumptionField.stoichAfr => 'AFR',
      AssumptionField.fuelDensity => '密度',
      AssumptionField.displacement => '排氣量',
      AssumptionField.volumetricEfficiency => 'VE',
    };
    final drivetrain = a.drivetrain;
    final value = drivetrain == null
        ? a.value
        : '${a.value} ${drivetrain.exportLabel}';
    final origin = a.origin;
    return origin == null
        ? '$name $value'
        : '$name $value（${_originLabel(origin)}）';
  }

  static String? serviceByte(String modeAndPid) {
    final value = PollableServices.normalise(modeAndPid);
    if (value.length < 2 || value.length.isOdd) return null;
    if (!RegExp(r'^[0-9A-F]+$').hasMatch(value)) return null;
    return value.substring(0, 2);
  }

  static OperationRisk riskFor(String modeAndPid) {
    final service = serviceByte(modeAndPid);
    if (service == null) return OperationRisk.program;
    if (PollableServices.isPollable(modeAndPid)) {
      return OperationRisk.boundedRead;
    }
    switch (service) {
      case '03':
      case '07':
      case '0A':
      case '09':
      case '21':
        return OperationRisk.boundedRead;
      case '04':
      case '14':
        return OperationRisk.clear;
      case '2F':
      case '31':
        return OperationRisk.stateChange;
      default:
        return OperationRisk.program;
    }
  }

  /// Send decision. Evidence / 未驗證 never authorizes a write.
  static bool allowSend({
    required String modeAndPid,
    OperationGate gate = const OperationGate(),
  }) {
    switch (riskFor(modeAndPid)) {
      case OperationRisk.display:
        return true;
      case OperationRisk.boundedRead:
        if (PollableServices.isPollable(modeAndPid)) return true;
        final service = serviceByte(modeAndPid);
        if (service == '21') return gate.oneShotConsent;
        if (service == '03' ||
            service == '07' ||
            service == '0A' ||
            service == '09') {
          return true;
        }
        return false;
      case OperationRisk.clear:
        return gate.clearSnapshotReady && gate.clearConfirmed;
      case OperationRisk.stateChange:
      case OperationRisk.program:
        return gate.programRecipeAuthorized;
    }
  }

  static bool canInstallBoundedReadProfile({
    required PowertrainProfileStatus status,
    required Iterable<String> modeAndIdentifiers,
    required bool validatorIssuesEmpty,
  }) {
    if (!validatorIssuesEmpty) return false;
    final commands = modeAndIdentifiers.toList(growable: false);
    if (commands.isEmpty) return false;
    switch (status) {
      case PowertrainProfileStatus.ready:
      case PowertrainProfileStatus.community:
      case PowertrainProfileStatus.experimental:
        return commands.every(PollableServices.isPollable);
      case PowertrainProfileStatus.researchOnly:
        return false;
    }
  }

  static bool _isDerivedId(String id) =>
      id == '000:00FF#derived-horsepower' || id == '000:00FE#derived-fuel-rate';

  static DatumOrigin _recordedOrigin({
    required TelemetrySignalDefinition definition,
    TelemetrySource? source,
  }) {
    if (_isDerivedId(definition.id)) return DatumOrigin.calculated;
    if (source == TelemetrySource.demo) return DatumOrigin.demo;
    if (definition.isCustom) return DatumOrigin.userEntered;
    return DatumOrigin.ecuReported;
  }

  static EvidenceKind _recordedEvidence(TelemetrySignalDefinition definition) {
    if (definition.isCustom) return EvidenceKind.userSupplied;
    return switch (definition.evidenceKind) {
      'community' => EvidenceKind.community,
      'experimental' => EvidenceKind.experimental,
      'fieldVerified' => EvidenceKind.fieldVerified,
      'userSupplied' => EvidenceKind.userSupplied,
      _ => EvidenceKind.notTested,
    };
  }

  static Compatibility _recordedCompatibility(
    TelemetrySignalDefinition definition,
  ) {
    if (_isDerivedId(definition.id) || definition.isCustom) {
      return Compatibility.userSelected;
    }
    return switch (definition.evidenceKind) {
      'community' || 'experimental' => Compatibility.candidate,
      _ => Compatibility.unknown,
    };
  }

  static String? _recordedEstimateReason(
    TelemetrySignalDefinition definition,
  ) => switch (definition.assumptionsConfirmed) {
    true => null,
    false => '假設尚未確認，仍可估算',
    null => null,
  };

  static DatumReason? _recordedEstimateReasonCode(
    TelemetrySignalDefinition definition,
  ) => switch (definition.assumptionsConfirmed) {
    true => null,
    false => DatumReason.assumptionsUnconfirmed,
    null => null,
  };

  /// Provenance for a frozen definition when no sample is under the playhead.
  static DatumStatus forRecordedDefinition({
    required TelemetrySignalDefinition definition,
    TelemetrySource? source,
  }) {
    final derived = _isDerivedId(definition.id);
    return DatumStatus(
      availability: FeatureAvailability.usableWithNotice,
      origin: _recordedOrigin(definition: definition, source: source),
      evidence: _recordedEvidence(definition),
      compatibility: _recordedCompatibility(definition),
      quality: DatumQuality.valid,
      operationRisk: derived
          ? OperationRisk.display
          : riskFor(definition.request),
      reason: derived ? _recordedEstimateReason(definition) : null,
      reasonCode: derived ? _recordedEstimateReasonCode(definition) : null,
      formula: derived ? definition.equation : null,
      assumptionNote: derived &&
              (definition.assumptions == null ||
                  definition.assumptions!.isEmpty)
          ? DatumAssumptionNote.recordedVehicleSettings
          : null,
      assumptions: derived
          ? definition.assumptions != null && definition.assumptions!.isNotEmpty
                ? definition.assumptions
                : '估算使用記錄當下的車輛設定'
          : null,
    );
  }

  static DatumStatus forRecordedEvent({
    required TelemetrySignalDefinition definition,
    required TelemetryEvent event,
    TelemetrySource? source,
  }) {
    final derived = _isDerivedId(definition.id);
    final origin = _recordedOrigin(definition: definition, source: source);
    final evidence = _recordedEvidence(definition);
    final compatibility = _recordedCompatibility(definition);
    if (event.kind == TelemetryEventKind.status) {
      return DatumStatus(
        availability: FeatureAvailability.unavailable,
        origin: origin,
        evidence: evidence,
        compatibility: compatibility,
        quality: switch (event.status) {
          TelemetryStatus.stale => DatumQuality.stale,
          TelemetryStatus.unsafeServiceRefusal => DatumQuality.invalid,
          _ => DatumQuality.partial,
        },
        operationRisk: derived
            ? OperationRisk.display
            : riskFor(definition.request),
        // The wire name is what the exported file carries; the screen reads
        // [statusReason] instead so a recorded `noAnswer` never renders to a
        // driver as an untranslated identifier.
        reason: event.status?.wireName,
        statusReason: event.status,
        nextStep: DatumNextStep.otherReadingsUnaffected,
      );
    }
    final status =
        decodedValue(
          structurallyValid: true,
          value: event.value,
          min: definition.minimum,
          max: definition.maximum,
          origin: origin,
          evidence: evidence,
          compatibility: compatibility,
          operationRisk: derived
              ? OperationRisk.display
              : OperationRisk.boundedRead,
        ).letQuality(
          event.quality == TelemetryQuality.outOfReferenceRange
              ? DatumQuality.outOfReferenceRange
              : event.quality == TelemetryQuality.tentativeDecode
              ? DatumQuality.tentativeDecode
              : null,
        );
    if (!derived) return status;
    return DatumStatus(
      availability: status.availability,
      origin: status.origin,
      evidence: status.evidence,
      compatibility: status.compatibility,
      quality: status.quality,
      operationRisk: status.operationRisk,
      reason: status.reason ?? _recordedEstimateReason(definition),
      reasonCode:
          status.reasonCode ?? _recordedEstimateReasonCode(definition),
      statusReason: status.statusReason,
      nextStep: status.nextStep,
      formula: definition.equation,
      assumptionNote:
          definition.assumptions == null || definition.assumptions!.isEmpty
          ? DatumAssumptionNote.recordedVehicleSettings
          : null,
      assumptions:
          definition.assumptions != null && definition.assumptions!.isNotEmpty
          ? definition.assumptions
          : '估算使用記錄當下的車輛設定',
      justUpdated: status.justUpdated,
    );
  }

  static PowertrainProfileStatus? _statusFromKind(String? kind) {
    if (kind == null) return null;
    for (final status in PowertrainProfileStatus.values) {
      if (status.name == kind) return status;
    }
    return null;
  }

  /// The exported wording for a gap. Screens read [DatumStatus.gaps].
  static String _gapText(DatumGap gap) => switch (gap) {
    DatumGap.vinNotRead => 'VIN 未讀到',
    DatumGap.modelYearUnknown => '年式未知',
    DatumGap.noCatalogMatch => '型錄無匹配',
  };

  static String _originLabel(VehicleFieldOrigin origin) => switch (origin) {
    VehicleFieldOrigin.genericDefault => '通用預設',
    VehicleFieldOrigin.userEntered => '手動輸入',
    VehicleFieldOrigin.officialRegistry => '官方型錄',
    VehicleFieldOrigin.manufacturerPublication => '原廠資料',
    VehicleFieldOrigin.scientificModel => '模型係數',
  };
}

extension on DatumStatus {
  DatumStatus letQuality(DatumQuality? quality) {
    if (quality == null || quality == this.quality) return this;
    return DatumStatus(
      availability: availability,
      origin: origin,
      evidence: evidence,
      compatibility: compatibility,
      quality: quality,
      operationRisk: operationRisk,
      reason: quality == DatumQuality.outOfReferenceRange
          ? '超出一般參考範圍，已保留'
          : reason,
      reasonCode: quality == DatumQuality.outOfReferenceRange
          ? DatumReason.outOfReferenceRangeKept
          : reasonCode,
      statusReason: statusReason,
      gaps: gaps,
      nextStep: nextStep,
      formula: formula,
      assumptions: assumptions,
      justUpdated: justUpdated,
    );
  }
}
