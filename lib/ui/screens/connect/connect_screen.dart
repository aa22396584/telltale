/// Connection wizard — the app's front door.
///
/// Shows the four transports, then the live AT handshake as it runs. Surfacing
/// the handshake is not decoration: when an adapter fails, *which* step failed
/// is the whole diagnosis, and hiding it behind a spinner throws that away.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/serial/spp_serial_platform.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ble_scan_permissions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../obd/elm327_client.dart';
import '../../../state/pid_registry.dart' show sharedPreferencesProvider;
import '../../../obd/transport/ble_transport.dart';
import '../../../obd/transport/classic_transport.dart';
import '../../../obd/transport/obd_transport.dart';
import '../../../obd/transport/serial_transport.dart';
import '../../../obd/transport/wifi_transport.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../state/obd_session.dart';
import '../../../state/settings.dart';
import '../../widgets/language_picker.dart';
import '../../widgets/panel.dart';
import '../../widgets/telemetry/telemetry_connect_recorder_status.dart';
import 'handshake_copy.dart';
import '../../widgets/telemetry/telemetry_history_entry.dart';
import '../../widgets/telemetry/telemetry_startup_recovery_notice.dart';
import '../../widgets/transcript_export.dart';
import '../../widgets/recommended_purchase_panel.dart';
import '../dashboard/dashboard_screen.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({
    this.onOpenRecommendedPurchase,
    this.onOpenRecommendedPurchaseDisclosure,
    super.key,
  });

  static const String path = '/';

  /// Tests inject this so a tap does not leave the process.
  @visibleForTesting
  final OpenRecommendedPurchase? onOpenRecommendedPurchase;

  /// Tests inject this so a tap does not need a GoRouter.
  @visibleForTesting
  final VoidCallback? onOpenRecommendedPurchaseDisclosure;

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  TransportKind? _expanded;
  List<DiscoveredDevice> _devices = const [];
  bool _scanning = false;
  String? _scanError;

  /// Remembered between launches.
  ///
  /// A Wi-Fi ELM327 hands out an address on its own hotspot, and it is rarely
  /// the shipped default. Re-typing an IP address is a poor thing to ask of
  /// someone sitting in a car every single time they open the app — and the
  /// keyboard for it is the numeric one, in a moving vehicle.
  static const _kWifiHostKey = 'wifi_host';
  static const _kWifiPortKey = 'wifi_port';

  /// The range the connect check enforces, and the only source for the range
  /// the error message quotes. Spelling "1–65535" into the sentence would
  /// create a second copy of a bound that is free to drift from the one the
  /// code actually tests.
  static const _kMinPort = 1;
  static const _kMaxPort = 65535;

  late final TextEditingController _hostController;
  late final TextEditingController _portController;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    _hostController = TextEditingController(
      text: prefs.getString(_kWifiHostKey) ?? WifiTransport.defaultHost,
    );
    _portController = TextEditingController(
      text: '${prefs.getInt(_kWifiPortKey) ?? WifiTransport.defaultPort}',
    );
  }

  /// Records which adapter was chosen, so the next launch can offer it first.
  ///
  /// On attempt, not on success. An adapter that failed once is still
  /// overwhelmingly the one that was meant, and the retry is exactly when not
  /// having to find it again in a list of headphones matters most — the same
  /// rule the Wi-Fi address above already follows.
  void _rememberAdapter(DiscoveredDevice device) =>
      _rememberAdapterRaw(id: device.id, name: device.name, kind: device.kind);

  void _rememberAdapterRaw({
    required String id,
    required String name,
    required TransportKind kind,
    int? port,
  }) {
    unawaited(
      ref
          .read(lastAdapterProvider.notifier)
          .remember(LastAdapter(id: id, name: name, kind: kind, port: port)),
    );
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  bool get _classicAvailable => classicTransportAvailable;

  bool get _bleAvailable => bleTransportAvailable;

  Future<void> _select(TransportKind kind) async {
    if (kind == TransportKind.bluetoothClassic && !_classicAvailable) return;
    if (kind == TransportKind.bluetoothLe && !_bleAvailable) return;
    setState(() {
      _expanded = _expanded == kind ? null : kind;
      _devices = const [];
      _scanError = null;
    });
    if (_expanded == TransportKind.bluetoothClassic) {
      await _loadPairedDevices();
    }
  }

  /// Acquires exactly the permissions the next action needs, and no others.
  ///
  /// The two actions have genuinely different requirements, and treating them
  /// as one had consequences in both directions:
  ///
  ///   * **Listing and connecting to a bonded adapter** needs
  ///     `BLUETOOTH_CONNECT` on Android 12+, and nothing at runtime below that
  ///     — `BLUETOOTH` and `BLUETOOTH_ADMIN` are install-time. It never needs
  ///     location on any version. Asking for it anyway meant a user on
  ///     Android 11 could not reach an adapter they had already paired unless
  ///     they also handed over their location.
  ///   * **Discovering an adapter nobody has paired yet** needs
  ///     `BLUETOOTH_SCAN` on 12+, and *is* gated behind location below that.
  ///
  /// The old code also let a granted location permission stand in for a
  /// permanently denied Bluetooth one: it returned true, the plugin failed
  /// later with something unhelpful, and the settings-recovery affordance was
  /// never offered because nothing had recorded the denial.
  /// The version-aware rule itself lives in [ensureBluetoothPermissions] so
  /// the wear shell shares it instead of growing a weaker copy; this wrapper
  /// only maps the outcome onto this screen's recovery affordances.
  Future<bool> _ensurePermissions({required bool forScanning}) async {
    _permissionPermanentlyDenied = false;
    final result = await ensureBluetoothPermissions(forScanning: forScanning);
    if (result.granted) return true;
    _permissionPermanentlyDenied =
        result.outcome == BlePermissionOutcome.permanentlyDenied;
    return false;
  }

  /// Set when the user has chosen "don't ask again". Every later request is
  /// auto-denied by the system, so the only way out is the settings screen —
  /// without offering it, the wizard is a dead end.
  bool _permissionPermanentlyDenied = false;

  // `BlePermissionResult.deniedLabel` is deliberately not read here. It
  // carries a fixed Chinese word chosen in the permission layer, which cannot
  // be localized from this screen, and it would name nothing new: the only
  // caller that shows it lists bonded adapters with `forScanning: false`, and
  // that path never requests location — the refusal is always the Bluetooth
  // one. The messages below say so outright instead of interpolating it.

  Future<void> _loadPairedDevices() async {
    // Read before the first await. Every await below can outlive the screen,
    // and the message belongs to the language that was on screen when the
    // user asked for the list.
    final l10n = AppLocalizations.of(context);
    setState(() {
      _scanning = true;
      _scanError = null;
    });
    try {
      // Windows/Linux Classic is Bluetooth SPP serial (COM / rfcomm).
      // Android / macOS list bonded Classic devices via ClassicTransport.
      // Empty enumeration is an emptyHint (not _scanError): showing both used
      // to stack two paragraphs that said the same thing in different words.
      if (sppSerialHostSupported) {
        final devices = await SerialTransport.bluetoothSppDevices();
        if (!mounted) return;
        setState(() => _devices = _likelyAdaptersFirst(devices));
        return;
      }
      // Each of these awaits can outlive the screen — the permission dialog in
      // particular sits in front of the app for as long as the user ignores it.
      // Listing bonded devices is not a scan, and must not ask as if it were.
      if (!await _ensurePermissions(forScanning: false)) {
        if (!mounted) return;
        setState(
          () => _scanError = _permissionPermanentlyDenied
              ? l10n.connectBluetoothPermissionDeniedForever
              : l10n.connectBluetoothPermissionNeededForPairedList,
        );
        return;
      }
      if (!await ClassicTransport.isAdapterEnabled()) {
        if (!mounted) return;
        setState(() => _scanError = l10n.connectBluetoothOff);
        return;
      }
      final devices = await ClassicTransport.pairedDevices();
      if (!mounted) return;
      setState(() => _devices = _likelyAdaptersFirst(devices));
    } on Object catch (e) {
      if (mounted) setState(() => _scanError = '$e');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  /// Names that ELM327 adapters are commonly sold under.
  ///
  /// Android will not let an app bond from inside a normal activity, so this
  /// list is every bonded device on the phone: headphones, speakers, a game
  /// controller, a desktop. Choosing one of those walks the whole three-tier
  /// connection cascade before failing, which is around half a minute of
  /// nothing happening.
  ///
  /// They are sorted, not filtered. The plugin does not report Class of Device
  /// — which is what a real filter would need — and guessing from a name would
  /// eventually hide someone's adapter because they renamed it. Sorting costs
  /// nothing when the guess is wrong.
  static const _adapterNameHints = [
    'obd',
    'elm',
    'obdii',
    'obd2',
    'vgate',
    'vlink',
    'viecar',
    'konnwei',
    'veepeak',
    'carista',
  ];

  static bool _looksLikeAdapter(DiscoveredDevice device) {
    final name = device.name.toLowerCase();
    return _adapterNameHints.any(name.contains);
  }

  static List<DiscoveredDevice> _likelyAdaptersFirst(
    List<DiscoveredDevice> devices,
  ) {
    final likely = devices.where(_looksLikeAdapter).toList();
    final rest = devices.where((d) => !_looksLikeAdapter(d)).toList();
    return [...likely, ...rest];
  }

  String? _wifiError;

  /// Validates before connecting rather than silently substituting a default.
  ///
  /// An empty or malformed port used to parse to null, and `connectWifi` then
  /// fell back to 35000 — so the field said one thing and the app did another,
  /// and a failed connection sent the user looking at their adapter instead of
  /// at the box they had just cleared.
  Future<void> _connectWifi() async {
    // Before the awaits below, for the same reason as `_loadPairedDevices`.
    final l10n = AppLocalizations.of(context);
    final host = _hostController.text.trim();
    final portText = _portController.text.trim();
    final port = int.tryParse(portText);

    String? error;
    if (host.isEmpty) {
      error = l10n.connectWifiHostRequired;
    } else if (portText.isEmpty) {
      error = l10n.connectWifiPortRequired(WifiTransport.defaultPort);
    } else if (port == null || port < _kMinPort || port > _kMaxPort) {
      error = l10n.connectWifiPortInvalid(portText, _kMinPort, _kMaxPort);
    }

    setState(() => _wifiError = error);
    if (error != null) return;

    // Stored on attempt rather than on success: an address that failed once is
    // still far more likely to be the right starting point next time than the
    // shipped default, and being made to retype it after a failure is exactly
    // when it is most annoying.
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kWifiHostKey, host);
    await prefs.setInt(_kWifiPortKey, port!);
    // Also recorded as *the* last adapter, so the shortcut at the top of this
    // screen covers Wi-Fi too. The fields above already remember the address;
    // what the card adds is not having to expand the section and press connect
    // — which is two taps and a scroll, in a car.
    _rememberAdapterRaw(
      id: host,
      name: 'Wi-Fi $host',
      kind: TransportKind.wifi,
      port: port,
    );

    await _connect(
      () => ref
          .read(obdSessionProvider.notifier)
          .connectWifi(host: host, port: port),
    );
  }

  Future<void> _connect(Future<bool> Function() action) async {
    final ok = await action();
    if (!mounted) return;
    if (ok) {
      context.go(DashboardScreen.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final connection = ref.watch(obdSessionProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(connection: connection)),
            const SliverToBoxAdapter(child: TelemetryConnectRecorderStatus()),
            const SliverToBoxAdapter(child: TelemetryStartupRecoveryNotice()),
            if (!connection.isBusy)
              const SliverToBoxAdapter(child: TelemetryHistoryEntry()),
            // Above the transport list, because on the second and every later
            // visit this is the only row that matters. The list below is a
            // phone's bonded devices — mostly headphones — and finding the one
            // adapter in it again, in a car park, every time, is the
            // difference between a tool and a chore.
            // The recording from the session that did not survive, offered
            // where somebody actually lands.
            //
            // It was only in Settings, and the store's own comment claimed it
            // was "offered back on the next launch" — which nothing did. The
            // sequence this exists for ends with the phone killing the app in
            // a car park; the next thing that happens is this screen, and a
            // recovery that has to be gone looking for is one that is not
            // found. It renders nothing when there is nothing stored.
            if (!connection.isConnected && !connection.isBusy)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: Spacing.lg),
                  child: RecoveredTranscriptPanel(),
                ),
              ),
            if (!connection.isConnected && !connection.isBusy)
              const SliverToBoxAdapter(child: _LastAdapterCard()),
            // Only on the first visit, when there is nothing remembered. Once
            // the shortcut above exists this question is already answered, and
            // a permanent "which one is mine?" panel would be advice nobody
            // needs occupying the top of the screen every time.
            if (!connection.isConnected && !connection.isBusy)
              const SliverToBoxAdapter(child: _WhichTransportCard()),
            // Kept visible after a failure too, because *which* command died
            // is the whole diagnosis and hiding it throws that away. What was
            // wrong before was the framing: a fully green step list sat
            // directly above a red "disconnected" banner and the two flatly
            // contradicted each other. The panel now says which attempt it
            // describes, so it reads as history rather than as current state.
            if (connection.isBusy || connection.initSteps.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    0,
                    Spacing.lg,
                    Spacing.lg,
                  ),
                  child: _HandshakePanel(connection: connection),
                ),
              ),
            if (connection.error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    0,
                    Spacing.lg,
                    Spacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ErrorBanner(
                        message:
                            connectionIssueText(
                              AppLocalizations.of(context),
                              connection,
                            ) ??
                            connection.error!,
                      ),
                      const SizedBox(height: Spacing.md),
                      // Where the failure is, not two screens away behind a
                      // connection that does not exist. This is the moment the
                      // recording was made for.
                      Text(
                        AppLocalizations.of(context).connectTranscriptKept,
                        style: context.texts.bodySmall,
                      ),
                      const SizedBox(height: Spacing.sm),
                      const TranscriptExportButtons(compact: true),
                    ],
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                0,
                Spacing.lg,
                Spacing.lg,
              ),
              sliver: SliverList.separated(
                itemCount: TransportKind.values.length,
                separatorBuilder: (_, _) => const SizedBox(height: Spacing.md),
                itemBuilder: (context, index) {
                  final kind = TransportKind.values[index];
                  final unavailable = switch (kind) {
                    TransportKind.bluetoothClassic => !_classicAvailable,
                    TransportKind.bluetoothLe => !_bleAvailable,
                    _ => false,
                  };
                  final disabledReason = switch (kind) {
                    TransportKind.bluetoothClassic when unavailable =>
                      classicUnavailableReason(l10n),
                    TransportKind.bluetoothLe when unavailable =>
                      bleUnavailableReason(l10n),
                    _ => null,
                  };
                  return _TransportCard(
                    kind: kind,
                    isExpanded: _expanded == kind,
                    isDisabled: unavailable || connection.isBusy,
                    disabledReason: disabledReason,
                    onTap: () => _select(kind),
                    child: _bodyFor(kind, l10n),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.md,
                  Spacing.lg,
                  Spacing.xxl,
                ),
                child: RecommendedPurchaseLink(
                  onOpen: widget.onOpenRecommendedPurchase,
                  onOpenDisclosure:
                      widget.onOpenRecommendedPurchaseDisclosure ??
                      () => context.go('/settings'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bodyFor(TransportKind kind, AppLocalizations l10n) {
    return switch (kind) {
      TransportKind.demo => _DemoBody(
        onConnect: () =>
            _connect(() => ref.read(obdSessionProvider.notifier).connectDemo()),
      ),
      TransportKind.wifi => _WifiBody(
        hostController: _hostController,
        portController: _portController,
        error: _wifiError,
        onConnect: _connectWifi,
      ),
      TransportKind.bluetoothClassic => _DeviceListBody(
        devices: _devices,
        scanning: _scanning,
        error: _scanError,
        emptyHint: classicDeviceListEmptyHint(
          l10n,
          serialHost: sppSerialHostSupported,
        ),
        // Bonded-device hosts (Android/macOS): cancel-early copy matters
        // because a wrong headphone row burns connection cascade time.
        // SPP serial hosts (Windows/Linux): the list is COM/rfcomm nodes —
        // never claim headphones appear here.
        listHint: classicDeviceListHint(
          l10n,
          serialHost: sppSerialHostSupported,
        ),
        showSettingsAction: _permissionPermanentlyDenied,
        onRefresh: _loadPairedDevices,
        onSelect: (device) => _connect(() {
          _rememberAdapter(device);
          return ref.read(obdSessionProvider.notifier).connectClassic(device);
        }),
      ),
      TransportKind.bluetoothLe => _BleBody(
        onConnect: (device) => _connect(() {
          _rememberAdapterRaw(
            id: device.id,
            name: device.name,
            kind: TransportKind.bluetoothLe,
          );
          return ref.read(obdSessionProvider.notifier).connectBle(device);
        }),
        ensurePermissions: () => _ensurePermissions(forScanning: true),
        // Classic already offered this. Without it the BLE screen was a dead
        // end: once "don't ask again" is chosen the system auto-denies every
        // later request, so recoverable configuration looked permanently
        // broken with no route out.
        isPermanentlyDenied: () => _permissionPermanentlyDenied,
      ),
    };
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.connection});

  final ObdConnectionState connection;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.xxl,
        Spacing.lg,
        Spacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Radii.md),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [palette.accent, palette.accentSoft],
                  ),
                ),
                child: Icon(Icons.speed, color: palette.background, size: 24),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).appTitle,
                      style: context.texts.headlineMedium,
                    ),
                    Text(
                      AppLocalizations.of(context).appTagline,
                      style: context.texts.bodySmall,
                    ),
                  ],
                ),
              ),
              TextButton(
                key: const Key('connect_language_entry'),
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    builder: (sheetContext) {
                      return const SafeArea(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: LanguagePicker(),
                        ),
                      );
                    },
                  );
                },
                child: Text(AppLocalizations.of(context).languageSectionTitle),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xl),
          Text(
            AppLocalizations.of(context).connectHeadline,
            style: context.texts.titleLarge,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            AppLocalizations.of(context).connectBody,
            style: context.texts.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _TransportCard extends StatelessWidget {
  const _TransportCard({
    required this.kind,
    required this.isExpanded,
    required this.isDisabled,
    required this.disabledReason,
    required this.onTap,
    required this.child,
  });

  final TransportKind kind;
  final bool isExpanded;
  final bool isDisabled;
  final String? disabledReason;
  final VoidCallback onTap;
  final Widget child;

  IconData get _icon => switch (kind) {
    TransportKind.bluetoothClassic => Icons.bluetooth,
    TransportKind.bluetoothLe => Icons.bluetooth_audio,
    TransportKind.wifi => Icons.wifi,
    TransportKind.demo => Icons.play_circle_outline,
  };

  Color _accent(AppPalette palette) => switch (kind) {
    TransportKind.bluetoothClassic => palette.info,
    TransportKind.bluetoothLe => palette.derived,
    TransportKind.wifi => palette.success,
    TransportKind.demo => palette.accent,
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = _accent(palette);

    return Panel(
      // Not wrapped in an Opacity. `disabledReason` is the only thing on
      // screen that explains *why* a transport cannot be used — "iOS exposes
      // RFCOMM only to MFi accessories", say — and fading the row put that
      // sentence below the contrast floor along with everything else. The
      // row already reads as unavailable from its muted icon and the absent
      // chevron and tap target.
      accent: isDisabled ? palette.textTertiary : accent,
      isActive: isExpanded,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: isDisabled ? null : onTap,
            borderRadius: Radii.cardRadius,
            child: Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      // The icon carries the dimming, because nothing has to
                      // be read off it.
                      color: (isDisabled ? palette.textTertiary : accent)
                          .withValues(alpha: isDisabled ? 0.08 : 0.14),
                      borderRadius: BorderRadius.circular(Radii.sm + 2),
                    ),
                    child: Icon(
                      _icon,
                      color: isDisabled ? palette.textTertiary : accent,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(kind.label, style: context.texts.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          disabledReason ?? kind.description,
                          style: context.texts.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (!isDisabled)
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: Motion.fast,
                      child: Icon(
                        Icons.expand_more,
                        color: palette.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: Motion.normal,
            curve: Motion.standard,
            alignment: Alignment.topCenter,
            child: isExpanded && !isDisabled
                ? Column(
                    children: [
                      Divider(height: 1, color: palette.hairline),
                      Padding(
                        padding: const EdgeInsets.all(Spacing.lg),
                        child: child,
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _DemoBody extends StatelessWidget {
  const _DemoBody({required this.onConnect});

  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).connectDemoBody,
          style: context.texts.bodyMedium,
        ),
        const SizedBox(height: Spacing.lg),
        FilledButton.icon(
          onPressed: onConnect,
          icon: const Icon(Icons.play_arrow, size: 20),
          label: Text(AppLocalizations.of(context).connectDemoStart),
        ),
      ],
    );
  }
}

class _WifiBody extends StatelessWidget {
  const _WifiBody({
    required this.hostController,
    required this.portController,
    required this.onConnect,
    this.error,
  });

  final TextEditingController hostController;
  final TextEditingController portController;
  final VoidCallback onConnect;

  /// Set when the address or port could not be used, so the field that is
  /// wrong is named rather than the connection simply failing later.
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(wifiConnectInstructions(l10n), style: context.texts.bodyMedium),
        const SizedBox(height: Spacing.lg),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: hostController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: l10n.connectWifiHostLabel,
                ),
              ),
            ),
            const SizedBox(width: Spacing.md),
            // Fixed rather than flexed: the field has to fit five digits plus
            // the caret at any text scale, and a flex share narrow enough to
            // look balanced clips "35000" to "3500".
            SizedBox(
              width: 108,
              child: TextField(
                controller: portController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
                decoration: InputDecoration(
                  labelText: l10n.connectWifiPortLabel,
                ),
              ),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: Spacing.md),
          Text(
            error!,
            style: context.texts.bodyMedium?.copyWith(
              color: context.palette.warning,
            ),
          ),
        ],
        const SizedBox(height: Spacing.lg),
        FilledButton.icon(
          onPressed: onConnect,
          icon: const Icon(Icons.link, size: 20),
          label: Text(l10n.connectConnect),
        ),
      ],
    );
  }
}

