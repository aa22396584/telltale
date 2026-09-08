/// Shared acquisition demand: several owners can want the same wire request.
///
/// Dashboard gauges, a recording session, a trip logger and an alert can all
/// ask for `7E0:010C` at once. The adapter still has one command slot. This
/// registry unions those leases by wire identity (header + mode+PID) and
/// drops a request only when the last owner releases it.
///
/// Decoded-channel identity stays beside the wire key: two formulas on the
/// same PID are one request and two channels. The same PID on two headers is
/// two requests. Exclusive diagnostic work is not registered here — it keeps
/// its single command owner in the session.
library;

import 'pid/priority_tier.dart';

/// Who is asking for a channel to be acquired.
enum DemandOwner { dashboard, recording, trip, alert }

/// One owner's lease on one decoded channel.
class TelemetryDemand {
  const TelemetryDemand({
    required this.owner,
    required this.leaseId,
    required this.header,
    required this.modeAndPid,
    required this.requestedPeriod,
    required this.priority,
    this.definitionId,
  });

  final DemandOwner owner;

  /// Unique among live leases. Releasing this id must not touch another
  /// owner's hold on the same wire request.
  final String leaseId;

  final String header;
  final String modeAndPid;
  final Duration requestedPeriod;
  final PriorityTier priority;

  /// Decoded-channel identity, when several formulas share one raw response.
  final String? definitionId;

  /// Wire-request identity. Not [definitionId].
  String get wireKey =>
      '${header.trim().toUpperCase()}:${modeAndPid.trim().toUpperCase()}';
}

/// The union of live leases, keyed for the scheduler as unique wire requests.
class DemandRegistry {
  final Map<String, TelemetryDemand> _byLease = {};

  void acquire(TelemetryDemand demand) {
    _byLease[demand.leaseId] = demand;
  }

  void release(String leaseId) {
    _byLease.remove(leaseId);
  }

  Iterable<TelemetryDemand> get leases => _byLease.values;

  /// One entry per wire identity. Period is the tightest requested; priority
  /// is the highest held. Starvation of a slower owner is the point of the
  /// union: the adapter is asked once.
  List<TelemetryDemand> uniqueWireRequests() {
    final grouped = <String, List<TelemetryDemand>>{};
    for (final demand in _byLease.values) {
      grouped.putIfAbsent(demand.wireKey, () => []).add(demand);
    }
    final out = <TelemetryDemand>[];
    for (final group in grouped.values) {
      var tightest = group.first;
      for (final demand in group.skip(1)) {
        if (demand.requestedPeriod < tightest.requestedPeriod) {
          tightest = demand;
        } else if (demand.requestedPeriod == tightest.requestedPeriod &&
            demand.priority.index > tightest.priority.index) {
          tightest = demand;
        }
      }
      out.add(tightest);
    }
    return out;
  }
}
