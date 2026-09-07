/// The live dashboard.
///
/// A responsive wall of dials plus a strip of figures the physics engine
/// derived. Column count follows available width rather than a device-class
/// guess, so a phone rotated into landscape on a windscreen mount gets the
/// wider layout automatically.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../diagnostics/availability.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../obd/physics/physics_engine.dart';
import '../../../obd/pid/pid.dart';
import '../../../obd/pid/pid_library.dart';
import '../../../obd/powertrain_battery/powertrain_battery_profile.dart';
import '../../../obd/telemetry.dart';
import '../../../obd/transport/obd_transport.dart';
import '../../../state/obd_session.dart';
import '../../../state/pid_registry.dart';
import '../../../state/settings.dart';
import '../../../state/telemetry_sessions.dart';
import '../../../state/vehicle_identity.dart';
import '../../../telemetry/session/derived_estimates.dart';
import '../../widgets/gauges/dial_gauge.dart';
import '../../widgets/panel.dart';
import '../../widgets/powertrain_profile_confirm_banner.dart';
import '../../widgets/status/datum_status_badge.dart';
import '../../widgets/status/datum_status_copy.dart';
import '../../widgets/telemetry/telemetry_recorder_panel.dart';
import '../pids/pid_manager_screen.dart';
import 'derived_source_copy.dart';
import 'telemetry_workspace.dart';

enum DashboardWorkspaceMode { gauges, trends }

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  static const String path = '/dashboard';
  static const String trendsPath = '/dashboard?workspace=trends';

  /// Tiles below this width stop being legible at arm's length.
  static const double _minTileWidth = 156;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DashboardWorkspaceMode _mode = DashboardWorkspaceMode.gauges;
  bool _routeModeApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.maybeOf(context);
    final wantsTrends =
        router
            ?.routerDelegate
            .currentConfiguration
            .uri
            .queryParameters['workspace'] ==
        'trends';
    if (wantsTrends &&
        (!_routeModeApplied || _mode != DashboardWorkspaceMode.trends)) {
      _mode = DashboardWorkspaceMode.trends;
    }
    _routeModeApplied = wantsTrends;
  }

  @override
  Widget build(BuildContext context) {
    final connection = ref.watch(obdSessionProvider);
    final activePids = ref.watch(activePidsProvider);
    final telemetry = ref.watch(telemetryProvider);
    final historyAccess = ref.watch(telemetryHistoryAccessProvider);
    final snapshot = telemetry.value ?? const TelemetrySnapshot();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _StatusStrip(connection: connection, snapshot: snapshot),
            ),
            const SliverToBoxAdapter(child: PowertrainProfileConfirmBanner()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  0,
                  Spacing.lg,
                  Spacing.md,
                ),
                child: _WorkspaceToolbar(
                  mode: _mode,
                  onModeChanged: (mode) => setState(() => _mode = mode),
                  historyAccess: historyAccess,
                  onHistory: historyAccess == TelemetryHistoryAccess.permitted
                      ? () => context.push('/sessions')
                      : null,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  Spacing.lg,
                  0,
                  Spacing.lg,
                  Spacing.lg,
                ),
                child: TelemetryRecorderPanel(),
              ),
            ),
            if (_mode == DashboardWorkspaceMode.trends)
              const SliverToBoxAdapter(child: TelemetryWorkspace())
            else if (activePids.isEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 320,
                  child: EmptyState(
                    icon: Icons.tune,
                    title: l10n.dashboardEmptyTitle,
                    message: l10n.dashboardEmptyBody,
                    action: FilledButton.icon(
                      onPressed: () => context.go(PidManagerScreen.path),
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(l10n.dashboardChoosePids),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  0,
                  Spacing.lg,
                  Spacing.md,
                ),
                sliver: _GaugeGrid(
                  pids: activePids,
                  snapshot: snapshot,
                  demo: connection.kind == TransportKind.demo,
                ),
              ),
            if (_mode == DashboardWorkspaceMode.gauges)
              SliverToBoxAdapter(child: _DerivedStrip(snapshot: snapshot)),
            // Clears the navigation bar so the derived figures can be scrolled
            // fully into view rather than sitting half-under it.
            SliverToBoxAdapter(
              child: SizedBox(
                height: Spacing.xl + MediaQuery.paddingOf(context).bottom,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceToolbar extends StatelessWidget {
  const _WorkspaceToolbar({
    required this.mode,
    required this.onModeChanged,
    required this.historyAccess,
    required this.onHistory,
  });

  final DashboardWorkspaceMode mode;
  final ValueChanged<DashboardWorkspaceMode> onModeChanged;
  final TelemetryHistoryAccess historyAccess;
  final VoidCallback? onHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final stack = constraints.maxWidth < 430 || scale > 1.35;
        final switcher = ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: SegmentedButton<DashboardWorkspaceMode>(
            key: const ValueKey('dashboard-workspace-switch'),
            segments: [
              ButtonSegment(
                value: DashboardWorkspaceMode.gauges,
                icon: const Icon(Icons.speed, size: 18),
                label: Text(l10n.dashboardWorkspaceGauges),
              ),
              ButtonSegment(
                value: DashboardWorkspaceMode.trends,
                icon: const Icon(Icons.show_chart, size: 18),
                label: Text(l10n.dashboardWorkspaceTrends),
              ),
            ],
            selected: {mode},
            expandedInsets: EdgeInsets.zero,
            showSelectedIcon: false,
            onSelectionChanged: (selection) => onModeChanged(selection.first),
          ),
        );
        final history = Column(
          crossAxisAlignment: stack
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              key: const ValueKey('telemetry-history'),
              onPressed: onHistory,
              icon: const Icon(Icons.history, size: 18),
              label: Text(l10n.dashboardLocalRecordings),
            ),
            if (historyAccess != TelemetryHistoryAccess.permitted) ...[
              const SizedBox(height: Spacing.xs),
              Text(
                historyAccess.message(l10n)!,
                key: const ValueKey('telemetry-history-blocked-copy'),
                style: context.texts.bodySmall,
                textAlign: stack ? TextAlign.start : TextAlign.end,
              ),
            ],
          ],
        );
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              switcher,
              const SizedBox(height: Spacing.sm),
              history,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: switcher),
            const SizedBox(width: Spacing.md),
            Expanded(child: history),
          ],
        );
      },
    );
  }
}