class _DeviceListBody extends StatelessWidget {
  const _DeviceListBody({
    required this.devices,
    required this.scanning,
    required this.error,
    required this.emptyHint,
    required this.onRefresh,
    required this.onSelect,
    this.listHint,
    this.showSettingsAction = false,
  });

  final List<DiscoveredDevice> devices;
  final bool scanning;
  final String? error;
  final bool showSettingsAction;
  final String emptyHint;

  /// Shown above a non-empty list, when the list needs explaining.
  final String? listHint;

  final VoidCallback onRefresh;
  final ValueChanged<DiscoveredDevice> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    if (scanning && devices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: Spacing.lg),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (error != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: Text(
              error!,
              style: context.texts.bodyMedium?.copyWith(color: palette.warning),
            ),
          ),
          if (showSettingsAction)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.md),
              child: OutlinedButton.icon(
                onPressed: openAppSettings,
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: Text(AppLocalizations.of(context).connectOpenSystemSettings),
              ),
            ),
        ],
        if (devices.isEmpty)
          Text(emptyHint, style: context.texts.bodyMedium)
        else ...[
          if (listHint != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.md),
              child: Text(listHint!, style: context.texts.bodySmall),
            ),
          ...devices.map(
            (device) => Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: _DeviceTile(device: device, onTap: () => onSelect(device)),
            ),
          ),
        ],
        const SizedBox(height: Spacing.md),
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(AppLocalizations.of(context).connectSearchAgain),
        ),
      ],
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.device, required this.onTap});

  final DiscoveredDevice device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.surfaceAlt,
      borderRadius: BorderRadius.circular(Radii.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.name, style: context.texts.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      device.id,
                      style: AppTypography.code(palette, size: 11.5),
                    ),
                  ],
                ),
              ),
              // Signal strength, where the link reports it.
              //
              // This is how somebody picks the adapter out of five
              // similarly-named devices: the one in the car two feet away is
              // the loud one. `signalBars` existed with full dBm thresholds
              // and had no caller at all — and it returned *four bars* when
              // there was no reading, so wiring it up naively would have drawn
              // "excellent" for every bonded device that has never been
              // scanned. It returns null for that now, and null draws nothing.
              if (device.signalBars != null) ...[
                _SignalBars(bars: device.signalBars!, palette: palette),
                const SizedBox(width: Spacing.sm),
              ],
              if (device.isPaired)
                StatusPill(
                  label: AppLocalizations.of(context).connectPairedPill,
                  tone: StatusTone.good,
                  dense: true,
                ),
              const SizedBox(width: Spacing.sm),
              Icon(Icons.chevron_right, color: palette.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _BleBody extends StatefulWidget {
  const _BleBody({
    required this.onConnect,
    required this.ensurePermissions,
    required this.isPermanentlyDenied,
  });

  final void Function(BleAdapterHandle device) onConnect;
  final Future<bool> Function() ensurePermissions;

  /// Read after a failed request — the flag is only set during one.
  final bool Function() isPermanentlyDenied;

  @override
  State<_BleBody> createState() => _BleBodyState();
}

class _BleBodyState extends State<_BleBody> {
  bool _scanning = false;

  /// Whether a scan has finished at least once.
  ///
  /// Without it the guidance would greet somebody who has not tapped anything
  /// yet with an explanation of a failure that has not happened.
  bool _scanned = false;
  String? _error;
  bool _permanentlyDenied = false;
  final List<_BleEntry> _found = [];
  StreamSubscription<_BleEntry>? _sub;

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  Future<void> _startScan() async {
    // Before the permission await: that dialog sits in front of the app for as
    // long as the user ignores it, and the refusal has to be phrased in the
    // language that was on screen when they tapped search.
    final l10n = AppLocalizations.of(context);
    if (!await widget.ensurePermissions()) {
      if (!mounted) return;
      setState(() {
        _permanentlyDenied = widget.isPermanentlyDenied();
        _error = _permanentlyDenied
            ? l10n.connectBlePermissionDeniedForever
            : l10n.connectBlePermissionNeeded;
      });
      return;
    }
    setState(() {
      _scanning = true;
      _error = null;
      _found.clear();
    });

    try {
      // Reached through the transport so this widget stays free of a direct
      // BLE package dependency.
      await _sub?.cancel();
      _sub = _bleScanStream().listen(
        (entry) {
          if (!mounted) return;
          setState(() {
            final index = _found.indexWhere((e) => e.id == entry.id);
            if (index >= 0) {
              _found[index] = entry;
            } else {
              _found.add(entry);
            }
          });
        },
        onError: (Object e) {
          if (mounted) {
            setState(() => _error = BleTransport.userFacingScanFailure(e));
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _scanning = false;
              _scanned = true;
            });
          }
        },
      );
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _error = BleTransport.userFacingScanFailure(e);
          _scanning = false;
          _scanned = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.connectBleBody, style: context.texts.bodyMedium),
        if (_error != null) ...[
          const SizedBox(height: Spacing.md),
          Text(
            _error!,
            style: context.texts.bodyMedium?.copyWith(color: palette.warning),
          ),
          if (_permanentlyDenied) ...[
            const SizedBox(height: Spacing.md),
            OutlinedButton.icon(
              onPressed: openAppSettings,
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: Text(l10n.connectOpenAppSettings),
            ),
          ],
        ],
        if (_scanned && !_scanning && _found.isEmpty) ...[
          const SizedBox(height: Spacing.md),
          Text(
            bleEmptyScanGuidance(
              l10n,
              classicAvailable: classicTransportAvailable,
            ),
            style: context.texts.bodyMedium,
          ),
        ],
        if (_found.isNotEmpty) ...[
          const SizedBox(height: Spacing.md),
          ..._found.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: _DeviceTile(
                device: DiscoveredDevice(
                  id: entry.id,
                  name: entry.name,
                  kind: TransportKind.bluetoothLe,
                  rssi: entry.rssi,
                ),
                onTap: () => widget.onConnect(entry.handle),
              ),
            ),
          ),
        ],
        const SizedBox(height: Spacing.md),
        FilledButton.icon(
          onPressed: _scanning ? null : _startScan,
          icon: _scanning
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search, size: 20),
          label: Text(
            _scanning ? l10n.connectBleScanning : l10n.connectBleScan,
          ),
        ),
      ],
    );
  }
}

