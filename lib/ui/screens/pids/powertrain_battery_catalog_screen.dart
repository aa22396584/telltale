/// Searchable, evidence-labelled vehicle-specific traction-battery catalog.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../obd/powertrain_battery/powertrain_battery_profile.dart';
import '../../../obd/powertrain_battery/powertrain_battery_catalog.dart';
import '../../../obd/powertrain_battery/powertrain_battery_probe.dart';
import '../../../obd/powertrain_battery/profile_catalog_validator.dart';
import '../../../obd/powertrain_battery/profile_pid_installer.dart';
import '../../../state/obd_session.dart';
import '../../../state/pid_registry.dart';
import '../../../state/powertrain_battery_profiles.dart';
import '../../../state/powertrain_battery_experiments.dart';
import '../../widgets/panel.dart';
import 'pid_mutation_copy.dart';
import 'powertrain_battery_copy.dart';

class PowertrainBatteryCatalogScreen extends ConsumerStatefulWidget {
  const PowertrainBatteryCatalogScreen({super.key});

  static const String path = '/powertrain-battery';

  @override
  ConsumerState<PowertrainBatteryCatalogScreen> createState() =>
      _PowertrainBatteryCatalogScreenState();
}

class _PowertrainBatteryCatalogScreenState
    extends ConsumerState<PowertrainBatteryCatalogScreen> {
  static const _filters = <String>[
    'all',
    'PHEV',
    'HEV',
    'BEV',
    'MHEV',
    'REEV',
    'FCEV',
  ];

  late Future<PowertrainBatteryCatalogSnapshot> _catalog;
  String _query = '';
  String _powertrain = 'all';
  String? _probingCommandKey;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    // The shared provider, not a private loader call: the restore path, the
    // dashboard banner and this screen must all see the same verified
    // snapshot (and the same failure), not three separate loads.
    _catalog = ref.read(powertrainBatteryCatalogSnapshotProvider.future);
  }

  void _retry() {
    ref.invalidate(powertrainBatteryCatalogSnapshotProvider);
    setState(_load);
  }

  Future<void> _probeExperimental(
    PowertrainBatteryCatalogSnapshot snapshot,
    PowertrainBatteryProfile profile,
  ) async {
    // Captured before the first await. Every message below belongs to the
    // language that was on screen when the driver tapped, and reading the
    // context again after an await is what `use_build_context_synchronously`
    // exists to stop.
    final l10n = AppLocalizations.of(context);
    if (!ref.read(powertrainBatteryExperimentalAccessProvider)) {
      _snack(l10n.powertrainEnableLabInSettings);
      return;
    }
    if (!ref.read(obdSessionProvider).isConnected) {
      _snack(l10n.powertrainConnectFirst);
      return;
    }
    final quarantine = ref
        .read(powertrainExperimentalProbeConsentsProvider.notifier)
        .quarantineReason(profile.id);
    if (quarantine != null) {
      _snack(
        powertrainProbeRefusalText(
          l10n,
          quarantine,
          // The same constant the decision below carries: the cap that
          // recorded the quarantine and the cap named in the sentence must
          // come from one place.
          attemptCap:
              PowertrainExperimentalProbeConsents.maxAttemptsPerCommand,
        ),
      );
      return;
    }

    final command = await _chooseExperimentalCommand(profile);
    if (command == null || !mounted) return;
    final year = await _confirmExperimentalProbe(profile, command);
    if (year == null || !mounted) return;

    final session = ref.read(obdSessionProvider.notifier);
    final decision = ref
        .read(powertrainExperimentalProbeConsentsProvider.notifier)
        .authorize(
          snapshot: snapshot,
          profileId: profile.id,
          commandKey: command.wireKey,
          vehicleYear: year,
          connectionGeneration: session.connectionGeneration,
        );
    final refusal = decision.refusal;
    if (refusal != null) {
      _snack(
        powertrainProbeRefusalText(
          l10n,
          refusal,
          attemptCap: decision.attemptCap,
        ),
      );
      return;
    }

    setState(() => _probingCommandKey = command.wireKey);
    try {
      final result = await session.probePowertrainBatteryCommand(
        snapshot: snapshot,
        profileId: profile.id,
        commandKey: command.wireKey,
        vehicleYear: year,
      );
      if (mounted) await _showProbeResult(result);
    } on PowertrainProbeRefusedException catch (refused) {
      // Caught before the arm below, and deliberately not reported to
      // `FlutterError`. A refusal is an outcome this code chose — not
      // connected, no live authorization, a lifecycle boundary crossed while
      // the read was in flight — and reporting an expected decision as a
      // framework error buries the real ones.
      //
      // It also used to be answered by `powertrainProbeDidNotFinish`, the same
      // sentence a genuine mid-read failure gets. The last of the three is not
      // a failure at all: a result was read and deliberately not kept.
      if (mounted) {
        _snack(
          powertrainProbeRefusalText(
            l10n,
            refused.refusal,
            attemptCap: decision.attemptCap,
          ),
        );
      }
    } on Object catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'Telltale powertrain battery laboratory',
          context: ErrorDescription('while running a one-shot probe'),
        ),
      );
      if (mounted) _snack(l10n.powertrainProbeDidNotFinish);
    } finally {
      if (mounted) setState(() => _probingCommandKey = null);
    }
  }

  Future<void> _installProfile(
    PowertrainBatteryCatalogSnapshot snapshot,
    PowertrainBatteryProfile profile,
  ) async {
    // Captured before the dialog opens. The install dialog doubles as this
    // connection's vehicle confirmation, and that statement is about the
    // vehicle on the wire *now* — if the connection changes while the
    // dialog sits open, the acceptance must not authorize whatever
    // connected next; the dashboard banner will ask for it instead.
    final l10n = AppLocalizations.of(context);
    final session = ref.read(obdSessionProvider.notifier);
    final wasConnected = ref.read(obdSessionProvider).isConnected;
    final generationAtPrompt = session.connectionGeneration;

    final year = await _confirmInstall(profile);
    if (year == null || !mounted) return;

    // Serialize with the startup restore: installing before it finishes
    // would persist a reference list that misses whatever restore was about
    // to rebuild. An integrity failure means the catalog itself is not
    // usable; any other failure is retryable, so re-arm the provider and
    // say so instead of locking installation behind a misleading message
    // until the next app start.
    try {
      await ref.read(installedPowertrainProfilesRestoreProvider.future);
    } on PowertrainBatteryCatalogAssetException {
      _snack(l10n.powertrainCatalogNotVerified);
      return;
    } on Object {
      ref.invalidate(installedPowertrainProfilesRestoreProvider);
      _snack(l10n.powertrainRestoreStorageErrorRetry);
      return;
    }
    if (!mounted) return;

    try {
      final outcome = await ref
          .read(pidRegistryProvider.notifier)
          .installPowertrainProfile(snapshot, profile.id, vehicleYear: year);
      final failure = outcome.failure;
      if (failure != null) {
        _snack(pidMutationFailureText(l10n, failure));
        return;
      }
    } on PowertrainProfileInstallException catch (error) {
      _snack(powertrainInstallIssueText(l10n, error.issue));
      return;
    }

    // A live connection can be confirmed in the same gesture — but only the
    // connection the dialog was opened against.
    if (wasConnected &&
        ref.read(obdSessionProvider).isConnected &&
        session.connectionGeneration == generationAtPrompt) {
      ref
          .read(powertrainProfileAuthorizationsProvider.notifier)
          .authorize(
            snapshot: snapshot,
            profileId: profile.id,
            vehicleYear: year,
            connectionGeneration: generationAtPrompt,
          );
    }
    final signals = profile.commands.fold<int>(
      0,
      (total, command) => total + command.signals.length,
    );
    _snack(l10n.powertrainInstalledSignalsSnack(signals));
    setState(() {});
  }

  Future<void> _uninstallProfile(PowertrainBatteryProfile profile) async {
    final l10n = AppLocalizations.of(context);
    final outcome = await ref
        .read(pidRegistryProvider.notifier)
        .uninstallPowertrainProfile(profile.id);
    final failure = outcome.failure;
    if (failure != null) {
      _snack(pidMutationFailureText(l10n, failure));
      return;
    }
    ref
        .read(powertrainProfileAuthorizationsProvider.notifier)
        .revoke(profile.id);
    _snack(l10n.powertrainUninstalledSignalsSnack(profile.displayName));
    setState(() {});
  }

  Future<int?> _confirmInstall(PowertrainBatteryProfile profile) =>
      showDialog<int>(
        context: context,
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          var year = profile.yearFrom;
          var identityAcknowledged = false;
          final years = [
            for (var value = profile.yearFrom; value <= profile.yearTo; value++)
              value,
          ];
          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: Text(l10n.powertrainInstallDialogTitle),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${profile.market} · ${profile.make} ${profile.model}\n'
                      '${profile.variant} · ${profile.powertrain}',
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      l10n.powertrainPrimarySource(
                        profile.source.name,
                        profile.source.license,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    for (final source in profile.secondarySources)
                      Text(
                        l10n.powertrainSecondarySource(
                          source.name,
                          source.license,
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      powertrainInstallDisclosure(l10n, profile.status),
                      key: const Key('powertrain_install_disclosure'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: Spacing.md),
                    if (years.length > 1)
                      DropdownButtonFormField<int>(
                        key: const Key('powertrain_install_year'),
                        initialValue: year,
                        decoration: InputDecoration(
                          labelText: l10n.powertrainVehicleYearLabel,
                        ),
                        items: [
                          for (final value in years)
                            DropdownMenuItem(
                              value: value,
                              child: Text('$value'),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) setDialogState(() => year = value);
                        },
                      )
                    else
                      Text(l10n.powertrainVehicleYearFixed(year)),
                    const SizedBox(height: Spacing.sm),
                    CheckboxListTile(
                      key: const Key('powertrain_install_identity_ack'),
                      value: identityAcknowledged,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(l10n.powertrainInstallIdentityAck),
                      onChanged: (value) => setDialogState(
                        () => identityAcknowledged = value ?? false,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.powertrainCancel),
                ),
                FilledButton(
                  key: const Key('powertrain_confirm_install'),
                  onPressed: identityAcknowledged
                      ? () => Navigator.pop(context, year)
                      : null,
                  child: Text(l10n.powertrainInstallConfirm),
                ),
              ],
            ),
          );
        },
      );

  Future<PowertrainBatteryCommand?> _chooseExperimentalCommand(
    PowertrainBatteryProfile profile,
  ) => showDialog<PowertrainBatteryCommand>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return SimpleDialog(
      title: Text(l10n.powertrainChooseCommandTitle),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            0,
            Spacing.lg,
            Spacing.sm,
          ),
          child: Text(
            l10n.powertrainChooseCommandNote,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        for (final command in profile.commands)
          SimpleDialogOption(
            key: Key(
              'powertrain_probe_command_${profile.id}_${command.modeAndIdentifier}',
            ),
            onPressed: () => Navigator.pop(context, command),
            child: Text(
              '${command.modeAndIdentifier} · '
              '${command.requestHeader} → ${command.expectedResponder}\n'
              // Not a literal '、'. This is the one list on the screen that
              // was still joining with an ideographic comma, so 18 of the 51
              // catalogue commands rendered "Battery temperature 1、Battery
              // temperature 2" to an English reader. The separator key was
              // already three lines below, in use by another list.
              '${command.signals.map((signal) => signal.name).join(l10n.powertrainFieldListSeparator)}',
            ),
          ),
      ],
      );
    },
  );

  Future<int?> _confirmExperimentalProbe(
    PowertrainBatteryProfile profile,
    PowertrainBatteryCommand command,
  ) => showDialog<int>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      var year = profile.yearFrom;
      var identityAcknowledged = false;
      var parkedAcknowledged = false;
      final years = [
        for (var value = profile.yearFrom; value <= profile.yearTo; value++)
          value,
      ];
      return StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.powertrainExperimentalDialogTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile.market} · ${profile.make} ${profile.model}\n'
                  '${profile.variant} · ${profile.powertrain}',
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'TX ${command.requestHeader} ${command.modeAndIdentifier}\n'
                  '${l10n.powertrainExperimentalWireLine(command.expectedResponder, command.payloadLength)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  l10n.powertrainSourceSha256(
                    profile.source.artifactSha256.substring(0, 12),
                  ),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  powertrainIdentityEvidenceSummary(
                    l10n,
                    profile.identityEvidence,
                  ),
                  key: const Key('powertrain_experimental_identity_evidence'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  l10n.powertrainExperimentalDataDisclosure,
                  key: const Key('powertrain_experimental_data_disclosure'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: Spacing.md),
                DropdownButtonFormField<int>(
                  key: const Key('powertrain_experimental_year'),
                  initialValue: year,
                  decoration: InputDecoration(
                    labelText: l10n.powertrainVehicleYearLabel,
                  ),
                  items: [
                    for (final value in years)
                      DropdownMenuItem(value: value, child: Text('$value')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => year = value);
                  },
                ),
                const SizedBox(height: Spacing.sm),
                CheckboxListTile(
                  key: const Key('powertrain_experimental_identity_ack'),
                  value: identityAcknowledged,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(l10n.powertrainExperimentalIdentityAck),
                  onChanged: (value) => setDialogState(
                    () => identityAcknowledged = value ?? false,
                  ),
                ),
                CheckboxListTile(
                  key: const Key('powertrain_experimental_parked_ack'),
                  value: parkedAcknowledged,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(l10n.powertrainExperimentalParkedAck),
                  onChanged: (value) =>
                      setDialogState(() => parkedAcknowledged = value ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.powertrainCancel),
            ),
            FilledButton(
              key: const Key('powertrain_confirm_experimental_probe'),
              onPressed: identityAcknowledged && parkedAcknowledged
                  ? () => Navigator.pop(context, year)
                  : null,
              child: Text(l10n.powertrainProbeOnceButton),
            ),
          ],
        ),
      );
    },
  );

  Future<void> _showProbeResult(
    PowertrainBatteryProbeResult result,
  ) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        result.passed
            ? AppLocalizations.of(context).powertrainProbePassedTitle
            : AppLocalizations.of(context).powertrainProbeRefusedTitle,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'catalog ${result.catalogSha256.substring(0, 12)}…\n'
              'source ${result.sourceRevision.substring(0, 12)}…\n'
              'TX ${result.command?.requestHeader ?? '—'} '
              '${result.command?.modeAndIdentifier ?? '—'}\n'
              'RX ${result.responder ?? '—'}',
            ),
            const SizedBox(height: Spacing.sm),
            if (result.rawResponseBytes.isNotEmpty)
              SelectableText(
                'RAW ${_hex(result.rawResponseBytes)}',
                key: const Key('powertrain_probe_raw_result'),
              ),
            if (result.passed) ...[
              const SizedBox(height: Spacing.sm),
              Text(AppLocalizations.of(context).powertrainProbeChecksPassed),
              for (final reading in result.readings)
                Text(
                  '${reading.signal.name}: ${reading.value} '
                  '${reading.signal.unit} · bytes ${_hex(reading.rawBytes)}',
                ),
            ] else ...[
              const SizedBox(height: Spacing.sm),
              Text('${result.failure?.name}: ${result.detail}'),
              Text(
                AppLocalizations.of(context).powertrainProbeNoValuePublished,
              ),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context).powertrainClose),
        ),
      ],
    ),
  );

  static String _hex(Iterable<int> bytes) => bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(' ');

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.powertrainCatalogTitle)),
      body: FutureBuilder<PowertrainBatteryCatalogSnapshot>(
        future: _catalog,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: l10n.powertrainCatalogLoadFailedTitle,
              message: l10n.powertrainCatalogLoadFailedBody,
              action: OutlinedButton(
                onPressed: _retry,
                child: Text(l10n.powertrainCatalogRevalidate),
              ),
            );
          }
          return _catalogBody(snapshot.data!);
        },
      ),
    );
  }

  Widget _catalogBody(PowertrainBatteryCatalogSnapshot snapshot) {
    final l10n = AppLocalizations.of(context);
    final catalog = snapshot.catalog;
    ref.watch(powertrainExperimentalProbeConsentsProvider);
    final connected = ref.watch(obdSessionProvider).isConnected;
    final experimentalAccess = ref.watch(
      powertrainBatteryExperimentalAccessProvider,
    );
    final installedIds = {
      for (final pid in ref.watch(pidRegistryProvider))
        if (!pid.isCustom && pid.ownerProfileId != null) pid.ownerProfileId!,
    };
    final query = _query.trim().toLowerCase();
    final visible =
        catalog.profiles
            .where((profile) {
              if (_powertrain != 'all' &&
                  profile.powertrain.toUpperCase() != _powertrain) {
                return false;
              }
              if (query.isEmpty) return true;
              final haystack = [
                profile.displayName,
                profile.make,
                profile.model,
                profile.variant,
                profile.market,
                profile.powertrain,
              ].join(' ').toLowerCase();
              return haystack.contains(query);
            })
            .toList(growable: false)
          ..sort((a, b) {
            final statusOrder = _statusOrder(a.status)
                .compareTo(_statusOrder(b.status));
            if (statusOrder != 0) return statusOrder;
            return a.displayName.compareTo(b.displayName);
          });

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.md,
              Spacing.lg,
              Spacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.powertrainCatalogCounts(
                    catalog.profiles.length,
                    catalog.profiles
                        .where(
                          (p) =>
                              const PowertrainBatteryProfileCatalogValidator()
                                  .validateProfile(p)
                                  .canProbe,
                        )
                        .length,
                  ),
                  style: context.texts.titleMedium,
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  l10n.powertrainCatalogScopeNote,
                  style: context.texts.bodySmall,
                ),
                const SizedBox(height: Spacing.md),
                TextField(
                  key: const Key('powertrain_profile_search'),
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: l10n.powertrainCatalogSearchHint,
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final filter in _filters) ...[
                        FilterChip(
                          key: Key('powertrain_filter_$filter'),
                          selected: _powertrain == filter,
                          showCheckmark: false,
                          label: Text(
                            filter == 'all' ? l10n.powertrainFilterAll : filter,
                          ),
                          onSelected: (_) =>
                              setState(() => _powertrain = filter),
                        ),
                        const SizedBox(width: Spacing.xs),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? EmptyState(
                    icon: Icons.search_off,
                    title: l10n.powertrainNoMatchTitle,
                    message: l10n.powertrainNoMatchBody,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.lg,
                      Spacing.sm,
                      Spacing.lg,
                      Spacing.xxl,
                    ),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: Spacing.sm),
                    itemBuilder: (context, index) {
                      final profile = visible[index];
                      return _ProfileCard(
                        profile: profile,
                        connected: connected,
                        experimentalAccess: experimentalAccess,
                        installed: installedIds.contains(profile.id),
                        quarantined:
                            ref
                                .read(
                                  powertrainExperimentalProbeConsentsProvider
                                      .notifier,
                                )
                                .quarantineReason(profile.id) !=
                            null,
                        probing: _probingCommandKey != null,
                        onProbe: () => _probeExperimental(snapshot, profile),
                        onInstall: () => _installProfile(snapshot, profile),
                        onUninstall: () => _uninstallProfile(profile),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  int _statusOrder(PowertrainProfileStatus status) => switch (status) {
    PowertrainProfileStatus.ready => 0,
    PowertrainProfileStatus.community => 1,
    PowertrainProfileStatus.experimental => 2,
    PowertrainProfileStatus.researchOnly => 3,
  };
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.connected,
    required this.experimentalAccess,
    required this.installed,
    required this.quarantined,
    required this.probing,
    required this.onProbe,
    required this.onInstall,
    required this.onUninstall,
  });

  final PowertrainBatteryProfile profile;
  final bool connected;
  final bool experimentalAccess;
  final bool installed;
  final bool quarantined;
  final bool probing;
  final VoidCallback onProbe;
  final VoidCallback onInstall;
  final VoidCallback onUninstall;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final validation = const PowertrainBatteryProfileCatalogValidator()
        .validateProfile(profile);
    final probeable = validation.canProbe;
    final installable = validation.canInstall;
    final years = profile.yearFrom == profile.yearTo
        ? '${profile.yearFrom}'
        : '${profile.yearFrom}–${profile.yearTo}';
    final statusLabel = powertrainProfileStatusLabel(
      l10n,
      profile.status,
      installable: installable,
    );
    final statusTone = switch (profile.status) {
      PowertrainProfileStatus.ready => StatusTone.good,
      PowertrainProfileStatus.community => StatusTone.accent,
      PowertrainProfileStatus.experimental => StatusTone.warn,
      PowertrainProfileStatus.researchOnly => StatusTone.neutral,
    };
    final evidence = powertrainProfileEvidenceLabel(l10n, profile.evidence);
    final signalCount = profile.commands.fold<int>(
      0,
      (total, command) => total + command.signals.length,
    );

    return Panel(
      key: Key('powertrain_profile_${profile.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  profile.displayName,
                  style: context.texts.titleMedium,
                ),
              ),
              StatusPill(label: statusLabel, tone: statusTone, dense: true),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Wrap(
            spacing: Spacing.xs,
            runSpacing: Spacing.xs,
            children: [
              StatusPill(
                label: profile.powertrain,
                tone: StatusTone.accent,
                dense: true,
              ),
              StatusPill(label: evidence, dense: true),
              if (quarantined)
                StatusPill(
                  label: l10n.powertrainQuarantinedPill,
                  tone: StatusTone.warn,
                  dense: true,
                ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            '$years · ${profile.market} · ${profile.variant}',
            style: context.texts.bodySmall,
          ),
          const SizedBox(height: Spacing.xs),
          Text(profile.description, style: context.texts.bodyMedium),
          const SizedBox(height: Spacing.xs),
          for (final limitation in profile.limitations.take(2))
            Text('• $limitation', style: context.texts.bodySmall),
          const SizedBox(height: Spacing.sm),
          Text(
            '${profile.source.name} · ${profile.source.license} · '
            '${profile.source.revision.substring(0, 8)} · '
            '${l10n.powertrainSignalCount(signalCount)}',
            style: context.texts.labelSmall,
          ),
          const SizedBox(height: Spacing.sm),
          if (installable) ...[
            Row(
              children: [
                Expanded(
                  child: installed
                      ? OutlinedButton(
                          key: Key('powertrain_uninstall_${profile.id}'),
                          onPressed: onUninstall,
                          child: Text(l10n.powertrainInstalledRemoveButton),
                        )
                      : FilledButton(
                          key: Key('powertrain_install_${profile.id}'),
                          onPressed: onInstall,
                          child: Text(l10n.powertrainInstallButton),
                        ),
                ),
              ],
            ),
            // Try-before-install: the same consented one-shot read the
            // experimental tier uses, available while the lab is open.
            if (probeable && experimentalAccess)
              Padding(
                padding: const EdgeInsets.only(top: Spacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: Key('powertrain_probe_${profile.id}'),
                        onPressed: connected && !quarantined && !probing
                            ? onProbe
                            : null,
                        child: Text(
                          quarantined
                              ? l10n.powertrainProbeReconnectFirst
                              : !connected
                              ? l10n.powertrainProbeConnectToTryOnce
                              : probing
                              ? l10n.powertrainProbeInProgress
                              : l10n.powertrainProbeTryOnceFirst,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ] else
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    key: Key('powertrain_probe_${profile.id}'),
                    onPressed: probeable
                        ? experimentalAccess &&
                                  connected &&
                                  !quarantined &&
                                  !probing
                              ? onProbe
                              : null
                        : null,
                    child: Text(
                      probeable
                          ? quarantined
                                ? l10n.powertrainProbeReconnectFirst
                                : !experimentalAccess
                                ? l10n.powertrainProbeEnableLabFirst
                                : !connected
                                ? l10n.powertrainProbeConnectForOneShot
                                : probing
                                ? l10n.powertrainProbeInProgress
                                : l10n.powertrainProbePickOneRead
                          : profile.status ==
                                PowertrainProfileStatus.researchOnly
                          ? l10n.powertrainResearchOnlyNeverQueries
                          : l10n.powertrainNotInstallableInThisRelease,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Provenance and installability copy, keyed off the catalog enums.
///
/// These take an [AppLocalizations] rather than a [BuildContext] because none
/// of them is chosen inside a widget that owns one, and because a pure-Dart
/// test can then walk every enum arm in both languages without a pump. The
/// screen's whole purpose is keeping "we found a candidate" apart from "this
/// works on your car", and that distinction lives in these four functions.

/// The install dialog's disclosure, one whole sentence per status.
///
/// Deliberately NOT a shared const prefix plus a status-specific tail. The
/// Chinese happens to concatenate cleanly; English does not, and gluing
/// fragments would force every future translation into Chinese clause order.
/// [PowertrainProfileStatus.researchOnly] must never read as installable.
String powertrainInstallDisclosure(
  AppLocalizations l10n,
  PowertrainProfileStatus status,
) => switch (status) {
  PowertrainProfileStatus.ready => l10n.powertrainInstallDisclosureReady,
  PowertrainProfileStatus.community => l10n.powertrainInstallDisclosureCommunity,
  PowertrainProfileStatus.experimental =>
    l10n.powertrainInstallDisclosureExperimental,
  PowertrainProfileStatus.researchOnly =>
    l10n.powertrainInstallDisclosureResearchOnly,
};

/// The card's status pill label.
///
/// `experimental` reads differently depending on whether the profile also
/// passes the install gate: one is an installable-but-unverified tier, the
/// other can only ever be read once. Collapsing them would tell a driver a
/// probe-only entry is installable.
String powertrainProfileStatusLabel(
  AppLocalizations l10n,
  PowertrainProfileStatus status, {
  required bool installable,
}) => switch (status) {
  PowertrainProfileStatus.ready => l10n.powertrainStatusReady,
  PowertrainProfileStatus.community => l10n.powertrainStatusCommunity,
  PowertrainProfileStatus.experimental => installable
      ? l10n.powertrainStatusExperimental
      : l10n.powertrainStatusExperimentalProbeOnly,
  PowertrainProfileStatus.researchOnly => l10n.powertrainStatusResearchOnly,
};

/// Where this entry's evidence came from — never what it proves about a car.
String powertrainProfileEvidenceLabel(
  AppLocalizations l10n,
  PowertrainProfileEvidence evidence,
) => switch (evidence) {
  PowertrainProfileEvidence.sourceBacked => l10n.powertrainEvidenceSourceBacked,
  PowertrainProfileEvidence.syntheticRig => l10n.powertrainEvidenceSyntheticRig,
  PowertrainProfileEvidence.physicalVehicle =>
    l10n.powertrainEvidencePhysicalVehicle,
};

/// How strongly the *source* pins one identity field. Not a match with the car
/// in front of the driver, which is what the acknowledgement asks for.
String powertrainIdentityEvidenceLabel(
  AppLocalizations l10n,
  PowertrainIdentityEvidenceLevel level,
) => switch (level) {
  PowertrainIdentityEvidenceLevel.exact => l10n.powertrainIdentityEvidenceExact,
  PowertrainIdentityEvidenceLevel.sourcePartial =>
    l10n.powertrainIdentityEvidenceSourcePartial,
  PowertrainIdentityEvidenceLevel.unknown =>
    l10n.powertrainIdentityEvidenceUnknown,
};

/// The four identity fields with their evidence level, plus the ones the
/// source could not establish.
///
/// A profile carrying no identity evidence at all is rendered as four
/// `unknown` fields rather than through a separate hand-written sentence:
/// absent evidence and evidence that says "unknown" mean the same thing to a
/// driver, and one code path cannot drift from the other.
String powertrainIdentityEvidenceSummary(
  AppLocalizations l10n,
  PowertrainBatteryIdentityEvidence? evidence,
) {
  const absent = PowertrainIdentityEvidenceLevel.unknown;
  final fields = <(String, PowertrainIdentityEvidenceLevel)>[
    (l10n.powertrainFieldMarket, evidence?.market ?? absent),
    (l10n.powertrainFieldModelYear, evidence?.year ?? absent),
    (l10n.powertrainFieldModel, evidence?.model ?? absent),
    (l10n.powertrainFieldVariant, evidence?.variant ?? absent),
  ];
  final unknown = [
    for (final field in fields)
      if (field.$2 == PowertrainIdentityEvidenceLevel.unknown) field.$1,
  ];
  return l10n.powertrainIdentityEvidenceSummary(
    fields
        .map(
          (field) =>
              '${field.$1} ${powertrainIdentityEvidenceLabel(l10n, field.$2)}',
        )
        .join(' · '),
    unknown.isEmpty
        ? l10n.powertrainIdentityEvidenceNone
        : unknown.join(l10n.powertrainFieldListSeparator),
  );
}
