/// #70 leftover: software-lane acquisition measurement on the live poller.
///
/// This is not a device profile and not a competitor comparison. It runs the
/// production [PollingEngine] against a scripted ELM327 so a zero-observation
/// or skipped run cannot be reported as PASS.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/polling_engine.dart';
import 'package:torque_obd/obd/telemetry.dart';

import '../support/fake_elm327.dart';

const _minimumObservations = 20;

/// Nearest-rank quantile. Empty input is not a number.
int nearestRank(List<int> sortedAscending, double q) {
  if (sortedAscending.isEmpty) {
    throw StateError('quantile of no samples');
  }
  final rank = (q * sortedAscending.length).ceil().clamp(
    1,
    sortedAscending.length,
  );
  return sortedAscending[rank - 1];
}

/// A snapshot that still contains the previous RPM is not a new acquisition.
bool isFreshAcquisition(Reading reading, DateTime? previous) {
  if (previous == null) return true;
  return reading.timestamp.isAfter(previous);
}

void main() {
  test('software acquisition records observations and refuses an empty run', () async {
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
            '010D': [0x41, 0x0D, 0x32],
            '015E': [0x41, 0x5E, 0x00, 0x14],
          },
        ),
      ],
    );
    final client = Elm327Client(transport);
    addTearDown(client.dispose);
    expect(await client.connect(), isTrue);

    final engine = PollingEngine(client)
      ..scheduler.fastModeEnabled = false
      ..setActivePids(const [
        PidLibrary.engineRpm,
      ], includeProfileDerivedInputs: false);
    addTearDown(engine.dispose);

    final started = DateTime.now();
    engine.start();

    final stamps = <DateTime>[];
    final faulted = <String>{};
    DateTime? lastRpmAt;
    // includeProfileDerivedInputs: false still schedules speed and fuel rate.
    const scheduledChannels = 3;
    await Future<void>(() async {
      await for (final snapshot in engine.snapshots) {
        faulted.addAll(snapshot.faults.keys);
        final reading = snapshot.readings[PidLibrary.engineRpm.id];
        if (reading == null) continue;
        if (!isFreshAcquisition(reading, lastRpmAt)) continue;
        lastRpmAt = reading.timestamp;
        stamps.add(reading.timestamp);
        if (stamps.length >= _minimumObservations) return;
      }
    }).timeout(const Duration(seconds: 20));

    expect(
      stamps.length,
      greaterThanOrEqualTo(_minimumObservations),
      reason: 'zero or truncated observations are not a PASS',
    );

    final firstMs = stamps.first.difference(started).inMilliseconds;
    expect(firstMs, greaterThanOrEqualTo(0));

    final gaps = <int>[
      for (var i = 1; i < stamps.length; i++)
        stamps[i].difference(stamps[i - 1]).inMilliseconds,
    ]..sort();
    expect(gaps, isNotEmpty);
    final report = <String, Object?>{
      'lane': 'software',
      'transport': 'FakeElm327',
      'engine': 'PollingEngine',
      'quantile': 'nearest-rank',
      'minimumObservations': _minimumObservations,
      'observations': stamps.length,
      'channels': scheduledChannels,
      'scheduledModeAndPid': const ['010C', '010D', '015E'],
      'firstObservationMs': firstMs,
      'interarrivalMs': {
        'n': gaps.length,
        'p50': nearestRank(gaps, 0.50),
        'p95': nearestRank(gaps, 0.95),
        'p99': nearestRank(gaps, 0.99),
      },
      'errors': faulted.length,
    };

    expect(nearestRank(gaps, 0.50), greaterThanOrEqualTo(0));
    expect(report['observations'], _minimumObservations);
    expect(
      report['errors'],
      0,
      reason: 'a clean software lane must not hide poller faults',
    );

    final out = Platform.environment['PERF_OBD_OUTPUT'];
    if (out != null && out.isNotEmpty) {
      final dir = Directory(out)..createSync(recursive: true);
      File('${dir.path}/software.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(report),
      );
    }
  });

  test('nearest-rank refuses an empty sample list', () {
    expect(() => nearestRank(const [], 0.5), throwsStateError);
  });

  test('a reused RPM timestamp is not a new acquisition', () {
    const pid = PidLibrary.engineRpm;
    final at = DateTime(2026, 9, 9, 1);
    final first = Reading(
      pid: pid,
      value: 1724,
      rawBytes: const [0x1A, 0xF8],
      timestamp: at,
    );
    final echo = Reading(
      pid: pid,
      value: 1724,
      rawBytes: const [0x1A, 0xF8],
      timestamp: at,
    );
    final later = Reading(
      pid: pid,
      value: 1800,
      rawBytes: const [0x1C, 0x20],
      timestamp: at.add(const Duration(milliseconds: 50)),
    );
    expect(isFreshAcquisition(first, null), isTrue);
    expect(isFreshAcquisition(echo, first.timestamp), isFalse);
    expect(isFreshAcquisition(later, first.timestamp), isTrue);
  });
}