/// Minimal projection of a BLE scan result, so the widget layer does not need
/// BLE package types in its signature.
class _BleEntry {
  const _BleEntry({required this.id, required this.name, required this.rssi});

  final String id;
  final String name;
  final int? rssi;

  /// What the transport needs to open this adapter.
  ///
  /// A BLE peripheral is addressed by its platform id alone, so this is a
  /// projection rather than a stored object — which is also why a remembered
  /// adapter can be reconnected on a fresh launch with no scan result to have
  /// held on to.
  BleAdapterHandle get handle =>
      BleAdapterHandle(id: id, name: name, rssi: rssi);
}

Stream<_BleEntry> _bleScanStream() async* {
  await for (final entry in BleTransport.scanEntries()) {
    yield _BleEntry(id: entry.$1, name: entry.$2, rssi: entry.$3);
  }
}

/// Live view of the AT handshake.
///
/// Each command appears as its own row and mutates in place from running to a
/// result, which turns "connection failed" into "it failed at ATSP0, so the
/// adapter never found a bus protocol — check the ignition".
class _HandshakePanel extends ConsumerWidget {
  const _HandshakePanel({required this.connection});

  final ObdConnectionState connection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final l10n = AppLocalizations.of(context);
    final steps = connection.initSteps;
    final done = steps.where((s) => s.status != InitStatus.running).length;
    final total = steps.isEmpty
        ? Elm327Client.initSequence.length
        : steps.first.total;

