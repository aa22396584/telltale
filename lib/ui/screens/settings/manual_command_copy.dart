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
///
/// The panel's other half is [manualCommandRefusalText]. A command this app
/// refuses to send never becomes a `TransportException` at all — no link is
/// involved and nothing was written — so it arrives as a
/// `ManualCommandRefusedException` carrying a `ManualCommandRefusal`, and the
/// two tables meet only at the screen.
library;

import '../../../l10n/generated/app_localizations.dart';
import '../../../obd/transport/obd_transport.dart';
import '../../../state/manual_command_refusal.dart';
import '../connect/handshake_copy.dart';

/// What a failed command reads like, or null when nothing here can say it.
///
/// Null means one thing only, and the set is now closed: the `TransportException`
/// subclasses that bake `issue: null` into their own constructors. The roster
/// test in `test/l10n/transport_issue_guard_test.dart` is what keeps it closed —
/// a fourth subclass has to be written into it by hand — and two of the three
/// can reach this panel, because `write()` is on the path a typed command
/// takes. `SettingsScreen.describeManualFailure` says which and what it does
/// with them.
///
/// `lib/state/obd_session.dart`'s throws are no longer part of that remainder.
/// One of them carries `TransportIssue.notConnected`; the other five are
/// refusals, which are not transport failures and are answered by
/// [manualCommandRefusalText].
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
    TransportIssue.operationRetired =>
      l10n.settingsManualCommandOperationRetired,
    TransportIssue.requestUnaddressable =>
      l10n.settingsManualCommandRequestUnaddressable,
    TransportIssue.busNotObd2 => switch (named) {
      'J1939' => l10n.commandFailureBusJ1939,
      'B' => l10n.commandFailureUserCanFramingUnknown('B', 'PP 2C'),
      'C' => l10n.commandFailureUserCanFramingUnknown('C', 'PP 2E'),
      _ => l10n.commandFailureBusUndetermined,
    },

    // The three whose sentence names an address.
    TransportIssue.queryHeaderRefused =>
      l10n.commandFailureQueryHeaderRefused(named),
    TransportIssue.wholeVehicleHeaderRefused =>
      l10n.commandFailureWholeVehicleHeaderRefused(named),
    TransportIssue.legacyScanWouldBePartial =>
      l10n.commandFailureLegacyScanWouldBePartial(named),
    TransportIssue.customFlowControlRejected =>
      l10n.settingsManualCommandCustomFlowControlRejected,
    TransportIssue.flowControlRestoreFailed =>
      l10n.settingsManualCommandFlowControlRestoreFailed,
    TransportIssue.extendedAddressingUnavailable =>
      l10n.settingsManualCommandExtendedAddressingUnavailable,
    TransportIssue.rawIsoTpModeUnavailable =>
      l10n.settingsManualCommandRawIsoTpModeUnavailable,
    TransportIssue.canPriorityUnavailable =>
      l10n.settingsManualCommandCanPriorityUnavailable,
    TransportIssue.canReceiveFilterUnavailable =>
      l10n.settingsManualCommandCanReceiveFilterUnavailable,

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

/// What a command this app refused to send reads like.
///
/// A refusal is not a failure: nothing was attempted, and every one of these
/// is a decision the app made about the text in the box. They used to be six
/// Traditional Chinese sentences composed in `lib/state/`, thrown as a
/// `TransportException` with no identifier, and rendered verbatim in every
/// language the app ships.
///
/// Two arms print values the refusal carries rather than values spelled into
/// the copy. [ManualCommandRefusal.allowed] is joined here, with the
/// separator the reader's language uses, because `、` in engine code is the
/// half of a translation that gets left behind.
///
/// The switch is written out in full with no `_` arm: a refusal added to
/// [ManualCommandRefusalReason] must fail to compile until somebody writes its
/// words, rather than silently borrowing a neighbour's sentence.
String manualCommandRefusalText(
  AppLocalizations l10n,
  ManualCommandRefusal refusal,
) {
  final allowed = refusal.allowed.join(l10n.settingsListSeparator);
  return switch (refusal.issue) {
    ManualCommandRefusalReason.emptyCommand => l10n.manualCommandRefusedEmpty,
    ManualCommandRefusalReason.moreThanOneCommand =>
      l10n.manualCommandRefusedMoreThanOneCommand,
    ManualCommandRefusalReason.adapterStateWouldChange =>
      l10n.manualCommandRefusedAdapterStateWouldChange(
        refusal.command,
        allowed,
      ),
    ManualCommandRefusalReason.clearHasItsOwnButton =>
      l10n.manualCommandRefusedClearHasItsOwnButton,
    ManualCommandRefusalReason.charactersNoObdCommandHas =>
      l10n.manualCommandRefusedCharactersNoObdCommandHas(refusal.command),
    ManualCommandRefusalReason.notAReadOnlyQuery =>
      l10n.manualCommandRefusedNotAReadOnlyQuery(refusal.command, allowed),
  };
}
