/// Settings: the vehicle parameters the physics engine needs, plus appearance
/// and the current connection.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/licenses/powertrain_battery_licenses.dart';
import '../../../obd/physics/vehicle_profile.dart';
import '../../../obd/physics/vehicle_evidence.dart';
import '../../../obd/transport/obd_transport.dart'
    show TransportException, TransportKind;
import '../../../obd/vehicle_catalog/us_vehicle_catalog.dart';
import '../../../obd/vehicle_catalog/us_vehicle_profile.dart';
import '../../../state/manual_command_refusal.dart';
import '../../../state/obd_session.dart';
import '../../../state/powertrain_battery_experiments.dart';
import '../../../state/powertrain_battery_profiles.dart';
import '../../../state/settings.dart';
import '../../../state/vehicle_catalog.dart';
import '../../../state/vehicle_identity.dart';
import '../../widgets/panel.dart';
import '../../widgets/gauges/dial_gauge.dart';
import '../../widgets/field_event_markers.dart';
import '../../../core/theme/gauge_skin.dart';
import '../../widgets/transcript_export.dart';
import '../../widgets/recommended_purchase_panel.dart';
import '../../widgets/language_picker.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../connect/connect_screen.dart';
import 'gauge_skin_copy.dart';
import 'vehicle_profile_copy.dart';
import 'adapter_concern_copy.dart';
import 'manual_command_copy.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({this.onOpenRecommendedPurchase, super.key});

  /// Tests inject this so a tap does not leave the process.
  @visibleForTesting
  final OpenRecommendedPurchase? onOpenRecommendedPurchase;

  static const String path = '/settings';

  /// What a failed manual command reads like on screen.
  ///
  /// The sentence, not the identifier. `'$e'` prefixes the Dart class name, so
  /// every refusal arrived as `TransportException: 清除故障碼請用…` — an
  /// English type name in front of a Chinese sentence, on the one screen
  /// somebody opens when they are already unsure whether the app is working.
  /// The app fixed exactly this once before for handshake failures; the manual
  /// box was the copy that got missed.
  ///
  /// Then it was still the *Chinese* sentence, in every language the app
  /// ships. `TransportException.message` is authored in Traditional Chinese
  /// and goes to the transcript verbatim, on purpose; this panel was reading
  /// the same string and putting it on the screen. So the identifier is asked
  /// first and the message is never rendered for anything that carries one.
  ///
  /// Three kinds of thing arrive here, and each is asked a different question.
  ///
  /// A command this app refused to send is a `ManualCommandRefusedException`.
  /// It is not a transport failure — nothing was written, no link was involved
  /// — so it carries a refusal identifier rather than a `TransportIssue`, and
  /// [manualCommandRefusalText] always answers it.
  ///
  /// A command that was sent and failed is a `TransportException`, answered by
  /// [commandFailureText] through its identifier.
  ///
  /// `WriteRefusedException` carries `TransportIssue.notConnected` and
  /// `OperationRetiredException` carries `TransportIssue.operationRetired`,
  /// so both go through [commandFailureText]. The remaining subclass that
  /// still bakes `issue: null` is `UnaddressableRequestException`, which the
  /// polling loop handles structurally and which does not reach this panel.
  /// There is therefore no `error.message` fallback: that was how an English
  /// reader still saw Traditional Chinese for the two that do arrive here.
  ///
  /// A function rather than two catch clauses so it can be tested. The panel
  /// it renders into only exists while connected, and a connected session
  /// cannot be driven from `testWidgets` — the fake-async clock never advances
  /// for the poller's real delays, so the test deadlocks instead of failing.
  /// Anything that is not one of ours keeps its `toString`, because an
  /// unexpected type is exactly when the identifier is the useful part.
  @visibleForTesting
  static String describeManualFailure(AppLocalizations l10n, Object error) {
    if (error is ManualCommandRefusedException) {
      return manualCommandRefusalText(l10n, error.refusal);
    }
    if (error is! TransportException) return '$error';
    return commandFailureText(l10n, error) ?? '$error';
  }

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _commandController = TextEditingController();
  String? _commandResult;
  bool _sending = false;
  bool _readingVin = false;
  bool _loadingVehicleCatalog = false;
  Future<UsVehicleCatalog>? _vehicleCatalogFuture;

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }

  Future<void> _sendManual() async {
    // Read before the await. The result is written into the panel after the
    // adapter answers, and it belongs to the language that was on screen when
    // the command was sent.
    final l10n = AppLocalizations.of(context);
    final text = _commandController.text;
    if (text.trim().isEmpty) return;
    setState(() {
      _sending = true;
      _commandResult = null;
    });
    String result;
    try {
      result = await ref
          .read(obdSessionProvider.notifier)
          .sendManualCommand(text);
      if (result.trim().isEmpty) result = l10n.settingsManualCommandNoContent;
    } on Object catch (e) {
      // Shown rather than thrown. This screen exists for the case where things
      // are already going wrong; an exception escaping it would be the one
      // place a diagnostic tool goes quiet.
      result = SettingsScreen.describeManualFailure(l10n, e);
    }
    if (!mounted) return;
    setState(() {
      _sending = false;
      _commandResult = result;
    });
  }

  Future<void> _refreshVin() async {
    if (_readingVin) return;
    setState(() => _readingVin = true);
    await ref
        .read(obdSessionProvider.notifier)
        .refreshVehicleIdentity(
          deadline: DateTime.now().add(const Duration(seconds: 12)),
        );
    if (!mounted) return;
    setState(() => _readingVin = false);
  }

  Future<void> _selectOfficialVehicle() async {
    if (_loadingVehicleCatalog) return;
    // Both refusals below are shown after the catalog load has awaited.
    final l10n = AppLocalizations.of(context);
    setState(() => _loadingVehicleCatalog = true);
    UsVehicleCatalog catalog;
    try {
      _vehicleCatalogFuture ??= ref.read(usVehicleCatalogLoaderProvider)();
      catalog = await _vehicleCatalogFuture!;
    } on UsVehicleCatalogException {
      _vehicleCatalogFuture = null;
      if (!mounted) return;
      setState(() => _loadingVehicleCatalog = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.settingsCatalogCorrupt)));
      return;
    } on Object catch (error, stack) {
      _vehicleCatalogFuture = null;
      if (mounted) setState(() => _loadingVehicleCatalog = false);
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'Telltale vehicle catalog',
          context: ErrorDescription(
            'while loading the bundled vehicle catalog',
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _loadingVehicleCatalog = false);
    final configuration = await showModalBottomSheet<UsEpaVehicleConfiguration>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _UsEpaVehiclePicker(catalog: catalog),
    );
    if (configuration == null || !mounted) return;
    final application = applyUsEpaConfiguration(
      catalog,
      epaId: configuration.epaId,
      baseProfile: ref.read(vehicleProfileProvider),
    );
    if (application.verifiedFieldKeys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsCatalogNothingApplicable)),
      );
      return;
    }
    await ref.read(vehicleProfileProvider.notifier).update(application.profile);
  }

  Future<void> _setExperimentalBatteryAccess(bool enabled) async {
    // Every string below is chosen after an await, and the consent dialog runs
    // under its own builder context. Reading the localizations once, here,
    // keeps the whole gate in the language that was on screen when the switch
    // was tapped.
    final l10n = AppLocalizations.of(context);
    if (!enabled) {
      ref
          .read(powertrainExperimentalProbeConsentsProvider.notifier)
          .revokeAll();
      try {
        await ref
            .read(powertrainBatteryExperimentalAccessProvider.notifier)
            .setEnabled(false);
      } on Object {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsBatteryLabDisableNotSaved)),
        );
      }
      return;
    }

    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) {
        var evidenceAcknowledged = false;
        var wireAcknowledged = false;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(l10n.settingsBatteryLabDialogTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.settingsBatteryLabDialogBody),
                  const SizedBox(height: Spacing.md),
                  CheckboxListTile(
                    key: const Key('experimental_evidence_ack'),
                    value: evidenceAcknowledged,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(l10n.settingsBatteryLabEvidenceAck),
                    onChanged: (value) => setDialogState(
                      () => evidenceAcknowledged = value ?? false,
                    ),
                  ),
                  CheckboxListTile(
                    key: const Key('experimental_wire_ack'),
                    value: wireAcknowledged,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(l10n.settingsBatteryLabWireAck),
                    onChanged: (value) =>
                        setDialogState(() => wireAcknowledged = value ?? false),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.settingsCancel),
              ),
              FilledButton(
                key: const Key('enable_experimental_battery_access'),
                onPressed: evidenceAcknowledged && wireAcknowledged
                    ? () => Navigator.pop(context, true)
                    : null,
                child: Text(l10n.settingsBatteryLabUnlockReadOnly),
              ),
            ],
          ),
        );
      },
    );
    if (accepted != true || !mounted) return;
    try {
      await ref
          .read(powertrainBatteryExperimentalAccessProvider.notifier)
          .setEnabled(true);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsBatteryLabEnableNotSaved)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final profile = ref.watch(vehicleProfileProvider);
    final themeMode = ref.watch(themeModeProvider);
    final connection = ref.watch(obdSessionProvider);
    final identity = ref.watch(vehicleIdentityProvider);
    final experimentalBatteryAccess = ref.watch(
      powertrainBatteryExperimentalAccessProvider,
    );
    final connected = connection.isConnected;

    void update(VehicleProfile next) =>
        ref.read(vehicleProfileProvider.notifier).update(next);

    return Scaffold(
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
            Text(l10n.settingsHeadline, style: context.texts.headlineMedium),
            const SizedBox(height: Spacing.xl),

            SectionHeading(l10n.settingsConnectionSection),
            Panel(
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        connection.isConnected ? Icons.link : Icons.link_off,
                        size: 18,
                        color: connection.isConnected
                            ? palette.success
                            : palette.textTertiary,
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              connection.isConnected
                                  ? connection.deviceName
                                  : l10n.settingsNotConnected,
                              style: context.texts.titleSmall,
                            ),
                            if (connection.protocol.isNotEmpty)
                              Text(
                                connection.protocol,
                                style: context.texts.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: connection.isConnected
                        ? OutlinedButton.icon(
                            onPressed: () async {
                              await ref
                                  .read(obdSessionProvider.notifier)
                                  .disconnect();
                              if (context.mounted) {
                                context.go(ConnectScreen.path);
                              }
                            },
                            icon: const Icon(Icons.link_off, size: 18),
                            label: Text(l10n.settingsDisconnect),
                          )
                        : FilledButton.icon(
                            onPressed: () => context.go(ConnectScreen.path),
                            icon: const Icon(Icons.link, size: 18),
                            label: Text(l10n.settingsGoToConnect),
                          ),
                  ),
                  const SizedBox(height: Spacing.md),
                  _VehicleIdentityPanel(
                    identity: identity,
                    connected: connected,
                    simulated: connection.kind == TransportKind.demo,
                    reading: _readingVin,
                    onRefresh: _refreshVin,
                  ),
                ],
              ),
            ),

            const SizedBox(height: Spacing.xl),
            SectionHeading(l10n.settingsVehicleProfileSection),
            Panel(
              child: Column(
                children: [
                  Text(
                    l10n.settingsProfileEstimatesIntro,
                    style: context.texts.bodySmall,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    l10n.settingsProfileNameProvesNothing,
                    style: context.texts.bodySmall,
                  ),
                  const SizedBox(height: Spacing.sm),
                  _ProfileProvenanceSummary(profile: profile),
                  const SizedBox(height: Spacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loadingVehicleCatalog
                          ? null
                          : _selectOfficialVehicle,
                      icon: const Icon(Icons.directions_car_outlined, size: 18),
                      label: Text(
                        _loadingVehicleCatalog
                            ? l10n.settingsCatalogVerifying
                            : l10n.settingsCatalogChoose,
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    l10n.settingsCatalogScope,
                    style: context.texts.bodySmall,
                  ),
                  const SizedBox(height: Spacing.md),
                  _ProfileConfirmationStatus(
                    profile: profile,
                    connected: connected,
                  ),
                  const SizedBox(height: Spacing.lg),
                  _SliderRow(
                    label: l10n.settingsFieldDisplacement,
                    value: profile.displacementL,
                    min: VehicleProfile.minDisplacementL,
                    max: VehicleProfile.maxDisplacementL,
                    divisions: 79,
                    format: (v) => '${v.toStringAsFixed(1)} L',
                    onChanged: (v) =>
                        update(profile.copyWith(displacementL: v)),
                  ),
                  _SliderRow(
                    label: l10n.settingsFieldMassWithDriver,
                    value: profile.massKg,
                    min: VehicleProfile.minMassKg,
                    max: VehicleProfile.maxMassKg,
                    divisions: 58,
                    format: (v) => '${v.round()} kg',
                    onChanged: (v) => update(profile.copyWith(massKg: v)),
                  ),
                  _SliderRow(
                    label: l10n.settingsFieldVolumetricEfficiency,
                    value: profile.volumetricEfficiency,
                    min: VehicleProfile.minVolumetricEfficiency,
                    max: VehicleProfile.maxVolumetricEfficiency,
                    divisions: 80,
                    format: (v) => '${v.round()} %',
                    onChanged: (v) =>
                        update(profile.copyWith(volumetricEfficiency: v)),
                  ),
                  _SliderRow(
                    label: l10n.settingsFieldDragCoefficient,
                    value: profile.dragCoefficient,
                    min: VehicleProfile.minDragCoefficient,
                    max: VehicleProfile.maxDragCoefficient,
                    divisions: 45,
                    format: (v) => v.toStringAsFixed(2),
                    onChanged: (v) =>
                        update(profile.copyWith(dragCoefficient: v)),
                  ),
                  _SliderRow(
                    label: l10n.settingsFieldFrontalArea,
                    value: profile.frontalAreaM2,
                    min: VehicleProfile.minFrontalAreaM2,
                    max: VehicleProfile.maxFrontalAreaM2,
                    divisions: 26,
                    format: (v) => '${v.toStringAsFixed(1)} m²',
                    onChanged: (v) =>
                        update(profile.copyWith(frontalAreaM2: v)),
                  ),
                  _SliderRow(
                    label: l10n.settingsFieldRollingResistance,
                    value: profile.rollingResistance,
                    min: VehicleProfile.minRollingResistance,
                    max: VehicleProfile.maxRollingResistance,
                    divisions: 24,
                    format: (v) => v.toStringAsFixed(3),
                    onChanged: (v) =>
                        update(profile.copyWith(rollingResistance: v)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Spacing.lg),
            SectionHeading(l10n.settingsFuelAndDrivetrainSection),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingsFuelTypeLabel,
                    style: context.texts.labelSmall,
                  ),
                  const SizedBox(height: Spacing.sm),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: [
                      for (final fuel in FuelType.values)
                        ChoiceChip(
                          selected: profile.fuelType == fuel,
                          onSelected: (_) =>
                              update(profile.copyWith(fuelType: fuel)),
                          label: Text(fuelTypeLabel(l10n, fuel)),
                          showCheckmark: false,
                          selectedColor: palette.accent.withValues(alpha: 0.16),
                          labelStyle: context.texts.labelMedium?.copyWith(
                            color: profile.fuelType == fuel
                                ? palette.accent
                                : palette.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    l10n.settingsFuelAfrAndDensity(
                      profile.stoichAfr,
                      profile.fuelDensityGPerL.round(),
                    ),
                    style: context.texts.bodySmall,
                  ),
                  const SizedBox(height: Spacing.lg),
                  Text(
                    l10n.settingsFieldDrivetrain,
                    style: context.texts.labelSmall,
                  ),
                  const SizedBox(height: Spacing.sm),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: [
                      for (final drivetrain in Drivetrain.values)
                        ChoiceChip(
                          selected: profile.drivetrain == drivetrain,
                          onSelected: (_) =>
                              update(profile.copyWith(drivetrain: drivetrain)),
                          label: Text(drivetrainLabel(l10n, drivetrain)),
                          showCheckmark: false,
                          selectedColor: palette.accent.withValues(alpha: 0.16),
                          labelStyle: context.texts.labelMedium?.copyWith(
                            color: profile.drivetrain == drivetrain
                                ? palette.accent
                                : palette.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    l10n.settingsDrivetrainEfficiency(
                      (profile.drivetrainEfficiency * 100).round(),
                    ),
                    style: context.texts.bodySmall,
                  ),
                  const SizedBox(height: Spacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          !connected ||
                              profile.isConfirmed ||
                              !profile.hasValidAssumptions
                          ? null
                          : () => ref
                                .read(vehicleProfileProvider.notifier)
                                .confirm(),
                      icon: Icon(
                        profile.isConfirmed
                            ? Icons.verified
                            : Icons.fact_check_outlined,
                        size: 18,
                      ),
                      label: Text(
                        profile.isConfirmed
                            ? l10n.settingsProfileConfirmedButton
                            : connected
                            ? l10n.settingsProfileConfirmButton
                            : l10n.settingsProfileConfirmAfterConnect,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Spacing.lg),
            SectionHeading(l10n.settingsDiagnosticsSection),
            const RecoveredTranscriptPanel(),
            const _AdapterIdentityPanel(),
            FieldEventMarkerPanel(
              enabled: connected && connection.kind != TransportKind.demo,
              onRecord: ref.read(obdSessionProvider.notifier).recordFieldEvent,
            ),
            const SizedBox(height: Spacing.md),
            const Panel(child: TranscriptExportButtons()),
            const SizedBox(height: Spacing.md),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingsManualCommandTitle,
                    style: context.texts.titleSmall,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    l10n.settingsManualCommandBody,
                    style: context.texts.bodySmall,
                  ),
                  const SizedBox(height: Spacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commandController,
                          enabled: connected && !_sending,
                          autocorrect: false,
                          enableSuggestions: false,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: l10n.settingsManualCommandFieldLabel,
                            // A wire command, not copy: ATI in both languages.
                            hintText: 'ATI',
                          ),
                          onSubmitted: (_) => _sendManual(),
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      FilledButton(
                        onPressed: connected && !_sending ? _sendManual : null,
                        child: Text(l10n.settingsManualCommandSend),
                      ),
                    ],
                  ),
                  if (_commandResult != null) ...[
                    const SizedBox(height: Spacing.sm),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(Spacing.sm),
                      decoration: BoxDecoration(
                        color: palette.surfaceAlt,
                        borderRadius: BorderRadius.circular(Radii.sm),
                      ),
                      child: SelectableText(
                        _commandResult!,
                        style: context.texts.bodySmall?.copyWith(
                          fontFeatures: const [],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: Spacing.lg),
            SectionHeading(l10n.settingsExperimentalSection),
            Panel(
              child: SwitchListTile(
                key: const Key('experimental_battery_access_switch'),
                contentPadding: EdgeInsets.zero,
                value: experimentalBatteryAccess,
                onChanged: _setExperimentalBatteryAccess,
                title: Text(l10n.settingsBatteryLabSwitchTitle),
                subtitle: Text(l10n.settingsBatteryLabSwitchSubtitle),
              ),
            ),

            const SizedBox(height: Spacing.lg),
            SectionHeading(l10n.languageSectionTitle),
            const Panel(child: LanguagePicker(showHeading: false)),

            const SizedBox(height: Spacing.lg),
            SectionHeading(l10n.appearanceSectionTitle),
            Panel(
              child: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(l10n.settingsThemeDark),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(l10n.settingsThemeLight),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(l10n.settingsThemeSystem),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (s) =>
                    ref.read(themeModeProvider.notifier).set(s.first),
                showSelectedIcon: false,
              ),
            ),
            const SizedBox(height: Spacing.md),
            const _GaugeSkinPicker(),

            const SizedBox(height: Spacing.xl),
            RecommendedPurchasePanel(onOpen: widget.onOpenRecommendedPurchase),
            const SizedBox(height: Spacing.lg),
            OutlinedButton.icon(
              key: const Key('open_source_licenses'),
              onPressed: () {
                registerPowertrainBatteryLicenses();
                showLicensePage(
                  context: context,
                  // The product name, not copy.
                  applicationName: 'Telltale',
                  applicationLegalese: l10n.settingsLicenseLegalese,
                );
              },
              icon: const Icon(Icons.description_outlined),
              label: Text(l10n.settingsOpenSourceLicenses),
            ),
            const SizedBox(height: Spacing.md),
            Text(l10n.settingsStandardsFooter, style: context.texts.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _UsEpaVehiclePicker extends StatefulWidget {
  const _UsEpaVehiclePicker({required this.catalog});

  final UsVehicleCatalog catalog;

  @override
  State<_UsEpaVehiclePicker> createState() => _UsEpaVehiclePickerState();
}

class _UsEpaVehiclePickerState extends State<_UsEpaVehiclePicker> {
  int? _year;
  String? _make;
  String? _model;
  UsEpaVehicleConfiguration? _configuration;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final years = widget.catalog.years.reversed.toList(growable: false);
    final makes = _year == null
        ? const <String>[]
        : widget.catalog.makes(year: _year);
    final models = _year == null || _make == null
        ? const <String>[]
        : widget.catalog.models(year: _year!, make: _make!);
    final configurations = _year == null || _make == null || _model == null
        ? const <UsEpaVehicleConfiguration>[]
        : widget.catalog.configurations(
            year: _year!,
            make: _make!,
            model: _model!,
          );
    final application = _configuration == null
        ? null
        : applyUsEpaConfiguration(widget.catalog, epaId: _configuration!.epaId);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.86,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.settingsEpaPickerTitle,
                      style: context.texts.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: l10n.settingsClose,
                  ),
                ],
              ),
              Text(
                // Both bounds come from the snapshot that was actually loaded.
                // Spelling 1984 into the sentence made a second copy of a
                // bound the catalog already carries.
                l10n.settingsEpaPickerScope(
                  widget.catalog.years.first,
                  widget.catalog.years.last,
                ),
                style: context.texts.bodySmall,
              ),
              const SizedBox(height: Spacing.md),
              _CatalogDropdown<int>(
                dropdownKey: const Key('us_epa_year'),
                label: l10n.settingsEpaYear,
                value: _year,
                values: years,
                display: (value) => '$value',
                onChanged: (value) => setState(() {
                  _year = value;
                  _make = null;
                  _model = null;
                  _configuration = null;
                }),
              ),
              const SizedBox(height: Spacing.sm),
              _CatalogDropdown<String>(
                dropdownKey: const Key('us_epa_make'),
                label: l10n.settingsEpaMake,
                value: _make,
                values: makes,
                display: (value) => value,
                onChanged: _year == null
                    ? null
                    : (value) => setState(() {
                        _make = value;
                        _model = null;
                        _configuration = null;
                      }),
              ),
              const SizedBox(height: Spacing.sm),
              _CatalogDropdown<String>(
                dropdownKey: const Key('us_epa_model'),
                label: l10n.settingsEpaModel,
                value: _model,
                values: models,
                display: (value) => value,
                onChanged: _make == null
                    ? null
                    : (value) => setState(() {
                        _model = value;
                        _configuration = null;
                      }),
              ),
              const SizedBox(height: Spacing.md),
              Expanded(
                child: configurations.isEmpty
                    ? Center(
                        child: Text(
                          _model == null
                              ? l10n.settingsEpaPickInOrder
                              : l10n.settingsEpaNoConfigurations,
                          style: context.texts.bodySmall,
                        ),
                      )
                    : ListView.separated(
                        itemCount: configurations.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: Spacing.xs),
                        itemBuilder: (context, index) {
                          final item = configurations[index];
                          final selected = item.epaId == _configuration?.epaId;
                          return ListTile(
                            key: Key('us_epa_config_${item.epaId}'),
                            selected: selected,
                            onTap: () => setState(() => _configuration = item),
                            leading: Icon(
                              selected
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                            ),
                            title: Text(_configurationTitle(l10n, item)),
                            subtitle: Text(
                              '${item.alternativeVehicleType.isEmpty ? '' : '${item.alternativeVehicleType} · '}'
                              '${item.fuelType.isEmpty ? l10n.settingsEpaFuelUnknown : item.fuelType} · '
                              '${item.drive.isEmpty ? l10n.settingsEpaDriveUnknown : item.drive} · '
                              'EPA ID ${item.epaId}',
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: Spacing.sm),
              if (application != null)
                Text(
                  application.verifiedFieldKeys.isEmpty
                      ? l10n.settingsEpaNoSafeFields
                      : l10n.settingsEpaWillApplyOnly(
                          _verifiedFieldLabels(
                            l10n,
                            application.verifiedFieldKeys,
                          ),
                        ),
                  style: context.texts.bodySmall,
                ),
              const SizedBox(height: Spacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _configuration == null
                      ? null
                      : application!.verifiedFieldKeys.isEmpty
                      ? () => Navigator.pop(context)
                      : () => Navigator.pop(context, _configuration),
                  child: Text(
                    application == null
                        ? l10n.settingsEpaChooseExact
                        : application.verifiedFieldKeys.isEmpty
                        ? l10n.settingsEpaCloseNoFields
                        : l10n.settingsEpaApplyFields(
                            application.verifiedFieldKeys.length,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Takes the localizations rather than a `BuildContext`: it is static, and
  /// a context parameter would exist only so this could reach for one.
  static String _configurationTitle(
    AppLocalizations l10n,
    UsEpaVehicleConfiguration item,
  ) {
    final parts = <String>[
      // Litres, the transmission code and the EPA id are data and units.
      if (item.displacementL != null) '${item.displacementL} L',
      if (item.cylinders != null) l10n.settingsEpaCylinders(item.cylinders!),
      if (item.transmission.isNotEmpty) item.transmission,
    ];
    return parts.isEmpty
        ? l10n.settingsEpaConfiguration(item.epaId)
        : parts.join(' · ');
  }

  static String _verifiedFieldLabels(AppLocalizations l10n, Set<String> keys) =>
      [
        if (keys.contains('displacementL')) l10n.settingsFieldDisplacement,
        if (keys.contains('fuelType')) l10n.settingsFuelTypeLabel,
      ].join(l10n.settingsListSeparator);
}

class _CatalogDropdown<T> extends StatelessWidget {
  const _CatalogDropdown({
    required this.dropdownKey,
    required this.label,
    required this.value,
    required this.values,
    required this.display,
    required this.onChanged,
  });

  final Key dropdownKey;
  final String label;
  final T? value;
  final List<T> values;
  final String Function(T value) display;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(labelText: label),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        key: dropdownKey,
        value: value,
        isExpanded: true,
        items: [
          for (final item in values)
            DropdownMenuItem(value: item, child: Text(display(item))),
        ],
        onChanged: onChanged,
      ),
    ),
  );
}

class _ProfileProvenanceSummary extends StatelessWidget {
  const _ProfileProvenanceSummary({required this.profile});

  final VehicleProfile profile;

  /// `VE`, `Cd` and `Crr` are symbols, not words. They are printed identically
  /// in both languages — on the sliders above, in the physics literature and
  /// in the session evidence file — so they are held here as literals rather
  /// than routed through the ARBs, where somebody would eventually translate
  /// one and make it unfindable.
  static const _symbolFieldLabels = <String, String>{
    'volumetricEfficiency': 'VE',
    'dragCoefficient': 'Cd',
    'rollingResistance': 'Crr',
  };

  /// Throws on an unknown key, exactly as the `!` on the map lookup it
  /// replaces did: a new profile field must be given a label rather than
  /// silently rendering as its Dart identifier.
  static String _fieldLabel(AppLocalizations l10n, String key) =>
      _symbolFieldLabels[key] ??
      switch (key) {
        'displacementL' => l10n.settingsFieldDisplacement,
        'massKg' => l10n.settingsFieldMass,
        'fuelType' => l10n.settingsFieldFuel,
        'drivetrain' => l10n.settingsFieldDrivetrain,
        'frontalAreaM2' => l10n.settingsFieldFrontalArea,
        _ => throw ArgumentError.value(
          key,
          'key',
          'vehicle profile field has no label',
        ),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fields = profile.inputFieldMap;
    final exact = fields.entries
        .where((entry) => entry.value.isVerifiedExact)
        .toList();
    final officialSourceCount = fields.values
        .where(
          (field) =>
              field.origin == VehicleFieldOrigin.officialRegistry ||
              field.origin == VehicleFieldOrigin.manufacturerPublication,
        )
        .length;
    final userSourceCount = fields.values
        .where((field) => field.origin == VehicleFieldOrigin.userEntered)
        .length;
    final genericSourceCount = fields.values
        .where((field) => field.origin == VehicleFieldOrigin.genericDefault)
        .length;
    final scientificSourceCount = fields.values
        .where((field) => field.origin == VehicleFieldOrigin.scientificModel)
        .length;
    int resolutionCount(EvidenceResolution resolution) =>
        fields.values.where((field) => field.resolution == resolution).length;
    final publishers =
        exact.map((entry) => entry.value.evidence!.publisher).toSet().toList()
          ..sort();
    final exactLabels = exact
        .map((entry) => _fieldLabel(l10n, entry.key))
        .join(l10n.settingsListSeparator);
    final exactEvidence = exact.isEmpty ? null : exact.first.value.evidence;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: context.palette.surfaceAlt,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.settingsProvenanceResolution(
              exact.length,
              resolutionCount(EvidenceResolution.userConfirmedSession),
              resolutionCount(EvidenceResolution.unknown),
              resolutionCount(EvidenceResolution.ambiguous),
              resolutionCount(EvidenceResolution.conflict),
              fields.length,
            ),
            style: context.texts.labelSmall,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            l10n.settingsProvenanceOrigins(
              officialSourceCount,
              userSourceCount,
              genericSourceCount,
              scientificSourceCount,
              fields.length,
            ),
            style: context.texts.labelSmall,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            exact.isEmpty
                ? l10n.settingsProvenanceNoneExact
                : l10n.settingsProvenanceOnlyExact(exactLabels),
            style: context.texts.bodySmall,
          ),
          if (publishers.isNotEmpty) ...[
            const SizedBox(height: Spacing.xs),
            Text(
              // Publisher names are data; only the label around them is copy.
              l10n.settingsProvenancePublishers(
                publishers.join(l10n.settingsListSeparator),
              ),
              style: context.texts.bodySmall,
            ),
          ],
          if (exactEvidence != null) ...[
            const SizedBox(height: Spacing.xs),
            Text(
              '${exactEvidence.year} ${exactEvidence.make} '
              '${exactEvidence.model} · ${exactEvidence.trim}',
              style: context.texts.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _VehicleIdentityPanel extends StatelessWidget {
  const _VehicleIdentityPanel({
    required this.identity,
    required this.connected,
    required this.simulated,
    required this.reading,
    required this.onRefresh,
  });

  final VehicleIdentity identity;
  final bool connected;
  final bool simulated;
  final bool reading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final (
      IconData icon,
      Color color,
      String title,
      String detail,
    ) = switch (identity.status) {
      VehicleIdentityStatus.notRead => (
        Icons.badge_outlined,
        palette.textSecondary,
        l10n.settingsVinNotRead,
        connected
            ? l10n.settingsVinNotReadConnectedDetail
            : l10n.settingsVinNotReadDisconnectedDetail,
      ),
      VehicleIdentityStatus.vehicleReported => (
        Icons.directions_car_outlined,
        palette.info,
        simulated
            ? l10n.settingsVinSimulatorReported
            : l10n.settingsVinVehicleReported,
        l10n.settingsVinReportedDetail,
      ),
      VehicleIdentityStatus.unavailable => (
        Icons.help_outline,
        palette.warning,
        l10n.settingsVinUnavailable,
        l10n.settingsVinUnavailableDetail,
      ),
      VehicleIdentityStatus.conflict => (
        Icons.warning_amber_outlined,
        palette.danger,
        l10n.settingsVinConflict,
        l10n.settingsVinConflictDetail,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: Spacing.sm),
              Expanded(child: Text(title, style: context.texts.titleSmall)),
              OutlinedButton(
                onPressed: connected && !reading ? onRefresh : null,
                child: Text(
                  reading ? l10n.settingsVinReading : l10n.settingsVinRead,
                ),
              ),
            ],
          ),
          if (identity.vin != null) ...[
            const SizedBox(height: Spacing.xs),
            SelectableText(
              identity.vin!,
              style: AppTypography.code(palette, color: color),
            ),
          ],
          const SizedBox(height: Spacing.xs),
          Text(detail, style: context.texts.bodySmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _ProfileConfirmationStatus extends StatelessWidget {
  const _ProfileConfirmationStatus({
    required this.profile,
    required this.connected,
  });

  final VehicleProfile profile;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final confirmed = profile.isConfirmed;
    final color = confirmed ? palette.success : palette.warning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            confirmed ? Icons.verified_outlined : Icons.info_outline,
            size: 18,
            color: color,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              confirmed
                  ? l10n.settingsProfileConfirmedDetail
                  : connected
                  ? l10n.settingsProfileUnconfirmedConnectedDetail
                  : l10n.settingsProfileUnconfirmedDisconnectedDetail,
              style: context.texts.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.format,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double) format;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: context.texts.bodyMedium)),
              Text(format(value), style: AppTypography.readout(palette, 15)),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// What the adapter says about itself, and where that fails to add up.
///
/// Here rather than on the dashboard, deliberately. `v1.5` is a firmware Elm
/// Electronics never released and it is printed on a very large share of the
/// adapters people actually buy — most of which work — so putting it in front
/// of a driver mid-drive would be an alarm that is wrong more often than
/// right. In a diagnostics section it is what it actually is: a fact about the
/// device, for the moment somebody is trying to work out why a reading looks
/// odd.
///
/// It is also careful not to imply more than it knows. This says nothing about
/// whether the *numbers* are true — no software can, without a second
/// independent measurement — and the copy says so rather than leaving a green
/// tick to be misread as a clean bill of health.
class _AdapterIdentityPanel extends ConsumerWidget {
  const _AdapterIdentityPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(obdSessionProvider);
    if (!session.isConnected) return const SizedBox.shrink();
    final identity = ref
        .read(obdSessionProvider.notifier)
        .engine
        ?.client
        .adapterIdentity;
    if (identity == null) return const SizedBox.shrink();

    final concerns = identity.concerns;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.settingsAdapterSelfReportTitle,
              style: context.texts.titleSmall,
            ),
            const SizedBox(height: Spacing.xs),
            SelectableText(
              identity.version.isEmpty
                  ? l10n.settingsAdapterNoVersion
                  : identity.version,
              style: context.texts.bodyMedium,
            ),
            if (identity.identity.isNotEmpty)
              SelectableText(identity.identity, style: context.texts.bodySmall),
            const SizedBox(height: Spacing.xs),
            if (concerns.isEmpty)
              Text(
                l10n.settingsAdapterNoContradictions,
                style: context.texts.bodySmall,
              )
            else ...[
              for (final concern in concerns) ...[
                Text(
                  '⚠ ${adapterConcernSummary(l10n, concern)}',
                  style: context.texts.bodyMedium,
                ),
                Text(
                  adapterConcernDetail(l10n, concern),
                  style: context.texts.bodySmall,
                ),
                const SizedBox(height: Spacing.xs),
              ],
              Text(
                l10n.settingsAdapterConcernsFooter,
                style: context.texts.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Choosing the instrument, by looking at it.
///
/// A list of five names would be five names. These are five genuinely
/// different dials — one has no needle, one draws blocks instead of a sweep,
/// one moves like a mechanical needle and two refuse to animate at all — and
/// none of that is conveyed by the word 極簡. So each option draws itself, at
/// a fixed value, using the real gauge with the real painter.
class _GaugeSkinPicker extends ConsumerWidget {
  const _GaugeSkinPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(gaugeSkinProvider);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.settingsGaugeSkinTitle, style: context.texts.titleSmall),
          const SizedBox(height: Spacing.xs),
          Text(l10n.settingsGaugeSkinBody, style: context.texts.bodySmall),
          const SizedBox(height: Spacing.md),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: GaugeSkin.all.length,
              separatorBuilder: (_, _) => const SizedBox(width: Spacing.sm),
              itemBuilder: (context, i) {
                final skin = GaugeSkin.all[i];
                final selected = skin.id == current.id;
                return _SkinChoice(
                  skin: skin,
                  selected: selected,
                  onTap: () => ref.read(gaugeSkinProvider.notifier).set(skin),
                );
              },
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            gaugeSkinDescription(l10n, current),
            style: context.texts.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SkinChoice extends StatelessWidget {
  const _SkinChoice({
    required this.skin,
    required this.selected,
    required this.onTap,
  });

  final GaugeSkin skin;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 132,
        padding: const EdgeInsets.all(Spacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? palette.accent : palette.hairline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The real gauge, under a theme carrying only this skin, so the
            // preview cannot drift from what selecting it produces.
            Expanded(
              child: Theme(
                data: Theme.of(context).copyWith(extensions: [palette, skin]),
                child: const IgnorePointer(
                  child: DialGauge(
                    label: 'RPM',
                    value: 2740,
                    minValue: 0,
                    maxValue: 8000,
                    units: 'rpm',
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              gaugeSkinName(AppLocalizations.of(context), skin),
              style: context.texts.labelMedium?.copyWith(
                color: selected ? palette.accent : palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
