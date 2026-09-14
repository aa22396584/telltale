/// Modal bottom sheet displaying detailed technical and safety specifications of a service recipe.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../diagnostics/service_recipes/active_test_profile.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../widgets/panel.dart';

/// Shows the detailed specification sheet for an [ActiveTestProfile].
Future<void> showServiceRecipeDetailSheet({
  required BuildContext context,
  required ActiveTestProfile profile,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ServiceRecipeDetailSheet(profile: profile),
    );

class ServiceRecipeDetailSheet extends StatelessWidget {
  const ServiceRecipeDetailSheet({
    required this.profile,
    super.key,
  });

  final ActiveTestProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;

    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(Spacing.lg),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    profile.profileId,
                    style: context.texts.headlineSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.serviceRecipesClose,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              l10n.serviceRecipesStandard(profile.standard),
              style: context.texts.titleSmall?.copyWith(color: palette.accent),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              profile.documentSection,
              style: context.texts.bodyMedium?.copyWith(
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: Spacing.md),

            // ECU Target & Addressing info
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.serviceRecipesEcuHeader(
                      profile.addressing.targetEcuHeader,
                    ),
                    style: context.texts.titleSmall,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    '${profile.applicability.make} ${profile.applicability.model} (${profile.applicability.targetEcuName})',
                    style: context.texts.bodySmall,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    'Session: ${profile.sessionType.name} | Bus: ${profile.addressing.busType.name}',
                    style: context.texts.bodySmall?.copyWith(
                      color: palette.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.md),

            // Preconditions
            SectionHeading(l10n.serviceRecipesPreconditions),
            Panel(
              child: profile.preconditions.isEmpty
                  ? Text(l10n.serviceRecipesNoPreconditions, style: context.texts.bodySmall)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final pre in profile.preconditions)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: Spacing.xs,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                  color: palette.accent,
                                ),
                                const SizedBox(width: Spacing.sm),
                                Expanded(
                                  child: Text(
                                    '${pre.parameterName}: ${pre.minValue} .. ${pre.maxValue} (max age: ${pre.maxAgeMs}ms)',
                                    style: context.texts.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: Spacing.md),

            // Recovery
            SectionHeading(l10n.serviceRecipesRecovery),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.recovery.releaseCommandDescription,
                    style: context.texts.bodyMedium,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    profile.recovery.lossOfClientBehavior,
                    style: context.texts.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    'Watchdog Timeout: ${profile.recovery.watchdogTimeoutMs} ms',
                    style: context.texts.bodySmall?.copyWith(
                      color: palette.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.md),

            // Canonical Hash & Provenance
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.serviceRecipesHash(profile.canonicalHash),
                    style: context.texts.bodySmall?.copyWith(
                      fontFamily: AppTypography.mono,
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    'Tier: ${profile.evidenceTier.name} | Rights: ${profile.redistributionRights.name}',
                    style: context.texts.bodySmall?.copyWith(
                      color: palette.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.lg),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.serviceRecipesClose),
            ),
          ],
        ),
      ),
    );
  }
}
