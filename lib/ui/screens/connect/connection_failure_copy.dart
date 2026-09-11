/// Screen copy for [ConnectionFailureAction].
library;

import '../../../diagnostics/connection_failure_actions.dart';
import '../../../l10n/generated/app_localizations.dart';

String connectionFailureActionText(
  AppLocalizations l10n,
  ConnectionFailureAction action,
) => switch (action) {
  ConnectionFailureAction.openSettings => l10n.connectionFailureOpenSettings,
  ConnectionFailureAction.turnRadioOn => l10n.connectionFailureTurnRadioOn,
  ConnectionFailureAction.checkDistanceOrPower =>
    l10n.connectionFailureCheckDistanceOrPower,
  ConnectionFailureAction.checkIgnitionProtocolAdapter =>
    l10n.connectionFailureCheckIgnitionProtocolAdapter,
  ConnectionFailureAction.retryOrAuto => l10n.connectionFailureRetryOrAuto,
  ConnectionFailureAction.keepInvalidAndExport =>
    l10n.connectionFailureKeepInvalidAndExport,
};
