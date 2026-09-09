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

  test('a small-positive wall rollback cannot revive a monotonically old VAL cache', () {
    // Wall was `at` at acquisition. 6 real seconds later (past maxCacheAge
    // of 5s) the clock is corrected to at+1s. Wall age is 1s; monotonic
    // age is 6s. Freshness follows the monotonic tick.
    final engine = FormulaEngine();
    final at = DateTime(2026, 9, 8, 12);
    engine.cachePidValue(rpm, 1500, at, receivedElapsed: Duration.zero);
    expect(
      engine.cachedPidValue(
        rpm,
        '010C',
        now: at.add(const Duration(seconds: 1)),
        elapsed: const Duration(seconds: 6),
      ),
      isNull,
    );
  });

  test(
    'monotonic advance with an unchanged wall still expires the VAL cache',
    () {
      final engine = FormulaEngine();
      final at = DateTime(2026, 9, 8, 12);
      engine.cachePidValue(rpm, 1500, at, receivedElapsed: Duration.zero);
      expect(
        engine.cachedPidValue(
          rpm,
          '010C',
          now: at,
          elapsed: FormulaEngine.maxCacheAge + const Duration(seconds: 1),
        ),
        isNull,
      );
    },
  );

  test(
    'a small-positive wall rollback cannot revive a monotonically old BARO',
    () {
      final engine = FormulaEngine();
      final at = DateTime(2026, 9, 8, 12);
      final probe = FormulaEngine.probePid('0000');
      engine.setBaroPressure(probe, 99.5, at, receivedElapsed: Duration.zero);
      expect(
        () => engine.evaluateBytes(
          'A-BARO',
          const [120],
          requester: probe,
          now: at.add(const Duration(seconds: 1)),
          elapsed: const Duration(seconds: 6),
        ),
        throwsA(
          isA<FormulaException>().having(
            (e) => e.issue,
            'issue',
            FormulaIssue.baroMeasurementStale,
          ),
        ),
      );
    },
  );

  test(
    'a small-positive wall rollback cannot revive a monotonically old ATRV',
    () async {
      var now = DateTime(2026, 9, 8, 12);
      var elapsed = Duration.zero;
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
        elapsed: () => elapsed,
      );
      expect(await client.connect(), isTrue);
      expect(client.batteryVoltage, closeTo(13.8, 0.001));
      now = now.add(const Duration(seconds: 1));
      elapsed = Elm327Client.voltageMaxAge + const Duration(seconds: 1);
      expect(client.batteryVoltage, isNull);
    },
  );

  test(
    'monotonic advance with an unchanged wall still expires ATRV',
    () async {
      final now = DateTime(2026, 9, 8, 12);
      var elapsed = Duration.zero;
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
        elapsed: () => elapsed,
      );
      expect(await client.connect(), isTrue);
      expect(client.batteryVoltage, closeTo(13.8, 0.001));
      elapsed = Elm327Client.voltageMaxAge + const Duration(seconds: 1);
      expect(client.batteryVoltage, isNull);
    },
  );

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
