/// #51 leftover: each Connect failure maps to one action, not a guess.
///
/// Permission → settings. Radio off → turn it on. Cannot reach the adapter →
/// distance or power as a possible cause, not a finding. Adapter up but no
/// ECU → ignition, protocol, or adapter capability. BUS INIT → retry or Auto.
/// Malformed reply → keep invalid and export. None of these send Mode 04.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/connection_failure_actions.dart';
import 'package:torque_obd/l10n/generated/app_localizations_en.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/transport/ble_transport.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/ui/screens/connect/connection_failure_copy.dart';

void main() {
  final en = AppLocalizationsEn();

  test('permission maps to settings, not a dead adapter', () {
    expect(
      connectionFailureAction(scan: BleScanIssue.permissionNeeded),
      ConnectionFailureAction.openSettings,
    );
    expect(
      connectionFailureActionText(en, ConnectionFailureAction.openSettings),
      'Open system settings.',
    );
  });

  test('radio off maps to turning it on', () {
    expect(
      connectionFailureAction(scan: BleScanIssue.poweredOff),
      ConnectionFailureAction.turnRadioOn,
    );
    expect(
      connectionFailureActionText(en, ConnectionFailureAction.turnRadioOn),
      'Turn Bluetooth on.',
    );
  });

  test('cannot reach the adapter is distance or power, not a finding', () {
    expect(
      connectionFailureAction(transport: TransportIssue.wifiHostUnreachable),
      ConnectionFailureAction.checkDistanceOrPower,
    );
    expect(
      connectionFailureAction(transport: TransportIssue.bleLinkFailed),
      ConnectionFailureAction.checkDistanceOrPower,
    );
    final text = connectionFailureActionText(
      en,
      ConnectionFailureAction.checkDistanceOrPower,
    );
    expect(text, contains('possible cause'));
    expect(text.toLowerCase(), isNot(contains('dead')));
    expect(text.toLowerCase(), isNot(contains('broken')));
  });

  test(
    'adapter up but no ECU is ignition, protocol, or adapter capability',
    () {
      expect(
        connectionFailureAction(note: InitNote.ecuSilent),
        ConnectionFailureAction.checkIgnitionProtocolAdapter,
      );
      expect(
        connectionFailureAction(adapterError: Elm327ErrorCode.unableToConnect),
        ConnectionFailureAction.checkIgnitionProtocolAdapter,
      );
      expect(
        connectionFailureAction(
          adapterError: Elm327ErrorCode.noData,
          command: '0100',
        ),
        ConnectionFailureAction.checkIgnitionProtocolAdapter,
      );
      expect(
        connectionFailureAction(adapterError: Elm327ErrorCode.noData),
        isNull,
      );
      expect(
        connectionFailureAction(
          adapterError: Elm327ErrorCode.noData,
          command: '010C',
        ),
        isNull,
      );
      final text = connectionFailureActionText(
        en,
        ConnectionFailureAction.checkIgnitionProtocolAdapter,
      );
      expect(text.toLowerCase(), contains('ignition'));
      expect(text.toLowerCase(), contains('protocol'));
      expect(text, contains('not proof the vehicle has no OBD'));
    },
  );

  test('BUS INIT maps to retry or Auto, not vehicle unsupported', () {
    expect(
      connectionFailureAction(adapterError: Elm327ErrorCode.busInitError),
      ConnectionFailureAction.retryOrAuto,
    );
    final text = connectionFailureActionText(
      en,
      ConnectionFailureAction.retryOrAuto,
    );
    expect(text, contains('Retry'));
    expect(text, contains('Auto'));
    expect(text.toLowerCase(), isNot(contains('unsupported')));
  });

  test('malformed reply stays invalid and is exported, not a reading', () {
    expect(
      connectionFailureAction(adapterError: Elm327ErrorCode.dataError),
      ConnectionFailureAction.keepInvalidAndExport,
    );
    final text = connectionFailureActionText(
      en,
      ConnectionFailureAction.keepInvalidAndExport,
    );
    expect(text.toLowerCase(), contains('invalid'));
    expect(text.toLowerCase(), contains('export'));
    expect(text, contains('not a reading'));
  });

  test('the Connect error banner reads the mapping', () {
    final source = File('lib/ui/screens/connect/connect_screen.dart')
        .readAsStringSync();
    expect(source.contains('connectionFailureAction('), isTrue);
    expect(source.contains('connectionFailureActionText('), isTrue);
    expect(
      source.contains('command: connection.issueStep?.step.command'),
      isTrue,
    );
    expect(source.contains('scan: scanIssue'), isTrue);
    expect(source.contains('scan: _scanIssue'), isTrue);
    expect(source.contains('BleScanIssue.permissionNeeded'), isTrue);
    expect(source.contains('BleScanIssue.poweredOff'), isTrue);
  });
}
