/// Typed host-visible ISO-TP (`ATCAF0` / `ATCAF1`) on the existing ELM session.
///
/// Vehicle profiles cannot supply AT text. There is no API here that accepts
/// an arbitrary command string. Apply and restore go through the client's
/// single-owner `_commandChain`.
library;

import 'iso_tp_assembler.dart';
import 'transport/obd_transport.dart';

/// How an `ATCAF0` apply or `ATCAF1` restore attempt ended.
enum ElmHostIsoTpResult {
  /// `ATCAF0` answered a literal `OK`. Host-visible reassembly is active.
  applied,

  /// `ATCAF1` answered a literal `OK`. Auto-format is back.
  restored,

  /// The adapter answered `?` (or any non-`OK`) to `ATCAF0`.
  rejectedUnknownCommand,

  /// `ATCAF1` was refused while auto-format was already the known state.
  ///
  /// That cannot leave host-visible mode installed, so polling may continue.
  restoreRejected,

  /// A CAF command timed out waiting for a prompt.
  timedOut,

  /// A write was handed to the transport and then failed without a disconnect.
  unconfirmedWrite,

  /// The link dropped while applying or restoring.
  disconnected,

  /// Wall-clock or response-byte budget was exceeded before a confirmed change.
  budgetExceeded,

  /// `ATCAF1` did not answer `OK` after host-visible mode had been claimed.
  /// Ordinary polling is refused until reconnect.
  restoreFailed,
}

final class ElmHostIsoTpOutcome {
  const ElmHostIsoTpOutcome({
    required this.result,
    required this.hostVisible,
  });

  final ElmHostIsoTpResult result;
  final bool hostVisible;

  /// A measurement may be produced only after `ATCAF0` was confirmed.
  /// Any other result is fail-closed: zero decoded value.
  bool get producedMeasurement => result == ElmHostIsoTpResult.applied;

  /// Named refusal for the surface that renders capability failures.
  TransportIssue? get refusalIssue => switch (result) {
        ElmHostIsoTpResult.rejectedUnknownCommand ||
        ElmHostIsoTpResult.restoreFailed =>
          TransportIssue.rawIsoTpModeUnavailable,
        _ => null,
      };
}

/// Bounds and command spellings for host-visible ISO-TP.
abstract final class ElmHostIsoTpConfig {
  static const applyCommand = 'ATCAF0';
  static const restoreCommand = 'ATCAF1';
  static const maxApplyCommands = 1;
  static const maxRestoreCommands = 1;
  static const maxResponseBytes = 256;
  static const defaultBudget = Duration(seconds: 8);
  static const maxPduBytes = IsoTpAssembler.maxPduBytes;
}

/// Transcript-only English for host-visible ISO-TP refusals.
abstract final class ElmHostIsoTpMessages {
  static const unavailable =
      'Host-visible ISO-TP reassembly is not available on this ELM327 path.';
  static const restoreFailed =
      'The adapter refused to restore auto-format (ATCAF1), so polling is stopped until you reconnect.';
}
