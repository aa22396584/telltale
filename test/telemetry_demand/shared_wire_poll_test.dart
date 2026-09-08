/// #70.B leftover: two formulas on one PID share a single adapter request.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/pid/priority_tier.dart';
import 'package:torque_obd/obd/polling_engine.dart';

import '../support/fake_elm327.dart';

void main() {
  test(
    'two definitions of 010C share one wire request and both get readings',
    () async {
      final transport = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: {
              '0100': [0x41, 0x00, 0xBE, 0x1F, 0xA8, 0x13],
              '010C': [0x41, 0x0C, 0x1A, 0xF8],
              '010D': [0x41, 0x0D, 0x00],
            },
          ),
        ],
      );
      final client = Elm327Client(transport);
      addTearDown(client.dispose);
      expect(await client.connect(), isTrue);

      const raw = Pid(
        name: 'RPM raw',
        shortName: 'RPMr',
        modeAndPid: '010C',
        equation: '((A*256)+B)/4',
        minValue: 0,
        maxValue: 8000,
        units: 'rpm',
        priority: PriorityTier.high,
        isCustom: true,
        variant: 'raw',
      );
      const scaled = Pid(
        name: 'RPM byte',
        shortName: 'RPMb',
        modeAndPid: '010C',
        equation: 'A',
        minValue: 0,
        maxValue: 255,
        units: '',
        priority: PriorityTier.medium,
        isCustom: true,
        variant: 'byte',
      );

      final engine = PollingEngine(client)
        ..scheduler.fastModeEnabled = false
        ..setActivePids(const [
          raw,
          scaled,
        ], includeProfileDerivedInputs: false);
      addTearDown(engine.dispose);

      engine.start();
      await engine.snapshots
          .firstWhere(
            (snapshot) =>
                snapshot.readings.containsKey(raw.id) &&
                snapshot.readings.containsKey(scaled.id),
          )
          .timeout(const Duration(seconds: 5));
      final rpmSends = transport.commandLog
          .where(
            (command) => command.replaceAll(' ', '').toUpperCase() == '010C',
          )
          .length;
      await engine.stop();
      expect(rpmSends, 1, reason: 'command log: ${transport.commandLog}');
      expect(engine.current.readings[raw.id]!.value, closeTo(1726, 0.5));
      expect(engine.current.readings[scaled.id]!.value, 0x1A);
      expect(
        engine.demands.uniqueWireRequests().where(
          (d) => d.wireKey == '7E0:010C',
        ),
        hasLength(1),
      );
    },
  );
}
