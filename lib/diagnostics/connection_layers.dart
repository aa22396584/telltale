/// Independent facts about one connection: transport, protocol, ECU, evidence.
///
/// #51. These must not collapse into a single "connected" flag. Demo is
/// software evidence, never field. An empty protocol string is unknown, not
/// AUTO. No ECU answers is notObserved, not unsupported.
library;

import '../obd/transport/obd_transport.dart';

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
  });

  final ConnectionLayerValue transport;
  final ConnectionLayerValue protocol;
  final ConnectionLayerValue ecu;
  final ConnectionLayerValue evidence;

  factory ConnectionLayerReport.fromConnection({
    required bool connected,
    TransportKind? kind,
    String protocol = '',
    Set<String> responders = const {},
  }) {
    if (!connected) {
      return const ConnectionLayerReport(
        transport: ConnectionLayerValue.unknown,
        protocol: ConnectionLayerValue.unknown,
        ecu: ConnectionLayerValue.notObserved,
        evidence: ConnectionLayerValue.unknown,
      );
    }
    return ConnectionLayerReport(
      transport: switch (kind) {
        TransportKind.demo => ConnectionLayerValue.demo,
        TransportKind.bluetoothLe => ConnectionLayerValue.ble,
        TransportKind.bluetoothClassic => ConnectionLayerValue.classic,
        TransportKind.wifi => ConnectionLayerValue.wifi,
        null => ConnectionLayerValue.unknown,
      },
      protocol: protocol.trim().isEmpty
          ? ConnectionLayerValue.unknown
          : ConnectionLayerValue.observed,
      ecu: responders.isEmpty
          ? ConnectionLayerValue.notObserved
          : ConnectionLayerValue.answered,
      evidence: kind == TransportKind.demo
          ? ConnectionLayerValue.software
          : ConnectionLayerValue.unknown,
    );
  }
}
