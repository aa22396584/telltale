/// Shipped copy for [AdapterConcernKind].
///
/// This is the clone-adapter detection — the thing the store listing means by
/// "when it is unsure, it says so", and the thing an independent developer on
/// r/CarHacking described as the first rule of talking to an ELM327: half of
/// them report v1.5 and behave like v1.3, so verify what comes back rather than
/// what it calls itself.
///
/// The words used to be `String summary` and `String detail` on
/// `AdapterConcern` itself, in Traditional Chinese, rendered straight by
/// `settings_screen.dart`. An English reader with a suspect adapter therefore
/// got a ⚠ and a paragraph they could not read — while the surrounding
/// "no contradictions" line and the footer were both already localized. The
/// app spoke English when it had nothing to report and Chinese when it did.
library;

import '../../../l10n/generated/app_localizations.dart';
import '../../../obd/adapter_identity.dart';

/// One line, for the list.
String adapterConcernSummary(AppLocalizations l10n, AdapterConcern concern) {
  // `?? ''` rather than a fallback version string: the two kinds that quote a
  // version are only ever constructed with one, and inventing a number here
  // would put a fabricated version in front of a reader who is being told not
  // to trust the one the adapter gave.
  final version = concern.version ?? '';
  return switch (concern.kind) {
    AdapterConcernKind.firmwareNeverReleased =>
      l10n.adapterConcernFirmwareNeverReleasedSummary(version),
    AdapterConcernKind.ppsRefusedDespiteVersion =>
      l10n.adapterConcernPpsRefusedSummary(version),
    AdapterConcernKind.noIdentityResponse =>
      l10n.adapterConcernNoIdentitySummary,
  };
}

/// What was observed, and why it means anything.
String adapterConcernDetail(AppLocalizations l10n, AdapterConcern concern) =>
    switch (concern.kind) {
      AdapterConcernKind.firmwareNeverReleased =>
        l10n.adapterConcernFirmwareNeverReleasedDetail,
      AdapterConcernKind.ppsRefusedDespiteVersion =>
        l10n.adapterConcernPpsRefusedDetail,
      AdapterConcernKind.noIdentityResponse =>
        l10n.adapterConcernNoIdentityDetail,
    };