    // Past rather than live. Signalled by the accent and the inactive panel
    // treatment, not by fading the contents.
    //
    // It used to composite the whole panel at 0.55 with a comment claiming it
    // stayed readable. Measured, the secondary text came out at 2.86:1 on the
    // dark theme and 2.58:1 on the light one, against a 4.5:1 minimum — so the
    // most diagnostic text on the screen, the one that says which handshake
    // step failed and why, became the least legible thing on it. In a car,
    // through glare, at the moment a connection just failed.
    //
    // No opacity clears the floor here: these strings use the secondary and
    // tertiary tokens, which are already near the limit at full strength.
    final isHistory = !connection.isBusy && !connection.isConnected;

    return Panel(
      accent: isHistory ? palette.textTertiary : palette.accent,
      isActive: !isHistory,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(switch (connection.phase) {
                  ConnectionPhase.connecting => l10n.connectOpeningConnection,
                  ConnectionPhase.handshaking => l10n.connectHandshakeTitle,
                  ConnectionPhase.connected => l10n.connectHandshakeTitle,
                  // Past tense, so a green row cannot be read as "fine now".
                  _ => l10n.connectHandshakeTitleLastAttempt,
                }, style: context.texts.titleMedium),
              ),
              Text(
                '$done / $total',
                style: AppTypography.code(palette, size: 12),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.pill),
            child: LinearProgressIndicator(
              value: total == 0 ? null : done / total,
              minHeight: 4,
              backgroundColor: palette.gaugeTrack,
              valueColor: AlwaysStoppedAnimation(palette.accent),
            ),
          ),
          // What the wait is for, when there is nothing else to show.
          //
          // Bluetooth Classic tries three ways of opening a socket, up to
          // twelve seconds each, before a single handshake byte is written —
          // and until now the screen showed an empty step list and a progress
          // bar at zero for all of it. Up to thirty-six seconds of that in a
          // windscreen mount reads as a frozen app, and a frozen app gets
          // force-quit rather than waited out.
          if (connection.isBusy && _busyLine(context, connection) != null) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              _busyLine(context, connection)!,
              style: context.texts.bodySmall,
            ),
          ],
          if (steps.isNotEmpty) ...[
            const SizedBox(height: Spacing.md),
            // Newest first: the step that matters is the one in flight or the
            // one that just failed.
            ...steps.reversed.take(5).map((step) => _StepRow(progress: step)),
          ],
          // A way out.
          //
          // There was none: no cancel, no back, and the wizard is the app's
          // first screen. Somebody who tapped the wrong row in a bonded-device
          // list — which lists headphones and laptops beside adapters — had to
          // wait the whole cascade out or kill the app.
          if (connection.isBusy) ...[
            const SizedBox(height: Spacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    ref.read(obdSessionProvider.notifier).disconnect(),
                icon: const Icon(Icons.close, size: 18),
                label: Text(l10n.connectCancel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The busy line, translated where this app authored it.
///
/// `ObdConnectionState.detail` also carries text a transport wrote — the
/// Bluetooth Classic tier notices — which is passed through as it arrived and
/// is still Chinese.
String? _busyLine(BuildContext context, ObdConnectionState connection) {
  final activity = connectionActivityText(
    AppLocalizations.of(context),
    connection,
  );
  if (activity != null) return activity;
  return connection.detail.isEmpty ? null : connection.detail;
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.progress});

  final InitProgress progress;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (icon, colour) = switch (progress.status) {
      InitStatus.ok => (Icons.check_circle, palette.success),
      InitStatus.failed => (Icons.error, palette.danger),
      InitStatus.skipped => (Icons.remove_circle_outline, palette.textTertiary),
      InitStatus.running => (Icons.more_horiz, palette.accent),
      InitStatus.pending => (Icons.circle_outlined, palette.textTertiary),
    };

    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: colour),
          const SizedBox(width: Spacing.sm),
          SizedBox(
            width: 76,
            child: Text(
              progress.step.command,
              style: AppTypography.code(
                palette,
                size: 11.5,
                color: palette.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              initProgressLine(AppLocalizations.of(context), progress),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: palette.danger.withValues(alpha: 0.10),
        borderRadius: Radii.cardRadius,
        border: Border.all(color: palette.danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: palette.danger, size: 20),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(
              message,
              style: context.texts.bodyMedium?.copyWith(
                color: palette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The adapter used last time, offered before the list of everything else.
///
/// Hidden while connected or connecting: it is a shortcut to somewhere the
/// user already is, and a live "reconnect" button during a handshake is an
/// invitation to break the handshake.
class _LastAdapterCard extends ConsumerWidget {
  const _LastAdapterCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last = ref.watch(lastAdapterProvider);
    if (last == null) return const SizedBox.shrink();
    final palette = context.palette;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.lg),
      child: Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, size: 18, color: palette.accent),
                const SizedBox(width: Spacing.xs),
                Text(l10n.connectLastAdapterTitle, style: context.texts.titleSmall),
              ],
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              last.name.isEmpty ? last.id : last.name,
              style: context.texts.bodyMedium,
            ),
            Text(
              last.port == null
                  ? '${last.kind.label} · ${last.id}'
                  : '${last.kind.label} · ${last.id}:${last.port}',
              style: context.texts.labelSmall,
            ),
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _reconnectAllowed(last)
                        ? () => _reconnect(context, ref, last)
                        : null,
                    icon: const Icon(Icons.link, size: 18),
                    label: Text(l10n.connectLastAdapterConnect),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                TextButton(
                  onPressed: () =>
                      ref.read(lastAdapterProvider.notifier).forget(),
                  child: Text(l10n.connectLastAdapterForget),
                ),
              ],
            ),
            if (!_reconnectAllowed(last)) ...[
              const SizedBox(height: Spacing.xs),
              Text(
                last.kind == TransportKind.bluetoothClassic
                    ? classicUnavailableReason(l10n)
                    : bleUnavailableReason(l10n),
                style: context.texts.labelSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Same host gates as the transport cards — a remembered Classic/BLE
  /// adapter must not offer reconnect on a host where that transport is
  /// disabled in the UI.
  bool _reconnectAllowed(LastAdapter last) => switch (last.kind) {
    TransportKind.bluetoothClassic => classicTransportAvailable,
    TransportKind.bluetoothLe => bleTransportAvailable,
    TransportKind.wifi || TransportKind.demo => true,
  };

  Future<void> _reconnect(
    BuildContext context,
    WidgetRef ref,
    LastAdapter last,
  ) async {
    if (!_reconnectAllowed(last)) return;
    // Taken before the first await, because this card does not survive its
    // own tap: the wizard hides it for the whole busy phase, so by the time
    // the connect resolves this context is unmounted and a mounted-check
    // here would silently drop the navigation — a live session polling
    // behind a connection screen that looks like nothing happened. The
    // router is app-scoped and outlives the card. Navigating even if the
    // user wandered elsewhere during the attempt is deliberate: the session
    // coming up is the thing they just asked for, and the dashboard is
    // where it is visible.
    final router = GoRouter.of(context);
    final session = ref.read(obdSessionProvider.notifier);
    late final bool ok;
    // Rebuilt from the stored identifiers rather than from a device object,
    // which is the whole point: on a fresh launch there is no scan result to
    // hold on to, and a shortcut that required one would only work in the
    // session where it was not needed.
    switch (last.kind) {
      case TransportKind.bluetoothClassic:
        ok = await session.connectClassic(
          DiscoveredDevice(
            id: last.id,
            name: last.name,
            kind: TransportKind.bluetoothClassic,
            isPaired: true,
          ),
        );
      case TransportKind.wifi:
        // The id is the host, verbatim, and the port is its own field —
        // packing them into one string and splitting on the colon was correct
        // for IPv4 and silently wrong for IPv6. Calling `connectWifi()` bare
        // would use the shipped default, which is the value the user had to
        // change in the first place.
        ok = await session.connectWifi(host: last.id, port: last.port);
      case TransportKind.bluetoothLe:
        // The handle is rebuilt from the stored address without a scan, which
        // is exactly what a shortcut on a fresh launch needs: there is no scan
        // result to have held on to. A device that has moved out of range
        // fails the connect, which is the same thing that happens when it is
        // picked from a list.
        ok = await session.connectBle(
          BleAdapterHandle(id: last.id, name: last.name),
        );
      case TransportKind.demo:
        // Nothing to remember, and nothing to shorten.
        return;
    }
    if (ok) {
      router.go(DashboardScreen.path);
    }
  }
}

/// Four bars, of which some are lit.
///
/// Drawn rather than iconified so the unlit bars stay visible: "one bar out of
/// four" and "one bar, and I cannot tell you about the rest" look identical
/// otherwise, and the first is the useful reading.
class _SignalBars extends StatelessWidget {
  const _SignalBars({required this.bars, required this.palette});

  /// How many bars are drawn, lit or not. The label quotes this rather than
  /// spelling a 4 into the sentence, so the two cannot disagree.
  static const int barCount = 4;

  final int bars;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).connectSignalStrength(bars, barCount),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 1; i <= barCount; i++) ...[
            Container(
              width: 3,
              height: 4.0 + i * 2.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                color: i <= bars
                    ? palette.accent
                    : palette.textTertiary.withValues(alpha: 0.28),
              ),
            ),
            if (i < barCount) const SizedBox(width: 2),
          ],
        ],
      ),
    );
  }
}

