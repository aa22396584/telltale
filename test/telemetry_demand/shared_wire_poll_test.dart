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
      expect(
        engine.capabilitySummary.statusFor(raw),
        PidCapabilityStatus.positive,
      );
      expect(
        engine.capabilitySummary.statusFor(scaled),
        PidCapabilityStatus.positive,
      );
    },
  );

  test(
    'a failing representative formula does not skip the sibling reading',
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

      const broken = Pid(
        name: 'RPM missing VAL',
        shortName: 'RPMx',
        modeAndPid: '010C',
        equation: 'VAL{FFFF}',
        minValue: 0,
        maxValue: 8000,
        units: 'rpm',
        priority: PriorityTier.high,
        isCustom: true,
        variant: 'broken',
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
          broken,
          scaled,
        ], includeProfileDerivedInputs: false);
      addTearDown(engine.dispose);

      engine.start();
      await engine.snapshots
          .firstWhere((snapshot) => snapshot.readings.containsKey(scaled.id))
          .timeout(const Duration(seconds: 5));
      await engine.stop();
      expect(engine.current.readings[scaled.id]!.value, 0x1A);
      expect(engine.current.readings.containsKey(broken.id), isFalse);
    },
  );

  test(
    'two profile windows on 22B046 keep their own offsets after one request',
    () async {
      // Payload after `62 B0 46`: 01 F4 01 18. SOC is bytes 0-1 = 50.0.
      // Temperature is bytes 2-3. Handing SOC's window to that formula is
      // 0x01F4/4-40 = 85 — in range, and wrong.
      const soc = Pid(
        name: 'raw-soc',
        shortName: 'SOC',
        modeAndPid: '22B046',
        equation: '(A*256+B)/10',
        minValue: 0,
        maxValue: 100,
        units: '%',
        header: '781',
        isCustom: true,
        ownerProfileId: 'mg-zs-ev-au-2021',
        sourceSignalId: 'raw-soc',
        sourceRevision: '2f485fcb',
        expectedResponseId: '789',
        dataOffsetBytes: 0,
        dataLengthBytes: 2,
        responseDataLengthBytes: 4,
      );
      const temp = Pid(
        name: 'pack-temp',
        shortName: 'Temp',
        modeAndPid: '22B046',
        equation: '(A*256+B)/4-40',
        minValue: -40,
        maxValue: 80,
        units: '°C',
        header: '781',
        isCustom: true,
        ownerProfileId: 'mg-zs-ev-au-2021',
        sourceSignalId: 'pack-temp',
        sourceRevision: '2f485fcb',
        expectedResponseId: '789',
        dataOffsetBytes: 2,
        dataLengthBytes: 2,
        responseDataLengthBytes: 4,
      );
      final transport = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: {
              '0100': [0x41, 0x00, 0xBE, 0x1F, 0xA8, 0x13],
              '010D': [0x41, 0x0D, 0x00],
            },
          ),
          FakeEcu(
            name: 'BMS',
            requestId: '781',
            responseId: '789',
            responses: {
              '22B046': [0x62, 0xB0, 0x46, 0x01, 0xF4, 0x01, 0x18],
            },
          ),
        ],
      );
      final client = Elm327Client(transport);
      addTearDown(client.dispose);
      expect(await client.connect(), isTrue);

      final engine = PollingEngine(client)
        ..scheduler.fastModeEnabled = false
        ..setActivePids(
          [soc, temp],
          includeProfileDerivedInputs: false,
          authorizedProfilePidIds: {soc.id, temp.id},
        );
      addTearDown(engine.dispose);

      engine.start();
      await engine.snapshots
          .firstWhere(
            (snapshot) =>
                snapshot.readings.containsKey(soc.id) &&
                snapshot.readings.containsKey(temp.id),
          )
          .timeout(const Duration(seconds: 5));
      final didSends = transport.commandLog
          .where(
            (command) => command.replaceAll(' ', '').toUpperCase() == '22B046',
          )
          .length;
      await engine.stop();
      expect(didSends, 1, reason: 'command log: ${transport.commandLog}');
      expect(engine.current.readings[soc.id]!.value, 50.0);
      expect(engine.current.readings[temp.id]!.value, 30.0);
      expect(engine.current.readings[temp.id]!.value, isNot(85));
    },
  );

  test('NO DATA on a shared wire request faults every definition, not just the representative', () async {
    final responses = <String, List<int>>{
      '0100': [0x41, 0x00, 0xBE, 0x1F, 0xA8, 0x13],
      '010C': [0x41, 0x0C, 0x1A, 0xF8],
      '010D': [0x41, 0x0D, 0x00],
    };
    final transport = FakeElm327(
      protocol: BusProtocol.can11,
      ecus: [
        FakeEcu(
          name: 'ECM',
          requestId: '7E0',
          responseId: '7E8',
          responses: responses,
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
      ..setActivePids(const [raw, scaled], includeProfileDerivedInputs: false);
    addTearDown(engine.dispose);

    engine.start();
    await engine.snapshots
        .firstWhere(
          (snapshot) =>
              snapshot.readings.containsKey(raw.id) &&
              snapshot.readings.containsKey(scaled.id),
        )
        .timeout(const Duration(seconds: 5));
    responses.remove('010C');
    await engine.snapshots
        .firstWhere(
          (snapshot) =>
              snapshot.faults.containsKey(raw.id) &&
              snapshot.faults.containsKey(scaled.id) &&
              !snapshot.readings.containsKey(raw.id) &&
              !snapshot.readings.containsKey(scaled.id),
        )
        .timeout(const Duration(seconds: 5));
    await engine.stop();
    expect(engine.current.readings.containsKey(raw.id), isFalse);
    expect(engine.current.readings.containsKey(scaled.id), isFalse);
    expect(engine.current.faults[raw.id], isNotNull);
    expect(engine.current.faults[scaled.id], isNotNull);
  });
}
