library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../state/obd_session.dart';
import '../../../state/pid_registry.dart';
import '../../../state/telemetry_recorder.dart';
import '../../../state/telemetry_runtime.dart';
import '../../../state/telemetry_trends.dart';
import '../../../telemetry/session/telemetry_recorder.dart';
import '../../../telemetry/session/telemetry_session.dart';
import '../../widgets/panel.dart';
import '../../widgets/telemetry/live_trend_card.dart';
import '../../widgets/telemetry/telemetry_lane_selector.dart';
import '../../../l10n/generated/app_localizations.dart';

/// What the recorder is doing, for the trend cards' semantics labels.
///
/// Takes an [AppLocalizations] rather than a [BuildContext] so a pure-Dart
/// test can walk every phase in both languages without a widget pump.
String telemetryRecorderPhaseLabel(
  AppLocalizations l10n,
  TelemetryRecorderPhase phase,
) => switch (phase) {
  TelemetryRecorderPhase.preparing => l10n.telemetryRecorderPhasePreparing,
  TelemetryRecorderPhase.recording => l10n.telemetryRecorderPhaseRecording,
  TelemetryRecorderPhase.finalizing => l10n.telemetryRecorderPhaseFinalizing,
  // This label answers "is a recording running", which is what a screen
  // reader announcing a live trend card needs. Why one failed is the
  // recorder panel's job to say, at the size that question deserves.
  TelemetryRecorderPhase.idle ||
  TelemetryRecorderPhase.completed ||
  TelemetryRecorderPhase.failed => l10n.telemetryRecorderPhaseIdle,
};

class TelemetryWorkspace extends ConsumerWidget {
  const TelemetryWorkspace({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(obdSessionProvider);
    ref.watch(telemetryProvider);
    final activePids = ref.watch(activePidsProvider);
    final trends = ref.watch(telemetryTrendsProvider);
    final evidence = ref.watch(currentTelemetryConnectionEvidenceProvider);
    final progress = ref.watch(telemetryRecorderProgressProvider);
    final safety = ref
        .read(liveTelemetryStartEnvironmentProvider)
        .snapshot('trendSelector');
    final l10n = AppLocalizations.of(context);
    final laneSelectionBlock = _laneSelectionBlock(
      l10n,
      connected: evidence != null,
      speedKnown: safety.speedKnown,
      speedKmh: safety.speedKmh,
    );
    final recordingLabel = telemetryRecorderPhaseLabel(
      l10n,
      progress.state.phase,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (evidence == null) ...[
            StatusPill(
              label: l10n.telemetryNotConnected,
              icon: Icons.link_off,
              tone: StatusTone.neutral,
            ),
            const SizedBox(height: Spacing.md),
          ] else if (evidence.source == TelemetrySource.demo) ...[
            StatusPill(
              label: l10n.telemetryDemoData,
              icon: Icons.science_outlined,
              tone: StatusTone.accent,
            ),
            const SizedBox(height: Spacing.md),
          ] else if (evidence.source == TelemetrySource.simulatedRig) ...[
            StatusPill(
              label: l10n.telemetryRigData,
              icon: Icons.developer_board_outlined,
              tone: StatusTone.warn,
            ),
            const SizedBox(height: Spacing.md),
          ],
          SectionHeading(l10n.trendSignalsHeading),
          TelemetryLaneSelector(
            activePids: activePids,
            selectedIds: trends.selectedIds,
            enabled: laneSelectionBlock == null,
            disabledReason: laneSelectionBlock,
          ),
          const SizedBox(height: Spacing.lg),
          if (activePids.isEmpty)
            SizedBox(
              height: 300,
              child: EmptyState(
                icon: Icons.tune,
                title: l10n.trendNoSignalsTitle,
                message: l10n.trendNoSignalsBody,
              ),
            )
          else if (trends.selectedIds.isEmpty)
            SizedBox(
              height: 300,
              child: EmptyState(
                icon: Icons.show_chart,
                title: l10n.trendPickSignalsTitle,
                message: l10n.trendPickSignalsBody(maximumTelemetryTrendLanes),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final textScale =
                    MediaQuery.textScalerOf(context).scale(14) / 14;
                final twoColumns =
                    constraints.maxWidth >= 760 && textScale <= 1.3;
                final cardWidth = twoColumns
                    ? (constraints.maxWidth - Spacing.md) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: Spacing.md,
                  runSpacing: Spacing.md,
                  children: [
                    for (final id in trends.selectedIds)
                      if (trends.lanes[id] case final lane?)
                        SizedBox(
                          key: ValueKey('telemetry-lane-$id'),
                          width: cardWidth,
                          child: LiveTrendCard(
                            lane: lane,
                            windowEndElapsedUs: trends.windowEndElapsedUs,
                            recordingLabel: recordingLabel,
                            isConnected: evidence != null,
                          ),
                        ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  static String? _laneSelectionBlock(
    AppLocalizations l10n, {
    required bool connected,
    required bool speedKnown,
    required double speedKmh,
  }) {
    if (!connected) return null;
    if (!speedKnown || !speedKmh.isFinite) {
      return l10n.telemetryStartSpeedUnknown;
    }
    if (speedKmh > 5) return l10n.telemetryStartMoving;
    return null;
  }
}
