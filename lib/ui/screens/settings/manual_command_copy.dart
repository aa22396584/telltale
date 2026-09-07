/// Shipped copy for a command that failed on a link that was already open.
///
/// `handshake_copy.dart` says the failures of *getting* connected. This file
/// says the failures of a command sent afterwards, which is a different set of
/// facts reaching a different screen: the manual command panel in settings
/// renders the result of one typed command as prose, and it used to render
/// `TransportException.message` — a Traditional Chinese sentence — verbatim, in
/// every language the app ships.
///
/// Like the other copy tables it takes an `AppLocalizations` parameter rather
/// than a `BuildContext`, so a test can walk both languages with no widget
/// pump.
///
/// Three of the command-path identifiers deliberately have no copy here, and
/// that is a finding rather than an omission; [commandFailureNotRenderedYet]
/// says why.
library;

import '../../../l10n/generated/app_localizations.dart';
import '../../../obd/transport/obd_transport.dart';
import '../connect/handshake_copy.dart';

/// The command-path identifiers that no screen can render yet.
///
/// Not an allowance. Each of these is thrown and two of them do reach a
/// screen — but not this one, and the files that would have to change are
/// owned by an unmerged branch:
///
///   * [TransportIssue.wholeVehicleHeaderRefused] and
///     [TransportIssue.legacyScanWouldBePartial] are thrown inside
///     `Elm327Client.sendGlobal`. `polling_engine.dart:1650` catches them and
///     rethrows `DtcReadException(e.message)`, dropping the identifier; the
///     fault-code screen then renders that Chinese message. Restoring it needs
///     two optional fields on `DtcReadException`, one line in
///     `polling_engine.dart` and two in `dtc_screen.dart`, all of which
///     `feat/l04-dtc-labels` currently owns.
///   * [TransportIssue.queryHeaderRefused] is thrown inside
///     `Elm327Client.sendOnHeader`, which the polling loop reaches through
///     `sendAddressed`. The loop treats a `TransportException` as a retryable
///     timeout, so this one is not rendered as prose anywhere at all.
///
/// Writing English for them here would put entries in the ARB files that no
/// screen can reach, which `dtc_screen.dart:848` already refuses by name: "an
/// ARB entry no screen can render is one a translator has to guess at". So
/// they carry an identifier — the guard requires that, and the identifier plus
/// `TransportException.issueDetail` is exactly what the follow-up routes — and
/// no sentence.
const commandFailureNotRenderedYet = <TransportIssue>{
  TransportIssue.queryHeaderRefused,
  TransportIssue.wholeVehicleHeaderRefused,
  TransportIssue.legacyScanWouldBePartial,
};

/// What a failed command reads like, or null when nothing here can say it.
///
/// Null has two causes and they are not the same: an exception carrying no
/// identifier at all (the six in `lib/state/obd_session.dart`, still to be
/// migrated — ImL1s/telltale#45), and one whose identifier is in
/// [commandFailureNotRenderedYet]. Both fall back to the Chinese sentence at
/// the call site, which is the behaviour this file exists to remove and has
/// removed for everything else.
///
/// Connect-path identifiers are answered by delegating to [transportIssueText]
/// rather than by returning null. One cannot arrive here — this panel only
/// exists while connected — but returning null for them would be a silent
/// route back to the raw sentence, and this file is what that route was
/// replaced with.
///
/// The switch is written out in full, with no `_` arm. A default would take a
/// new [TransportIssue] and quietly hand it to the connect screen's table,
/// which is where the last such identifier came from and the reason this file
/// exists.
String? commandFailureText(AppLocalizations l10n, TransportException error) {
  final issue = error.issue;
  if (issue == null) return null;
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

    // See [commandFailureNotRenderedYet].
    TransportIssue.queryHeaderRefused ||
    TransportIssue.wholeVehicleHeaderRefused ||
    TransportIssue.legacyScanWouldBePartial => null,

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
