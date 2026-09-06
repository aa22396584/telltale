/// Shipped copy for the AT handshake, which runs in front of the user.
///
/// `lib/obd` is pure Dart and may not reach for `AppLocalizations`, so the
/// engine reports identifiers — a command string, an [InitNote], an
/// [Elm327ErrorCode] — and this file says them. Like the other copy tables it
/// takes an `AppLocalizations` parameter rather than a `BuildContext`, so a
/// test can walk both languages with no widget pump.
///
/// [InitProgress.detail] is deliberately still consulted, last. Some of what
/// arrives there is not copy at all: the adapter's version string, its battery
/// voltage, the protocol it settled on, or the text of an exception nothing
/// else identifies. Those are shown exactly as they arrived.
library;

import '../../../l10n/generated/app_localizations.dart';
import '../../../obd/elm327_client.dart';
import '../../../obd/transport/obd_transport.dart';
import '../../../state/obd_session.dart';

/// What a handshake command is for.
///
/// Keyed on the command, which is the identifier the engine already has and
/// the one the row prints beside this sentence. An unknown command falls back
/// to itself rather than to a wrong explanation.
String initStepPurposeLabel(AppLocalizations l10n, String command) =>
    switch (command) {
      'ATZ' => l10n.handshakeStepReset,
      'ATE0' => l10n.handshakeStepEchoOff,
      'ATL0' => l10n.handshakeStepLinefeedsOff,
      'ATM0' => l10n.handshakeStepMemoryOff,
      'ATS0' => l10n.handshakeStepSpacesOff,
      'ATAT1' => l10n.handshakeStepAdaptiveTiming,
      'ATST66' => l10n.handshakeStepResponseTimeout,
      'ATSP0' => l10n.handshakeStepProtocolAuto,
      'ATI' => l10n.handshakeStepAdapterVersion,
      'AT@1' => l10n.handshakeStepDeviceIdentity,
      'ATRV' => l10n.handshakeStepBatteryVoltage,
      '0100' => l10n.handshakeStepSupportProbe,
      'ATDP' => l10n.handshakeStepProtocolDescription,
      'ATDPN' => l10n.handshakeStepProtocolNumber,
      _ => command,
    };

String initNoteLabel(AppLocalizations l10n, InitNote note) => switch (note) {
  InitNote.aborted => l10n.handshakeNoteAborted,
  InitNote.notAcknowledged => l10n.handshakeNoteNotAcknowledged,
  InitNote.ecuSilent => l10n.handshakeNoteEcuSilent,
  InitNote.ecuRefusedSupportQuery => l10n.handshakeNoteEcuRefusedSupportQuery,
  InitNote.supportMaskTooShort => l10n.handshakeNoteSupportMaskTooShort,
  InitNote.notModeOnePositiveReply =>
    l10n.handshakeNoteNotModeOnePositiveReply,
  InitNote.pidEchoMismatch => l10n.handshakeNotePidEchoMismatch,
  InitNote.timedOut => l10n.handshakeNoteTimedOut,
};

/// What the adapter reported in place of data.
///
/// [Elm327ErrorCode.none] is not an error and has nothing to say, which is why
/// this returns the empty string rather than inventing an "OK".
String adapterErrorLabel(AppLocalizations l10n, Elm327ErrorCode code) =>
    switch (code) {
      Elm327ErrorCode.none => '',
      // Not "the vehicle does not support this". `NO DATA` is the adapter
      // saying nothing arrived before its own timeout — a busy ECU, a receive
      // filter or one aggressive timing window produces it exactly as an
      // absent sensor does.
      Elm327ErrorCode.noData => l10n.adapterErrorNoData,
      Elm327ErrorCode.busInitError => l10n.adapterErrorBusInit,
      Elm327ErrorCode.canError => l10n.adapterErrorCan,
      Elm327ErrorCode.unableToConnect => l10n.adapterErrorUnableToConnect,
      Elm327ErrorCode.stopped => l10n.adapterErrorStopped,
      Elm327ErrorCode.bufferFull => l10n.adapterErrorBufferFull,
      Elm327ErrorCode.busBusy => l10n.adapterErrorBusBusy,
      Elm327ErrorCode.busError => l10n.adapterErrorBus,
      Elm327ErrorCode.dataError => l10n.adapterErrorData,
      Elm327ErrorCode.feedbackError => l10n.adapterErrorFeedback,
      Elm327ErrorCode.lowVoltageReset => l10n.adapterErrorLowVoltageReset,
      Elm327ErrorCode.activityAlert => l10n.adapterErrorActivityAlert,
      Elm327ErrorCode.lowPowerAlert => l10n.adapterErrorLowPowerAlert,
      Elm327ErrorCode.internalError => l10n.adapterErrorInternal,
      Elm327ErrorCode.unknownCommand => l10n.adapterErrorUnknownCommand,
    };

/// The one line a handshake row shows to the right of its command.
///
/// Order matters. An adapter error and a refused reply are both more specific
/// than the step's purpose, and both are more specific than the raw
/// [InitProgress.detail] — which for those cases holds the same sentence in
/// one language.
String initProgressLine(AppLocalizations l10n, InitProgress progress) {
  final note = progress.note;
  if (note != null) return initNoteLabel(l10n, note);
  final code = progress.errorCode;
  if (code != null && code != Elm327ErrorCode.none) {
    return adapterErrorLabel(l10n, code);
  }
  final detail = progress.detail;
  if (detail != null && detail.isNotEmpty) return detail;
  return initStepPurposeLabel(l10n, progress.step.command);
}

