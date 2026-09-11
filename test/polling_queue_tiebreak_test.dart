/// Re-queue order must not depend on `DateTime` uniqueness.
///
/// Instrumentation on `origin/main` (see #346): six high-priority PIDs
/// stamped in one tight loop, first drain `010C` / `NO DATA`, same
/// `QueuedRequest` re-inserted. On Linux unique microseconds put `010C`
/// back at the head (`010C0D04110B10`). On Windows ~1 ms resolution all
/// six shared `enqueuedAt=@1789117522558635`, `_insertSorted` treated
/// `compareTo == 0` as insert-at-tail (`010D04110B100C`).
///
/// A monotonic `seq` assigned at first enqueue makes the colliding-clock
/// case emit the same command as the unique-timestamp case.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/pid/priority_scheduler.dart';

const _expectedGroup = '010C0D04110B10';

const _six = [
  PidLibrary.engineRpm,
  PidLibrary.vehicleSpeed,
  PidLibrary.engineLoad,
  PidLibrary.throttlePosition,
  PidLibrary.manifoldPressure,
  PidLibrary.mafRate,
];

String _recoveryCommand(PriorityScheduler scheduler) {
  for (final pid in _six) {
    scheduler.enqueue(pid, pid.priority);
  }
  scheduler
    ..canBatch = false
    ..fastModeEnabled = true;
  final first = scheduler.popBatch();
  expect(first.single.pid.modeAndPid, '010C');
  scheduler.canBatch = true;
  scheduler.enqueueRequest(first.single);
  return scheduler.buildCommand(scheduler.popBatch());
}

void main() {
  test(
    're-queue after NO DATA groups 010C0D04110B10 even when timestamps collide',
    () {
      final frozen = DateTime.utc(2026, 9, 11, 8, 21, 11);
      final collided = PriorityScheduler(now: () => frozen);
      expect(_recoveryCommand(collided), _expectedGroup);

      var tick = DateTime.utc(2026, 9, 11, 8, 21, 11);
      final unique = PriorityScheduler(
        now: () {
          final stamped = tick;
          tick = tick.add(const Duration(microseconds: 1));
          return stamped;
        },
      );
      expect(_recoveryCommand(unique), _expectedGroup);
    },
  );
}
