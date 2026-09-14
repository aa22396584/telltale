import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/app_locales_platform.dart';
import 'core/form_factor.dart';
import 'core/theme/app_theme.dart';
import 'l10n/generated/app_localizations.dart';
import 'l10n/locale_resolution.dart';
import 'l10n/startup_copy.dart';
import 'state/app_locales_synchronizer.dart';
import 'state/app_share_coordinator.dart';
import 'state/locale_settings.dart';
import 'state/pid_registry.dart';
import 'state/powertrain_battery_profiles.dart';
import 'state/settings.dart';
import 'state/telemetry_recorder.dart';
import 'state/telemetry_sessions.dart';
import 'ui/wear/wear_shell.dart';
import 'ui/screens/connect/connect_screen.dart';
import 'ui/screens/dashboard/dashboard_screen.dart';
import 'ui/screens/dtc/dtc_screen.dart';
import 'ui/screens/performance/performance_screen.dart';
import 'ui/screens/pids/powertrain_battery_catalog_screen.dart';
import 'ui/screens/pids/pid_editor_screen.dart';
import 'ui/screens/pids/pid_manager_screen.dart';
import 'ui/screens/settings/settings_screen.dart';
import 'ui/screens/telemetry/telemetry_session_detail_screen.dart';
import 'ui/screens/telemetry/telemetry_sessions_screen.dart';
import 'ui/screens/workshop/service_recipes_screen.dart';
import 'ui/shell.dart';
import 'ui/widgets/telemetry/telemetry_artifact_restart_notice.dart';

class TorqueApp extends ConsumerStatefulWidget {
  const TorqueApp({super.key});

  @override
  ConsumerState<TorqueApp> createState() => _TorqueAppState();
}

