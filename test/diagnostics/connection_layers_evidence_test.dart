/// Simulated sessions are software evidence. Names and ATI strings never
/// become a field claim.
///
/// #51 leftover: the four-row panel must not treat a BLE/Wi-Fi session as
/// field just because it is not Demo. A test-rig / simulated session is
/// software. A production session without field attestation stays unknown.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/connection_layers.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';

void main() {
  test('a test-rig BLE session is software, never field', () {
    final report = ConnectionLayerReport.fromConnection(
      kind: TransportKind.bluetoothLe,
      protocol: '6',
      testRig: true,
    );
    expect(report.evidence, ConnectionLayerValue.software);
    expect(report.evidence, isNot(ConnectionLayerValue.field));
    expect(report.transport, ConnectionLayerValue.ble);
  });

  test('a production BLE session stays unknown, never field', () {
    final report = ConnectionLayerReport.fromConnection(
      kind: TransportKind.bluetoothLe,
      protocol: '6',
    );
    expect(report.evidence, ConnectionLayerValue.unknown);
    expect(report.evidence, isNot(ConnectionLayerValue.field));
  });

  test('Demo is software even when testRig is not passed', () {
    final report = ConnectionLayerReport.fromConnection(
      kind: TransportKind.demo,
      protocol: '6',
    );
    expect(report.evidence, ConnectionLayerValue.software);
    expect(report.evidence, isNot(ConnectionLayerValue.field));
  });

  test('the Connect screen feeds session simulated-evidence into the report', () {
    final source = File(
      'lib/ui/screens/connect/connect_screen.dart',
    ).readAsStringSync();
    expect(source.contains('testRig:'), isTrue);
    expect(source.contains('requiresSimulatedEvidence'), isTrue);
  });
}
