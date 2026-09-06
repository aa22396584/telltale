library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../state/obd_session.dart';
import '../../../state/pid_registry.dart';
import '../../../state/settings.dart';
import '../../../state/telemetry_recorder.dart';
import '../../../state/telemetry_runtime.dart';
import '../../../state/telemetry_sessions.dart';
import '../../../state/telemetry_trends.dart';
import '../../../telemetry/session/derived_estimates.dart';
import '../../../telemetry/session/telemetry_recorder.dart';
import '../../widgets/panel.dart';
import 'telemetry_status_copy.dart';
import '../../../l10n/generated/app_localizations.dart';

class TelemetryRecorderPanel extends ConsumerStatefulWidget {
  const TelemetryRecorderPanel({super.key});

  @override
  ConsumerState<TelemetryRecorderPanel> createState() =>
      _TelemetryRecorderPanelState();
}

class _TelemetryRecorderPanelState
    extends ConsumerState<TelemetryRecorderPanel> {
  bool _starting = false;
  bool _startNeedsRestart = false;

  @override
  Widget build(BuildContext context) {
    // These watches intentionally drive safety-copy refreshes. The environment
    // itself is a stable authority and reads these values synchronously.
    ref.watch(obdSessionProvider);
    ref.watch(telemetryProvider);
    final activePids = ref.watch(activePidsProvider);
    final evidence = ref.watch(currentTelemetryConnectionEvidenceProvider);
    final progress = ref.watch(telemetryRecorderProgressProvider);
    final environment = ref.read(liveTelemetryStartEnvironmentProvider);
    final safety = environment.snapshot('recorderPanel');
    final state = progress.state;
    final phase = state.phase;
    final l10n = AppLocalizations.of(context);
    final recoveryCopy = telemetryRecorderRecoveryLabel(
      l10n,
      state,
      startNeedsRestart: _startNeedsRestart,
    );
    final historyAccess = ref.watch(telemetryHistoryAccessProvider);
    final isTransition =
        phase == TelemetryRecorderPhase.preparing ||
        phase == TelemetryRecorderPhase.recording ||
        phase == TelemetryRecorderPhase.finalizing;
    final canOfferStart =
        !isTransition && !state.requiresRestart && !_startNeedsRestart;
    final blockReason = _startBlockReason(
      l10n,
      evidencePresent: evidence != null,
      foreground: safety.foreground,
      speedKnown: safety.speedKnown,
      speedKmh: safety.speedKmh,
      activeCount: activePids.length,
    );
    final canStart = canOfferStart && blockReason == null && !_starting;
    final accent = switch (phase) {
      TelemetryRecorderPhase.recording => context.palette.danger,
      TelemetryRecorderPhase.preparing ||
      TelemetryRecorderPhase.finalizing => context.palette.warning,
      TelemetryRecorderPhase.completed => context.palette.success,
      TelemetryRecorderPhase.failed => context.palette.danger,
      TelemetryRecorderPhase.idle => context.palette.accent,
    };

    return Panel(
      accent: accent,
      isActive: isTransition,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion:
                phase == TelemetryRecorderPhase.completed ||
                phase == TelemetryRecorderPhase.failed,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Spacing.md,
              runSpacing: Spacing.sm,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_phaseIcon(phase), size: 20, color: accent),
                    const SizedBox(width: Spacing.sm),
                    Flexible(
                      child: Text(
                        telemetryRecorderPhaseTitle(l10n, progress),
                        style: context.texts.titleMedium,
                      ),
                    ),
                  ],
                ),
                if (phase == TelemetryRecorderPhase.recording ||
                    phase == TelemetryRecorderPhase.finalizing)
                  Text(
                    formatTelemetryDuration(progress.elapsedUs),
                    style: AppTypography.readout(context.palette, 22),
                  ),
              ],
            ),
          ),
          if (phase == TelemetryRecorderPhase.recording ||
              phase == TelemetryRecorderPhase.finalizing ||
              phase == TelemetryRecorderPhase.completed ||
              phase == TelemetryRecorderPhase.failed) ...[
            const SizedBox(height: Spacing.md),
            _RecorderMetrics(
              l10n: l10n,
              valueCount: state.valueCount,
              statusCount: state.statusCount,
              gapCount: state.gapCount,
              bytesLabel: _bytesLabel(progress),
            ),
          ],
          if (state.terminalReason case final reason?) ...[
            const SizedBox(height: Spacing.md),
            Text(
              telemetryTerminalReasonLabel(l10n, reason),
              style: context.texts.bodyMedium,
            ),
          ],
          if (recoveryCopy != null) ...[
            const SizedBox(height: Spacing.md),
            Text(
              recoveryCopy,
              style: context.texts.bodyMedium?.copyWith(
                color: context.palette.danger,
              ),
            ),
          ],
          if ((phase == TelemetryRecorderPhase.completed ||
                  phase == TelemetryRecorderPhase.failed) &&
              !state.requiresRestart) ...[
            const SizedBox(height: Spacing.md),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('telemetry-open-history'),
                  onPressed: historyAccess == TelemetryHistoryAccess.permitted
                      ? () => context.push('/sessions')
                      : null,
                  icon: const Icon(Icons.history, size: 18),
                  label: Text(l10n.telemetryOpenHistory),
                ),
                TextButton(
                  key: const ValueKey('telemetry-dismiss-outcome'),
                  onPressed: () => ref
                      .read(telemetryRecorderControllerProvider)
                      .dismissTerminalOutcome(),
                  child: Text(l10n.telemetryDismissNotice),
                ),
              ],
            ),
            if (historyAccess != TelemetryHistoryAccess.permitted) ...[
              const SizedBox(height: Spacing.xs),
              Text(
                historyAccess.message(l10n)!,
                style: context.texts.bodySmall?.copyWith(
                  color: context.palette.warning,
                ),
              ),
            ],
          ],
          const SizedBox(height: Spacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline,
                size: 18,
                color: context.palette.textTertiary,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  l10n.telemetryRecorderDisclosure(
                    maximumTelemetryTrendLanes,
                    activePids.length,
                  ),
                  style: context.texts.bodySmall,
                ),
              ),
            ],
          ),
          if (phase == TelemetryRecorderPhase.idle || canOfferStart) ...[
            if (blockReason != null) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                blockReason,
                style: context.texts.bodySmall?.copyWith(
                  color: context.palette.warning,
                ),
              ),
            ],
            const SizedBox(height: Spacing.md),
            FilledButton.icon(
              key: const ValueKey('telemetry-start'),
              onPressed: canStart ? _start : null,
              icon: _starting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.fiber_manual_record, size: 18),
              label: Text(
                _starting
                    ? l10n.telemetryStarting
                    : l10n.telemetryStartRecordingButton,
              ),
            ),
          ] else if (phase == TelemetryRecorderPhase.recording) ...[
            const SizedBox(height: Spacing.md),
            FilledButton.icon(
              key: const ValueKey('telemetry-stop'),
              onPressed: () =>
                  ref.read(telemetryRecorderControllerProvider).stop(),
              style: FilledButton.styleFrom(
                backgroundColor: context.palette.danger,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.stop, size: 18),
              label: Text(l10n.telemetryStopAndSave),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _start() async {
    // Read before the await. The refusal describes the start the user asked
    // for, so it belongs to the language that was on screen when they asked.
    final l10n = AppLocalizations.of(context);
    final evidence = ref.read(currentTelemetryConnectionEvidenceProvider);
    if (evidence == null) return;
    setState(() {
      _starting = true;
      _startNeedsRestart = false;
    });
    final result = await ref
        .read(telemetryRecorderControllerProvider)
        .start(
          TelemetryStartRequest(
            source: evidence.source,
            transport: evidence.transport,
            protocol: evidence.protocol,
            activePids: ref.read(activePidsProvider),
            vehicleProfile: ref.read(vehicleProfileProvider),
          ),
        );
    if (!mounted) return;
    setState(() {
      _starting = false;
      _startNeedsRestart =
          result.outcome == TelemetryStartOutcome.restartRequired;
    });
    if (result.outcome != TelemetryStartOutcome.recording) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(telemetryStartOutcomeLabel(l10n, result.outcome)),
        ),
      );
    }
  }

  /// Why the start button is refused, or null when it is offered.
  ///
  /// Four of these sentences are also reached through
  /// [telemetryStartOutcomeLabel] after the recorder itself refuses. They are
  /// one ARB key each rather than one literal here and another there, because
  /// a pre-flight warning that disagrees with the refusal it predicts is worse
  /// than either sentence alone.
  static String? _startBlockReason(
    AppLocalizations l10n, {
    required bool evidencePresent,
    required bool foreground,
    required bool speedKnown,
    required double speedKmh,
    required int activeCount,
  }) {
    if (!evidencePresent) return l10n.telemetryStartNeedsConnection;
    if (!foreground) return l10n.telemetryStartNeedsForeground;
    if (!speedKnown || !speedKmh.isFinite) {
      return l10n.telemetryStartSpeedUnknown;
    }
    if (speedKmh > 5) return l10n.telemetryStartMoving;
    if (activeCount == 0) return l10n.telemetryStartNeedsActivePid;
    if (activeCount > DerivedEstimates.maxLiveSignals) {
      return l10n.telemetryStartTooManyPids;
    }
    return null;
  }

  static IconData _phaseIcon(TelemetryRecorderPhase phase) => switch (phase) {
    TelemetryRecorderPhase.idle => Icons.fiber_manual_record_outlined,
    TelemetryRecorderPhase.preparing => Icons.hourglass_top,
    TelemetryRecorderPhase.recording => Icons.fiber_manual_record,
    TelemetryRecorderPhase.finalizing => Icons.save_outlined,
    TelemetryRecorderPhase.completed => Icons.check_circle_outline,
    TelemetryRecorderPhase.failed => Icons.error_outline,
  };

  static String _bytesLabel(TelemetryRecorderProgress progress) {
    final used = formatTelemetryBytes(progress.bytesBeforeFooter);
    final limit = progress.effectiveSessionLimit;
    return limit == null ? used : '$used / ${formatTelemetryBytes(limit)}';
  }
}