/// "Which of these four is mine?", asked by hardware rather than by protocol.
///
/// The four cards below name transports — RFCOMM/SPP, GATT UART, TCP — and
/// somebody who has just bought a £12 dongle knows none of those words. The
/// competitor with 27 million downloads lists "wrong connection type" as its
/// third-commonest support issue and still asks the user to pick one cold.
///
/// So this does not explain the protocols. It asks the three questions whose
/// answers the owner already has, in the order that settles it fastest: does
/// it make its own Wi-Fi network, does it show up in the phone's Bluetooth
/// pairing list, and if neither, is it one of the newer low-energy ones.
///
/// Shown only until an adapter has been remembered. After that the shortcut
/// above has already answered it.
/// One yes/no question about the hardware, and the transport it points at.
///
/// [transport] is a value, not a substring of [answer]. The first version of
/// this had callers and tests read the destination out of the prose, and the
/// first time the BLE answer gained a "if you cannot find it, use Bluetooth
/// Classic" fallback the tests declared two questions were routing to Classic.
/// A routing rule expressed only in a sentence cannot be checked, and the
/// sentence has to be free to say more than the rule.
typedef TransportQuestion = ({
  String question,
  String answer,
  TransportKind transport,
});

/// "Which of these is mine?", answered by what the adapter does rather than by
/// what protocol it speaks.
///
/// A top-level function rather than markup inside the card because the rule it
/// encodes is worth holding still, and two rounds of getting it wrong say why.
///
/// **It does not ask whether the adapter appears in the Bluetooth pairing
/// list.** That was the first version, and it is the wrong discriminator:
/// Android's "pair new device" scan lists BLE peripherals as well as Classic
/// ones, so the commonest adapters sold today — Vgate iCar Pro BLE, Veepeak
/// OBDCheck BLE — answer yes truthfully, get routed to Bluetooth Classic, and
/// then cannot be paired at all. They expose no SPP service, and their own
/// manuals tell you not to pair them in system settings. The branch that would
/// have worked was unreachable for precisely the people who needed it, which
/// makes it worse than no card.
///
/// The marking on the box separates the two, so that is what it asks.
///
/// On iOS the Classic question is absent rather than reworded. Bluetooth SPP is
/// not available to third-party apps there, the transport card on the same
/// screen is disabled saying so, and a question above it telling somebody to
/// pair a Classic adapter made one screen give two opposite instructions with
/// the wrong one first.
/// Whether Bluetooth Classic SPP is usable on this platform at all.
///
/// One predicate, read by both the transport card and the guidance above it.
/// They used to have their own: the card asked `Platform.isAndroid`, the
/// guidance asked `!isIOS`. On macOS — a target this app builds for — those
/// disagree, so the card was greyed out saying Classic is unavailable while
/// four lines above it a question told you to pick it. That is the same defect
/// as the iOS wording it replaced, in the platform nobody checked.
///
/// Hosts with a real Classic path:
/// - **Android:** RFCOMM three-tier cascade (`ClassicTransport`).
/// - **macOS:** IOBluetooth RFCOMM via `flutter_classic_bluetooth`
///   (`openRFCOMMChannelAsync`, SDP → channel else channel 1). macOS does
///   **not** expose paired SPP as a general POSIX TTY the way Windows COM /
///   Linux `/dev/rfcomm*` do (`/dev/cu.Bluetooth-Incoming-Port` is the host
///   incoming serial profile, not remote-ELM327 enumeration), so the product
///   path is the plugin — not `SerialTransport`.
/// - **Windows / Linux:** Bluetooth SPP serial (38400 8N1) via
///   `SerialTransport` + `com.cbstudio.telltale/spp_serial`.
/// - **iOS:** permanent OS/API host limit — no generic third-party SPP.
///
/// Empty paired/port lists fail closed in the wizard (no fake adapters).
///
/// [classicIoBluetoothHostOverride] is a test seam — do not mock
/// [Platform.isMacOS] globally. Production leaves it null.
@visibleForTesting
bool? classicIoBluetoothHostOverride;

