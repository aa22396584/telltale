/// Short per-value USABILITY-R2 badge. Status follows the datum.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../diagnostics/availability.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../panel.dart';
import 'datum_status_copy.dart';

class DatumStatusBadge extends StatelessWidget {
  const DatumStatusBadge({required this.status, this.dense = true, super.key});

  final DatumStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (status.badges.isEmpty) return const SizedBox.shrink();
    final text = datumBadgeText(AppLocalizations.of(context), status);
    final tone = switch (status.quality) {
      DatumQuality.invalid => StatusTone.bad,
      DatumQuality.outOfReferenceRange => StatusTone.warn,
      DatumQuality.stale || DatumQuality.partial => StatusTone.warn,
      DatumQuality.tentativeDecode => StatusTone.neutral,
      DatumQuality.valid =>
        status.isEstimate
            ? StatusTone.accent
            : status.isFieldVerified
            ? StatusTone.good
            : StatusTone.neutral,
    };
    return StatusPill(label: text, tone: tone, dense: dense, softWrap: true);
  }
}

Future<void> showDatumStatusDetails(
  BuildContext context, {
  required String title,
  required DatumStatus status,
  List<DatumStatus> extra = const [],
}) {
  final items = [status, ...extra];
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < items.length; index++) ...[
                if (index > 0) const SizedBox(height: Spacing.lg),
                // Says only that nothing was flagged. Never "valid", "OK" or
                // "normal" — the datum has not been checked, it merely
                // carries no badge.
                Text(
                  items[index].badges.isEmpty
                      ? l10n.datumStatusFollowsData
                      : datumBadgeText(l10n, items[index]),
                ),
                if (datumReasonText(l10n, items[index]) != null) ...[
                  const SizedBox(height: Spacing.sm),
                  Text(datumReasonText(l10n, items[index])!),
                ],
                if (items[index].formula != null) ...[
                  const SizedBox(height: Spacing.md),
                  Text(
                    l10n.datumStatusFormula,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Text(items[index].formula!),
                ],
                if (items[index].assumptions != null) ...[
                  const SizedBox(height: Spacing.md),
                  Text(
                    l10n.datumStatusAssumptions,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Text(items[index].assumptions!),
                ],
                if (items[index].nextStep != null) ...[
                  const SizedBox(height: Spacing.md),
                  Text(datumNextStepLabel(l10n, items[index].nextStep!)),
                ],
              ],
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
