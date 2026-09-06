/// Shipped copy for the data-status vocabulary in `lib/diagnostics`.
///
/// The engine keeps the distinctions and this file keeps the words. Every
/// function takes an [AppLocalizations] rather than a [BuildContext], for the
/// same reason `telemetry_status_copy.dart` does: half of this is chosen from
/// places with no widget above them, and a pure-Dart test can then assert both
/// languages with `lookupAppLocalizations(...)` and no widget pump.
///
/// What deliberately does NOT live here: the *strings*
/// [DatumStatus.reason], [DatumStatus.formula] and [DatumStatus.assumptions],
/// because `AvailabilityPolicy.exportFields` writes them into telemetry
/// exports. Two people comparing one evidence file cannot do it if its wording
/// follows a phone setting.
///
/// That argument is about what gets *stored*, and for a while it was quietly
/// applied to what gets *shown* as well: `datum_status_badge.dart` rendered the
/// exported formula and assumptions verbatim, so an English reader who opened
/// the estimate details dialog got a wall of Chinese. The split
/// [datumReasonText] already made is now made three times —
/// [DatumStatus.reasonCode], [DatumStatus.formulaCode] and
/// [DatumStatus.assumptionFields] are what the screen renders, and the exported
/// sentences are left alone.
library;

import '../../../diagnostics/availability.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../obd/physics/vehicle_evidence.dart';
import '../../screens/settings/vehicle_profile_copy.dart';
import '../telemetry/telemetry_status_copy.dart';

/// One badge word.
///
/// Every line here draws a distinction the app exists to draw, and the
/// @-descriptions in `app_en.arb` say which. Estimated is not measured,
/// unverified is neither invalid nor verified, partial is not all clear, stale
/// is not live, out-of-range means a check ran and failed, and demo has to be
/// unmistakable.
String datumBadgeLabel(AppLocalizations l10n, DatumBadge badge) =>
    switch (badge) {
      DatumBadge.estimated => l10n.datumBadgeEstimated,
      DatumBadge.userSupplied => l10n.datumBadgeUserSupplied,
      DatumBadge.demo => l10n.datumBadgeDemo,
      DatumBadge.fieldVerified => l10n.datumBadgeFieldVerified,
      DatumBadge.communityDecode => l10n.datumBadgeCommunityDecode,
      DatumBadge.unverifiedOnThisVehicle =>
        l10n.datumBadgeUnverifiedOnThisVehicle,
      DatumBadge.experimental => l10n.datumBadgeExperimental,
      DatumBadge.unverified => l10n.datumBadgeUnverified,
      DatumBadge.outOfReferenceRange => l10n.datumBadgeOutOfReferenceRange,
      DatumBadge.stale => l10n.datumBadgeStale,
      DatumBadge.partial => l10n.datumBadgePartial,
      DatumBadge.tentativeDecode => l10n.datumBadgeTentativeDecode,
      DatumBadge.invalid => l10n.datumBadgeInvalid,
      DatumBadge.justUpdated => l10n.datumBadgeJustUpdated,
    };

/// The badge line under a value, or the empty string when nothing is flagged.
///
/// The separator is the same middot the rest of the app composes with, and the
/// dashboard's English scan splits on it — so it must stay ` · `.
String datumBadgeText(AppLocalizations l10n, DatumStatus status) =>
    status.badges.map((badge) => datumBadgeLabel(l10n, badge)).join(' · ');

String datumGapLabel(AppLocalizations l10n, DatumGap gap) => switch (gap) {
  DatumGap.vinNotRead => l10n.datumGapVinNotRead,
  DatumGap.modelYearUnknown => l10n.datumGapModelYearUnknown,
  DatumGap.noCatalogMatch => l10n.datumGapNoCatalogMatch,
};

String datumReasonLabel(AppLocalizations l10n, DatumReason reason) =>
    switch (reason) {
      DatumReason.malformedPacket => l10n.datumReasonMalformedPacket,
      DatumReason.nonFiniteValue => l10n.datumReasonNonFiniteValue,
      DatumReason.outOfReferenceRangeKept =>
        l10n.datumReasonOutOfReferenceRangeKept,
      DatumReason.unsafeServiceStopped => l10n.datumReasonUnsafeServiceStopped,
      DatumReason.unsafeService => l10n.datumReasonUnsafeService,
      DatumReason.pidUnsupported => l10n.datumReasonPidUnsupported,
      DatumReason.noAnswer => l10n.datumReasonNoAnswer,
      DatumReason.busError => l10n.datumReasonBusError,
      DatumReason.formulaError => l10n.datumReasonFormulaError,
      DatumReason.headerNotOnThisBus => l10n.datumReasonHeaderNotOnThisBus,
      DatumReason.noReadingYet => l10n.datumReasonNoReadingYet,
      DatumReason.horsepowerEstimateMissingInputs =>
        l10n.datumReasonHorsepowerEstimateMissingInputs,
      DatumReason.fuelEstimateMissingInputs =>
        l10n.datumReasonFuelEstimateMissingInputs,
      DatumReason.assumptionsUnconfirmed =>
        l10n.datumReasonAssumptionsUnconfirmed,
    };

String datumNextStepLabel(AppLocalizations l10n, DatumNextStep step) =>
    switch (step) {
      DatumNextStep.genericObdContinues => l10n.datumNextStepGenericObd,
      DatumNextStep.rawOnlyNeverANumber => l10n.datumNextStepRawOnly,
      DatumNextStep.otherReadingsUnaffected => l10n.datumNextStepOtherReadings,
      DatumNextStep.estimateOnlyOtherReadingsUnaffected =>
        l10n.datumNextStepEstimateOnly,
    };