class _GaugeGrid extends StatelessWidget {
  const _GaugeGrid({
    required this.pids,
    required this.snapshot,
    this.demo = false,
  });

  final List<Pid> pids;
  final TelemetrySnapshot snapshot;
  final bool demo;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        // The dial's readout is sized from the tile, not from the text scale,
        // so honouring an accessibility setting means giving each tile more
        // room rather than growing type inside a fixed box. At 2x scale on a
        // narrow phone this correctly drops to a single column of large dials
        // instead of two cramped ones.
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final minWidth = DashboardScreen._minTileWidth * scale;
        final columns = math.max(1, (width / minWidth).floor());

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: Spacing.md,
            crossAxisSpacing: Spacing.md,
            // Square tiles: the dial is circular and its label and units live
            // inside the ring, so extra vertical room would only be padding.
            childAspectRatio: 1,
          ),
          delegate: SliverChildBuilderDelegate(childCount: pids.length, (
            context,
            index,
          ) {
            final pid = pids[index];
            final reading = snapshot[pid.id];
            final fault = snapshot.faults[pid.id];
            final stale = snapshot.isStale(pid);
            return _GaugeTile(
              pid: pid,
              reading: reading,
              fault: fault,
              isStale: stale,
              status: AvailabilityPolicy.forPid(
                pid: pid,
                reading: reading,
                fault: fault,
                isStale: stale,
                demo: demo,
                catalogStatus: switch (pid.evidenceKind) {
                  'community' => PowertrainProfileStatus.community,
                  'experimental' => PowertrainProfileStatus.experimental,
                  'ready' => PowertrainProfileStatus.ready,
                  _ => null,
                },
              ),
              delay: Duration(milliseconds: 28 * index),
            );
          }),
        );
      },
    );
  }
}

