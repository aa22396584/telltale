/// After support discovery, the first Mode 01 drain must already be grouped.
///
/// `PriorityScheduler.canBatch` is documented as recomputed before every
/// command (`lib/ui/screens/dashboard/dashboard_screen.dart`,
/// `test/l10n/dashboard_polling_mode_help_test.dart`): CAN addressing and a
/// support block has answered. `discoverSupportedPids()` is that answer.
/// Applying the gate only inside `_pollBatch` left `popBatch` reading a stale
/// `false`, so the first drain was a singleton even after discovery.
///
/// Hand-typed wire (same six high-priority PIDs, field-shaped fixture that
/// answers only the canonical group):
///
///   before (gate after popBatch):
///     010C
///     010D04110B100C
///   after (gate before popBatch):
///     010C0D04110B10
///
/// The before second command is not a reorder of the same request: 010C was
/// already drained, re-enqueued at the tail, and the fixture never answers
/// that permutation, so RPM stays null. Linux/Android/iOS send the same
/// first command — there is no `Platform` branch in the gate.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/polling_engine.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';

class _GroupOnlyTransport extends BaseObdTransport {
  final List<String> commands = [];

  @override
  TransportKind get kind => TransportKind.bluetoothLe;

  @override
  String get displayName => 'batching-gate probe';

  @override
  Future<void> connect() async => setConnected(true);

  @override
  Future<void> disconnect() async => setConnected(false);

  @override
  Future<void> write(List<int> data) async {
    final command = ascii
        .decode(data, allowInvalid: true)
        .trim()
        .replaceAll(' ', '')
        .toUpperCase();
    commands.add(command);
    if (command == 'ATZ') {
      emitBytes(ascii.encode('ATZ\rELM327 v1.5\r>'));
      return;
    }
    if (command == '010C0D04110B10') {
      emitBytes(ascii.encode('00F\r'));
      emitBytes(ascii.encode('0:410C1AF80D00\r'));
      emitBytes(ascii.encode('1:043311200B6410\r'));
      emitBytes(ascii.encode('2:01900000000000\r'));
      await Future<void>.delayed(Duration.zero);
      emitBytes(ascii.encode('>'));
      return;
    }
    final reply = switch (command) {
      'ATE0' ||
      'ATL0' ||
      'ATM0' ||
      'ATS0' ||
      'ATAT1' ||
      'ATST66' ||
      'ATSP0' ||
      'ATSH7E0' => 'OK',
      'ATI' => 'ELM327 v1.5',
      'AT@1' => 'probe',
      'ATRV' => '14.2V',
      'ATDP' => 'AUTO, ISO 15765-4 (CAN 11/500)',
      'ATDPN' => 'A6',
      'ATPPS' => '?',
      '0100' => '4100BE3FA813',
      '0120' => '4120B007B011',
      '0140' => '4140FEDC8051',
      '0160' => '416008000000',
      _ => 'NO DATA',
    };
    emitBytes(ascii.encode('$reply\r>'));
  }
}

void main() {
  test(
    'after discovery the first Mode 01 drain is the six-PID group, not 010C',
    () async {
      const beforeFirst = '010C';
      const beforeSecond = '010D04110B100C';
      const afterFirst = '010C0D04110B10';

      final transport = _GroupOnlyTransport();
      final client = Elm327Client(
        transport,
        commandTimeout: const Duration(milliseconds: 500),
      );
      addTearDown(client.dispose);
      expect(await client.connect(), isTrue);

      final engine = PollingEngine(client);
      addTearDown(engine.dispose);
      await engine.discoverSupportedPids();

      final pollStart = transport.commands.length;
      engine
        ..setActivePids(const [
          PidLibrary.engineRpm,
          PidLibrary.vehicleSpeed,
          PidLibrary.engineLoad,
          PidLibrary.throttlePosition,
          PidLibrary.manifoldPressure,
          PidLibrary.mafRate,
        ], includeProfileDerivedInputs: false)
        ..start();

      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (engine.current.valueOf(PidLibrary.engineRpm) == null &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      final mode01 = transport.commands.sublist(pollStart).where((command) {
        return command.startsWith('01') &&
            command != '0100' &&
            command != '0120' &&
            command != '0140' &&
            command != '0160';
      }).toList();

      expect(mode01, isNotEmpty);
      expect(
        mode01.first,
        afterFirst,
        reason:
            'before the gate moved ahead of popBatch this was $beforeFirst '
            'then $beforeSecond; those are not the fixture command, so RPM '
            'stayed null. The documented contract is canBatch recomputed '
            'before every command once a support block has answered.',
      );
      expect(mode01.contains(beforeFirst), isFalse);
      expect(mode01.contains(beforeSecond), isFalse);
      expect(engine.current.valueOf(PidLibrary.engineRpm), closeTo(1726, 0.1));
    },
  );
}
