/// #70.C leftover: a recording lease keeps its definition after the dashboard
/// drops it, and `_refillQueue` still schedules that unique wire request.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/pid/priority_tier.dart';
import 'package:torque_obd/obd/polling_engine.dart';
import 'package:torque_obd/obd/telemetry_demand.dart';

import '../support/fake_elm327.dart';

const _rpm = Pid(
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

const _scaled = Pid(
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

const _soc = Pid(
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

TelemetryDemand _recordingLease(Pid pid, {required String leaseId}) =>
    TelemetryDemand(
      owner: DemandOwner.recording,
      leaseId: leaseId,
      header: pid.header,
      modeAndPid: pid.modeAndPid,
      requestedPeriod: pid.priority.targetInterval,
      priority: pid.priority,
      definitionId: pid.id,
    );

int _sends(FakeElm327 transport, String modeAndPid) => transport.commandLog
    .where(
      (command) =>
          command.replaceAll(' ', '').toUpperCase() ==
          modeAndPid.replaceAll(' ', '').toUpperCase(),
    )
    .length;

Future<Elm327Client> _connect(FakeElm327 transport) async {
  final client = Elm327Client(transport);
  expect(await client.connect(), isTrue);
  return client;
}

FakeElm327 _rpmTransport() => FakeElm327(
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

void main() {
  test(
    'a recording lease keeps polling after the dashboard drops the PID',
    () async {
      final transport = _rpmTransport();
      final client = await _connect(transport);
      addTearDown(client.dispose);

      final engine = PollingEngine(client)
        ..scheduler.fastModeEnabled = false
        ..setActivePids(const [_rpm], includeProfileDerivedInputs: false);
      addTearDown(engine.dispose);

      engine.hold(_recordingLease(_rpm, leaseId: 'rec-rpm'), _rpm);
      engine.setActivePids(const [], includeProfileDerivedInputs: false);

      expect(
        engine.demands.leases.where((d) => d.owner == DemandOwner.recording),
        hasLength(1),
      );
      expect(
        engine.demands.leases.where(
          (d) =>
              d.owner == DemandOwner.dashboard &&
              d.modeAndPid.replaceAll(' ', '').toUpperCase() == '010C',
        ),
        isEmpty,
      );

      engine.start();
      await engine.snapshots
          .firstWhere((snapshot) => snapshot.readings.containsKey(_rpm.id))
          .timeout(const Duration(seconds: 5));
      final rpmSends = _sends(transport, '010C');
      await engine.stop();
      expect(
        rpmSends,
        greaterThanOrEqualTo(1),
        reason: 'command log: ${transport.commandLog}',
      );
      expect(engine.current.readings[_rpm.id]!.value, closeTo(1726, 0.5));
    },
  );

  test(
    'releaseHold drops the definition and stops further wire requests',
    () async {
      final transport = _rpmTransport();
      final client = await _connect(transport);
      addTearDown(client.dispose);

      final engine = PollingEngine(client)
        ..scheduler.fastModeEnabled = false
        ..setActivePids(const [], includeProfileDerivedInputs: false);
      addTearDown(engine.dispose);

      engine.hold(_recordingLease(_rpm, leaseId: 'rec-rpm'), _rpm);
      engine.start();
      await engine.snapshots
          .firstWhere((snapshot) => snapshot.readings.containsKey(_rpm.id))
          .timeout(const Duration(seconds: 5));

      engine.releaseHold('rec-rpm');
      expect(
        engine.demands.leases.where((d) => d.leaseId == 'rec-rpm'),
        isEmpty,
      );

      await engine.snapshots.take(3).drain<void>();
      final afterRelease = _sends(transport, '010C');
      await engine.snapshots.take(5).drain<void>();
      await engine.stop();
      expect(
        _sends(transport, '010C'),
        afterRelease,
        reason: 'command log: ${transport.commandLog}',
      );
    },
  );

  test(
    'a held sibling on the same wire is evaluated without a second request',
    () async {
      final transport = _rpmTransport();
      final client = await _connect(transport);
      addTearDown(client.dispose);

      final engine = PollingEngine(client)
        ..scheduler.fastModeEnabled = false
        ..setActivePids(const [_rpm], includeProfileDerivedInputs: false);
      addTearDown(engine.dispose);

      engine.hold(_recordingLease(_scaled, leaseId: 'rec-byte'), _scaled);
      engine.start();
      await engine.snapshots
          .firstWhere(
            (snapshot) =>
                snapshot.readings.containsKey(_rpm.id) &&
                snapshot.readings.containsKey(_scaled.id),
          )
          .timeout(const Duration(seconds: 5));
      final rpmSends = _sends(transport, '010C');
      await engine.stop();
      expect(rpmSends, 1, reason: 'command log: ${transport.commandLog}');
      expect(engine.current.readings[_rpm.id]!.value, closeTo(1726, 0.5));
      expect(engine.current.readings[_scaled.id]!.value, 0x1A);
    },
  );

  test(
    'a held profile definition stays authorized after the dashboard drops it',
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
      final client = await _connect(transport);
      addTearDown(client.dispose);

      final engine = PollingEngine(client)
        ..scheduler.fastModeEnabled = false
        ..setActivePids(
          const [_soc],
          includeProfileDerivedInputs: false,
          authorizedProfilePidIds: {_soc.id},
        );
      addTearDown(engine.dispose);

      engine.hold(_recordingLease(_soc, leaseId: 'rec-soc'), _soc);
      engine.setActivePids(const [], includeProfileDerivedInputs: false);

      engine.start();
      await engine.snapshots
          .firstWhere((snapshot) => snapshot.readings.containsKey(_soc.id))
          .timeout(const Duration(seconds: 5));
      final didSends = _sends(transport, '22B046');
      await engine.stop();
      expect(
        didSends,
        greaterThanOrEqualTo(1),
        reason: 'command log: ${transport.commandLog}',
      );
      expect(engine.current.readings[_soc.id]!.value, 50.0);
    },
  );

  test('hold refuses an unauthorized profile definition', () async {
    final transport = _rpmTransport();
    final client = await _connect(transport);
    addTearDown(client.dispose);
    final engine = PollingEngine(client);
    addTearDown(engine.dispose);

    expect(
      () => engine.hold(_recordingLease(_soc, leaseId: 'rec-soc'), _soc),
      throwsA(isA<StateError>()),
    );
    expect(engine.demands.leases, isEmpty);
  });

  test(
    'hold refuses a dashboard owner — those leases come from setActivePids',
    () async {
      final transport = _rpmTransport();
      final client = await _connect(transport);
      addTearDown(client.dispose);
      final engine = PollingEngine(client);
      addTearDown(engine.dispose);

      expect(
        () => engine.hold(
          TelemetryDemand(
            owner: DemandOwner.dashboard,
            leaseId: 'dashboard-forged',
            header: _rpm.header,
            modeAndPid: _rpm.modeAndPid,
            requestedPeriod: _rpm.priority.targetInterval,
            priority: _rpm.priority,
            definitionId: _rpm.id,
          ),
          _rpm,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(engine.demands.leases, isEmpty);
    },
  );
}
