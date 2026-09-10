/// Per-connection vehicle confirmation for installed battery profiles.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../obd/powertrain_battery/powertrain_battery_catalog.dart';
import '../../obd/powertrain_battery/powertrain_battery_profile.dart';
import '../../state/obd_session.dart';
import '../../state/pid_registry.dart';
import '../../state/powertrain_battery_profiles.dart';
import '../../l10n/generated/app_localizations.dart';
import '../screens/pids/powertrain_battery_copy.dart';
import 'panel.dart';

/// Shown on the dashboard while a connection is live and an installed
/// battery profile has not yet been confirmed for it.
///
/// Installation makes definitions available; it does not say "the vehicle at
/// the other end of this adapter is that vehicle". This banner is where the
/// driver says so, once per connection — the grant dies with the connection,
/// so plugging into a different car never inherits it.
class PowertrainProfileConfirmBanner extends ConsumerWidget {
  const PowertrainProfileConfirmBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final connected = ref.watch(obdSessionProvider).isConnected;
    if (!connected) return const SizedBox.shrink();

    final registryPids = ref.watch(pidRegistryProvider);
    final authorizations = ref.watch(powertrainProfileAuthorizationsProvider);
    // One source revision per installed profile, taken from its own PIDs so
    // the liveness check below matches exactly what the polling filter sees.
    final installedRevisions = <String, String?>{
      for (final pid in registryPids)
        if (!pid.isCustom && pid.ownerProfileId != null)
          pid.ownerProfileId!: pid.sourceRevision,
    };
    final generation = ref
        .read(obdSessionProvider.notifier)
        .connectionGeneration;
    // The banner and the polling filter share one liveness predicate: any
    // grant the poller would refuse — stale generation, or a catalog
    // revision that changed under the install — makes the row reappear and
    // ask again, instead of hiding it over dark gauges.
    final unconfirmed = [
      for (final entry in installedRevisions.entries)
        if (!isLivePowertrainAuthorization(
          authorizations[entry.key],
          connectionGeneration: generation,
          sourceRevision: entry.value,
        ))
          entry.key,
    ];
    if (unconfirmed.isEmpty) return const SizedBox.shrink();

    final snapshot = ref.watch(powertrainBatteryCatalogSnapshotProvider).value;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.md),
      child: Panel(
        key: const Key('powertrain_profile_confirm_banner'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.powertrainConfirmTitle, style: context.texts.titleMedium),
            const SizedBox(height: Spacing.xs),
            Text(l10n.powertrainConfirmBody, style: context.texts.bodySmall),
            const SizedBox(height: Spacing.sm),
            for (final profileId in unconfirmed)
              _ConfirmRow(
                profileId: profileId,
                snapshot: snapshot,
                profile: snapshot?.catalog.profiles
                    .where((profile) => profile.id == profileId)
                    .firstOrNull,
              ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmRow extends ConsumerWidget {
  const _ConfirmRow({
    required this.profileId,
    required this.snapshot,
    required this.profile,
  });

  final String profileId;
  final PowertrainBatteryCatalogSnapshot? snapshot;
  final PowertrainBatteryProfile? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final resolved = profile;
    final resolvedSnapshot = snapshot;
    final year = ref
        .read(pidRegistryProvider.notifier)
        .installedVehicleYear(profileId);
    return Row(
      children: [
        Expanded(
          child: Text(
            resolved == null
                ? profileId
                : '${resolved.displayName}${year == null ? '' : ' · $year'}',
            style: context.texts.bodyMedium,
          ),
        ),
        FilledButton(
          key: Key('powertrain_confirm_connection_$profileId'),
          onPressed:
              resolved == null || resolvedSnapshot == null || year == null
              ? null
              : () => _confirm(context, ref, resolvedSnapshot, resolved, year),
          child: Text(l10n.powertrainConfirmButton),
        ),
      ],
    );
  }

  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref,
    PowertrainBatteryCatalogSnapshot snapshot,
    PowertrainBatteryProfile profile,
    int year,
  ) async {
    // Captured before the dialog opens. The confirmation is a statement
    // about the vehicle on the wire *now*; if the connection changes while
    // the dialog sits open — a different adapter, a different car — the
    // acceptance must not carry over to whatever connected next.
    // Read before the dialog opens, for the same reason the generation is: the
    // answer belongs to the language that was on screen when the driver was
    // asked, not to whatever the app is set to when the dialog closes.
    final l10n = AppLocalizations.of(context);
    final session = ref.read(obdSessionProvider.notifier);
    final generationAtPrompt = session.connectionGeneration;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.powertrainConfirmDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$year ${profile.make} ${profile.model}\n'
              '${profile.variant} · ${profile.market}',
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              l10n.powertrainConfirmDialogBody,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.powertrainCancel),
          ),
          FilledButton(
            key: const Key('powertrain_confirm_connection_accept'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.powertrainConfirmAccept),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    if (!ref.read(obdSessionProvider).isConnected ||
        session.connectionGeneration != generationAtPrompt) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.powertrainConnectionChanged)));
      return;
    }

    final result = ref
        .read(powertrainProfileAuthorizationsProvider.notifier)
        .authorize(
          snapshot: snapshot,
          profileId: profile.id,
          vehicleYear: year,
          connectionGeneration: generationAtPrompt,
        );
    if (!context.mounted) return;
    final granted = result?.canInstall ?? false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? l10n.powertrainAuthorizationGranted(profile.displayName)
              : l10n.powertrainAuthorizationRefused(
                  result == null || result.issues.isEmpty
                      ? l10n.powertrainProfileNotVerified
                      : powertrainProfileIssueText(l10n, result.issues.first),
                ),
        ),
      ),
    );
  }
}
