/// Typed ELM327 custom flow-control configuration.
///
/// Vehicle profiles cannot supply AT text. A future catalog field (out of
/// scope for this slice) would carry these typed values — mode, header, and
/// data bytes — never a free-form command string. There is no API here that
/// accepts an arbitrary AT string.
///
/// Compact command spellings follow the datasheet's `AT FC SH` / `AT FC SD` /
/// `AT FC SM` family without spaces (`ATFCSH`, `ATFCSD`, `ATFCSM0|1|2`).
/// Modes 3/8/9/A are undocumented in prose and are not represented.
library;

import 'addressing.dart';
import 'transport/obd_transport.dart';

/// How the adapter should build ISO 15765-4 flow-control frames.
enum ElmFlowControlMode {
  /// Datasheet `AT FC SM 0`: ELM provides ID and data per ISO 15765-4.
  automatic,

  /// Datasheet `AT FC SM 1`: user ID (`AT FC SH`) and user data (`AT FC SD`).
  customHeaderAndData,

  /// Datasheet `AT FC SM 2`: ELM copies ID from the received First Frame;
  /// user data only.
  customDataKeepId,
}

/// Adapter flow-control programming this client currently believes is in
/// effect.
///
/// `automatic` is the ELM327 default after reset. `custom` is claimed only
/// after every command in a typed apply sequence answered a literal `OK`.
/// `unknown` means a write left and was not confirmed — never treated as
/// `automatic` and never treated as `custom`.
sealed class ElmFlowControlState {
  const ElmFlowControlState();
}

final class ElmFlowControlAutomatic extends ElmFlowControlState {
  const ElmFlowControlAutomatic();
}

final class ElmFlowControlCustom extends ElmFlowControlState {
  const ElmFlowControlCustom(this.config);
  final ElmFlowControlConfig config;
}

final class ElmFlowControlUnknown extends ElmFlowControlState {
  const ElmFlowControlUnknown();
}

/// How an apply or restore attempt ended.
enum ElmFlowControlResult {
  /// Custom mode (SM1/SM2) was acknowledged on every command.
  applied,

  /// Defaults were restored with a literal `OK` to `ATFCSM0`.
  restored,

  /// The adapter answered `?` (or any non-`OK`) to a typed FC command.
  rejectedUnknownCommand,

  /// `ATFCSM0` was refused or not sent while this client was already automatic.
  ///
  /// That cannot install SM1/SM2, so polling may continue. Distinct from
  /// [rejectedUnknownCommand] so surfaces do not claim a custom command failed.
  restoreRejected,

  /// A typed FC command timed out waiting for a prompt.
  timedOut,

  /// A write was handed to the transport and then failed without a disconnect.
  ///
  /// `socket.add` can deliver bytes before `flush` throws, so the adapter may
  /// already be in the requested mode. Restore must still run.
  unconfirmedWrite,

  /// The link dropped while applying or restoring.
  disconnected,

  /// Command count, wall-clock budget, or response-byte budget was exceeded.
  budgetExceeded,

  /// `ATFCSM0` did not answer `OK`; polling must stop until reconnect.
  restoreFailed,
}

final class ElmFlowControlOutcome {
  const ElmFlowControlOutcome({
    required this.result,
    required this.state,
  });

  final ElmFlowControlResult result;
  final ElmFlowControlState state;

  /// A measurement may be produced only after the requested custom mode was
  /// confirmed active. Any other result is fail-closed: zero decoded value.
  bool get producedMeasurement => result == ElmFlowControlResult.applied;

  /// Named refusal for the surface that renders capability failures, or null
  /// when this outcome is not a capability refusal (success, timeout,
  /// disconnect, budget).
  TransportIssue? get refusalIssue => switch (result) {
        ElmFlowControlResult.rejectedUnknownCommand =>
          TransportIssue.customFlowControlRejected,
        ElmFlowControlResult.restoreFailed =>
          TransportIssue.flowControlRestoreFailed,
        _ => null,
      };
}

/// Transcript-only English for ELM327 flow-control refusals.
///
/// The screen maps [TransportIssue] through ARB. These strings still land in
/// `TransportException.message` and in logs, and they stay English like the
/// other ELM327 pre-wire refusals.
abstract final class ElmFlowControlMessages {
  static const restoreFailed =
      'The adapter refused to restore default flow control (ATFCSM0), so polling is stopped until you reconnect.';
  static const customRejected =
      'The adapter refused a custom flow-control command, so the requested mode was not applied and no measurement was produced.';
  static const extendedAddressingUnavailable =
      'Extended addressing is not available on this ELM327 path.';
  static const rawIsoTpModeUnavailable =
      'Host-visible ISO-TP reassembly is not available on this ELM327 path.';
}

/// A reviewed flow-control program. Construction throws on an invalid shape.
final class ElmFlowControlConfig {
  ElmFlowControlConfig._({
    required this.mode,
    this.header,
    List<int>? data,
  }) : data = data == null ? null : List<int>.unmodifiable(data);

  /// Datasheet defaults. Emits `ATFCSM0`.
  factory ElmFlowControlConfig.automatic() => ElmFlowControlConfig._(
        mode: ElmFlowControlMode.automatic,
      );

