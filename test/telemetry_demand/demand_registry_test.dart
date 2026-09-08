/// #70.B leftover: union dashboard/recording demand by wire identity.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/pid/priority_tier.dart';
import 'package:torque_obd/obd/telemetry_demand.dart';

TelemetryDemand _demand({
  required DemandOwner owner,
  required String leaseId,
  String header = '7E0',
  String modeAndPid = '010C',
  Duration period = const Duration(milliseconds: 60),
  PriorityTier priority = PriorityTier.high,
  String? definitionId,
}) => TelemetryDemand(
  owner: owner,
  leaseId: leaseId,
  header: header,
  modeAndPid: modeAndPid,
  requestedPeriod: period,
  priority: priority,
  definitionId: definitionId,
);

void main() {
  test('two owners of the same PID share one wire request', () {
    final registry = DemandRegistry()
      ..acquire(_demand(owner: DemandOwner.dashboard, leaseId: 'dash-rpm'))
      ..acquire(
        _demand(
          owner: DemandOwner.recording,
          leaseId: 'rec-rpm',
          period: const Duration(milliseconds: 250),
          priority: PriorityTier.medium,
        ),
      );
    final wire = registry.uniqueWireRequests();
    expect(wire, hasLength(1));
    expect(wire.single.wireKey, '7E0:010C');
    expect(wire.single.requestedPeriod, const Duration(milliseconds: 60));
    expect(wire.single.priority, PriorityTier.high);
  });

  test('the same PID on two controllers is two wire requests', () {
    final registry = DemandRegistry()
      ..acquire(
        _demand(owner: DemandOwner.dashboard, leaseId: 'a', header: '7E0'),
      )
      ..acquire(
        _demand(owner: DemandOwner.dashboard, leaseId: 'b', header: '7E1'),
      );
    expect(registry.uniqueWireRequests().map((d) => d.wireKey).toSet(), {
      '7E0:010C',
      '7E1:010C',
    });
  });

  test('two formulas on one PID still share the wire request', () {
    final registry = DemandRegistry()
      ..acquire(
        _demand(
          owner: DemandOwner.dashboard,
          leaseId: 'raw',
          definitionId: 'rpm-raw',
        ),
      )
      ..acquire(
        _demand(
          owner: DemandOwner.dashboard,
          leaseId: 'scaled',
          definitionId: 'rpm-scaled',
        ),
      );
    expect(registry.uniqueWireRequests(), hasLength(1));
    expect(registry.leases.map((d) => d.definitionId).toSet(), {
      'rpm-raw',
      'rpm-scaled',
    });
  });

  test('releasing one owner leaves the other holding the request', () {
    final registry = DemandRegistry()
      ..acquire(_demand(owner: DemandOwner.dashboard, leaseId: 'dash'))
      ..acquire(_demand(owner: DemandOwner.recording, leaseId: 'rec'));
    registry.release('dash');
    expect(registry.uniqueWireRequests(), hasLength(1));
    expect(registry.uniqueWireRequests().single.leaseId, 'rec');
  });

  test('releasing the last owner drops the wire request', () {
    final registry = DemandRegistry()
      ..acquire(_demand(owner: DemandOwner.alert, leaseId: 'a'));
    registry.release('a');
    expect(registry.uniqueWireRequests(), isEmpty);
  });

  test('fastest period and highest priority are kept independently', () {
    final registry = DemandRegistry()
      ..acquire(
        _demand(
          owner: DemandOwner.dashboard,
          leaseId: 'fast-medium',
          period: const Duration(milliseconds: 60),
          priority: PriorityTier.medium,
        ),
      )
      ..acquire(
        _demand(
          owner: DemandOwner.recording,
          leaseId: 'slow-high',
          period: const Duration(milliseconds: 250),
          priority: PriorityTier.high,
        ),
      );
    final wire = registry.uniqueWireRequests().single;
    expect(wire.requestedPeriod, const Duration(milliseconds: 60));
    expect(wire.priority, PriorityTier.high);
  });

  test('internal spaces are not a second adapter address', () {
    final registry = DemandRegistry()
      ..acquire(
        _demand(owner: DemandOwner.dashboard, leaseId: 'a', header: '7E0'),
      )
      ..acquire(
        _demand(
          owner: DemandOwner.recording,
          leaseId: 'b',
          header: '7 E 0',
          modeAndPid: '01 0C',
        ),
      );
    expect(registry.uniqueWireRequests(), hasLength(1));
    expect(registry.uniqueWireRequests().single.wireKey, '7E0:010C');
  });
}
