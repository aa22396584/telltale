/// Four connection facts must not collapse into one "connected".
///
/// #51: asking "does this support K-line?" needs to know whether the phone
/// reached the adapter, which protocol the adapter settled on, whether any
/// ECU answered, and what evidence layer that combination has. A single
/// connected flag answers none of those.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/connection_layers.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';

void main() {
  test('a Demo session is software evidence, never field', () {
    final report = ConnectionLayerReport.fromConnection(
      connected: true,
      kind: TransportKind.demo,
      protocol: 'AUTO, ISO 15765-4 (CAN 11/500)',
      responders: const {'7E8'},
    );
    expect(report.transport, ConnectionLayerValue.demo);
    expect(report.evidence, ConnectionLayerValue.software);
    expect(report.evidence, isNot(ConnectionLayerValue.field));
    expect(report.ecu, ConnectionLayerValue.answered);
    expect(report.protocol, ConnectionLayerValue.observed);
  });

  test('an empty protocol string is unknown, not AUTO', () {
    final report = ConnectionLayerReport.fromConnection(
      connected: true,
      kind: TransportKind.bluetoothLe,
      protocol: '',
      responders: const {'7E8'},
    );
    expect(report.protocol, ConnectionLayerValue.unknown);
    expect(report.transport, ConnectionLayerValue.ble);
  });

  test('no ECU answers is notObserved, not unsupported', () {
    final report = ConnectionLayerReport.fromConnection(
      connected: true,
      kind: TransportKind.bluetoothLe,
      protocol: 'ISO 9141-2',
      responders: const {},
    );
    expect(report.ecu, ConnectionLayerValue.notObserved);
    expect(report.ecu, isNot(ConnectionLayerValue.unsupported));
    expect(report.protocol, ConnectionLayerValue.observed);
  });

  test('the four layers are four facts, not one connected flag', () {
    final report = ConnectionLayerReport.fromConnection(
      connected: true,
      kind: TransportKind.wifi,
      protocol: '',
      responders: const {},
    );
    final values = {
      report.transport,
      report.protocol,
      report.ecu,
      report.evidence,
    };
    expect(values, isNot(equals({ConnectionLayerValue.connected})));
    expect(values.length, greaterThan(1));
    expect(report.transport, ConnectionLayerValue.wifi);
    expect(report.protocol, ConnectionLayerValue.unknown);
    expect(report.ecu, ConnectionLayerValue.notObserved);
    expect(report.evidence, ConnectionLayerValue.unknown);
  });

  test('disconnected is unknown on every layer except ecu notObserved', () {
    final report = ConnectionLayerReport.fromConnection(connected: false);
    expect(report.transport, ConnectionLayerValue.unknown);
    expect(report.protocol, ConnectionLayerValue.unknown);
    expect(report.ecu, ConnectionLayerValue.notObserved);
    expect(report.evidence, ConnectionLayerValue.unknown);
  });
}