  /// SM1: user header and 1–5 data bytes. [addressing] selects 11-bit vs
  /// 29-bit header width.
  factory ElmFlowControlConfig.customHeaderAndData({
    required String header,
    required List<int> data,
    required BusAddressing addressing,
  }) =>
      ElmFlowControlConfig(
        mode: ElmFlowControlMode.customHeaderAndData,
        header: header,
        data: data,
        addressing: addressing,
      );

  /// SM2: user data only. Still CAN-only; [addressing] must name an 11- or
  /// 29-bit ISO 15765-4 bus.
  factory ElmFlowControlConfig.customDataKeepId({
    required List<int> data,
    required BusAddressing addressing,
  }) =>
      ElmFlowControlConfig(
        mode: ElmFlowControlMode.customDataKeepId,
        data: data,
        addressing: addressing,
      );

  /// Throws [ArgumentError] (never assert) when the shape is not a reviewed
  /// FC program for [addressing].
  factory ElmFlowControlConfig({
    required ElmFlowControlMode mode,
    String? header,
    List<int>? data,
    BusAddressing? addressing,
  }) {
    switch (mode) {
      case ElmFlowControlMode.automatic:
        if (header != null || data != null) {
          throw ArgumentError(
            'automatic flow control takes no header or data',
          );
        }
        return ElmFlowControlConfig._(
          mode: ElmFlowControlMode.automatic,
        );
      case ElmFlowControlMode.customHeaderAndData:
        _requireCan(addressing);
        final normalised = _requireHeader(header, addressing!);
        final bytes = _requireData(data, forMode: mode);
        return ElmFlowControlConfig._(
          mode: mode,
          header: normalised,
          data: bytes,
        );
      case ElmFlowControlMode.customDataKeepId:
        _requireCan(addressing);
        if (header != null) {
          throw ArgumentError(
            'custom-data-keep-id flow control takes no header',
          );
        }
        final bytes = _requireData(data, forMode: mode);
        return ElmFlowControlConfig._(
          mode: mode,
          data: bytes,
        );
    }
  }

  static const int maxApplyCommands = 4;
  static const int maxRestoreCommands = 2;
  static const int maxResponseBytes = 256;
  static const Duration defaultBudget = Duration(seconds: 8);
  static const String restoreCommand = 'ATFCSM0';

  final ElmFlowControlMode mode;
  final String? header;
  final List<int>? data;

  /// Compact AT commands in datasheet order: SH → SD → SM, or `ATFCSM0`.
  List<String> toAtCommands() {
    switch (mode) {
      case ElmFlowControlMode.automatic:
        return const [restoreCommand];
      case ElmFlowControlMode.customHeaderAndData:
        return [
          'ATFCSH$header',
          'ATFCSD${_hexBytes(data!)}',
          'ATFCSM1',
        ];
      case ElmFlowControlMode.customDataKeepId:
        return [
          'ATFCSD${_hexBytes(data!)}',
          'ATFCSM2',
        ];
    }
  }

  bool compatibleWith(BusAddressing bus) {
    if (mode == ElmFlowControlMode.automatic) return true;
    if (!bus.isCan) return false;
    final configured = header;
    if (configured != null && !bus.acceptsHeader(configured)) return false;
    return true;
  }

  static void _requireCan(BusAddressing? addressing) {
    if (addressing == null || !addressing.isCan) {
      throw ArgumentError(
        'custom flow control is defined only on 11-bit or 29-bit CAN',
      );
    }
  }

  static String _requireHeader(String? header, BusAddressing addressing) {
    if (header == null || header.trim().isEmpty) {
      throw ArgumentError('customHeaderAndData requires a CAN header');
    }
    final normalised = BusAddressing.normaliseHeader(header);
    if (!RegExp(r'^[0-9A-F]+$').hasMatch(normalised)) {
      throw ArgumentError.value(
        header,
        'header',
        'must be hexadecimal',
      );
    }
    if (normalised.length != 3 && normalised.length != 8) {
      throw ArgumentError.value(
        header,
        'header',
        'must be exactly 3 or 8 hex digits',
      );
    }
    if (normalised.length != addressing.headerHexDigits) {
      throw ArgumentError.value(
        header,
        'header',
        '3 hex digits only on 11-bit CAN, 8 only on 29-bit CAN',
      );
    }
    if (!BusAddressing.isLegalCanId(normalised)) {
      throw ArgumentError.value(
        header,
        'header',
        'not a legal CAN identifier at this width',
      );
    }
    return normalised;
  }

  static List<int> _requireData(
    List<int>? data, {
    required ElmFlowControlMode forMode,
  }) {
    if (data == null || data.isEmpty) {
      throw ArgumentError('$forMode requires 1 to 5 data bytes');
    }
    if (data.length > 5) {
      throw ArgumentError.value(
        data.length,
        'data',
        'flow-control data is 1 to 5 bytes',
      );
    }
    for (final byte in data) {
      if (byte < 0 || byte > 255) {
        throw ArgumentError.value(
          byte,
          'data',
          'each byte must be in 0..255',
        );
      }
    }
    return List<int>.from(data);
  }

  static String _hexBytes(List<int> data) => data
      .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
      .join();

  @override
  bool operator ==(Object other) {
    if (other is! ElmFlowControlConfig) return false;
    if (mode != other.mode || header != other.header) return false;
    final a = data;
    final b = other.data;
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(mode, header, Object.hashAll(data ?? const []));
}