bool get classicIoBluetoothHostSupported =>
    classicIoBluetoothHostOverride ?? Platform.isMacOS;

bool get classicTransportAvailable =>
    Platform.isAndroid ||
    classicIoBluetoothHostSupported ||
    sppSerialHostSupported;

/// Why the Classic transport card is greyed out on hosts without a path.
///
/// The old copy always said "iOS", which was true for iPhone and false for
/// every other platform that already builds this app. Desktop and iOS share
/// the same gate (`classicTransportAvailable`) but not the same reason.
///
/// Takes an [AppLocalizations] rather than a [BuildContext] because it is a
/// top-level function with no widget above it, and because a pure-Dart test
/// can then walk both languages without pumping anything.
String classicUnavailableReason(AppLocalizations l10n) {
  if (Platform.isIOS) {
    return l10n.connectClassicUnavailableIos;
  }
  return l10n.connectClassicUnavailableHost;
}

/// Whether Bluetooth LE scanning/connect is usable on this host.
///
/// Every shipping host has a path:
/// - Android / iOS / macOS / Windows: `universal_ble` native pigeon plugins
/// - Linux: Dart BlueZ backend inside `universal_ble` (`bluez` → D-Bus). No
///   Flutter plugin registrant is expected — `linux/flutter/generated_plugins.cmake`
///   correctly omits it. The earlier Linux UI gate assumed
///   `MissingPluginException`; that was a misread of the package layout.
bool get bleTransportAvailable => true;

