/// Shipped copy for a command that failed on a link that was already open.
///
/// `handshake_copy.dart` says the failures of *getting* connected. This file
/// says the failures of a command sent afterwards, which is a different set of
/// facts: the settings manual command panel renders the result of one typed
/// command as prose, and it used to render `TransportException.message` — a
/// Traditional Chinese sentence — verbatim, in every language the app ships.
///
/// Two screens, not one. The settings panel asks [commandFailureText] with the
/// exception it caught; the fault-code screen reaches the same table through
/// [commandIssueText], because a scan is a command on an open link too and its
/// failures are the same failures. This file therefore lives under `settings/`
/// for history rather than for ownership, and the name that matters is
/// `commandFailure`, not `settingsManualCommand`.
///
/// **The scan is the only one wired.** A clear and a VIN read also reach
/// `sendGlobal` and can raise the same identifiers, and neither carries one to
/// a screen: `PollingEngine.clearDtcs` lets the `TransportException` escape
/// uncaught into `dtc_scan.dart`'s `on Object`, which interpolates
/// `toString()` -- and `toString()` prints the message and drops the issue --
/// into a Chinese wrapper sentence; `readVin`'s is discarded outright. Both
/// render exactly what they rendered before this file existed. They are not
/// wired here because the clear panel's own prose is still engine-composed
/// Traditional Chinese, so an identifier arriving there would be a field
/// nothing reads. ImL1s/telltale#45 owns that, and until it lands this
/// paragraph is the honest description of the reach.
///
/// Like the other copy tables it takes an `AppLocalizations` parameter rather
/// than a `BuildContext`, so a test can walk both languages with no widget
/// pump.
///
/// There is no roster of identifiers this file declines to answer. There was
/// one — three command-path identifiers whose sentences name a controller
/// address carried no copy, on the reasoning that nothing rendered them yet —
/// and it was an exception list in shipped code that the tests then had to skip
/// on. The identifiers are carried through `DtcReadException` now and every one
/// of them is answered below.
library;

import '../../../l10n/generated/app_localizations.dart';
import '../../../obd/transport/obd_transport.dart';
import '../connect/handshake_copy.dart';

/// What a failed command reads like, or null when nothing here can say it.
///
/// Null means one thing only: an exception carrying no identifier at all (the
/// six in `lib/state/obd_session.dart`, still to be migrated —
/// ImL1s/telltale#45). Those fall back to the Chinese sentence at the call
/// site, which is the behaviour this file exists to remove and has removed for
/// everything else.
String? commandFailureText(AppLocalizations l10n, TransportException error) {
  final issue = error.issue;
  if (issue == null) return null;
  return commandIssueText(l10n, issue, detail: error.issueDetail);
}

/// The same table, reached by an identifier rather than by an exception.
///
/// The fault-code screen needs this shape: what it holds is a
/// `DtcReadException` that carried the identifier out of the transport, not the
/// `TransportException` itself.
///
/// [detail] is the one value a sentence may have to name — the header the
/// adapter refused, or the one it is stuck on. Three identifiers interpolate
/// it; the guard in `test/l10n/transport_issue_guard_test.dart` is what stops a
/// throw naming one of those three without passing it. Empty rather than null
/// where it is missing, because a sentence with a hole in it is still a
/// sentence and an exception thrown while rendering an error is not.
///
/// Connect-path identifiers are answered by delegating to [transportIssueText]
/// rather than by returning null. One cannot arrive from the settings panel —
/// it only exists while connected — but returning null for them would be a
/// silent route back to the raw sentence, and this file is what that route was
/// replaced with.
///
/// The nullable return is that delegation's type and nothing else: every arm
/// below answers, and `transportIssueText` returns null only for the identifier
/// it hands back here. A `!` would turn a future gap into an exception raised
/// while rendering an error message, which is the one place a crash is least
/// affordable, so the guard asserts non-null for every identifier instead.
///
/// The switch is written out in full, with no `_` arm. A default would take a
/// new [TransportIssue] and quietly hand it to the connect screen's table,
/// which is where the last such identifier came from and the reason this file
/// exists.
String? commandIssueText(
  AppLocalizations l10n,
  TransportIssue issue, {
  String? detail,
}) {
  final named = detail ?? '';
  return switch (issue) {
    TransportIssue.notConnected => l10n.settingsManualCommandNotConnected,
    TransportIssue.linkDroppedMidSession =>
      l10n.settingsManualCommandLinkDropped,
    TransportIssue.disconnectedByApp =>
      l10n.settingsManualCommandDisconnectedByApp,
    TransportIssue.adapterSilentOnResync =>
      l10n.settingsManualCommandAdapterSilentOnResync,
    TransportIssue.linkStoppedResponding =>
      l10n.settingsManualCommandLinkStoppedResponding,
    TransportIssue.writeFailed => l10n.settingsManualCommandWriteFailed,

    // The three whose sentence names an address.
    TransportIssue.queryHeaderRefused =>
      l10n.commandFailureQueryHeaderRefused(named),
    TransportIssue.wholeVehicleHeaderRefused =>
      l10n.commandFailureWholeVehicleHeaderRefused(named),
    TransportIssue.legacyScanWouldBePartial =>
      l10n.commandFailureLegacyScanWouldBePartial(named),

    // The connect screen's half, delegated rather than duplicated.
    TransportIssue.cancelled ||
    TransportIssue.wifiRouteNoNetwork ||
    TransportIssue.wifiRouteAmbiguous ||
    TransportIssue.wifiRouteRefused ||
    TransportIssue.wifiRouteTimeout ||
    TransportIssue.wifiRouteUnclassified ||
    TransportIssue.wifiHostUnreachable ||
    TransportIssue.wifiConnectTimeout ||
    TransportIssue.wifiRouteRestoreFailed ||
    TransportIssue.bleLinkFailed ||
    TransportIssue.bleNoSerialCharacteristic ||
    TransportIssue.classicAllTiersRefused ||
    TransportIssue.classicConnectTimeout ||
    TransportIssue.serialPortOpenFailed ||
    TransportIssue.serialDroppedOnOpen => transportIssueText(l10n, issue),
  };
}