/// The recorder phase, as a sentence.
///
/// Top-level and taking an [AppLocalizations] rather than a [BuildContext]:
/// the shell strip renders the same phases from a different widget, and a
/// pure-Dart test can walk all six of them in both languages without a pump.
String telemetryRecorderPhaseTitle(
  AppLocalizations l10n,
  TelemetryRecorderProgress progress,
) {
  final state = progress.state;
  return switch (state.phase) {
    TelemetryRecorderPhase.idle => l10n.telemetryRecorderPhaseIdle,
    TelemetryRecorderPhase.preparing => l10n.telemetryRecorderPhasePreparing,
    // Started, but nothing has landed yet. Not the same claim as `recording`,
    // where values are arriving, and not the same as `preparing`, where the
    // recorder has not begun.
    TelemetryRecorderPhase.recording =>
      state.valueCount == 0
          ? l10n.telemetryRecorderPhaseAwaitingValues
          : l10n.telemetryRecorderPhaseRecording,
    TelemetryRecorderPhase.finalizing => l10n.telemetryRecorderPhaseFinalizing,
    TelemetryRecorderPhase.completed => l10n.telemetryRecorderPhaseCompleted,
    TelemetryRecorderPhase.failed => l10n.telemetryRecorderPhaseFailed,
  };
}

