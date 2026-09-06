library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../state/telemetry_recorder.dart';
import '../../../telemetry/session/telemetry_recorder.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import 'telemetry_status_copy.dart';
import '../../../l10n/generated/app_localizations.dart';

class TelemetryRecorderStrip extends ConsumerWidget {
  const TelemetryRecorderStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(telemetryRecorderProgressProvider);
    final state = progress.state;
    if (state.phase != TelemetryRecorderPhase.preparing &&
        state.phase != TelemetryRecorderPhase.recording &&
        state.phase != TelemetryRecorderPhase.finalizing) {
      return const SizedBox.shrink();
    }
    final palette = context.palette;
    final recording = state.phase == TelemetryRecorderPhase.recording;
    final finalizing = state.phase == TelemetryRecorderPhase.finalizing;
    final l10n = AppLocalizations.of(context);
    final recoveryCopy = telemetryRecorderRecoveryLabel(l10n, state);
    // The phase titles are the panel's, by key rather than by copy: a strip
    // that names the phase differently from the panel behind it would let one
    // of the two be wrong without anybody noticing.
    final title = recording
        ? state.valueCount == 0
              ? l10n.telemetryRecorderPhaseAwaitingValues
              : l10n.telemetryRecorderStripRecording(
                  formatTelemetryDuration(progress.elapsedUs),
                )
        : finalizing
        ? l10n.telemetryRecorderPhaseFinalizing
        : l10n.telemetryRecorderPhasePreparing;
    final detail =
        '${l10n.telemetryValueCount(state.valueCount)} · '
        '${l10n.telemetryStatusCount(state.statusCount)} · '
        '${l10n.telemetryGapCount(state.gapCount)}';
    // Folded rather than joined on a literal: the separator between phrases is
    // punctuation, and Chinese does not use the same mark English does.
    var semantics = title;
    for (final part in [detail, ?recoveryCopy]) {
      semantics = l10n.telemetryPhraseJoin(semantics, part);
    }

    return Material(
      color: Color.alphaBlend(
        (recording ? palette.danger : palette.warning).withValues(alpha: 0.1),
        palette.surface,
      ),
      child: Semantics(
        container: true,
        label: semantics,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: palette.hairline),
              bottom: BorderSide(color: palette.hairline),
            ),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Spacing.sm,
            runSpacing: Spacing.xs,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      recording
                          ? Icons.fiber_manual_record
                          : finalizing
                          ? Icons.save_outlined
                          : Icons.hourglass_top,
                      size: 18,
                      color: recording ? palette.danger : palette.warning,
                    ),
                    const SizedBox(width: Spacing.sm),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: context.texts.labelMedium),
                          Wrap(
                            spacing: Spacing.sm,
                            runSpacing: Spacing.xs,
                            children: [
                              Text(
                                l10n.telemetryValueCount(state.valueCount),
                                style: context.texts.labelMedium,
                              ),
                              Text(
                                l10n.telemetryStatusCount(state.statusCount),
                                style: context.texts.labelMedium,
                              ),
                              Text(
                                l10n.telemetryGapCount(state.gapCount),
                                style: context.texts.labelMedium,
                              ),
                            ],
                          ),
                          if (recoveryCopy != null)
                            Text(
                              recoveryCopy,
                              style: context.texts.labelMedium,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: Spacing.xs,
                runSpacing: Spacing.xs,
                children: [
                  TextButton(
                    key: const ValueKey('telemetry-return-to-trends'),
                    onPressed: () => context.go(DashboardScreen.trendsPath),
                    style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                    child: Text(l10n.telemetryReturnToTrends),
                  ),
                  if (recording)
                    FilledButton.icon(
                      key: const ValueKey('telemetry-shell-stop'),
                      onPressed: () =>
                          ref.read(telemetryRecorderControllerProvider).stop(),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        backgroundColor: palette.danger,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.stop, size: 18),
                      label: Text(l10n.telemetryStopAndSave),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
