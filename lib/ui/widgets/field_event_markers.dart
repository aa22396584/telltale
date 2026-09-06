import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/obd_session.dart';
import 'panel.dart';

typedef FieldEventRecorder = Future<FieldEventRecordResult> Function(
  FieldEventMarker marker,
);

/// The button caption for a marker.
///
/// Takes the localizations rather than a context because the enum lives in
/// `state/` and has no element in the tree. [FieldEventMarker.label] is
/// deliberately left alone: it is what `ObdSession` writes into the diagnostic
/// transcript, and an evidence file whose contents depend on the phone's UI
/// language is an evidence file two readers cannot compare.
String fieldEventMarkerLabel(AppLocalizations l10n, FieldEventMarker marker) =>
    switch (marker) {
      FieldEventMarker.ignitionOn => l10n.fieldEventIgnitionOn,
      FieldEventMarker.engineStarted => l10n.fieldEventEngineStarted,
      FieldEventMarker.throttleBlip => l10n.fieldEventThrottleBlip,
      FieldEventMarker.roadTestStarted => l10n.fieldEventRoadTestStarted,
    };

/// Four large, low-ambiguity markers for a passenger during a field session.
class FieldEventMarkerPanel extends StatefulWidget {
  const FieldEventMarkerPanel({
    super.key,
    required this.enabled,
    required this.onRecord,
  });

  final bool enabled;
  final FieldEventRecorder onRecord;

  @override
  State<FieldEventMarkerPanel> createState() => _FieldEventMarkerPanelState();
}

class _FieldEventMarkerPanelState extends State<FieldEventMarkerPanel> {
  bool _saving = false;

  Future<void> _record(FieldEventMarker marker) async {
    if (!widget.enabled || _saving) return;
    // Read before the await, not after: the outcome belongs to the language
    // that was on screen when the passenger pressed the button, and reading a
    // context across an await is what `use_build_context_synchronously` is
    // about.
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    final result = await widget.onRecord(marker);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (result) {
          FieldEventRecordResult.persisted => l10n.fieldEventRecorded(
            fieldEventMarkerLabel(l10n, marker),
          ),
          // Two different failures, two different sentences. "In memory only"
          // is not "saved", and the remedy is immediate.
          FieldEventRecordResult.memoryOnly => l10n.fieldEventMemoryOnly,
          FieldEventRecordResult.unavailable => l10n.fieldEventUnavailable,
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final enabled = widget.enabled && !_saving;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.fieldEventHeading, style: context.texts.titleSmall),
          const SizedBox(height: Spacing.xs),
          Text(l10n.fieldEventBody, style: context.texts.bodySmall),
          const SizedBox(height: Spacing.sm),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              for (final marker in FieldEventMarker.values)
                FilledButton.tonal(
                  onPressed: enabled ? () => _record(marker) : null,
                  child: Text(fieldEventMarkerLabel(l10n, marker)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
