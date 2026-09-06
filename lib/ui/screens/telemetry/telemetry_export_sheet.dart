library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../state/telemetry_sessions.dart';
import '../../../l10n/generated/app_localizations.dart';

Future<TelemetryExportFormat?> showTelemetryExportSheet(BuildContext context) =>
    showModalBottomSheet<TelemetryExportFormat>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const TelemetryExportSheet(),
    );

class TelemetryExportSheet extends StatelessWidget {
  const TelemetryExportSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        primary: false,
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.telemetryExportSheetTitle,
              style: context.texts.titleLarge,
            ),
            const SizedBox(height: Spacing.md),
            Text(l10n.telemetryExportDisclosure),
            const SizedBox(height: Spacing.lg),
            Wrap(
              spacing: Spacing.md,
              runSpacing: Spacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pop(context, TelemetryExportFormat.csv),
                  icon: const Icon(Icons.table_chart_outlined),
                  label: Text(l10n.telemetryExportCsv),
                ),
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.pop(context, TelemetryExportFormat.json),
                  icon: const Icon(Icons.data_object),
                  label: Text(l10n.telemetryExportJson),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
