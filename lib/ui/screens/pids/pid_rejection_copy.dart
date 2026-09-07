/// Screen copy for the one rule that decides whether a PID definition is
/// admissible.
///
/// `PollableServices.rejectionReason` and `PidDefinition.rejectionReason` are
/// the safety and sanity gate on both doors onto a car's bus — the custom-PID
/// editor and the CSV importer — and they live in `lib/obd/pid/pid.dart`, which
/// has no language. They hand out a [PidRejectionReason]: an identifier plus
/// the values the sentence names. The words are here.
///
/// The list joins go through `pidListSeparator`, which is `, ` in English and
/// `、` in Traditional Chinese. Writing either separator into this file would
/// be the defect `no_cjk_punctuation_in_ui_source_test.dart` exists to catch:
/// an English build rendering `01、02、09、22`.
library;

import '../../../l10n/generated/app_localizations.dart';
import '../../../obd/pid/pid.dart';

/// Why [reason] cannot be polled or saved, in the reader's language.
///
/// Not nullable: [PidRejectionReason.issue] is not, so every value reaches a
/// sentence and a new one is a compile error in the switch below.
String pidRejectionText(AppLocalizations l10n, PidRejectionReason reason) {
  // Exhaustive, with no default arm.
  return switch (reason.issue) {
    PidRejection.malformedModeAndPid => l10n.pidRejectionMalformedModeAndPid,
    PidRejection.serviceNotReadOnly => l10n.pidRejectionServiceNotReadOnly(
      reason.service ?? '',
      (reason.allowedServices ?? const <String>[]).join(l10n.pidListSeparator),
    ),
    PidRejection.freezeFrameNeedsFrame =>
      l10n.pidRejectionFreezeFrameNeedsFrame,
    PidRejection.identifierNeedsTwoBytes =>
      l10n.pidRejectionIdentifierNeedsTwoBytes,
    PidRejection.identifierWrongLength =>
      l10n.pidRejectionIdentifierWrongLength(
        reason.service ?? '',
        reason.expectedBytes ?? 0,
      ),
    PidRejection.nameRequired => l10n.pidRejectionNameRequired,
    PidRejection.invalidHeader => l10n.pidRejectionInvalidHeader(
      reason.text ?? '',
    ),
    PidRejection.boundsRequired => l10n.pidRejectionBoundsRequired,
    PidRejection.minNotANumber => l10n.pidRejectionMinNotANumber(
      reason.text ?? '',
    ),
    PidRejection.maxNotANumber => l10n.pidRejectionMaxNotANumber(
      reason.text ?? '',
    ),
    PidRejection.minNotFinite => l10n.pidRejectionMinNotFinite,
    PidRejection.maxNotFinite => l10n.pidRejectionMaxNotFinite,
    PidRejection.redlineNotANumber => l10n.pidRejectionRedlineNotANumber(
      reason.text ?? '',
    ),
    PidRejection.redlineNotFinite => l10n.pidRejectionRedlineNotFinite,
    PidRejection.maxNotAboveMin => l10n.pidRejectionMaxNotAboveMin,
  };
}
