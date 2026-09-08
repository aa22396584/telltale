/// Recording-session leases on the live [PollingEngine].
///
/// Dashboard [PollingEngine.setActivePids] rebuilds only dashboard demand.
/// A recording that froze a PID set must keep those definitions on the wire
/// after the user removes the gauges.
library;

import 'pid/pid.dart';
import 'polling_engine.dart';
import 'telemetry_demand.dart';

class RecordingDemandLease {
  RecordingDemandLease(this._engine);

  final PollingEngine _engine;
  final List<String> _ids = [];

  void acquire(List<Pid> pids) {
    release();
    final acquired = <String>[];
    try {
      for (final pid in pids) {
        final id = 'recording:${pid.id}';
        try {
          _engine.hold(
            TelemetryDemand(
              owner: DemandOwner.recording,
              leaseId: id,
              header: pid.header,
              modeAndPid: pid.modeAndPid,
              requestedPeriod: pid.priority.targetInterval,
              priority: pid.priority,
              definitionId: pid.id,
            ),
            pid,
          );
          acquired.add(id);
        } on StateError {
          // Unauthorized profile definition: skip rather than fail Start.
        }
      }
      _ids.addAll(acquired);
    } on Object {
      for (final id in acquired) {
        _engine.releaseHold(id);
      }
      rethrow;
    }
  }

  void release() {
    for (final id in _ids) {
      _engine.releaseHold(id);
    }
    _ids.clear();
  }
}