class _RecorderMetrics extends StatelessWidget {
  const _RecorderMetrics({
    required this.l10n,
    required this.valueCount,
    required this.statusCount,
    required this.gapCount,
    required this.bytesLabel,
  });

  final AppLocalizations l10n;
  final int valueCount;
  final int statusCount;
  final int gapCount;
  final String bytesLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final singleColumn = constraints.maxWidth < 520 || scale > 1.3;
        final width = singleColumn
            ? constraints.maxWidth
            : (constraints.maxWidth - Spacing.sm) / 2;
        return Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: [
            SizedBox(
              width: width,
              child: _RecorderMetric(
                label: l10n.telemetryValueCount(valueCount),
                icon: Icons.data_usage,
                color: context.palette.accent,
              ),
            ),
            SizedBox(
              width: width,
              child: _RecorderMetric(
                label: l10n.telemetryStatusCount(statusCount),
                icon: Icons.info_outline,
                color: context.palette.textSecondary,
              ),
            ),
            SizedBox(
              width: width,
              child: _RecorderMetric(
                label: l10n.telemetryGapCount(gapCount),
                icon: Icons.link_off,
                color: gapCount == 0
                    ? context.palette.textSecondary
                    : context.palette.warning,
              ),
            ),
            SizedBox(
              width: width,
              child: _RecorderMetric(
                label: bytesLabel,
                icon: Icons.storage_outlined,
                color: context.palette.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecorderMetric extends StatelessWidget {
  const _RecorderMetric({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.palette.surfaceAlt,
        border: Border.all(color: context.palette.hairline),
        borderRadius: const BorderRadius.all(Radius.circular(Radii.sm)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: Spacing.sm),
          Expanded(child: Text(label, style: context.texts.labelMedium)),
        ],
      ),
    );
  }
}