/// Why the BLE transport card is greyed out when [bleTransportAvailable] is
/// false. Kept for UI wiring; every current host returns true above.
String bleUnavailableReason(AppLocalizations l10n) =>
    l10n.connectBleUnavailableHost;

/// Wi-Fi body copy. Phone hosts keep cellular-handoff guidance; desktop hosts
/// talk about the computer joining the adapter AP without inventing a binder.
String wifiConnectInstructions(
  AppLocalizations l10n, {
  @visibleForTesting bool? isPhone,
}) {
  final phone = isPhone ?? _phoneFormFactor;
  return phone
      ? l10n.connectWifiInstructionsPhone
      : l10n.connectWifiInstructionsDesktop;
}

bool get _phoneFormFactor => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

List<TransportQuestion> whichTransportGuidance(
  AppLocalizations l10n, {
  required bool classicAvailable,
  bool bleAvailable = true,
  @visibleForTesting bool? phoneCentricCopy,
}) {
  final phone = phoneCentricCopy ?? _phoneFormFactor;
  return [
    (
      transport: TransportKind.wifi,
      question: phone
          ? l10n.connectQuestionWifiPhone
          : l10n.connectQuestionWifiDesktop,
      answer: phone
          ? l10n.connectAnswerWifiPhone
          : l10n.connectAnswerWifiDesktop,
    ),
    if (bleAvailable)
      (
        transport: TransportKind.bluetoothLe,
        question: l10n.connectQuestionBle,
        // The fallback is in the answer rather than only in the note at the
        // bottom, because the cheap clones lie: a box marked "Bluetooth 4.0"
        // is sometimes an SPP-only adapter with a dual-mode chip it does not
        // use. Somebody who answered honestly and got nothing needs the next
        // step attached to the answer that failed them, not four lines below
        // it. Only offer Classic when this host actually enables it.
        answer: classicAvailable
            ? l10n.connectAnswerBleWithClassic
            : l10n.connectAnswerBleWithoutClassic,
      ),
    if (classicAvailable)
      (
        transport: TransportKind.bluetoothClassic,
        question: l10n.connectQuestionClassic,
        // Classic SPP genuinely does have to be paired in system settings
        // first, which is the opposite of the BLE answer above. Neither may
        // drift toward the other.
        answer: l10n.connectAnswerClassic,
      ),
  ];
}

