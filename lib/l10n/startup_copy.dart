import 'generated/app_localizations.dart';

/// Title on the pre-router startup screen.
///
/// Loading, retryable failure, and restart-required are three states.
/// They must not share copy.
String startupStatusTitle({
  required AppLocalizations l10n,
  required bool loading,
  required bool restartRequired,
}) {
  if (loading) return l10n.startupChecking;
  if (restartRequired) return l10n.startupRestartRequired;
  return l10n.startupCannotComplete;
}
