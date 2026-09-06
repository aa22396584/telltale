library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../obd/pid/pid.dart';
import '../../../state/telemetry_trends.dart';

/// Why a selection was not applied, or null when it was.
///
/// Takes an [AppLocalizations] rather than a [BuildContext]: the outcome is
/// decided in a notifier and reported after an await, and a pure-Dart test can
/// walk every outcome in both languages with no widget pump.
String? telemetryTrendSelectionOutcomeLabel(
  AppLocalizations l10n,
  TelemetryTrendSelectionOutcome outcome,
) => switch (outcome) {
  TelemetryTrendSelectionOutcome.tooMany => l10n.trendTooManySelected(
    maximumTelemetryTrendLanes,
  ),
  TelemetryTrendSelectionOutcome.unavailable => l10n.trendSignalNoLongerActive,
  TelemetryTrendSelectionOutcome.storageFailure => l10n.trendSelectionSaveFailed,
  // Applied and no-change are not worth a message.
  TelemetryTrendSelectionOutcome.applied ||
  TelemetryTrendSelectionOutcome.noChange => null,
};

class TelemetryLaneSelector extends ConsumerWidget {
  const TelemetryLaneSelector({
    required this.activePids,
    required this.selectedIds,
    required this.enabled,
    required this.disabledReason,
    super.key,
  });

  final List<Pid> activePids;
  final List<String> selectedIds;
  final bool enabled;
  final String? disabledReason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final byId = {for (final pid in activePids) pid.id: pid};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: [
            for (final id in selectedIds)
              if (byId[id] case final pid?)
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: InputChip(
                    label: Text(_name(pid)),
                    avatar: Icon(
                      Icons.show_chart,
                      size: 18,
                      color: context
                          .gaugeColors(GaugeHue.forKey(pid.id))
                          .bright,
                    ),
                    onDeleted: enabled
                        ? () => unawaited(_remove(context, ref, id))
                        : null,
                    deleteButtonTooltipMessage: l10n.trendRemoveSignal(
                      _name(pid),
                    ),
                  ),
                ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: ActionChip(
                key: const ValueKey('telemetry-lane-selector'),
                avatar: const Icon(Icons.tune, size: 18),
                label: Text(l10n.trendChooseSignals),
                onPressed: enabled && activePids.isNotEmpty
                    ? () => _showSelector(context, ref)
                    : null,
              ),
            ),
          ],
        ),
        if (!enabled && disabledReason != null) ...[
          const SizedBox(height: Spacing.sm),
          Text(
            disabledReason!,
            style: context.texts.bodySmall?.copyWith(
              color: context.palette.warning,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, String id) async {
    final l10n = AppLocalizations.of(context);
    final next = selectedIds.where((candidate) => candidate != id).toList();
    final outcome = await ref
        .read(telemetryTrendsProvider.notifier)
        .setSelectedIds(next);
    if (!context.mounted) return;
    _showOutcome(context, l10n, outcome);
  }

  Future<void> _showSelector(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final initial = selectedIds.toSet();
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TelemetryLaneSheet(
        activePids: activePids,
        initialSelection: initial,
      ),
    );
    if (result == null || !context.mounted) return;
    final outcome = await ref
        .read(telemetryTrendsProvider.notifier)
        .setSelectedIds(result);
    if (!context.mounted) return;
    _showOutcome(context, l10n, outcome);
  }

  static void _showOutcome(
    BuildContext context,
    AppLocalizations l10n,
    TelemetryTrendSelectionOutcome outcome,
  ) {
    final message = telemetryTrendSelectionOutcomeLabel(l10n, outcome);
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  static String _name(Pid pid) =>
      pid.shortName.isEmpty ? pid.name : pid.shortName;
}

class _TelemetryLaneSheet extends StatefulWidget {
  const _TelemetryLaneSheet({
    required this.activePids,
    required this.initialSelection,
  });

  final List<Pid> activePids;
  final Set<String> initialSelection;

  @override
  State<_TelemetryLaneSheet> createState() => _TelemetryLaneSheetState();
}

class _TelemetryLaneSheetState extends State<_TelemetryLaneSheet> {
  late final Set<String> _selected = {...widget.initialSelection};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        maxChildSize: 0.94,
        builder: (context, controller) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.sm,
                Spacing.lg,
                Spacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.trendSignalsHeading,
                    style: context.texts.headlineSmall,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    l10n.trendSheetBody(maximumTelemetryTrendLanes),
                    style: context.texts.bodySmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: widget.activePids.length,
                itemBuilder: (context, index) {
                  final pid = widget.activePids[index];
                  final selected = _selected.contains(pid.id);
                  return CheckboxListTile(
                    value: selected,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      pid.shortName.isEmpty ? pid.name : pid.shortName,
                    ),
                    subtitle: Text(
                      pid.units.isEmpty
                          ? pid.modeAndPid
                          : '${pid.modeAndPid} · ${pid.units}',
                    ),
                    onChanged: (value) {
                      if (value == true &&
                          _selected.length >= maximumTelemetryTrendLanes) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.trendTooManySelected(
                                maximumTelemetryTrendLanes,
                              ),
                            ),
                          ),
                        );
                        return;
                      }
                      setState(() {
                        if (value == true) {
                          _selected.add(pid.id);
                        } else {
                          _selected.remove(pid.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(
                  widget.activePids
                      .where((pid) => _selected.contains(pid.id))
                      .map((pid) => pid.id)
                      .toList(),
                ),
                child: Text(
                  l10n.trendSheetDone(
                    _selected.length,
                    maximumTelemetryTrendLanes,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
