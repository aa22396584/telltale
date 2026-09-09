/// #70 leftover: software-lane 20-channel acquisition on the live poller.
///
/// The 1-PID and 6-channel software lanes cannot stand in for the 20-channel
/// matrix. Not a device profile and not a competitor comparison.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/polling_engine.dart';
import 'package:torque_obd/obd/telemetry.dart';

import '../support/fake_elm327.dart';

const _minimumPerChannel = 8;

int _nearestRank(List<int> sortedAscending, double q) {
  if (sortedAscending.isEmpty) {
    throw StateError('quantile of no samples');
  }
  final rank = (q * sortedAscending.length).ceil().clamp(
    1,
    sortedAscending.length,
  );
  return sortedAscending[rank - 1];
}

bool _isFresh(Reading reading, DateTime? previous) {
  if (previous == null) return true;
  return reading.timestamp.isAfter(previous);
}

void main() {
  test('twenty software channels each record fresh observations', () async {
    const channels = <Pid>[
      PidLibrary.engineRpm,
      PidLibrary.vehicleSpeed,
      PidLibrary.engineFuelRate,
      PidLibrary.coolantTemp,
      PidLibrary.engineLoad,
      PidLibrary.throttlePosition,
      PidLibrary.intakeAirTemp,
      PidLibrary.manifoldPressure,
      PidLibrary.mafRate,
      PidLibrary.timingAdvance,
      PidLibrary.fuelPressure,
      PidLibrary.fuelLevel,
      PidLibrary.barometricPressure,
      PidLibrary.controlModuleVoltage,
      PidLibrary.ambientAirTemp,
      PidLibrary.engineOilTemp,
      PidLibrary.shortFuelTrimB1,
      PidLibrary.longFuelTrimB1,
      PidLibrary.runTime,
      PidLibrary.commandedEgr,
    ];
    expect(channels, hasLength(20));

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
            '010F': [0x41, 0x0F, 0x50],
            '010B': [0x41, 0x0B, 0x64],
            '0110': [0x41, 0x10, 0x10, 0x00],
            '010E': [0x41, 0x0E, 0x80],
            '010A': [0x41, 0x0A, 0x20],
            '012F': [0x41, 0x2F, 0x80],
            '0133': [0x41, 0x33, 0x64],
            '0142': [0x41, 0x42, 0x36, 0xB0],
            '0146': [0x41, 0x46, 0x50],
            '015C': [0x41, 0x5C, 0x5A],
            '0106': [0x41, 0x06, 0x80],
            '0107': [0x41, 0x07, 0x80],
            '011F': [0x41, 0x1F, 0x00, 0x64],
            '012C': [0x41, 0x2C, 0x40],
          },
        ),
      ],
    );
    final client = Elm327Client(transport);
    addTearDown(client.dispose);
    expect(await client.connect(), isTrue);

    // FakeElm327 answers single Mode 01 reads, not fastMode batches.
    final engine = PollingEngine(client)
      ..scheduler.fastModeEnabled = false
      ..setActivePids(channels, includeProfileDerivedInputs: false);
    addTearDown(engine.dispose);

    final counts = <String, int>{for (final pid in channels) pid.id: 0};
    final lastAt = <String, DateTime>{};
    final rpmStamps = <DateTime>[];
    final faulted = <String>{};
    final done = Completer<void>();
    final started = DateTime.now();
    final sub = engine.snapshots.listen(
      (snapshot) {
        faulted.addAll(snapshot.faults.keys);
        for (final pid in channels) {
          final reading = snapshot.readings[pid.id];
          if (reading == null) continue;
          if (!_isFresh(reading, lastAt[pid.id])) continue;
          lastAt[pid.id] = reading.timestamp;
          counts[pid.id] = (counts[pid.id] ?? 0) + 1;
          if (pid.id == PidLibrary.engineRpm.id) {
            rpmStamps.add(reading.timestamp);
          }
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
    await done.future.timeout(const Duration(seconds: 45));

    expect(
      counts.length,
      20,
      reason: 'a 6-channel PASS is not a 20-channel matrix',
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

    final gaps = <int>[
      for (var i = 1; i < rpmStamps.length; i++)
        rpmStamps[i].difference(rpmStamps[i - 1]).inMilliseconds,
    ]..sort();
    expect(gaps, isNotEmpty);
    final perChannel = <String, int>{
      for (final pid in channels) pid.modeAndPid: counts[pid.id] ?? 0,
    };
    final report = <String, Object?>{
      'lane': 'software',
      'transport': 'FakeElm327',
      'engine': 'PollingEngine',
      'quantile': 'nearest-rank',
      'minimumObservations': _minimumPerChannel,
      'observations': counts.values.reduce((a, b) => a < b ? a : b),
      'channels': 20,
      'scheduledModeAndPid': [for (final pid in channels) pid.modeAndPid],
      'perChannel': perChannel,
      'firstObservationMs': rpmStamps.first.difference(started).inMilliseconds,
      'interarrivalMs': {
        'n': gaps.length,
        'p50': _nearestRank(gaps, 0.50),
        'p95': _nearestRank(gaps, 0.95),
        'p99': _nearestRank(gaps, 0.99),
      },
      'errors': faulted.length,
    };
    expect(report['channels'], 20);
    expect(report['observations'], greaterThanOrEqualTo(_minimumPerChannel));

    final out = Platform.environment['PERF_OBD_OUTPUT'];
    if (out != null && out.isNotEmpty) {
      final dir = Directory(out)..createSync(recursive: true);
      File(
        '${dir.path}/software-twenty.json',
      ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
    }
  }, timeout: const Timeout(Duration(seconds: 60)));
}
