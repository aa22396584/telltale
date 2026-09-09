/// #70 leftover: software-lane 6-channel acquisition on the live poller.
///
/// The 1-PID software lane already exists. This exercises six Mode 01
/// channels together so a 1-channel PASS cannot stand in for the 6-channel
/// matrix. Not a device profile and not a competitor comparison.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/polling_engine.dart';
import 'package:torque_obd/obd/telemetry.dart';

import '../support/fake_elm327.dart';

const _minimumPerChannel = 8;

bool _isFresh(Reading reading, DateTime? previous) {
  if (previous == null) return true;
  return reading.timestamp.isAfter(previous);
}

void main() {
  test('six software channels each record fresh observations', () async {
    const channels = <Pid>[
      PidLibrary.engineRpm,
      PidLibrary.vehicleSpeed,
      PidLibrary.engineFuelRate,
      PidLibrary.coolantTemp,
      PidLibrary.engineLoad,
      PidLibrary.throttlePosition,
    ];
    expect(channels, hasLength(6));

    final transport = FakeElm327(
      protocol: BusProtocol.can11,
      ecus: [
        FakeEcu(
          name: 'ECM',
          requestId: '7E0',
          responseId: '7E8',
          responses: {
            '0100': [0x41, 0x00, 0xFF, 0xFF, 0xFF, 0xFF],
            '0120': [0x41, 0x20, 0xFF, 0xFF, 0xFF, 0xFF],
            '0140': [0x41, 0x40, 0xFF, 0xFF, 0xFF, 0xFF],
            '010C': [0x41, 0x0C, 0x1A, 0xF8],
            '010D': [0x41, 0x0D, 0x32],
            '015E': [0x41, 0x5E, 0x00, 0x14],
            '0105': [0x41, 0x05, 0x5A],
            '0104': [0x41, 0x04, 0x80],
            '0111': [0x41, 0x11, 0x40],
          },
        ),
      ],
    );
    final client = Elm327Client(transport);
    addTearDown(client.dispose);
    expect(await client.connect(), isTrue);

    final engine = PollingEngine(client)
      ..scheduler.fastModeEnabled = false
      ..setActivePids(channels, includeProfileDerivedInputs: false);
    addTearDown(engine.dispose);

    final counts = <String, int>{for (final pid in channels) pid.id: 0};
    final lastAt = <String, DateTime>{};
    final faulted = <String>{};
    final done = Completer<void>();
    final sub = engine.snapshots.listen(
      (snapshot) {
        faulted.addAll(snapshot.faults.keys);
        for (final pid in channels) {
          final reading = snapshot.readings[pid.id];
          if (reading == null) continue;
          if (!_isFresh(reading, lastAt[pid.id])) continue;
          lastAt[pid.id] = reading.timestamp;
          counts[pid.id] = (counts[pid.id] ?? 0) + 1;
        }
        if (counts.values.every((n) => n >= _minimumPerChannel) &&
            !done.isCompleted) {
          done.complete();
        }
      },
      onError: (Object error, StackTrace stack) {
        if (!done.isCompleted) done.completeError(error, stack);
      },
    );
    addTearDown(sub.cancel);

    engine.start();
    await done.future.timeout(const Duration(seconds: 30));

    expect(
      counts.length,
      6,
      reason: 'a 1-channel PASS is not a 6-channel matrix',
    );
    for (final pid in channels) {
      expect(
        counts[pid.id],
        greaterThanOrEqualTo(_minimumPerChannel),
        reason: '${pid.modeAndPid} produced ${counts[pid.id]} observations',
      );
    }
    expect(
      faulted,
      isEmpty,
      reason: 'a clean software lane must not hide poller faults: $faulted',
    );
  });
}
