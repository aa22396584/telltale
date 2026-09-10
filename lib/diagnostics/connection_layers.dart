/// Independent facts about one connection: transport, protocol, ECU, evidence.
///
/// #51. These must not collapse into a single "connected" flag. Demo is
/// software evidence, never field. An empty protocol string is unknown, not
/// AUTO. No ECU answers is notObserved, not unsupported.
library;

import '../obd/addressing.dart';
import '../obd/transport/obd_transport.dart';

enum ConnectionLayerKind { transport, protocol, ecu, evidence }

enum ConnectionLayerValue {
  unknown,
  notObserved,
  observed,
  answered,
  unsupported,
  connected,
  demo,
  ble,
  classic,
  wifi,
  software,
  field,
}

final class ConnectionLayerReport {
  const ConnectionLayerReport({
    required this.transport,
    required this.protocol,
    required this.ecu,
    required this.evidence,
    this.requestedProtocol = '',
    this.observedProtocol = '',
    this.protocolNumber = '',
    this.protocolDescription = '',
  });

  final ConnectionLayerValue transport;
  final ConnectionLayerValue protocol;
  final ConnectionLayerValue ecu;
  final ConnectionLayerValue evidence;

  /// What was asked of the adapter (`ATSPn`), which may differ from ATDPN.
  final String requestedProtocol;

  /// What the adapter actually settled on (`ATDP` / `ATDPN`).
  final String observedProtocol;

  /// `ATDPN` only. Empty when the adapter would not print a number.
  final String protocolNumber;

  /// `ATDP` sentence. Not a substitute for [protocolNumber] 4 vs 5.
  final String protocolDescription;

  /// 5-baud vs fast is `ATDPN` 4 vs 5. An ISO 14230 sentence is [KwpInit.unknown].
  KwpInit get kwpInit => BusAddressing.kwpInit(
        protocolNumber: protocolNumber,
        description: protocolDescription.isNotEmpty
            ? protocolDescription
            : observedProtocol,
      );

  factory ConnectionLayerReport.fromConnection({
    TransportKind? kind,
    String protocol = '',
    String requestedProtocol = '',
    String protocolNumber = '',
    String protocolDescription = '',
    Set<String> responders = const {},
    bool testRig = false,
  }) {
    // Each layer is its own input. A dropped socket is not permission to
    // forget a protocol or ECU that already answered. Requested and
    // observed stay two strings: ATSP 5 vs ATDPN 6 is a fact, not a merge.
    // Evidence is fail-closed: Demo and the no-car test rig are software.
    // Nothing else becomes field here — ATI strings and adapter names are
    // not inputs, so they cannot elevate the row.
    final observed = protocol.trim();
    final requested = requestedProtocol.trim();
    final number = protocolNumber.trim();
    final description = protocolDescription.trim();
    return ConnectionLayerReport(
      transport: switch (kind) {
        TransportKind.demo => ConnectionLayerValue.demo,
        TransportKind.bluetoothLe => ConnectionLayerValue.ble,
        TransportKind.bluetoothClassic => ConnectionLayerValue.classic,
        TransportKind.wifi => ConnectionLayerValue.wifi,
        null => ConnectionLayerValue.unknown,
      },
      protocol: observed.isEmpty
          ? ConnectionLayerValue.unknown
          : ConnectionLayerValue.observed,
      ecu: responders.isEmpty
          ? ConnectionLayerValue.notObserved
          : ConnectionLayerValue.answered,
      evidence: kind == TransportKind.demo || testRig
          ? ConnectionLayerValue.software
          : ConnectionLayerValue.unknown,
      requestedProtocol: requested,
      observedProtocol: observed,
      protocolNumber: number,
      protocolDescription:
          description.isNotEmpty ? description : observed,
    );
  }
}
