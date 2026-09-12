/// Typed ELM327 composite query transaction.
///
/// Combines extended addressing (`ATCEA`), CAN priority (`ATCP`),
/// CAN receive filter (`ATCRA`), custom flow control (`ATFCSM1|2`),
/// and host-visible ISO-TP (`ATCAF0`) into a single indivisible
/// apply → query → reverse-restore transaction on the client's command chain.
library;

import 'elm_can_addressing.dart';
import 'elm_flow_control.dart';

/// Configuration bundle for a composite ELM327 transaction.
final class ElmCompositeTransactionConfig {
  const ElmCompositeTransactionConfig({
    this.header,
    this.restoreHeader = false,
    this.extendedAddressByte,
    this.canPriorityByte,
    this.canReceiveFilter,
    this.flowControl,
    this.hostVisibleIsoTp = false,
    this.timeout,
    this.budget,
  });

  /// Target ECU header (e.g. `6F1`, `18DADBF1`).
  final String? header;

  /// Whether to restore the previous header in finally if [header] was changed.
  final bool restoreHeader;

  /// ISO 15765-2 extended addressing target byte (e.g. `0x07` for `ATCEA07`).
  final int? extendedAddressByte;

  /// 29-bit CAN priority byte (e.g. `0x17` for `ATCP17`). Restores to `0x18`.
  final int? canPriorityByte;

  /// CAN receive filter (e.g. `607` for `ATCRA607`). Restores to bare `ATCRA`.
  final ElmCanReceiveFilterConfig? canReceiveFilter;

  /// Custom ISO 15765-4 flow control (e.g. `ATFCSM1` with header and data). Restores to `ATFCSM0`.
  final ElmFlowControlConfig? flowControl;

  /// Host-visible ISO-TP PCI framing (`ATCAF0`). Restores to `ATCAF1`.
  final bool hostVisibleIsoTp;

  /// Timeout for each query command in the transaction.
  final Duration? timeout;

  /// Overall budget for the transaction apply phase.
  final Duration? budget;

  /// Whether any adapter mutation is requested by this configuration.
  bool get hasMutations =>
      extendedAddressByte != null ||
      canPriorityByte != null ||
      canReceiveFilter != null ||
      flowControl != null ||
      hostVisibleIsoTp ||
      header != null;
}
