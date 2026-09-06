/// Polling-after-success close, then reconnect, through the TCP chaos proxy.
///
/// Handshake and the first live reading must succeed. The armed `close` is
/// consumed on a later driver command. A fresh client then handshakes against
/// Ircama through the same listen port; leftover PID bytes from the killed
/// session must not be read as adapter identity.
///
///     flutter test test/chaos_poll_oracle_test.dart \
///       --dart-define=CHAOS_ORACLE=true \
///       --dart-define=CHAOS_ORACLE_PORT=35001 \
///       --dart-define=CHAOS_CONTROL_PORT=35002 \
///       --dart-define=CHAOS_CONTROL_TOKEN=<token>
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/polling_engine.dart';
import 'package:torque_obd/obd/telemetry.dart';
import 'package:torque_obd/obd/transport/wifi_transport.dart';

const _enabled = bool.fromEnvironment('CHAOS_ORACLE');
const _host = '127.0.0.1';
const _port = int.fromEnvironment('CHAOS_ORACLE_PORT', defaultValue: 35001);
const _controlPort = int.fromEnvironment(
  'CHAOS_CONTROL_PORT',
  defaultValue: 35002,
);
const _token = String.fromEnvironment('CHAOS_CONTROL_TOKEN');

void main() {
  test(
    'a close after the first poll does not poison the next handshake',
    () async {
      if (!_enabled) {
        markTestSkipped(
          'Start Ircama and an armed chaos proxy, then set CHAOS_ORACLE=true.',
        );
        return;
      }
      expect(_token, isNotEmpty, reason: 'CHAOS_CONTROL_TOKEN is required');

      final transport = WifiTransport(host: _host, port: _port);
      final client = Elm327Client(transport);
      addTearDown(client.dispose);
      final poller = PollingEngine(client);
      addTearDown(poller.dispose);

      expect(
        await client.connect().timeout(const Duration(seconds: 20)),
        isTrue,
      );

      final firstReading = Completer<TelemetrySnapshot>();
      final subscription = poller.snapshots.listen((snapshot) {
        if (snapshot.readings.isNotEmpty && !firstReading.isCompleted) {
          firstReading.complete(snapshot);
        }
      });
      addTearDown(subscription.cancel);
      poller.start();
      final live = await firstReading.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw TimeoutException(
          'no live reading before arming the close',
          const Duration(seconds: 20),
        ),
      );
      expect(live.readings, isNotEmpty);

      final control = await Socket.connect(
        _host,
        _controlPort,
        timeout: const Duration(seconds: 3),
      );
      addTearDown(control.destroy);
      final replies = StringBuffer();
      control.listen((bytes) => replies.write(String.fromCharCodes(bytes)));
      control.write('ARM $_token\n');
      for (var i = 0; i < 40; i++) {
        if (replies.toString().contains('ARMED')) break;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(
        replies.toString(),
        contains('ARMED'),
        reason: 'the proxy must acknowledge the arm before the next command',
      );

      final deadline = DateTime.now().add(const Duration(seconds: 20));
      while (transport.isConnected && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(
        transport.isConnected,
        isFalse,
        reason: 'the armed close must drop the polling socket',
      );
      await poller.stop();
      await client.dispose();

      final next = WifiTransport(host: _host, port: _port);
      final client2 = Elm327Client(next);
      addTearDown(client2.dispose);
      expect(
        await client2.connect().timeout(const Duration(seconds: 20)),
        isTrue,
        reason: 'reconnect handshake must succeed on a fresh TCP session',
      );
      expect(
        client2.deviceIdentity,
        contains('OBDII to RS232 Interpreter'),
        reason: 'stale PID bytes must not be parsed as AT@1',
      );
      expect(client2.deviceVersion, contains('ELM327'));
    },
  );
}
