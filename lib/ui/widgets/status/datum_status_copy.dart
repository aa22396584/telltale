/// Shipped copy for the data-status vocabulary in `lib/diagnostics`.
///
/// The engine keeps the distinctions and this file keeps the words. Every
/// function takes an [AppLocalizations] rather than a [BuildContext], for the
/// same reason `telemetry_status_copy.dart` does: half of this is chosen from
/// places with no widget above them, and a pure-Dart test can then assert both
/// languages with `lookupAppLocalizations(...)` and no widget pump.
///
/// What deliberately does NOT live here: [DatumStatus.reason],
/// [DatumStatus.formula] and [DatumStatus.assumptions] keep their Chinese,
/// because `AvailabilityPolicy.exportFields` writes them into telemetry
/// exports. Two people comparing one evidence file cannot do it if its wording
/// follows a phone setting. [datumReasonText] renders [DatumStatus.reasonCode]
/// on screen and leaves the exported sentence alone.
library;

import '../../../diagnostics/availability.dart';
import '../../../l10n/generated/app_localizations.dart';
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
