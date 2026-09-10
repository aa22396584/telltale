/// Independent facts about one connection: transport, protocol, ECU, evidence.
///
/// #51. These must not collapse into a single "connected" flag. Demo is
/// software evidence, never field. An empty protocol string is unknown, not
/// AUTO. No ECU answers is notObserved, not unsupported.
library;

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
  });

  final ConnectionLayerValue transport;
  final ConnectionLayerValue protocol;
  final ConnectionLayerValue ecu;
  final ConnectionLayerValue evidence;

  /// What was asked of the adapter (`ATSPn`), which may differ from ATDPN.
  final String requestedProtocol;

  /// What the adapter actually settled on (`ATDP` / `ATDPN`).
  final String observedProtocol;

  factory ConnectionLayerReport.fromConnection({
    TransportKind? kind,
    String protocol = '',
    String requestedProtocol = '',
    Set<String> responders = const {},
  }) {
    // Each layer is its own input. A dropped socket is not permission to
    // forget a protocol or ECU that already answered. Requested and
    // observed stay two strings: ATSP 5 vs ATDPN 6 is a fact, not a merge.
    final observed = protocol.trim();
    final requested = requestedProtocol.trim();
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
      evidence: kind == TransportKind.demo
          ? ConnectionLayerValue.software
          : ConnectionLayerValue.unknown,
      requestedProtocol: requested,
      observedProtocol: observed,
    );
  }
}