/// The fault line under a gauge.
///
/// These five sentences are the same five [TelemetryStatus] renders in the
/// trend cards, so they share the ARB keys rather than being written twice.
/// They had already drifted once — this switch said 標頭不符本車匯流排 while
/// telemetry_status_copy.dart said 標頭不符目前匯流排, one word apart, for the
/// same condition on the same screen.
String? _gaugeFootnote(
  AppLocalizations l10n,
  PidFault? fault,
  DatumStatus status,
) {
  final faultLabel = switch (fault) {
    PidFault.formulaError => l10n.telemetryStatusFormulaError,
    PidFault.busError => l10n.telemetryStatusBusError,
    PidFault.noAnswer => l10n.telemetryStatusNoAnswer,
    PidFault.headerNotOnThisBus => l10n.telemetryStatusHeaderMismatch,
    PidFault.refusedUnsafeService => l10n.telemetryStatusUnsafeServiceRefusal,
    PidFault.unsupported || null => null,
  };
  final badge = status.badges.isEmpty
      ? null
      : datumBadgeText(l10n, status);
  if (faultLabel != null && badge != null) return '$badge · $faultLabel';
  return faultLabel ?? badge;
}

class _GaugeTile extends StatelessWidget {
  const _GaugeTile({
    required this.pid,
    required this.reading,
    required this.fault,
    required this.isStale,
    required this.status,
    required this.delay,
  });

  final Pid pid;
  final Reading? reading;
  final PidFault? fault;
  final bool isStale;
  final DatumStatus status;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final hue = GaugeHue.forKey(pid.id);
    final accent = context.gaugeColors(hue).bright;
    final isUnsupported = fault == PidFault.unsupported;

    return _FadeInUp(
      delay: delay,
      child: Panel(
        accent: accent,
        padding: const EdgeInsets.all(Spacing.sm),
        child: isUnsupported
            ? _UnsupportedTile(pid: pid, status: status)
            : DialGauge(
                value: reading?.value,
                minValue: pid.minValue,
                maxValue: pid.maxValue,
                label: pid.shortName.isEmpty ? pid.name : pid.shortName,
                units: pid.units,
                hue: hue,
                redlineFrom: pid.redlineFrom,
                // A value older than its PID's own refresh target is not live,
                // however plausible it looks.
                isStale: isStale,
                footnote: _gaugeFootnote(
                  AppLocalizations.of(context),
                  fault,
                  status,
                ),
              ),
      ),
    );
  }
}

class _UnsupportedTile extends StatelessWidget {
  const _UnsupportedTile({required this.pid, required this.status});

