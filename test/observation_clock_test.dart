import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/pid/formula_engine.dart';
import 'package:torque_obd/obd/pid/pid.dart';

import 'support/fake_elm327.dart';

void main() {
  const rpm = Pid(
    name: 'RPM',
    shortName: 'RPM',
    modeAndPid: '010C',
    equation: '((A*256)+B)/4',
    minValue: 0,
    maxValue: 8000,
    units: 'rpm',
  );

  test('formula cache does not revive after a backwards clock step', () {
    final engine = FormulaEngine();
    final at = DateTime(2026, 9, 8, 12);
    engine.cachePidValue(rpm, 1500, at);
    expect(engine.cachedPidValue(rpm, '010C', now: at), 1500);
    expect(
      engine.cachedPidValue(
        rpm,
        '010C',
        now: at.subtract(const Duration(hours: 1)),
      ),
      isNull,
    );
  });

  test('adapter voltage cache expires on a backwards clock step', () async {
    var now = DateTime(2026, 9, 8, 12);
    final transport = FakeElm327(
      protocol: BusProtocol.can11,
      ecus: [
        FakeEcu(
          name: 'ECM',
          requestId: '7E0',
          responseId: '7E8',
          responses: {
            '0100': [0x41, 0x00, 0xBE, 0x1F, 0xA8, 0x13],
          },
        ),
      ],
      faults: const AdapterFaults(voltageText: '13.8V'),
    );
    final client = Elm327Client(
      transport,
      commandTimeout: const Duration(milliseconds: 200),
      clock: () => now,
    );
    expect(await client.connect(), isTrue);
    expect(client.batteryVoltage, closeTo(13.8, 0.001));
    now = now.subtract(const Duration(hours: 1));
    expect(client.batteryVoltage, isNull);
  });
}