class _TorqueAppState extends ConsumerState<TorqueApp>
    with WidgetsBindingObserver {
  late Future<_AppStartupOutcome> _startupInitialization;
  late final AppLifecycleListener _lifecycleListener;
  bool _startupReady = false;
  bool _startupRequiresRestart = false;

  static const _l10nDelegates = <LocalizationsDelegate<dynamic>>[
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // These authorities outlive every route. Creating them before the router
    // makes lifecycle, OBD-boundary, and cross-feature file exclusion active
    // even while the user is still on Connect.
    ref.read(telemetryRecorderControllerProvider);
    ref.read(telemetryRecorderProgressProvider);
    _startupInitialization = _initializeStartup();
    _lifecycleListener = AppLifecycleListener(onResume: _onResume);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncAppLocales());
  }

  void _onResume() {
    _retryStartup();
    _syncAppLocales();
  }

  void _syncAppLocales() {
    unawaited(_syncAppLocalesAsync());
  }

  Future<void> _syncAppLocalesAsync() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final sync = AppLocalesSynchronizer(
      prefs: prefs,
      getOs: AppLocalesPlatform.get,
      setOs: AppLocalesPlatform.setOverrideTags,
    );
    final plan = await sync.sync();
    if (!mounted) return;
    final next = localePreferenceFromStored(plan.storedIdToKeep);
    if (ref.read(localePreferenceProvider) != next) {
      await ref.read(localePreferenceProvider.notifier).set(next);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    _syncAppLocales();
    if (ref.read(localePreferenceProvider) == LocalePreference.system) {
      setState(() {});
    }
  }

  Locale _resolvedLocale() {
    return resolveAppLocale(
      preference: ref.watch(localePreferenceProvider),
      deviceLocales: WidgetsBinding.instance.platformDispatcher.locales,
    );
  }

  Future<_AppStartupOutcome> _initializeStartup() async {
    try {
      final share = await ref.read(appShareCoordinatorProvider).initialize();
      if (share != AppShareInitializationOutcome.ready) {
        return _rememberStartupOutcome(_AppStartupOutcome(share: share));
      }
      final recovery = await ref
          .read(telemetryStartupRecoveryProvider.notifier)
          .initialize();
      return _rememberStartupOutcome(
        _AppStartupOutcome(share: share, recovery: recovery.phase),
      );
    } on Object {
      // Startup reconstruction owns durable files. An unexpected exception is
      // indeterminate rather than retryable in-process.
      return _rememberStartupOutcome(
        const _AppStartupOutcome(unexpectedFailure: true),
      );
    }
  }

  _AppStartupOutcome _rememberStartupOutcome(_AppStartupOutcome outcome) {
    _startupReady = outcome.isReady;
    _startupRequiresRestart = outcome.requiresRestart;
    return outcome;
  }

  void _retryStartup() {
    if (!mounted || _startupReady || _startupRequiresRestart) return;
    setState(() {
      _startupInitialization = _initializeStartup();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Rehydrates installed battery-profile PIDs from the verified catalog.
    ref.watch(installedPowertrainProfilesRestoreProvider);
    if (isWatchFormFactor()) {
      return MaterialApp(
        title: 'Telltale',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(skin: ref.watch(gaugeSkinProvider)),
        locale: _resolvedLocale(),
        supportedLocales: supportedAppLocales,
        localizationsDelegates: _l10nDelegates,
        home: const WearShell(),
      );
    }
    final themeMode = ref.watch(themeModeProvider);
    // Both themes get the same skin. A skin is what kind of instrument this
    // is; light and dark are the light you are reading it in, and a skin that
    // only existed in one of them would strand anybody who drives at night.
    final skin = ref.watch(gaugeSkinProvider);
    return FutureBuilder<_AppStartupOutcome>(
      future: _startupInitialization,
      builder: (context, snapshot) {
        final outcome = snapshot.data;
        if (outcome?.isReady != true) {
          return MaterialApp(
            title: 'Telltale',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(skin: skin),
            darkTheme: AppTheme.dark(skin: skin),
            themeMode: themeMode,
            locale: _resolvedLocale(),
            supportedLocales: supportedAppLocales,
            localizationsDelegates: _l10nDelegates,
            builder: _withTelemetryArtifactNotice,
            home: AppStartupScreen(
              loading: outcome == null,
              restartRequired: outcome?.requiresRestart == true,
              retry: _retryStartup,
            ),
          );
        }
        return MaterialApp.router(
          title: 'Telltale',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(skin: skin),
          darkTheme: AppTheme.dark(skin: skin),
          themeMode: themeMode,
          locale: _resolvedLocale(),
          supportedLocales: supportedAppLocales,
          localizationsDelegates: _l10nDelegates,
          builder: _withTelemetryArtifactNotice,
          routerConfig: _router,
        );
      },
    );
  }
}

Widget _withTelemetryArtifactNotice(BuildContext context, Widget? child) {
  return Stack(
    fit: StackFit.expand,
    children: [
      child ?? const SizedBox.shrink(),
      const Align(
        alignment: Alignment.topCenter,
        child: TelemetryArtifactRestartNotice(),
      ),
    ],
  );
}

final class _AppStartupOutcome {
  const _AppStartupOutcome({
    this.share,
    this.recovery,
    this.unexpectedFailure = false,
  });

  final AppShareInitializationOutcome? share;
  final TelemetryStartupRecoveryPhase? recovery;
  final bool unexpectedFailure;

  bool get isReady =>
      share == AppShareInitializationOutcome.ready &&
      recovery == TelemetryStartupRecoveryPhase.ready &&
      !unexpectedFailure;

  bool get requiresRestart =>
      unexpectedFailure ||
      share == AppShareInitializationOutcome.blocked ||
      recovery == TelemetryStartupRecoveryPhase.restartRequired;
}

/// Pre-router startup status. Loading, retryable failure, and restart-required
/// are three states and must not share title copy.
class AppStartupScreen extends StatelessWidget {
  const AppStartupScreen({
    required this.loading,
    required this.restartRequired,
    required this.retry,
    super.key,
  });

  final bool loading;
  final bool restartRequired;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = startupStatusTitle(
      l10n: l10n,
      loading: loading,
      restartRequired: restartRequired,
    );
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (loading) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(title, textAlign: TextAlign.center),
                  ] else ...[
                    Icon(
                      restartRequired
                          ? Icons.restart_alt
                          : Icons.lock_clock_outlined,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      restartRequired
                          ? l10n.startupRestartHint
                          : l10n.startupRetryHint,
                      textAlign: TextAlign.center,
                    ),
                    if (!restartRequired) ...[
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: retry,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.startupRetry),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Whether this app is running on a watch.
///
/// Backed by `PackageManager.FEATURE_WATCH` prefetched at startup — the
/// platform's own claim, not window geometry, because a phone in a narrow
/// split screen is still a phone and must keep its full shell.
/// `defaultTargetPlatform` rather than `dart:io` so a widget test can steer
/// the route; on a device the two agree.
bool isWatchFormFactor() =>
    defaultTargetPlatform == TargetPlatform.android && FormFactor.isWatch;

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final _router = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: ConnectScreen.path,
  routes: [
    GoRoute(
      path: ConnectScreen.path,
      builder: (context, state) => const ConnectScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: DashboardScreen.path,
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: PidManagerScreen.path,
          builder: (context, state) => const PidManagerScreen(),
        ),
        GoRoute(
          path: DtcScreen.path,
          builder: (context, state) => const DtcScreen(),
        ),
        GoRoute(
          path: PerformanceScreen.path,
          builder: (context, state) => const PerformanceScreen(),
        ),
        GoRoute(
          path: SettingsScreen.path,
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: PidEditorScreen.path,
      parentNavigatorKey: _rootKey,
      builder: (context, state) =>
          PidEditorScreen(pidId: state.uri.queryParameters['id']),
    ),
    GoRoute(
      path: PowertrainBatteryCatalogScreen.path,
      parentNavigatorKey: _rootKey,
      builder: (context, state) => const PowertrainBatteryCatalogScreen(),
    ),
    GoRoute(
      path: ServiceRecipesScreen.path,
      parentNavigatorKey: _rootKey,
      builder: (context, state) => const ServiceRecipesScreen(),
    ),
    GoRoute(
      path: TelemetrySessionsScreen.path,
      parentNavigatorKey: _rootKey,
      builder: (context, state) => const TelemetrySessionsScreen(),
      routes: [
        GoRoute(
          path: ':sessionId',
          parentNavigatorKey: _rootKey,
          builder: (context, state) => TelemetrySessionDetailScreen(
            sessionId: state.pathParameters['sessionId'] ?? '',
          ),
        ),
      ],
    ),
  ],
);
