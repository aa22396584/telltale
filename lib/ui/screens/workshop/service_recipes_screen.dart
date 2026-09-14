/// Workshop diagnostics screen exposing Mode 08 capability discovery and service recipes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../diagnostics/service_recipes/candidate_matrix.dart';
import '../../../diagnostics/service_recipes/mode08_discovery_service.dart';
import '../../../diagnostics/service_recipes/qualification_tier.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../state/obd_session.dart';
import '../../../state/service_recipes_provider.dart';
import '../../widgets/panel.dart';
import 'service_recipe_detail_sheet.dart';

class ServiceRecipesScreen extends ConsumerWidget {
  const ServiceRecipesScreen({super.key});

  static const String path = '/workshop/service-recipes';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final connection = ref.watch(obdSessionProvider);
    final matrixAsync = ref.watch(serviceRecipesMatrixProvider);
    final discoveryState = ref.watch(mode08DiscoveryStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.serviceRecipesTitle),
      ),
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
            Text(
              l10n.serviceRecipesSubtitle,
              style: context.texts.bodyMedium?.copyWith(
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: Spacing.lg),

            // Zero Live Candidates Safety Banner
            _SafetyBanner(
              title: l10n.serviceRecipesSafetyBannerTitle,
              body: l10n.serviceRecipesSafetyBannerBody,
              palette: palette,
            ),
            const SizedBox(height: Spacing.xl),

            // Mode 08 Discovery Section
            SectionHeading(l10n.serviceRecipesDiscoverySection),
            _Mode08DiscoveryPanel(
              connected: connection.isConnected,
              state: discoveryState,
              onDiscover: () => ref
                  .read(mode08DiscoveryStateProvider.notifier)
                  .runDiscovery(),
            ),
            const SizedBox(height: Spacing.xl),

            // Service Recipes Catalog
            SectionHeading(l10n.serviceRecipesCatalogSection),
            matrixAsync.when(
              data: (matrix) => _RecipeCatalogList(matrix: matrix),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(Spacing.xl),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.xl),
                  child: Text(
                    'Error loading service recipes: $err',
                    style: context.texts.bodySmall?.copyWith(
                      color: palette.danger,
                    ),
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

class _SafetyBanner extends StatelessWidget {
  const _SafetyBanner({
    required this.title,
    required this.body,
    required this.palette,
  });

  final String title;
  final String body;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('zero_live_candidates_banner'),
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: palette.warning.withValues(alpha: 0.12),
        borderRadius: Radii.cardRadius,
        border: Border.all(
          color: palette.warning.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            color: palette.warning,
            size: 24,
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.texts.titleSmall?.copyWith(
                    color: palette.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  body,
                  style: context.texts.bodySmall?.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Mode08DiscoveryPanel extends StatelessWidget {
  const _Mode08DiscoveryPanel({
    required this.connected,
    required this.state,
    required this.onDiscover,
  });

  final bool connected;
  final Mode08DiscoveryState state;
  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.serviceRecipesDiscoveryDescription,
            style: context.texts.bodySmall?.copyWith(
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.md),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('mode08_discovery_button'),
              onPressed: (!connected || state.isDiscovering) ? null : onDiscover,
              icon: state.isDiscovering
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: palette.textPrimary,
                      ),
                    )
                  : const Icon(Icons.radar_outlined, size: 18),
              label: Text(
                state.isDiscovering
                    ? l10n.serviceRecipesDiscovering
                    : l10n.serviceRecipesDiscoveryButton,
              ),
            ),
          ),

          if (!connected) ...[
            const SizedBox(height: Spacing.xs),
            Text(
              'Requires an active OBD-II CAN bus connection.',
              style: context.texts.bodySmall?.copyWith(
                color: palette.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          // Discovery Outcome
          if (state.isCompleted && state.result != null) ...[
            const SizedBox(height: Spacing.md),
            _buildCompletedResult(context, state.result!),
          ] else if (state.isFailed) ...[
            const SizedBox(height: Spacing.md),
            _buildStatusContainer(
              context: context,
              color: palette.danger,
              icon: Icons.error_outline,
              message: l10n.serviceRecipesDiscoveryUnknown(
                state.message ?? 'Unknown error',
              ),
            ),
          ] else if (state.isRefused) ...[
            const SizedBox(height: Spacing.md),
            _buildStatusContainer(
              context: context,
              color: palette.warning,
              icon: Icons.block_outlined,
              message: state.message ?? 'Discovery refused',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletedResult(
    BuildContext context,
    Mode08DiscoveryResult result,
  ) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;

    if (result.supportStatus == EcuSupportStatus.supported) {
      final tidsFormatted = result.supportedTids
          .map((t) => '\$${t.toRadixString(16).padLeft(2, '0').toUpperCase()}')
          .join(', ');

      return Container(
        key: const Key('mode08_discovery_success_container'),
        width: double.infinity,
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: palette.surfaceAlt,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(color: palette.accent.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: palette.accent, size: 18),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    l10n.serviceRecipesDiscoverySuccess(tidsFormatted),
                    style: context.texts.bodySmall?.copyWith(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Wrap(
              spacing: Spacing.xs,
              runSpacing: Spacing.xs,
              children: [
                for (final tid in result.supportedTids)
                  _TidChip(
                    tid: tid,
                    palette: palette,
                  ),
              ],
            ),
          ],
        ),
      );
    } else {
      return _buildStatusContainer(
        context: context,
        color: palette.warning,
        icon: Icons.info_outline,
        message: l10n.serviceRecipesDiscoveryUnsupported,
      );
    }
  }

  Widget _buildStatusContainer({
    required BuildContext context,
    required Color color,
    required IconData icon,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              message,
              style: context.texts.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _TidChip extends StatelessWidget {
  const _TidChip({
    required this.tid,
    required this.palette,
  });

  final int tid;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final hex = tid.toRadixString(16).padLeft(2, '0').toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: palette.accent.withValues(alpha: 0.5)),
        color: palette.accent.withValues(alpha: 0.08),
      ),
      child: Text(
        'TID \$$hex',
        style: context.texts.labelSmall?.copyWith(
          color: palette.accent,
          fontFamily: AppTypography.mono,
        ),
      ),
    );
  }
}

class _RecipeCatalogList extends StatelessWidget {
  const _RecipeCatalogList({required this.matrix});

  final CandidateMatrix matrix;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;

    return Column(
      children: [
        for (final entry in matrix.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            child: Panel(
              key: Key('service_recipe_tile_${entry.profile.profileId}'),
              onTap: () => showServiceRecipeDetailSheet(
                context: context,
                profile: entry.profile,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.profile.profileId,
                          style: context.texts.titleSmall,
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                  const SizedBox(height: Spacing.xs),
                  Wrap(
                    spacing: Spacing.xs,
                    runSpacing: Spacing.xs,
                    children: [
                      if (entry.category == CandidateCategory.simulationReady)
                        _Badge(
                          label: l10n.serviceRecipesSimulationBadge,
                          color: palette.info,
                        ),
                      if (!entry.isLiveCandidate)
                        _Badge(
                          label: l10n.serviceRecipesLiveBlockedBadge,
                          color: palette.warning,
                        ),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    l10n.serviceRecipesStandard(entry.profile.standard),
                    style: context.texts.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    l10n.serviceRecipesEcuHeader(
                      entry.profile.addressing.targetEcuHeader,
                    ),
                    style: context.texts.bodySmall?.copyWith(
                      color: palette.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        color: color.withValues(alpha: 0.1),
      ),
      child: Text(
        label,
        style: context.texts.labelSmall?.copyWith(
          color: color,
          fontSize: 10,
        ),
      ),
    );
  }
}
