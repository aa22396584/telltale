/// #70 leftover: recording Start holds frozen PIDs on the live poller.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/pid/priority_tier.dart';
import 'package:torque_obd/obd/polling_engine.dart';
import 'package:torque_obd/obd/recording_demand_lease.dart';
import 'package:torque_obd/obd/telemetry.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/artifact_operation_gate.dart';
import 'package:torque_obd/state/pid_mutation_lock.dart';
import 'package:torque_obd/state/telemetry_recorder.dart';
import 'package:torque_obd/state/telemetry_runtime.dart';
import 'package:torque_obd/telemetry/session/telemetry_session.dart';
import 'package:torque_obd/telemetry/session/telemetry_session_store.dart';

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

int _sends(FakeElm327 transport, String modeAndPid) => transport.commandLog
    .where(
      (command) =>
          command.replaceAll(' ', '').toUpperCase() ==
          modeAndPid.replaceAll(' ', '').toUpperCase(),
    )
    .length;

void main() {
  test(
    'recording Start keeps a dropped dashboard PID on the wire until Stop',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'telemetry-hold-',
      );
      addTearDown(() => temporary.delete(recursive: true));

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

      final engine = PollingEngine(client)
        ..scheduler.fastModeEnabled = false
        ..setActivePids(const [_rpm], includeProfileDerivedInputs: false);
      addTearDown(engine.dispose);
      engine.start();
      await engine.snapshots
          .firstWhere((snapshot) => snapshot.readings.containsKey(_rpm.id))
          .timeout(const Duration(seconds: 5));

      final lease = RecordingDemandLease(engine);
      var now = DateTime.utc(2026, 8, 30, 1);
      var elapsedUs = 1000000;
      final environment = LiveTelemetryStartEnvironment(
        readConnection: () => const TelemetryConnectionSnapshot(
          connected: true,
          foreground: true,
          connectionGeneration: 1,
          foregroundEpoch: 1,
        ),
        utcNow: () => now,
        elapsedUs: () => elapsedUs,
      )..observeTelemetry(
        TelemetrySnapshot(
          readings: {
            PidLibrary.vehicleSpeed.id: Reading(
              pid: PidLibrary.vehicleSpeed,
              value: 0,
              rawBytes: const [0],
              timestamp: now,
            ),
          },
          capturedAt: now,
        ),
      );
      final store = TelemetrySessionStore(
        documentsDirectory: () async => temporary,
        idSource: () => '0123456789abcdef0123456789abcdef',
        nowUtc: () => now,
      );
      final recorder = RootTelemetryRecorder(
        environment: environment,
        storage: FileTelemetryRecorderStorage(store),
        startCommandMutex: StartCommandMutex(),
        artifactGate: ArtifactOperationGate(),
        pidMutationLock: PidMutationLock(),
        utcNow: () => now,
        elapsedUs: () => elapsedUs,
        acquireRecordingChannels: lease.acquire,
        releaseRecordingChannels: lease.release,
      );

      final started = await recorder.start(
        TelemetryStartRequest(
          source: TelemetrySource.fieldAppConnection,
          transport: TransportKind.wifi,
          protocol: 'ISO 15765-4 CAN',
          activePids: const [_rpm],
        ),
      );
      expect(started.outcome, TelemetryStartOutcome.recording);

      final beforeDrop = _sends(transport, '010C');
      engine.setActivePids(const [], includeProfileDerivedInputs: false);
      await engine.snapshots
          .firstWhere((_) => _sends(transport, '010C') > beforeDrop)
          .timeout(const Duration(seconds: 5));
      expect(engine.current.readings[_rpm.id]!.value, closeTo(1726, 0.5));

      recorder.stop();
      await recorder.drainFinalization();
      await engine.snapshots
          .where((snapshot) => snapshot.readings.containsKey(PidLibrary.vehicleSpeed.id))
          .take(3)
          .timeout(const Duration(seconds: 5))
          .drain<void>();
      final afterStop = _sends(transport, '010C');
      await engine.snapshots
          .where((snapshot) => snapshot.readings.containsKey(PidLibrary.vehicleSpeed.id))
          .take(5)
          .timeout(const Duration(seconds: 5))
          .drain<void>();
      await engine.stop();
      expect(
        _sends(transport, '010C'),
        afterStop,
        reason: 'command log: ${transport.commandLog}',
      );
    },
  );

  test('unauthorized profile PIDs are skipped, ordinary holds stay', () {
    final transport = FakeElm327(
      protocol: BusProtocol.can11,
      ecus: [
        FakeEcu(
          name: 'ECM',
          requestId: '7E0',
          responseId: '7E8',
          responses: const {},
        ),
      ],
    );
    final client = Elm327Client(transport);
    addTearDown(client.dispose);
    final engine = PollingEngine(client);
    addTearDown(engine.dispose);
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
    );
    final lease = RecordingDemandLease(engine);
    expect(() => lease.acquire(const [_rpm, soc]), returnsNormally);
    expect(
      engine.demands.leases.where((d) => d.leaseId == 'recording:${_rpm.id}'),
      hasLength(1),
    );
    expect(
      engine.demands.leases.where((d) => d.leaseId == 'recording:${soc.id}'),
      isEmpty,
    );
  });
}
