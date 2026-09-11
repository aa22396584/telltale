/// #51 leftover: one Connect failure maps to one action.
///
/// Permission → settings. Radio off → turn it on. Cannot reach the adapter →
/// distance or power as a possible cause, not a finding. Adapter up but no
/// ECU → ignition, protocol, or adapter capability. BUS INIT → retry or Auto.
/// Malformed reply → keep invalid and export. None of these send Mode 04.
library;

import '../obd/elm327_client.dart';
import '../obd/transport/ble_transport.dart';
import '../obd/transport/obd_transport.dart';

enum ConnectionFailureAction {
  openSettings,
  turnRadioOn,
  checkDistanceOrPower,
  checkIgnitionProtocolAdapter,
  retryOrAuto,
  keepInvalidAndExport,
}

/// The leftover mapping. Scan, adapter error, handshake note, and transport
/// are independent inputs; the first matching arm wins.
ConnectionFailureAction? connectionFailureAction({
  BleScanIssue? scan,
  Elm327ErrorCode? adapterError,
  InitNote? note,
  TransportIssue? transport,
  String? command,
}) {
  if (scan == BleScanIssue.permissionNeeded) {
    return ConnectionFailureAction.openSettings;
  }
  if (scan == BleScanIssue.poweredOff) {
    return ConnectionFailureAction.turnRadioOn;
  }
  if (adapterError == Elm327ErrorCode.dataError ||
      note == InitNote.notModeOnePositiveReply ||
      note == InitNote.pidEchoMismatch ||
      note == InitNote.supportMaskTooShort) {
    return ConnectionFailureAction.keepInvalidAndExport;
  }
  if (adapterError == Elm327ErrorCode.busInitError) {
    return ConnectionFailureAction.retryOrAuto;
  }
  if (adapterError == Elm327ErrorCode.unableToConnect ||
      note == InitNote.ecuSilent ||
      (adapterError == Elm327ErrorCode.noData && command == '0100')) {
    return ConnectionFailureAction.checkIgnitionProtocolAdapter;
  }
  if (transport == TransportIssue.wifiHostUnreachable ||
      transport == TransportIssue.wifiConnectTimeout ||
      transport == TransportIssue.bleLinkFailed) {
    return ConnectionFailureAction.checkDistanceOrPower;
  }
  return null;
}
