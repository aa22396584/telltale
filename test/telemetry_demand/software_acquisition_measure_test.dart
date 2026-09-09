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
    await for (final snapshot in engine.snapshots.timeout(
      const Duration(seconds: 20),
    )) {
      if (!snapshot.readings.containsKey(PidLibrary.engineRpm.id)) continue;
      stamps.add(DateTime.now());
      if (stamps.length >= _minimumObservations) break;
    }

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
      'channels': 1,
      'firstObservationMs': firstMs,
      'interarrivalMs': {
        'n': gaps.length,
        'p50': nearestRank(gaps, 0.50),
        'p95': nearestRank(gaps, 0.95),
        'p99': nearestRank(gaps, 0.99),
      },
      'errors': 0,
    };

    expect(nearestRank(gaps, 0.50), greaterThanOrEqualTo(0));
    expect(report['observations'], _minimumObservations);

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
}
