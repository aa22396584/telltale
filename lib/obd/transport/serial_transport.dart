/// Byte-stream transport over a serial port (Windows COM / Linux RFCOMM).
///
/// ELM327 Classic adapters appear as Bluetooth serial nodes after pairing
/// (Windows `COMx`, Linux `/dev/rfcomm*`). This transport opens that port at
/// the conventional 38400 8N1 and feeds the same `Elm327Client` path used by
/// Wi-Fi / RFCOMM / BLE.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../core/serial/spp_serial_platform.dart';
import 'obd_transport.dart';

typedef SppSerialSessionFactory = SppSerialSession Function();

class SerialTransport extends BaseObdTransport {
  SerialTransport({
    required this.portName,
    this.displayLabel,
    this.baudRate = defaultBaudRate,
    SppSerialSession? session,
    SppSerialSessionFactory? sessionFactory,
  }) : _session = session ?? (sessionFactory ?? _defaultSessionFactory)();

  /// Conventional ELM327 UART / Bluetooth SPP bitrate.
  static const int defaultBaudRate = 38400;

  final String portName;
  final String? displayLabel;
  final int baudRate;

  final SppSerialSession _session;
  StreamSubscription<List<int>>? _inboundSub;
  var _aborted = false;

  @visibleForTesting
  static SppSerialSessionFactory defaultSessionFactoryForTest =
      _defaultSessionFactory;

  static SppSerialSession _defaultSessionFactory() =>
      MethodChannelSppSerialSession();

  @override
  TransportKind get kind => TransportKind.bluetoothClassic;

  @override
  String get displayName {
    final label = displayLabel?.trim();
    if (label != null && label.isNotEmpty) return label;
    return portName;
  }

  @override
  Map<String, Object> get diagnosticMetadata => Map.unmodifiable({
    'deviceIdentifier': portName,
    'deviceName': displayName,
    'baudRate': baudRate,
    'link': 'spp_serial',
  });

  /// Lists Bluetooth-associated serial nodes for the Classic wizard
  /// (Windows COM / Linux RFCOMM).
  static Future<List<DiscoveredDevice>> bluetoothSppDevices({
    SppSerialSession? session,
  }) async {
    final ports = await (session ?? MethodChannelSppSerialSession())
        .listBluetoothSppPorts();
    return ports
        .map(
          (p) => DiscoveredDevice(
            id: p.portName,
            name: p.friendlyName,
            kind: TransportKind.bluetoothClassic,
            isPaired: true,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> connect() async {
    if (_aborted) {
      throw const TransportException(
        'The connection was cancelled.',
        issue: TransportIssue.cancelled,
      );
    }
    // Listen before open so a native disconnect/error that races the open
    // await is not dropped on the broadcast inbound controller.
    var sawTerminalDuringOpen = false;
    _inboundSub = _session.inbound.listen(
      emitBytes,
      onError: (Object _) {
        sawTerminalDuringOpen = true;
        setConnected(false);
      },
      onDone: () {
        sawTerminalDuringOpen = true;
        setConnected(false);
      },
      cancelOnError: false,
    );
    try {
      await _session.open(portName: portName, baudRate: baudRate);
    } on Object catch (e) {
      await _inboundSub?.cancel();
      _inboundSub = null;
      throw TransportException(
        'Cannot open $displayName ($portName). '
        'Confirm the system has a serial port for that Bluetooth adapter '
        '(Windows COMx / Linux /dev/rfcomm*) and the ignition is on.',
        cause: e,
        issue: TransportIssue.serialPortOpenFailed,
      );
    }
    if (_aborted || sawTerminalDuringOpen) {
      await _inboundSub?.cancel();
      _inboundSub = null;
      await _session.close();
      throw TransportException(
        sawTerminalDuringOpen
            ? 'The serial port dropped immediately after opening.'
            : 'The connection was cancelled.',
        issue: sawTerminalDuringOpen
            ? TransportIssue.serialDroppedOnOpen
            : TransportIssue.cancelled,
      );
    }
    setConnected(true);
  }

  @override
  Future<void> disconnect() async {
    _aborted = true;
    await _inboundSub?.cancel();
    _inboundSub = null;
    try {
      await _session.close();
    } on Object {
      // Already closed.
    }
    setConnected(false);
  }

  @override
  Future<void> write(List<int> data) async {
    if (!isConnected) {
      throw const WriteRefusedException(
        'The serial-port connection is not established.',
      );
    }
    try {
      await _session.write(data);
    } on Object catch (e) {
      throw TransportException(
        'Write to $displayName failed.',
        cause: e,
        issue: TransportIssue.writeFailed,
      );
    }
  }
}