/// What a failed step said about itself, or that it said nothing.
///
/// Mirrors `first.detail ?? '無回應'`: unlike [initProgressLine] it never falls
/// back to the step's purpose, because "software-reset the adapter" is not a
/// reason a handshake failed.
String _failureReason(AppLocalizations l10n, InitProgress? step) {
  if (step == null) return l10n.handshakeStepNoReason;
  final note = step.note;
  if (note != null) return initNoteLabel(l10n, note);
  final code = step.errorCode;
  if (code != null && code != Elm327ErrorCode.none) {
    return adapterErrorLabel(l10n, code);
  }
  final detail = step.detail;
  if (detail != null && detail.isNotEmpty) return detail;
  return l10n.handshakeStepNoReason;
}

/// Why the wizard is showing a failure banner.
///
/// Returns null only when neither identifier is set. Both are asked for: the
/// handshake's own diagnosis first, then the transport's. A failure is authored
/// in one place or the other and never both, so the order is a formality rather
/// than a precedence rule -- but it is written down so it stays one.
///
/// When both are null the caller still falls back to [ObdConnectionState.error],
/// which is Traditional Chinese.
///
/// That fallback is kept, but do not read it as a licence. An earlier version of
/// this comment claimed it was live because `elm327_client` and `obd_session`
/// still throw `TransportException` without an identifier. Review traced it: all
/// eight `elm327_client` throws are reachable only inside `send()`, whose three
/// callers each catch `on Object`, so none escapes `connect()`; the six in
/// `obd_session` are on the raw-terminal and experimental-probe paths, not this
/// screen. `connectExceptionIssue` is non-nullable, so the generic catch always
/// supplies one. On the connect screen the fallback is now effectively dead.
///
/// Which is why the guard exists: the next identifier-less throw on this path
/// would land here silently, and a comment saying "the fallback handles it" is
/// how that stops being noticed. See `test/l10n/transport_issue_guard_test.dart`
/// and ImL1s/telltale#45 for the fourteen throws still to be given identifiers.
String? connectionIssueText(AppLocalizations l10n, ObdConnectionState state) {
  final issue = state.issue;
  if (issue == null) return _transportIssueText(l10n, state.transportIssue);
  final step = state.issueStep;
  return switch (issue) {
    ObdConnectionIssue.handshakeIncomplete => l10n.connectIssueHandshakeIncomplete,
    ObdConnectionIssue.adapterSilentOnReset => l10n.connectIssueAdapterSilentOnReset(
      step?.step.command ?? '',
    ),
    ObdConnectionIssue.handshakeStepFailed =>
      l10n.connectIssueHandshakeStepFailed(
        step?.step.command ?? '',
        _failureReason(l10n, step),
      ),
    ObdConnectionIssue.adapterAcceptedThenSilent =>
      l10n.connectIssueAdapterAcceptedThenSilent,
    ObdConnectionIssue.connectionSetupFailed =>
      l10n.connectIssueConnectionSetupFailed,
    ObdConnectionIssue.previousConnectionStillAborting =>
      l10n.connectIssuePreviousConnectionStillAborting,
    ObdConnectionIssue.adapterStoppedResponding =>
      l10n.connectIssueAdapterStoppedResponding,
  };
}

/// The transports' half of [connectionIssueText].
///
/// `writeFailed` is deliberately absent from the mapping: it is not a connect
/// failure and never reaches this screen, so giving it a string here would add
/// copy that nothing can ever render and no test could hold to anything.
String? _transportIssueText(AppLocalizations l10n, TransportIssue? issue) =>
    switch (issue) {
      null => null,
      TransportIssue.cancelled => l10n.connectTransportCancelled,
      TransportIssue.wifiRouteNoNetwork =>
        l10n.connectTransportWifiRouteNoNetwork,
      TransportIssue.wifiRouteAmbiguous =>
        l10n.connectTransportWifiRouteAmbiguous,
      TransportIssue.wifiRouteRefused => l10n.connectTransportWifiRouteRefused,
      TransportIssue.wifiRouteTimeout => l10n.connectTransportWifiRouteTimeout,
      TransportIssue.wifiRouteUnclassified =>
        l10n.connectTransportWifiRouteUnclassified,
      TransportIssue.wifiHostUnreachable =>
        l10n.connectTransportWifiHostUnreachable,
      TransportIssue.wifiConnectTimeout =>
        l10n.connectTransportWifiConnectTimeout,
      TransportIssue.wifiRouteRestoreFailed =>
        l10n.connectTransportWifiRouteRestoreFailed,
      TransportIssue.bleLinkFailed => l10n.connectTransportBleLinkFailed,
      TransportIssue.bleNoSerialCharacteristic =>
        l10n.connectTransportBleNoSerialCharacteristic,
      TransportIssue.classicAllTiersRefused =>
        l10n.connectTransportClassicAllTiersRefused,
      TransportIssue.classicConnectTimeout =>
        l10n.connectTransportClassicConnectTimeout,
      TransportIssue.serialPortOpenFailed =>
        l10n.connectTransportSerialPortOpenFailed,
      TransportIssue.serialDroppedOnOpen =>
        l10n.connectTransportSerialDroppedOnOpen,
      TransportIssue.writeFailed => null,
    };

/// The line under a busy spinner, or null when there is nothing to say.
String? connectionActivityText(AppLocalizations l10n, ObdConnectionState state) =>
    switch (state.activity) {
      ObdConnectionActivity.abortingPreviousConnection =>
        l10n.connectActivityAbortingPreviousConnection,
      null => null,
    };