/// What to say when a BLE scan finishes having found nothing.
///
/// The Classic branch has had an equivalent since it was written; this branch
/// showed nothing at all, so a scan that found no adapter left the screen
/// exactly as it was before the tap. Somebody standing at a car reads that as
/// a broken app, and the three things that actually cause it are all invisible
/// from a blank panel.
///
/// Ordered by how often each one is the answer, not by how interesting it is.
/// When Classic is unavailable on this host, never point at the greyed-out
/// Classic card — offer power/range checks and Wi‑Fi instead.
String bleEmptyScanGuidance(AppLocalizations l10n, {bool? classicAvailable}) {
  final classic = classicAvailable ?? classicTransportAvailable;
  // A whole sentence, not a clause: the third check reads differently on a
  // host with no Classic path, and a fragment assembled from words would not
  // survive translation into a language that orders them differently.
  final classicOrWifi = classic
      ? l10n.connectBleEmptyScanNextClassic
      : l10n.connectBleEmptyScanNextWifi;
  return l10n.connectBleEmptyScan(classicOrWifi);
}

/// Empty-state copy for the Classic device list.
///
/// Bonded-device hosts (Android / macOS) talk about system pairing. SPP serial
/// hosts (Windows / Linux) talk about COM / rfcomm nodes — headphones never
/// appear in that enumeration, so the bonded-device paragraph must not.
String classicDeviceListEmptyHint(
  AppLocalizations l10n, {
  required bool serialHost,
  @visibleForTesting bool? linuxHost,
}) {
  if (!serialHost) {
    return l10n.connectClassicEmptyPaired;
  }
  final linux = linuxHost ?? Platform.isLinux;
  return linux
      ? l10n.connectClassicEmptyLinuxPort
      : l10n.connectClassicEmptyWindowsPort;
}

/// Non-empty list explanation for Classic.
///
/// The cancel-early sentence on bonded hosts exists because a wrong headphone
/// row used to burn ~30s of cascade before failing. Serial hosts do not list
/// headphones; inventing that warning there would make COM/rfcomm look broken.
String classicDeviceListHint(
  AppLocalizations l10n, {
  required bool serialHost,
  @visibleForTesting bool? linuxHost,
}) {
  if (!serialHost) {
    return l10n.connectClassicListPaired;
  }
  final linux = linuxHost ?? Platform.isLinux;
  return linux
      ? l10n.connectClassicListLinuxPort
      : l10n.connectClassicListWindowsPort;
}

class _WhichTransportCard extends ConsumerStatefulWidget {
  const _WhichTransportCard();

  @override
  ConsumerState<_WhichTransportCard> createState() =>
      _WhichTransportCardState();
}

class _WhichTransportCardState extends ConsumerState<_WhichTransportCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    // Nothing to explain once the app knows which one worked.
    if (ref.watch(lastAdapterProvider) != null) return const SizedBox.shrink();
    final palette = context.palette;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.lg),
      child: Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Row(
                children: [
                  Icon(Icons.help_outline, size: 18, color: palette.accent),
                  const SizedBox(width: Spacing.xs),
                  Expanded(
                    child: Text(
                      l10n.connectWhichTitle,
                      style: context.texts.titleSmall,
                    ),
                  ),
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: palette.textTertiary,
                  ),
                ],
              ),
            ),
            if (_open) ...[
              const SizedBox(height: Spacing.sm),
              Text(l10n.connectWhichIntro, style: context.texts.bodySmall),
              const SizedBox(height: Spacing.sm),
              for (final row in whichTransportGuidance(
                l10n,
                classicAvailable: classicTransportAvailable,
                bleAvailable: bleTransportAvailable,
              ))
                _WhichRow(question: row.question, answer: row.answer),
              const SizedBox(height: Spacing.sm),
              Text(
                Platform.isIOS
                    // The constraint that has no workaround in any app, so it
                    // is worth saying before somebody spends an afternoon on
                    // it rather than after.
                    ? l10n.connectWhichNoteIos
                    // Said out loud because the fear of picking wrong is what
                    // makes somebody close the app instead of tapping
                    // something. Nothing here is destructive and nothing is
                    // remembered until a handshake succeeds.
                    : l10n.connectWhichNoteGuessing,
                style: context.texts.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WhichRow extends StatelessWidget {
  const _WhichRow({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: context.texts.bodyMedium?.copyWith(
              color: palette.textPrimary,
            ),
          ),
          Text(answer, style: context.texts.bodySmall),
        ],
      ),
    );
  }
}
