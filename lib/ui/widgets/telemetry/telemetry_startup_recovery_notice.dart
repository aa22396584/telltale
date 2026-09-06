library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../state/telemetry_sessions.dart';
import '../../../telemetry/session/telemetry_session_store.dart';
import '../../screens/telemetry/telemetry_sessions_screen.dart';
import '../panel.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Reports durable startup recovery without implying that damaged data was
/// repaired or that a physical vehicle was involved.
class TelemetryStartupRecoveryNotice extends ConsumerStatefulWidget {
  const TelemetryStartupRecoveryNotice({super.key});

  @override
  ConsumerState<TelemetryStartupRecoveryNotice> createState() =>
      _TelemetryStartupRecoveryNoticeState();
}

class _TelemetryStartupRecoveryNoticeState
    extends ConsumerState<TelemetryStartupRecoveryNotice> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final recovery = ref.watch(telemetryStartupRecoveryProvider);
    if (_dismissed ||
        recovery.phase != TelemetryStartupRecoveryPhase.ready ||
        recovery.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final installed = recovery.items.where((item) {
      return item.outcome == TelemetryRecoveryOutcome.recoveredAndInstalled ||
          item.outcome == TelemetryRecoveryOutcome.installedUnchanged;
    }).length;
    final cleaned = recovery.items
        .where(
          (item) => item.outcome == TelemetryRecoveryOutcome.deletedZeroValue,
        )
        .length;
    final damaged = recovery.items.where((item) {
      return item.outcome == TelemetryRecoveryOutcome.corruptDeleteOnly ||
          item.outcome == TelemetryRecoveryOutcome.collisionDeleteOnly;
    }).length;
    final hasHistory = installed + damaged > 0;
    final access = ref.watch(telemetryHistoryAccessProvider);
    final mayOpen = hasHistory && access == TelemetryHistoryAccess.permitted;
    final details = <String>[
      if (installed > 0) l10n.telemetryRecoveryInstalled(installed),
      if (cleaned > 0) l10n.telemetryRecoveryCleaned(cleaned),
      if (damaged > 0) l10n.telemetryRecoveryDamaged(damaged),
    ];
    // Folded rather than joined on a literal: the sentence separator is
    // punctuation, and Chinese ends a sentence with 。 rather than a period.
    final summary = details.isEmpty
        ? ''
        : details.reduce(l10n.telemetrySentenceJoin);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.lg),
      child: Panel(
        accent: damaged > 0 ? context.palette.warning : context.palette.success,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  damaged > 0
                      ? Icons.warning_amber_rounded
                      : Icons.restore_outlined,
                  color: damaged > 0
                      ? context.palette.warning
                      : context.palette.success,
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.telemetryRecoveryTitle,
                        style: context.texts.titleMedium,
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(summary, style: context.texts.bodySmall),
                      if (damaged > 0) ...[
                        const SizedBox(height: Spacing.xs),
                        Text(
                          l10n.telemetryRecoveryDamagedNote,
                          style: context.texts.bodySmall,
                        ),
                      ],
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
                if (hasHistory)
                  OutlinedButton.icon(
                    key: const ValueKey('telemetry-recovery-open-history'),
                    onPressed: mayOpen
                        ? () => context.push(TelemetrySessionsScreen.path)
                        : null,
                    icon: const Icon(Icons.history, size: 18),
                    label: Text(l10n.telemetryOpenHistory),
                  ),
                TextButton(
                  key: const ValueKey('telemetry-recovery-dismiss'),
                  onPressed: () => setState(() => _dismissed = true),
                  child: Text(l10n.telemetryDismissNotice),
                ),
              ],
            ),
            if (hasHistory && !mayOpen) ...[
              const SizedBox(height: Spacing.xs),
              Text(
                access.message(l10n)!,
                style: context.texts.bodySmall?.copyWith(
                  color: context.palette.warning,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
