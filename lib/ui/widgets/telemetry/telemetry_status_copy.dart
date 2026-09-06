/// Human-readable copy for telemetry status, recorder outcomes and durations.
///
/// These take an [AppLocalizations] rather than a [BuildContext] on purpose.
/// Half of this copy is chosen in places that have no widget above them — a
/// static table, a top-level function, a notifier — and threading a context to
/// those would either fail or invite someone to reach for a global one. A
/// plain parameter keeps the functions pure, so a pure-Dart test can assert
/// both languages with `lookupAppLocalizations(...)` and no widget pump.
///
/// Limits are placeholders, never spelled into the sentence. The recorder
/// already owns `telemetryRecorderDurationLimit` and `TelemetryQuota.groupLimit`;
/// writing "60 minutes" into the copy would create a second copy of a constant
/// that can drift from the one the code enforces.
library;

import '../../../l10n/generated/app_localizations.dart';
import '../../../state/telemetry_recorder.dart';
import '../../../telemetry/session/telemetry_recorder.dart';
import '../../../telemetry/session/telemetry_session.dart';
import '../../../telemetry/session/telemetry_session_store.dart';

String telemetryStatusLabel(AppLocalizations l10n, TelemetryStatus status) =>
    switch (status) {
      TelemetryStatus.stale => l10n.telemetryStatusStale,
      TelemetryStatus.unsupported => l10n.telemetryStatusUnsupported,
      TelemetryStatus.noAnswer => l10n.telemetryStatusNoAnswer,
      TelemetryStatus.formulaError => l10n.telemetryStatusFormulaError,
      TelemetryStatus.busError => l10n.telemetryStatusBusError,
      TelemetryStatus.headerMismatch => l10n.telemetryStatusHeaderMismatch,
      TelemetryStatus.unsafeServiceRefusal =>
        l10n.telemetryStatusUnsafeServiceRefusal,
    };

String telemetryTerminalReasonLabel(
  AppLocalizations l10n,
  TelemetryTerminalReason reason,
) => switch (reason) {
  TelemetryTerminalReason.user => l10n.telemetryEndedByUser,
  TelemetryTerminalReason.disconnect => l10n.telemetryEndedByDisconnect,
  TelemetryTerminalReason.sessionReplacement =>
    l10n.telemetryEndedBySessionReplacement,
  TelemetryTerminalReason.background => l10n.telemetryEndedByBackground,
  TelemetryTerminalReason.durationLimit => l10n.telemetryEndedByDurationLimit(
    telemetryRecorderDurationLimit.inMinutes,
  ),
  TelemetryTerminalReason.sessionSizeLimit =>
    l10n.telemetryEndedBySessionSizeLimit,
  TelemetryTerminalReason.librarySizeLimit =>
    l10n.telemetryEndedByLibrarySizeLimit,
  TelemetryTerminalReason.storageBackpressure =>
    l10n.telemetryEndedByStorageBackpressure,
  TelemetryTerminalReason.configurationChanged =>
    l10n.telemetryEndedByConfigurationChanged,
  TelemetryTerminalReason.storageFailure => l10n.telemetryEndedByStorageFailure,
  TelemetryTerminalReason.recoveredAfterInterruption =>
    l10n.telemetryEndedByRecoveredAfterInterruption,
};

String telemetryStartOutcomeLabel(
  AppLocalizations l10n,
  TelemetryStartOutcome outcome,
) => switch (outcome) {
  TelemetryStartOutcome.recording => l10n.telemetryStartRecording,
  TelemetryStartOutcome.disconnected => l10n.telemetryStartNeedsConnection,
  TelemetryStartOutcome.background => l10n.telemetryStartNeedsForeground,
  // Unknown speed refuses exactly as hard as known movement does. The absence
  // of a speed reading is not evidence that the car is parked.
  TelemetryStartOutcome.speedUnknown ||
  TelemetryStartOutcome.startInvalidatedSpeedUnknown =>
    l10n.telemetryStartSpeedUnknown,
  TelemetryStartOutcome.moving ||
  TelemetryStartOutcome.startInvalidatedMoving => l10n.telemetryStartMoving,
  TelemetryStartOutcome.startInvalidatedBackground =>
    l10n.telemetryStartInvalidatedBackground,
  TelemetryStartOutcome.startInvalidatedDisconnect =>
    l10n.telemetryStartInvalidatedDisconnect,
  TelemetryStartOutcome.startInvalidatedSessionReplacement =>
    l10n.telemetryStartInvalidatedSessionReplacement,
  TelemetryStartOutcome.libraryGroupLimit =>
    l10n.telemetryStartLibraryGroupLimit(TelemetryQuota.groupLimit),
  TelemetryStartOutcome.libraryByteLimit ||
  TelemetryStartOutcome.noRoomForValue => l10n.telemetryStartLibraryByteLimit,
  TelemetryStartOutcome.invalidConfiguration =>
    l10n.telemetryStartInvalidConfiguration,
  TelemetryStartOutcome.idCollision ||
  TelemetryStartOutcome.storageFailure => l10n.telemetryStartCannotCreateFile,
  TelemetryStartOutcome.restartRequired => l10n.telemetryRestartToRepairStartup,
  TelemetryStartOutcome.startBusy ||
  TelemetryStartOutcome.artifactBusy ||
  TelemetryStartOutcome.pidLocked => l10n.telemetryStartBusy,
};

/// Persistent recovery guidance for recorder work that cannot safely be
/// cancelled or released by a UI timeout.
String? telemetryRecorderRecoveryLabel(
  AppLocalizations l10n,
  TelemetryRecorderState state, {
  bool startNeedsRestart = false,
}) {
  if (state.phase == TelemetryRecorderPhase.preparing ||
      state.phase == TelemetryRecorderPhase.finalizing) {
    return l10n.telemetryPendingOwnerRecovery;
  }
  if (!state.requiresRestart && !startNeedsRestart) return null;
  return state.phase == TelemetryRecorderPhase.preparing
      ? l10n.telemetryRestartToRepairStartup
      : l10n.telemetryRestartToRepairSave;
}

String formatTelemetryDuration(int elapsedUs) {
  final seconds = elapsedUs < 0
      ? 0
      : elapsedUs ~/ Duration.microsecondsPerSecond;
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final remainder = seconds % 60;
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${remainder.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:'
      '${remainder.toString().padLeft(2, '0')}';
}

String formatTelemetryBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KiB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
}
