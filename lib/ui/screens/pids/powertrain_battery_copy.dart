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
};