/// What the details dialog shows above the formula.
///
/// The gaps come first because a status that has them has no other reason, and
/// [DatumStatus.reason] is the last resort: it is the exported sentence, so
/// reaching it means some producer has not been given a code yet.
String? datumReasonText(AppLocalizations l10n, DatumStatus status) {
  if (status.gaps.isNotEmpty) {
    return status.gaps.map((gap) => datumGapLabel(l10n, gap)).join(' · ');
  }
  final code = status.reasonCode;
  if (code != null) return datumReasonLabel(l10n, code);
  final recorded = status.statusReason;
  if (recorded != null) return telemetryStatusLabel(l10n, recorded);
  return status.reason;
}

/// The formula shown above the assumptions.
///
/// Falls back to the exported string when a producer has not been given a code,
/// on the same reasoning as [datumReasonText]: a formula in the wrong language
/// is still checkable arithmetic, and showing nothing would be worse.
String? datumFormulaText(AppLocalizations l10n, DatumStatus status) =>
    switch (status.formulaCode) {
      DatumFormula.horsepower => l10n.datumFormulaHorsepower,
      DatumFormula.fuelRate => l10n.datumFormulaFuelRate,
      null => status.formula,
    };

/// What an estimate rests on, one parameter per clause.
///
/// Returns null rather than an empty string when there is nothing structured to
/// show, so the caller can drop the whole section instead of printing a heading
/// over a blank.
///
/// The drivetrain's name is appended to its efficiency here rather than being
/// baked into [VehicleAssumption.value], because it is a word and words belong
/// to the reader's language. It arrives on the assumption itself, as does the
/// fuel type, so this needs no `VehicleProfile` — the parameter existed, one of
/// two callers forgot it, and the fuel's name silently became a blank.
String? assumptionsText(AppLocalizations l10n, DatumStatus status) {
  if (status.assumptionFields.isEmpty) {
    // The app speaking for itself, keyed.
    if (status.assumptionNote == DatumAssumptionNote.recordedVehicleSettings) {
      return l10n.datumAssumptionsFromRecording;
    }
    // Anything left is a sentence a recording stored. It is a quotation from an
    // evidence file, in whatever language that file was written, and it is
    // shown as written — translating a record would be inventing one.
    return status.assumptions;
  }
  final parts = status.assumptionFields.map((assumption) {
    final field = assumptionFieldLabel(l10n, assumption.field);
    // Exhaustive, with nothing to fall through to. A fourth kind of value
    // breaks the compile here and in `AvailabilityPolicy._exportNote` at the
    // same time, which is what makes "decide how this is worded" impossible to
    // skip. The previous shape dispatched on which nullable field was set and
    // ended in `: assumption.value` — so a new word-valued parameter rendered
    // its frozen export wording on the English screen, caught only if that
    // wording happened to contain Han characters.
    final value = switch (assumption.value) {
      MeasuredValue(:final formatted) => formatted,
      FuelValue(:final fuel) => fuelTypeLabel(l10n, fuel),
      DrivetrainValue(:final percent, :final drivetrain) =>
        '$percent ${drivetrainLabel(l10n, drivetrain)}',
    };
    final origin = assumption.origin;
    return origin == null
        ? l10n.assumptionWithoutOrigin(field, value)
        : l10n.assumptionWithOrigin(
            field,
            value,
            vehicleFieldOriginLabel(l10n, origin),
          );
  });
  return parts.join(l10n.assumptionSeparator);
}

/// One vehicle parameter's name.
String assumptionFieldLabel(AppLocalizations l10n, AssumptionField field) =>
    switch (field) {
      AssumptionField.mass => l10n.assumptionFieldMass,
      AssumptionField.dragCoefficient => l10n.assumptionFieldDragCoefficient,
      AssumptionField.frontalArea => l10n.assumptionFieldFrontalArea,
      AssumptionField.rollingResistance =>
        l10n.assumptionFieldRollingResistance,
      AssumptionField.drivetrainEfficiency =>
        l10n.assumptionFieldDrivetrainEfficiency,
      AssumptionField.fuelType => l10n.assumptionFieldFuelType,
      AssumptionField.stoichAfr => l10n.assumptionFieldStoichAfr,
      AssumptionField.fuelDensity => l10n.assumptionFieldFuelDensity,
      AssumptionField.displacement => l10n.assumptionFieldDisplacement,
      AssumptionField.volumetricEfficiency =>
        l10n.assumptionFieldVolumetricEfficiency,
    };

/// Where a parameter's value came from.
///
/// These five are not interchangeable and must not be smoothed into each other
/// in translation. "Generic default" means the app knows nothing about this
/// vehicle; "official registry" means it matched a record. A reader deciding
/// whether to trust a power figure is deciding on exactly this word.
String vehicleFieldOriginLabel(
  AppLocalizations l10n,
  VehicleFieldOrigin origin,
) => switch (origin) {
  VehicleFieldOrigin.genericDefault => l10n.vehicleFieldOriginGenericDefault,
  VehicleFieldOrigin.userEntered => l10n.vehicleFieldOriginUserEntered,
  VehicleFieldOrigin.officialRegistry =>
    l10n.vehicleFieldOriginOfficialRegistry,
  VehicleFieldOrigin.manufacturerPublication =>
    l10n.vehicleFieldOriginManufacturerPublication,
  VehicleFieldOrigin.scientificModel => l10n.vehicleFieldOriginScientificModel,
};
