import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/ui/screens/performance/acceleration_run_controller.dart';

void main() {
  test('elapsed follows observation ticks, not wall-clock jumps', () {
    final run = AccelerationRunController();
    run.arm();
    run.ingestSpeed(kmh: 0, receivedElapsed: const Duration(seconds: 10));
    run.ingestSpeed(kmh: 3, receivedElapsed: const Duration(seconds: 10, milliseconds: 200));
    run.ingestSpeed(kmh: 100, receivedElapsed: const Duration(seconds: 18, milliseconds: 500));

    expect(run.state, AccelerationRunState.finished);
    expect(run.elapsed, const Duration(seconds: 8, milliseconds: 300));

    // Same observation ticks after a wall-clock step would have added 30s.
    final again = AccelerationRunController();
    again.arm();
    again.ingestSpeed(kmh: 0, receivedElapsed: const Duration(seconds: 10));
    again.ingestSpeed(kmh: 3, receivedElapsed: const Duration(seconds: 10, milliseconds: 200));
    again.ingestSpeed(kmh: 100, receivedElapsed: const Duration(seconds: 18, milliseconds: 500));
    expect(again.elapsed, run.elapsed);
  });

  test('start [0.0, 0.2]s and target [8.0, 8.3]s yield duration [7.8, 8.3]s', () {
    final run = AccelerationRunController();
    run.arm();
    // t=0 standstill on the run clock.
    run.ingestSpeed(kmh: 0, receivedElapsed: Duration.zero);
    // first moving at 0.2s
    run.ingestSpeed(kmh: 3, receivedElapsed: const Duration(milliseconds: 200));
    // last below 100 at 8.0s from standstill = 7.8s from launch
    run.ingestSpeed(kmh: 99, receivedElapsed: const Duration(seconds: 8));
    // first at/above 100 at 8.3s from standstill = 8.1s from launch
    run.ingestSpeed(kmh: 100, receivedElapsed: const Duration(seconds: 8, milliseconds: 300));

    expect(run.startBracket, isNotNull);
    expect(run.startBracket!.lowerSeconds, closeTo(0.0, 1e-9));
    expect(run.startBracket!.upperSeconds, closeTo(0.2, 1e-9));
    expect(run.targetBracket!.lowerSeconds, closeTo(8.0, 1e-9));
    expect(run.targetBracket!.upperSeconds, closeTo(8.3, 1e-9));
    expect(run.durationBracket!.lowerSeconds, closeTo(7.8, 1e-9));
    expect(run.durationBracket!.upperSeconds, closeTo(8.3, 1e-9));
    expect(
      run.elapsed,
      const Duration(seconds: 8, milliseconds: 100),
      reason: 'displayed elapsed is still first-moving → first-at-target',
    );
  });

  test('a duplicate observation tick does not advance the run', () {
    final run = AccelerationRunController();
    run.arm();
    run.ingestSpeed(kmh: 0, receivedElapsed: const Duration(seconds: 1));
    run.ingestSpeed(kmh: 3, receivedElapsed: const Duration(seconds: 2));
    run.ingestSpeed(kmh: 40, receivedElapsed: const Duration(seconds: 3));
    final elapsed = run.elapsed;
    final points = run.trace.length;
    run.ingestSpeed(kmh: 80, receivedElapsed: const Duration(seconds: 3));
    expect(run.elapsed, elapsed);
    expect(run.trace, hasLength(points));
    expect(run.splits.containsKey(80), isFalse);
  });

  test('absence past the grace aborts a running run and keeps splits', () {
    final run = AccelerationRunController();
    run.arm();
    run.ingestSpeed(kmh: 0, receivedElapsed: Duration.zero);
    run.ingestSpeed(kmh: 3, receivedElapsed: const Duration(milliseconds: 100));
    run.ingestSpeed(kmh: 55, receivedElapsed: const Duration(seconds: 4));
    expect(run.splits[50], isNotNull);

    run.ingestAbsence(nowElapsed: const Duration(seconds: 4, milliseconds: 200));
    expect(run.state, AccelerationRunState.running);

    run.ingestAbsence(nowElapsed: const Duration(seconds: 6));
    expect(run.state, AccelerationRunState.aborted);
    expect(run.splits[50], isNotNull);
    expect(run.elapsed, isNotNull);
  });

  test('a stale sample aborts immediately', () {
    final run = AccelerationRunController();
    run.arm();
    run.ingestSpeed(kmh: 0, receivedElapsed: Duration.zero);
    run.ingestStale();
    expect(run.state, AccelerationRunState.aborted);
  });

  test('arming while moving waits for standstill', () {
    final run = AccelerationRunController();
    run.arm();
    run.ingestSpeed(kmh: 70, receivedElapsed: Duration.zero);
    expect(run.state, AccelerationRunState.awaitingStandstill);
    expect(run.elapsed, isNull);
    run.ingestSpeed(kmh: 0, receivedElapsed: const Duration(seconds: 1));
    expect(run.state, AccelerationRunState.staged);
  });
}
