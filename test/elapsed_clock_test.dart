/// Deep sleep is elapsed time. Dart Stopwatch is not.
///
/// Android `SystemClock.elapsedRealtime` includes time spent in deep sleep.
/// Dart `Stopwatch` on this VM follows uptime and does not. After a 60s
/// sleep, a Stopwatch-backed sample still looks one second old and a
/// high-priority gauge stays lit. Freshness must follow a clock that names
/// its sleep policy, and a failed native mapping must not silently fall back
/// to Stopwatch as if it were elapsedRealtime.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/elapsed_clock.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/pid/priority_tier.dart';
import 'package:torque_obd/obd/telemetry.dart';

const _rpm = Pid(
  name: 'RPM',
  shortName: 'RPM',
  modeAndPid: '010C',
  equation: '((A*256)+B)/4',
  minValue: 0,
  maxValue: 8000,
  units: 'rpm',
  priority: PriorityTier.high,
);

void main() {
  final wall = DateTime(2026, 9, 9, 12);

  test(
    'a host without native mapping does not claim to include deep sleep',
    () {
      final clock = NativeElapsedCache();
      expect(clock.includesDeepSleep, isFalse);
    },
  );

  test(
    'elapsedRealtime that includes sleep ages the sample across deep sleep',
    () async {
      var realtimeMs = 1000;
      final clock = NativeElapsedCache(readMs: () async => realtimeMs);
      await clock.sync();
      expect(clock.includesDeepSleep, isTrue);
      final reading = Reading(
        pid: _rpm,
        value: 800,
        rawBytes: const [0x0c, 0x80],
        timestamp: wall,
        receivedElapsed: clock.elapsed,
      );
      expect(
        reading.isStaleAt(
          wall.add(const Duration(seconds: 1)),
          elapsed: clock.elapsed,
        ),
        isFalse,
      );

      // Phone slept 60s. elapsedRealtime advanced; uptime did not.
      realtimeMs += 60 * 1000;
      await clock.sync();
      expect(
        reading.isStaleAt(
          wall.add(const Duration(seconds: 1)),
          elapsed: clock.elapsed,
        ),
        isTrue,
      );
    },
  );

  test('a native read that goes backwards retires continuity', () async {
    var realtimeMs = 5000;
    final clock = NativeElapsedCache(readMs: () async => realtimeMs);
    await clock.sync();
    final reading = Reading(
      pid: _rpm,
      value: 800,
      rawBytes: const [0x0c, 0x80],
      timestamp: wall,
      receivedElapsed: clock.elapsed,
    );
    realtimeMs = 1000;
    await clock.sync();
    expect(clock.unknown, isTrue);
    expect(reading.isStaleAt(wall, elapsed: clock.elapsed), isTrue);
  });

  test('a failed native mapping does not fall back to Stopwatch', () async {
    var fail = false;
    var realtimeMs = 2000;
    final clock = NativeElapsedCache(
      readMs: () async => fail ? null : realtimeMs,
    );
    await clock.sync();
    final reading = Reading(
      pid: _rpm,
      value: 800,
      rawBytes: const [0x0c, 0x80],
      timestamp: wall,
      receivedElapsed: clock.elapsed,
    );
    fail = true;
    await clock.sync();
    expect(clock.unknown, isTrue);
    expect(
      reading.isStaleAt(wall, elapsed: clock.elapsed),
      isTrue,
      reason:
          'unknown continuity must not present the last Stopwatch-shaped age',
    );
  });

  test('an unsynced native cache is stale, not zero-fresh', () {
    final clock = NativeElapsedCache(readMs: () async => 1);
    expect(clock.elapsed, greaterThan(const Duration(hours: 1)));
    final reading = Reading(
      pid: _rpm,
      value: 800,
      rawBytes: const [0x0c, 0x80],
      timestamp: wall,
      receivedElapsed: Duration.zero,
    );
    expect(reading.isStaleAt(wall, elapsed: clock.elapsed), isTrue);
  });
}
