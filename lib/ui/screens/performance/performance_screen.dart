/// Acceleration timing.
///
/// Times a run from a standing start to a target speed using OBD road speed.
/// The timer arms itself when the car is stationary and starts on first
/// movement, because a driver cannot press a button and launch at once.
library;

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../obd/pid/pid_library.dart';
import '../../../obd/telemetry.dart';
import '../../../state/obd_session.dart';
import '../../widgets/gauges/dial_gauge.dart';
import '../../widgets/panel.dart';
import 'acceleration_run_controller.dart';

class PerformanceScreen extends ConsumerStatefulWidget {
  const PerformanceScreen({super.key});

  static const String path = '/performance';

  @override
  ConsumerState<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends ConsumerState<PerformanceScreen> {
  final AccelerationRunController _run = AccelerationRunController();

  /// A provider subscription rather than a raw stream one, so this screen
  /// shares the heartbeat that makes staleness observable.
  ProviderSubscription<AsyncValue<TelemetrySnapshot>>? _sub;

  AccelerationRunState get _state => _run.state;
  int get _target => _run.targetKmh;
  Duration? get _elapsed => _run.elapsed;
  double get _peakSpeed => _run.peakSpeed;
  Map<int, Duration> get _splits => _run.splits;
  List<FlSpot> get _trace => _run.trace;

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  void _arm() {
    setState(_run.arm);
    _sub?.close();
    // The heartbeat source, not the raw engine stream. Subscribing directly
    // meant that when snapshots simply stopped — no teardown, no event — this
    // screen received no clock tick with which to notice, and a run could stay
    // in `running` indefinitely against a signal that had gone.
    _sub = ref.listenManual(telemetryProvider, (_, next) {
      final snapshot = next.value;
      if (snapshot != null) _onSample(snapshot);
    });
  }

  void _onSample(TelemetrySnapshot snapshot) {
    if (!mounted) return;
    final before = _run.state;
    final reading = snapshot[PidLibrary.vehicleSpeed.id];
    if (reading == null) {
      _run.ingestAbsence(nowElapsed: snapshot.elapsedNow?.call());
    } else if (snapshot.isStale(PidLibrary.vehicleSpeed)) {
      _run.ingestStale();
    } else {
      _run.ingestSpeed(
        kmh: reading.value,
        receivedElapsed: reading.receivedElapsed,
      );
    }
    final after = _run.state;
    if (after == AccelerationRunState.finished ||
        after == AccelerationRunState.aborted) {
      _sub?.close();
      _sub = null;
    }
    if (before != after || after == AccelerationRunState.running) {
      setState(() {});
    }
  }

  void _reset() {
    _sub?.close();
    setState(_run.reset);
  }

  /// One decimal, because that is what the sampling supports.
  ///
  /// The clock starts and stops on speed *samples*, which arrive around ten
  /// times a second on a good link — so the elapsed figure is only ever
  /// accurate to roughly a tenth. Printing hundredths implied a precision of
  /// about five milliseconds that nothing here measures, and a 0-100 time is
  /// exactly the number someone will quote or compare.
  String _format(Duration? d) =>
      d == null ? '--.-' : (d.inMilliseconds / 1000).toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final connected = ref.watch(obdSessionProvider).isConnected;
    final snapshot = ref.watch(telemetryProvider).value ?? const TelemetrySnapshot();
    // Nullable on purpose. Coercing an absent speed to zero told the user the
    // car was stationary and let them arm a run with no valid speed stream
    // behind it — the timer would then never start, or start on the first
    // number that happened to arrive.
    final speed = snapshot.valueOf(PidLibrary.vehicleSpeed);
    final hasSpeed = speed != null;

    if (!connected) {
      return Scaffold(
        body: SafeArea(
          child: EmptyState(
            icon: Icons.link_off,
            title: l10n.performanceNotConnectedTitle,
            message: l10n.performanceNotConnectedBody,
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.md,
            Spacing.lg,
            Spacing.xxl,
          ),
          children: [
            Text(l10n.performanceHeadline, style: context.texts.headlineMedium),
            // Says what the number is before the number appears: one timed run
            // that begins at rest. Nothing on this screen is a rated figure.
            Text(l10n.performanceSubhead, style: context.texts.bodySmall),
            const SizedBox(height: Spacing.xl),

            Center(
              child: SizedBox(
                width: 230,
                height: 230,
                child: DialGauge(
                  value: speed,
                  minValue: 0,
                  // The needle pins at the top of the scale while the readout
                  // keeps climbing unless the scale can hold the whole run.
                  maxValue: math.max(_target.toDouble() * 1.3, 260),
                  label: l10n.performanceSpeedGaugeLabel,
                  units: 'km/h',
                  hue: GaugeHue.blue,
                  isStale: !hasSpeed,
                ),
              ),
            ),
            const SizedBox(height: Spacing.xl),

            Panel(
              accent: switch (_state) {
                AccelerationRunState.running => palette.warning,
                AccelerationRunState.finished => palette.success,
                AccelerationRunState.aborted => palette.danger,
                _ => palette.accent,
              },
              isActive: _state != AccelerationRunState.idle,
              child: Column(
                children: [
                  Text(
                    switch (_state) {
                      AccelerationRunState.idle => l10n.performanceStateIdle,
                      // Two different sentences on purpose. A speed that reads
                      // above standstill is an observation; no speed at all is
                      // the app admitting it cannot tell, and a driver must be
                      // able to tell those apart from the panel alone.
                      AccelerationRunState.awaitingStandstill => hasSpeed
                          ? l10n.performanceStateAwaitingStandstill(
                              speed.toStringAsFixed(0),
                            )
                          : l10n.performanceStateAwaitingSpeedSignal,
                      AccelerationRunState.staged =>
                        l10n.performanceStateStaged,
                      AccelerationRunState.running =>
                        l10n.performanceStateRunning,
                      AccelerationRunState.finished =>
                        l10n.performanceStateFinished(_target),
                      AccelerationRunState.aborted =>
                        l10n.performanceStateAborted,
                    },
                    style: context.texts.labelSmall,
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    _format(_elapsed),
                    style: AppTypography.readout(palette, 56).copyWith(
                      color: switch (_state) {
                        AccelerationRunState.finished => palette.success,
                        AccelerationRunState.running => palette.warning,
                        AccelerationRunState.aborted => palette.danger,
                        _ => palette.textPrimary,
                      },
                    ),
                  ),
                  Text(
                    l10n.performanceSecondsUnit,
                    style: context.texts.labelMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.lg),

            SectionHeading(l10n.performanceTargetSpeedHeading),
            SegmentedButton<int>(
              segments: [
                for (final target in AccelerationRunController.splitTargetsKmh)
                  ButtonSegment(value: target, label: Text('$target')),
              ],
              selected: {_target},
              onSelectionChanged: _state == AccelerationRunState.running
                  ? null
                  : (s) => setState(() => _run.targetKmh = s.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: Spacing.lg),

            if (_trace.length > 1) ...[
              SectionHeading(l10n.performanceSpeedTraceHeading),
              Panel(
                child: SizedBox(
                  height: 170,
                  child: _SpeedTrace(spots: _trace, target: _target.toDouble()),
                ),
              ),
              const SizedBox(height: Spacing.lg),
            ],

            if (_splits.isNotEmpty) ...[
              SectionHeading(l10n.performanceSplitsHeading),
              Panel(
                child: Column(
                  children: [
                    for (final target
                        in AccelerationRunController.splitTargetsKmh)
                      if (_splits.containsKey(target))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                          child: Row(
                            children: [
                              Text('0 → $target km/h', style: context.texts.bodyMedium),
                              const Spacer(),
                              Text(
                                '${_format(_splits[target])} s',
                                style: AppTypography.readout(palette, 17),
                              ),
                            ],
                          ),
                        ),
                    Divider(color: palette.hairline),
                    Padding(
                      padding: const EdgeInsets.only(top: Spacing.sm),
                      child: Row(
                        children: [
                          Text(
                            l10n.performancePeakSpeed,
                            style: context.texts.bodyMedium,
                          ),
                          const Spacer(),
                          Text(
                            '${_peakSpeed.toStringAsFixed(0)} km/h',
                            style: AppTypography.readout(palette, 17),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.lg),
            ],

            if (_state == AccelerationRunState.idle) ...[
              FilledButton.icon(
                // Arming without a live speed stream produces a run that never
                // starts, or one that starts on whichever number arrives first.
                onPressed: hasSpeed ? _arm : null,
                icon: const Icon(Icons.play_arrow, size: 20),
                label: Text(l10n.performanceArm),
              ),
              if (!hasSpeed) ...[
                const SizedBox(height: Spacing.md),
                Text(
                  l10n.performanceNoSpeedSignal,
                  textAlign: TextAlign.center,
                  style: context.texts.bodySmall,
                ),
              ],
            ]
            else
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l10n.performanceReset),
              ),

            const SizedBox(height: Spacing.lg),
            // The hedge, not a footnote: this is a timed observation off one
            // speed signal, not a measurement of what the car can do.
            Text(l10n.performanceDisclaimer, style: context.texts.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Speed against time for the current run.
///
/// The shape is what makes a run readable: gear changes show as flat spots,
/// wheelspin as a step, and a bogged launch as a slow first second — none of
/// which the single elapsed number can tell you.
class _SpeedTrace extends StatelessWidget {
  const _SpeedTrace({required this.spots, required this.target});

  final List<FlSpot> spots;
  final double target;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final maxX = spots.last.x <= 0 ? 1.0 : spots.last.x;
    final maxY = target * 1.15;

    final labelStyle = context.texts.labelSmall?.copyWith(
      color: palette.textTertiary,
      fontFeatures: AppTypography.tabular,
    );

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: maxY / 3,
          getDrawingHorizontalLine: (_) => FlLine(
            color: palette.hairline,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: maxY / 3,
              getTitlesWidget: (value, _) => Text(
                value.round().toString(),
                style: labelStyle,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              // Roughly four labels regardless of run length, so a 4-second
              // sprint and a 20-second pull are equally readable.
              interval: (maxX / 4).clamp(0.5, 60),
              getTitlesWidget: (value, _) => Text(
                '${value.toStringAsFixed(value >= 10 ? 0 : 1)}s',
                style: labelStyle,
              ),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.2,
            preventCurveOverShooting: true,
            barWidth: 3,
            isStrokeCapRound: true,
            gradient: LinearGradient(
              colors: [
                context.gaugeColors(GaugeHue.blue).dim,
                context.gaugeColors(GaugeHue.blue).bright,
              ],
            ),
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.gaugeColors(GaugeHue.blue).bright.withValues(alpha: 0.28),
                  context.gaugeColors(GaugeHue.blue).bright.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: target,
              color: palette.success.withValues(alpha: 0.7),
              strokeWidth: 1.5,
              dashArray: const [6, 5],
            ),
          ],
        ),
        lineTouchData: const LineTouchData(enabled: false),
      ),
    );
  }
}