  final Pid pid;
  final DatumStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppLocalizations.of(context);
    final badge = datumBadgeText(l10n, status);
    final unsupported = l10n.gaugeUnsupportedByVehicle;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, size: 22, color: palette.textTertiary),
            const SizedBox(height: Spacing.sm),
            Text(
              pid.shortName.isEmpty ? pid.name : pid.shortName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.titleSmall,
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              badge.isEmpty ? unsupported : '$badge · $unsupported',
              textAlign: TextAlign.center,
              style: context.texts.bodySmall?.copyWith(
                color: palette.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Connection identity, throughput and battery voltage.
class _StatusStrip extends ConsumerWidget {
  const _StatusStrip({required this.connection, required this.snapshot});

  final ObdConnectionState connection;
  final TelemetrySnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(vehicleIdentityProvider);
    final sessionStatus = AvailabilityPolicy.genericObdSession(
      identity: identity,
    );
    // Null means the adapter has not reported a plausible supply voltage, so
    // the pill is omitted rather than showing a number nobody measured.
    // No fallback to the handshake reading. Ageing the live value in the
    // client and then resurrecting the connect-time figure here defeats the
    // whole thing: an adapter that stops answering `ATRV` produced
    // `snapshot.batteryVoltage == null`, and the pill immediately substituted
    // 13.9 V from the handshake and held it indefinitely. `null` renders as
    // "--", which is what not knowing looks like.
    final voltage = snapshot.batteryVoltage;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.lg,
        Spacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LiveDot(active: connection.isConnected),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connection.deviceName.isEmpty
                          ? l10n.dashboardNotConnected
                          : connection.deviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.titleMedium,
                    ),
                    if (connection.protocol.isNotEmpty)
                      Text(
                        connection.protocol,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              StatusPill(
                label: identity.vin == null
                    ? l10n.dashboardGenericObd
                    : l10n.dashboardVinRead,
                tone: identity.vin == null
                    ? StatusTone.neutral
                    : StatusTone.good,
              ),
              // The chip reads the gap identifiers, not the exported sentence
              // in `sessionStatus.reason`. Missing identification never blocks
              // generic OBD, and none of these says the vehicle lacks a VIN —
              // only that this session did not read one.
              if (sessionStatus.gaps.isNotEmpty)
                StatusPill(
                  label: sessionStatus.gaps
                      .map((gap) => datumGapLabel(l10n, gap))
                      .join(' · '),
                  tone: StatusTone.warn,
                ),
              StatusPill(
                label: '${snapshot.pidsPerSecond.round()} PIDs/s',
                icon: Icons.bolt,
                tone: snapshot.pidsPerSecond > 0
                    ? StatusTone.accent
                    : StatusTone.neutral,
              ),
              // Only once something has actually been polled.
              //
              // `capturedAt` is not that. `PollingEngine.current` stamps it on
              // every heartbeat, including the 120 ms idle spin when no PID
              // is selected, so a session that had sent nothing announced
              // single-request mode after about a second. A poll leaves a
              // reading, a fault, or a non-zero PIDs/s; the heartbeat leaves
              // none of those.
              if (_snapshotHasBeenPolled(snapshot))
                PollingModePill(
                  schedulerAllowsGrouping: snapshot.fastModeEnabled,
                  busAllowsGrouping: ref.watch(busGroupsRequestsProvider),
                ),
              // Shown even when unknown. Hiding the pill would make "the
              // adapter stopped reporting voltage" look identical to "this
              // screen has no voltage pill", and the whole point of ageing the
              // value is that its absence should be visible.
              StatusPill(
                label: voltage == null
                    ? '-- V'
                    : '${voltage.toStringAsFixed(1)} V',
                icon: Icons.battery_charging_full,
                tone: voltage == null
                    ? StatusTone.warn
                    : (voltage < 11.8 ? StatusTone.bad : StatusTone.good),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// True when [snapshot] is from a polling cycle, not the idle heartbeat.
///
/// `PollingEngine.current` stamps `capturedAt` on every read. The loop that
/// finds `_active` empty delays 120 ms and never calls `_pollBatch`, so a
/// session with no PIDs selected still gets a non-null stamp after about a
/// second. A poll leaves a reading, a fault, or a non-zero PIDs/s.
bool _snapshotHasBeenPolled(TelemetrySnapshot snapshot) {
  if (snapshot.capturedAt == null) return false;
  // BUFFER FULL and a throwing first batch add no reading and no PIDs/s,
  // but they do withdraw grouping. That is the fallback the help describes.
  // The idle heartbeat leaves the flag at its default `true`.
  if (!snapshot.fastModeEnabled) return true;
  return snapshot.readings.isNotEmpty ||
      snapshot.faults.isNotEmpty ||
      snapshot.pidsPerSecond > 0;
}

/// The polling-mode pill, and the explanation behind it.
///
/// What the label may say is fixed by what the state proves, and the state has
/// two halves that have to agree.
///
/// [schedulerAllowsGrouping] is `TelemetrySnapshot.fastModeEnabled`, which is
/// permission the scheduler grants itself: `true` before any request goes out,
/// reset `true` by `PollingEngine.start` on every connection, and withdrawn
/// only by `PriorityScheduler.handleCorruptionEvent`. On its own it proves
/// nothing about the vehicle.
///
/// [busAllowsGrouping] is `PriorityScheduler.canBatch`, recomputed before
/// every command from the detected addressing and the verified support map.
/// On a non-CAN vehicle it is `false` for the whole session, and on CAN it is
/// `false` until a support block has answered. Reading the first half alone is
/// how this pill came to announce grouping in sessions where `popBatch` can
/// never group anything — review found exactly that.
///
/// So "Batching enabled" requires both, and it is still only permission:
/// `popBatch` also wants the member PID confirmed batchable and more than one
/// request queued, so "active", "batched" or "verified" remain claims this
/// state cannot make. When either half is down, every Mode 01 PID is read on
/// its own, which is what the fallback label says and what the code does.
///
/// **The fallback label covers three states and cannot tell them apart.** The
/// bus is not CAN and never will group; the bus is CAN but no support block
/// has answered yet, so `canBatch` is still false and grouping is held back on
/// purpose, because asking about PIDs the vehicle has not confirmed is what
/// makes a batch come back short; or grouping was withdrawn after a bad reply.
/// A driver sees one label for all three, and they are not equivalent — the
/// second resolves itself as discovery lands, the first never does. Two labels
/// cannot say that, so the explanation behind the pill enumerates all three
/// rather than the pill implying a single cause.
///
/// The one thing neither half stops is a powertrain profile response: those
/// PIDs share a single reply by construction, `popBatch` drains them as one
/// batch before it reads either flag, and `buildCommand` sends them as one
/// command in both modes. The copy says "Mode 01" for that reason.
///
/// Symbols rather than line numbers, because nothing in the suite holds a
/// `file:line` written in a comment to the line it names. Symbols are not free
/// either — review found `nextBatch` here, a method that has never existed —
/// so they are worth exactly what a `grep` for them is worth.
///
/// The whole pill is the button, and what it opens touches nothing else: no
/// provider is written and no command is queued. That is a statement about
/// what this code does, not about what it could do — the session, and through
/// it the transport, is reachable from this `context` like any other provider.
/// The guarantee is behavioural, and the zero-traffic test is what holds it.
class PollingModePill extends StatelessWidget {
  const PollingModePill({
    required this.schedulerAllowsGrouping,
    required this.busAllowsGrouping,
    super.key,
  });

  /// `TelemetrySnapshot.fastModeEnabled`, carried verbatim from the scheduler.
  final bool schedulerAllowsGrouping;

  /// `PriorityScheduler.canBatch`, read through `busGroupsRequestsProvider`.
  final bool busAllowsGrouping;

  static const Key pillKey = Key('dashboardPollingModePill');

  /// The minimum height a finger gets, in a car, over a bump.
  ///
  /// The decoration stays the size it was: this pads the interactive region
  /// out to the target, it does not inflate the pill. At large text the pill
  /// is already taller than this and the constraint stops mattering.
  ///
  /// Height only. A `minWidth` was here too and never bound: the label is a
  /// multi-word localized string, so the pill is several times the target wide
  /// in every geometry the suite renders, and the assertion that guarded it
  /// could not fail — pushing this constant down fired the height message at
  /// most of the geometries and the width message at none of them. A
  /// constraint that cannot bind and a check that cannot fail are both worse
  /// than their absence, because the next reader counts them as protection.
  ///
  /// Material's own constant rather than another bare `48` typed into this
  /// file, which several other controls in `lib/ui` still are. The test does
  /// not read this constant back — it types 48 itself, so shrinking the target
  /// here turns the geometry cases red instead of moving the goalposts with
  /// them.
  static const double minTapTarget = kMinInteractiveDimension;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final grouping = schedulerAllowsGrouping && busAllowsGrouping;
    final label = grouping
        ? l10n.dashboardBatchingEnabled
        : l10n.dashboardSingleRequestMode;
    // Merged rather than excluded: the InkWell contributes the focus and tap
    // semantics a keyboard user needs, and the pill contributes the state.
    // Excluding the subtree would have made the node read cleanly in a test
    // while dropping both.
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: l10n.dashboardPollingModeHelpAction,
        child: InkWell(
          key: pillKey,
          borderRadius: BorderRadius.circular(Radii.pill),
          onTap: () => showPollingModeHelp(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: minTapTarget),
            // Sizes to the pill, then the constraint above grows the box
            // around it rather than stretching it.
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: StatusPill(
                label: label,
                icon: grouping
                    ? Icons.fast_forward
                    : Icons.slow_motion_video,
                tone: grouping ? StatusTone.good : StatusTone.warn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What batching is, what the fallback means, and what the rate is not.
///
/// A dialog rather than a tooltip because three paragraphs have to survive
/// 200% text on a 320dp screen, and `AlertDialog`'s scroll view is what makes
/// that a scroll instead of an overflow.
Future<void> showPollingModeHelp(BuildContext context) {
  return showDialog<void>(
    context: context,
    // Read inside the builder, not captured outside it. A dialog that closed
    // over the localizations of the screen that opened it keeps speaking the
    // old language after the user changes it underneath.
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return AlertDialog(
        title: Text(l10n.dashboardPollingModeHelpTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.dashboardPollingModeHelpBatching),
              const SizedBox(height: Spacing.md),
              Text(l10n.dashboardPollingModeHelpSingle),
              const SizedBox(height: Spacing.md),
              Text(l10n.dashboardPollingModeHelpRate),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.datumStatusClose),
          ),
        ],
      );
    },
  );
}

class _LiveDot extends StatefulWidget {
  const _LiveDot({required this.active});

  final bool active;

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final colour = widget.active ? palette.success : palette.textTertiary;

    if (!widget.active) {
      return Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(shape: BoxShape.circle, color: colour),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return SizedBox(
          width: 18,
          height: 18,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 9 + 9 * t,
                  height: 9 + 9 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colour.withValues(alpha: 0.28 * (1 - t)),
                  ),
                ),
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colour,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Figures the physics engine computed rather than read off the bus. Marked in
/// the derived colour throughout so nobody mistakes an estimate for a sensor.
class _DerivedStrip extends ConsumerWidget {
  const _DerivedStrip({required this.snapshot});

  final TelemetrySnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final profile = ref.watch(vehicleProfileProvider);
    final demo = ref.watch(obdSessionProvider).kind == TransportKind.demo;
    final l10n = AppLocalizations.of(context);

    final rpm = snapshot.valueOf(PidLibrary.engineRpm);
    final speed = snapshot.valueOf(PidLibrary.vehicleSpeed);
    final maf = snapshot.valueOf(PidLibrary.mafRate);
    final map = snapshot.valueOf(PidLibrary.manifoldPressure);
    final iat = snapshot.valueOf(PidLibrary.intakeAirTemp);
    final measuredFuelRate = snapshot.valueOf(PidLibrary.engineFuelRate);

    // Horsepower needs road speed and acceleration. RPM is only for torque
    // (`P = τ·ω`); inventing a crank speed would fabricate N·m. Acceleration
    // used to arrive as a non-nullable 0 whenever it was unknown, which the
    // force terms consume as a real steady-cruise measurement — so a gap in
    // speed replies produced confident horsepower from a number nobody
    // measured.
    final accel = snapshot.accelerationMs2;
    final hasPowerInputs = speed != null && accel != null;
    DatumStatus measuredFuelStatus(double? value) =>
        AvailabilityPolicy.decodedValue(
          structurallyValid: true,
          value: value,
          min: PidLibrary.engineFuelRate.minValue,
          max: PidLibrary.engineFuelRate.maxValue,
          origin: demo ? DatumOrigin.demo : DatumOrigin.ecuReported,
          evidence: EvidenceKind.notTested,
        );

    if (!hasPowerInputs) {
      if (measuredFuelRate != null &&
          measuredFuelRate.isFinite &&
          measuredFuelRate >= 0) {
        return _MeasuredFuelStrip(
          fuelRateLPerHour: measuredFuelRate,
          speedKmh: speed,
          status: measuredFuelStatus(measuredFuelRate),
        );
      }
      final estimatedFuel = DerivedEstimates.valuesFor(
        snapshot: snapshot,
        profile: profile,
      )[DerivedEstimates.fuelRate.id];
      if (estimatedFuel != null) {
        final fuelStatus = AvailabilityPolicy.forEstimate(
          profile: profile,
          value: estimatedFuel,
          formula: AvailabilityPolicy.fuelEstimateFormula,
          kind: EstimateKind.fuel,
        );
        return _MeasuredFuelStrip(
          title: l10n.derivedEstimatedFuelTitle,
          fuelRateLPerHour: estimatedFuel,
          speedKmh: speed,
          status: fuelStatus,
        );
      }
      return const _DerivedUnavailable();
    }

    final metrics = PhysicsEngine.derive(
      profile: profile,
      rpm: rpm,
      speedKmh: speed,
      accelMs2: accel,
      mafSensorGps: maf,
      mapKpa: map,
      intakeTempC: iat,
      // The vehicle's own figure where it reports one: it accounts for the
      // mixture actually being run, where the stoichiometric estimate assumes
      // lambda 1 and is wrong by roughly lambda on anything that is not.
      fuelRateSensorLPerHour: measuredFuelRate,
    );

    // `--` rather than a number nobody measured.
    final consumption = metrics.isMoving
        ? metrics.litresPer100Km!.toStringAsFixed(1)
        : metrics.fuelRateLPerHour?.toStringAsFixed(1) ?? '--';
    final consumptionUnits = metrics.isMoving ? 'L/100km' : 'L/h';
    final hpStatus = AvailabilityPolicy.forEstimate(
      profile: profile,
      value: metrics.engineHorsepower,
      formula: AvailabilityPolicy.horsepowerFormula,
      kind: EstimateKind.horsepower,
    );
    final fuelStatus = metrics.fuelSource == FuelSource.measured
        ? measuredFuelStatus(metrics.fuelRateLPerHour)
        : AvailabilityPolicy.forEstimate(
            profile: profile,
            value: metrics.fuelRateLPerHour,
            formula: AvailabilityPolicy.fuelEstimateFormula,
            kind: EstimateKind.fuel,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Panel(
        accent: palette.derived,
        onTap: () => showDatumStatusDetails(
          context,
          title: l10n.derivedEstimatesDetailsTitle,
          status: hpStatus,
          extra: [if (fuelStatus.badges.isNotEmpty) fuelStatus],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reflows instead of squeezing, like the pills below it.
            //
            // The badge is a StatusPill, and a StatusPill's own Row does not
            // shrink: handing it a Flexible slice narrower than its content
            // overflows it visibly. That already happened in Chinese at 320dp,
            // and the longer English title widened the gap enough to do it at
            // 360dp too. Giving the badge its own line when the two do not fit
            // side by side costs one row of height and hides nothing.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Spacing.sm,
              runSpacing: Spacing.xs,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.functions, size: 15, color: palette.derived),
                    const SizedBox(width: Spacing.sm),
                    Text(
                      l10n.derivedEstimatesTitle,
                      style: context.texts.labelSmall?.copyWith(
                        color: palette.derived,
                      ),
                    ),
                  ],
                ),
                DatumStatusBadge(status: hpStatus),
              ],
            ),
            if (metrics.airflowSource != AirflowSource.unavailable ||
                fuelStatus.badges.isNotEmpty) ...[
              const SizedBox(height: Spacing.xs),
              Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.xs,
                children: [
                  if (metrics.airflowSource != AirflowSource.unavailable)
                    StatusPill(
                      label: metrics.fuelSource == FuelSource.measured
                          ? airflowSourceLabel(l10n, metrics.airflowSource)
                          : '${airflowSourceLabel(l10n, metrics.airflowSource)}'
                                ' · '
                                '${fuelSourceLabel(l10n, metrics.fuelSource)}',
                      tone: StatusTone.neutral,
                      dense: true,
                    ),
                  if (fuelStatus.badges.isNotEmpty)
                    DatumStatusBadge(status: fuelStatus),
                ],
              ),
            ],
            const SizedBox(height: Spacing.md),
            // Reflows instead of shrinking.
            //
            // Four cells in one row meant that at 320dp with 200% text scaling
            // the labels ellipsised and `FittedBox.scaleDown` shrank the
            // numbers — making telemetry smaller at precisely the moment the
            // user asked for it to be larger. The gauge grid above already
            // adapts by column count; this now follows the same policy.
            LayoutBuilder(
              builder: (context, constraints) {
                final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
                final cells = [
                  _DerivedCell(
                    label: l10n.derivedAirflow,
                    value:
                        metrics.mafGramsPerSecond?.toStringAsFixed(1) ?? '--',
                    units: 'g/s',
                  ),
                  _DerivedCell(
                    label: l10n.derivedFuelUse,
                    value: consumption,
                    units: consumptionUnits,
                  ),
                  _DerivedCell(
                    label: l10n.derivedEngineHorsepower,
                    value: metrics.engineHorsepower.isFinite
                        ? metrics.engineHorsepower.toStringAsFixed(0)
                        : '--',
                    units: 'hp',
                  ),
                  _DerivedCell(
                    label: l10n.derivedTorque,
                    value: rpm != null && metrics.torqueNm.isFinite
                        ? metrics.torqueNm.toStringAsFixed(0)
                        : '--',
                    units: 'N·m',
                  ),
                ];

                // Each cell needs roughly this much to render its label
                // without truncation at the current text size.
                final perCell = 88 * scale;
                final columns = (constraints.maxWidth / perCell).floor().clamp(
                  1,
                  4,
                );

                final rows = <Widget>[];
                for (var i = 0; i < cells.length; i += columns) {
                  final slice = cells.sublist(
                    i,
                    math.min(i + columns, cells.length),
                  );
                  rows.add(
                    Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : Spacing.md),
                      child: Row(
                        children: [
                          for (var j = 0; j < slice.length; j++)
                            slice[j].copyWith(isLast: j == slice.length - 1),
                          // Keeps a short final row aligned with the ones
                          // above rather than stretching its cells.
                          for (var j = slice.length; j < columns; j++)
                            const Expanded(child: SizedBox.shrink()),
                        ],
                      ),
                    ),
                  );
                }
                return Column(children: rows);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasuredFuelStrip extends StatelessWidget {
  const _MeasuredFuelStrip({
    required this.fuelRateLPerHour,
    required this.speedKmh,
    required this.status,
    this.title,
  });

  final double fuelRateLPerHour;
  final double? speedKmh;
  final DatumStatus status;

  /// Null means the ECU reported this rate itself. The estimated variant
  /// passes its own title, so a profile-derived figure can never inherit the
  /// heading that says the vehicle measured it.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppLocalizations.of(context);
    final heading = title ?? l10n.derivedEcuFuelTitle;
    final moving =
        fuelRateLPerHour > 0 &&
        speedKmh != null &&
        speedKmh! > PhysicsEngine.minSpeedForConsumption;
    final value = moving
        ? (fuelRateLPerHour / speedKmh! * 100).toStringAsFixed(1)
        : fuelRateLPerHour.toStringAsFixed(1);
    final units = moving ? 'L/100km' : 'L/h';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Panel(
        accent: palette.derived,
        onTap: () =>
            showDatumStatusDetails(context, title: heading, status: status),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Same reflow as the estimated strip's header, for the same
            // reason: 'Estimated fuel use' is wider than 估算油耗, and the
            // badge beside it does not shrink.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Spacing.sm,
              runSpacing: Spacing.xs,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_gas_station,
                      size: 15,
                      color: palette.derived,
                    ),
                    const SizedBox(width: Spacing.sm),
                    Text(
                      heading,
                      style: context.texts.labelSmall?.copyWith(
                        color: palette.derived,
                      ),
                    ),
                  ],
                ),
                if (status.badges.isNotEmpty)
                  DatumStatusBadge(status: status)
                else
                  StatusPill(
                    label: l10n.derivedEcuReported,
                    tone: StatusTone.neutral,
                    dense: true,
                  ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            Row(
              children: [
                _DerivedCell(
                  label: l10n.derivedFuelUse,
                  value: value,
                  units: units,
                  isLast: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DerivedCell extends StatelessWidget {
  const _DerivedCell({
    required this.label,
    required this.value,
    required this.units,
    this.isLast = false,
  });

  final String label;
  final String value;
  final String units;

  /// Suppresses the trailing divider. Which cell is last depends on how many
  /// columns the row ended up with, so it is decided at layout time.
  final bool isLast;

  _DerivedCell copyWith({required bool isLast}) =>
      _DerivedCell(label: label, value: value, units: units, isLast: isLast);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Expanded(
      child: Container(
        decoration: isLast
            ? null
            : BoxDecoration(
                border: Border(right: BorderSide(color: palette.hairline)),
              ),
        padding: EdgeInsets.only(right: isLast ? 0 : Spacing.sm),
        margin: EdgeInsets.only(right: isLast ? 0 : Spacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.labelSmall,
            ),
            const SizedBox(height: Spacing.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value, style: AppTypography.readout(palette, 20)),
                  const SizedBox(width: 3),
                  Text(
                    units,
                    style: context.texts.labelSmall?.copyWith(
                      color: palette.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One-shot entrance: fade plus a short rise, staggered by [delay].
class _FadeInUp extends StatefulWidget {
  const _FadeInUp({required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  State<_FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<_FadeInUp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.slow,
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Motion.emphasised,
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - curved.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Stands in for the derived-metrics strip when its inputs are not available.
///
/// Deliberately a distinct state rather than a row of zeroes: "we cannot work
/// this out yet" and "your engine is producing no power" look identical when
/// both render as 0 hp.
class _DerivedUnavailable extends StatelessWidget {
  const _DerivedUnavailable();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final message = AppLocalizations.of(context).derivedUnavailableMessage;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Panel(
        child: Row(
          children: [
            Icon(Icons.functions, size: 15, color: palette.textTertiary),
            const SizedBox(width: Spacing.sm),
            Expanded(child: Text(message, style: context.texts.bodySmall)),
          ],
        ),
      ),
    );
  }
}
