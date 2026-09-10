/// Screen words for the engine's experimental-probe refusal identifiers.
///
/// `PowertrainExperimentalProbeConsents.authorize` used to answer with a
/// Traditional Chinese sentence and the screen wrapped it in
/// `powertrainNotAuthorized` — a localized frame around an unlocalized blob, so
/// an English reader was refused with `Not authorized: 目錄完整性雜湊無效`. The
/// frame is gone: each identifier owns one whole sentence, because a frame
/// plus a full sentence reads worse in English than one sentence written for
/// the refusal it describes, and it forces every future translation into the
/// clause order of whichever language the frame was written in.
///
/// Takes an [AppLocalizations] rather than a [BuildContext], like every other
/// `*_copy.dart` in this tree: nothing here is chosen inside a widget that owns
/// a context, and a pure-Dart test can then walk every arm in both languages
/// without pumping a frame.
library;

import '../../../l10n/generated/app_localizations.dart';
import '../../../obd/powertrain_battery/profile_catalog_validator.dart';
import '../../../obd/powertrain_battery/profile_pid_installer.dart';
import '../../../state/powertrain_battery_profiles.dart';

/// One whole sentence per refusal identifier.
///
/// The switch is exhaustive with no `_` arm on purpose: a refusal added to
/// [PowertrainProbeRefusal] must fail to compile until somebody writes its
/// copy, rather than silently rendering a neighbour's sentence.
///
/// [attemptCap] is rendered by exactly one arm. It is passed rather than
/// spelled into the copy so that raising
/// [PowertrainExperimentalProbeConsents.maxAttemptsPerCommand] cannot leave
/// three translations claiming the old number.
String powertrainProbeRefusalText(
  AppLocalizations l10n,
  PowertrainProbeRefusal refusal, {
  required int attemptCap,
}) => switch (refusal) {
  PowertrainProbeRefusal.labClosed => l10n.powertrainRefusedLabClosed,
  PowertrainProbeRefusal.catalogHashInvalid =>
    l10n.powertrainRefusedCatalogHashInvalid,
  PowertrainProbeRefusal.profileNotInCatalog =>
    l10n.powertrainRefusedProfileNotInCatalog,
  PowertrainProbeRefusal.profileNotProbeable =>
    l10n.powertrainRefusedProfileNotProbeable,
  PowertrainProbeRefusal.profileFailedValidation =>
    l10n.powertrainRefusedProfileFailedValidation,
  PowertrainProbeRefusal.commandNotInProfile =>
    l10n.powertrainRefusedCommandNotInProfile,
  PowertrainProbeRefusal.quarantinedAtAttemptCap =>
    l10n.powertrainRefusedQuarantinedAtAttemptCap(attemptCap),
  PowertrainProbeRefusal.quarantinedAfterRejectedRead =>
    l10n.powertrainRefusedQuarantinedAfterRejectedRead,

  // The session's own three. Everything above is the consent ledger answering
  // before a read begins; these are the session refusing to start one, or
  // refusing to publish what it got. They arrived here as
  // `l10n.powertrainProbeDidNotFinish` — one sentence for every outcome — so a
  // driver who was simply not connected read the same words as one whose
  // adapter failed mid-read, and the last of the three read as a failure when
  // what happened is that a result was deliberately not kept.
  PowertrainProbeRefusal.notConnectedOrNotInForeground =>
    l10n.powertrainRefusedNotConnectedOrNotInForeground,
  PowertrainProbeRefusal.noLiveAuthorization =>
    l10n.powertrainRefusedNoLiveAuthorization,
  PowertrainProbeRefusal.discardedAtLifecycleBoundary =>
    l10n.powertrainRefusedDiscardedAtLifecycleBoundary,
};

/// One whole sentence per install refusal. Exhaustive: a new
/// [PowertrainProfileInstallIssue] must fail to compile here rather than
/// fall back to `exception.message`.
/// Connection-confirm refusals. [PowertrainBatteryProfileIssue.message] is
/// an English diagnostic for the catalog log; the snack must not interpolate
/// it. Unknown codes use [AppLocalizations.powertrainProfileNotVerified]
/// rather than the engine sentence.
String powertrainProfileIssueText(
  AppLocalizations l10n,
  PowertrainBatteryProfileIssue issue,
) => switch (issue.code) {
  'vehicle_year_out_of_range' => l10n.powertrainAuthorizeYearOutOfRange,
  _ => l10n.powertrainProfileNotVerified,
};

String powertrainInstallIssueText(
  AppLocalizations l10n,
  PowertrainProfileInstallIssue issue,
) => switch (issue) {
  PowertrainProfileInstallIssue.catalogShaMissing =>
    l10n.powertrainInstallCatalogShaMissing,
  PowertrainProfileInstallIssue.profileNotInCatalog =>
    l10n.powertrainInstallProfileNotInCatalog,
  PowertrainProfileInstallIssue.yearOutOfRange =>
    l10n.powertrainInstallYearOutOfRange,
  PowertrainProfileInstallIssue.profileNotInstallable =>
    l10n.powertrainInstallProfileNotInstallable,
  PowertrainProfileInstallIssue.persistFailed =>
    l10n.powertrainInstallPersistFailed,
};
