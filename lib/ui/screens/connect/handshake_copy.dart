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
