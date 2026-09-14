/// Widget and interaction tests for ServiceRecipesScreen and ServiceRecipeDetailSheet.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/diagnostics/service_recipes/active_test_profile.dart';
import 'package:torque_obd/diagnostics/service_recipes/candidate_matrix.dart';
import 'package:torque_obd/diagnostics/service_recipes/mode08_discovery_service.dart';
import 'package:torque_obd/diagnostics/service_recipes/qualification_tier.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart'
    show sharedPreferencesProvider;
import 'package:torque_obd/state/service_recipes_provider.dart';
import 'package:torque_obd/ui/screens/settings/settings_screen.dart';
import 'package:torque_obd/ui/screens/workshop/service_recipe_detail_sheet.dart';
import 'package:torque_obd/ui/screens/workshop/service_recipes_screen.dart';

import '../../support/localized_app.dart';

class _DisconnectedSession extends ObdSession {
  @override
  ObdConnectionState build() => const ObdConnectionState();
}

class _ConnectedCanSession extends ObdSession {
  @override
  ObdConnectionState build() => const ObdConnectionState(
        phase: ConnectionPhase.connected,
        protocol: 'ISO 15765-4 (CAN 11/500)',
      );
}

class _TestDiscoveryNotifier extends Mode08DiscoveryNotifier {
  _TestDiscoveryNotifier(this._initialState);

  final Mode08DiscoveryState _initialState;
  bool discoveryInvoked = false;

  @override
  Mode08DiscoveryState build() => _initialState;

  @override
  Future<void> runDiscovery({
    Duration timeout = Mode08DiscoveryService.defaultDiscoveryTimeout,
    Duration budget = Mode08DiscoveryService.defaultTotalBudget,
    DateTime? deadline,
  }) async {
    discoveryInvoked = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CandidateMatrix bundledMatrix;

  setUpAll(() async {
    final profiles = <ActiveTestProfile>[];
    for (final path in BundledServiceRecipes.bundledAssetPaths) {
      final jsonString = await rootBundle.loadString(path);
      profiles.add(BundledServiceRecipes.parseProfileJson(jsonString));
    }
    bundledMatrix = CandidateMatrix.fromProfiles(profiles);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ServiceRecipesScreen', () {
    testWidgets(
      'renders Zero Live Candidates Safety Banner and loads bundled recipes',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              obdSessionProvider.overrideWith(_DisconnectedSession.new),
              serviceRecipesMatrixProvider.overrideWith(
                (ref) async => bundledMatrix,
              ),
            ],
            child: localizedMaterialApp(
              home: const ServiceRecipesScreen(),
              locale: const Locale('en'),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        // Safety Banner
        expect(
          find.byKey(const Key('zero_live_candidates_banner')),
          findsOneWidget,
        );
        expect(find.text('Zero Live Candidates'), findsOneWidget);
        expect(
          find.textContaining('strictly prohibited (0 qualified vehicles)'),
          findsOneWidget,
        );

        // Bundled recipes
        expect(
          find.byKey(
            const Key('service_recipe_tile_synthetic_mode08_evap_01'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const Key('service_recipe_tile_synthetic_uds_2f_fan_control_01'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const Key('service_recipe_tile_synthetic_uds_31_pump_routine_01'),
          ),
          findsOneWidget,
        );

        // Badges
        expect(find.text('Simulation Ready'), findsNWidgets(3));
        expect(
          find.text('Live Blocked (0 Live Candidates)'),
          findsNWidgets(3),
        );
      },
    );

    testWidgets(
      'tapping a recipe tile opens detail sheet with full specifications',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              obdSessionProvider.overrideWith(_DisconnectedSession.new),
              serviceRecipesMatrixProvider.overrideWith(
                (ref) async => bundledMatrix,
              ),
            ],
            child: localizedMaterialApp(
              home: const ServiceRecipesScreen(),
              locale: const Locale('en'),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        final tile = find.byKey(
          const Key('service_recipe_tile_synthetic_mode08_evap_01'),
        );
        expect(tile, findsOneWidget);
        await tester.tap(tile);
        await tester.pumpAndSettle();

        // Sheet contents
        final sheet = find.byType(ServiceRecipeDetailSheet);
        expect(sheet, findsOneWidget);
        expect(
          find.descendant(
            of: sheet,
            matching: find.text('Standard: SAE J1979:2014'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: sheet,
            matching: find.textContaining('Section 8.4 Mode 08'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: sheet,
            matching: find.text('ECU Header: 7E0'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: sheet,
            matching: find.textContaining('vehicleSpeedKmh: 0 .. 0'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: sheet,
            matching: find.text('Automatic return upon completion or timeout'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: sheet,
            matching: find.textContaining(
              '341756910e1fac80dfe5c34410a5a2ce5487c2f2c0d4e4abc1025f3e595f287d',
            ),
          ),
          findsOneWidget,
        );

        // Close the sheet
        final closeBtn = find.widgetWithText(FilledButton, 'Close');
        expect(closeBtn, findsOneWidget);
        await tester.tap(closeBtn);
        await tester.pumpAndSettle();

        expect(find.byType(ServiceRecipeDetailSheet), findsNothing);
      },
    );

    testWidgets(
      'Mode 08 discovery button is disabled when not connected',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              obdSessionProvider.overrideWith(_DisconnectedSession.new),
              serviceRecipesMatrixProvider.overrideWith(
                (ref) async => bundledMatrix,
              ),
            ],
            child: localizedMaterialApp(
              home: const ServiceRecipesScreen(),
              locale: const Locale('en'),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        final button = tester.widget<FilledButton>(
          find.byKey(const Key('mode08_discovery_button')),
        );
        expect(button.onPressed, isNull);
        expect(
          find.text('Requires an active OBD-II CAN bus connection.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Mode 08 discovery triggers runDiscovery on tap when connected',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final notifier = _TestDiscoveryNotifier(const Mode08DiscoveryState.idle());

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              obdSessionProvider.overrideWith(_ConnectedCanSession.new),
              serviceRecipesMatrixProvider.overrideWith(
                (ref) async => bundledMatrix,
              ),
              mode08DiscoveryStateProvider.overrideWith(() => notifier),
            ],
            child: localizedMaterialApp(
              home: const ServiceRecipesScreen(),
              locale: const Locale('en'),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        final button = find.byKey(const Key('mode08_discovery_button'));
        expect(button, findsOneWidget);
        await tester.tap(button);
        await tester.pump();

        expect(notifier.discoveryInvoked, isTrue);
      },
    );

    testWidgets(
      'Mode 08 discovery completed state renders success message and TID chips',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final result = Mode08DiscoveryResult(
          isSupported: true,
          supportStatus: EcuSupportStatus.supported,
          supportedTids: const {0x01, 0x02},
          queriedBlocks: const [0x00],
          discoveredAt: DateTime.utc(2026, 9, 14),
        );

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              obdSessionProvider.overrideWith(_ConnectedCanSession.new),
              serviceRecipesMatrixProvider.overrideWith(
                (ref) async => bundledMatrix,
              ),
              mode08DiscoveryStateProvider.overrideWith(
                () => _TestDiscoveryNotifier(
                  Mode08DiscoveryState.completed(result: result),
                ),
              ),
            ],
            child: localizedMaterialApp(
              home: const ServiceRecipesScreen(),
              locale: const Locale('en'),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('mode08_discovery_success_container')),
          findsOneWidget,
        );
        expect(
          find.text('Mode 08 is supported by ECU. Supported TIDs: \$01, \$02'),
          findsOneWidget,
        );
        expect(find.text('TID \$01'), findsOneWidget);
        expect(find.text('TID \$02'), findsOneWidget);
      },
    );

    testWidgets(
      'Mode 08 discovery partially completed renders partial warning with failure reason, uncompleted blocks, and disclaimer',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final result = Mode08DiscoveryResult(
          isSupported: true,
          supportStatus: EcuSupportStatus.supported,
          supportedTids: const {0x01, 0x02},
          queriedBlocks: const [0x00],
          unqueriedBlocks: const [0x20],
          isComplete: false,
          failureReason: 'Timeout on block 0x20',
          discoveredAt: DateTime.utc(2026, 9, 14),
        );

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              obdSessionProvider.overrideWith(_ConnectedCanSession.new),
              serviceRecipesMatrixProvider.overrideWith(
                (ref) async => bundledMatrix,
              ),
              mode08DiscoveryStateProvider.overrideWith(
                () => _TestDiscoveryNotifier(
                  Mode08DiscoveryState.completed(result: result),
                ),
              ),
            ],
            child: localizedMaterialApp(
              home: const ServiceRecipesScreen(),
              locale: const Locale('en'),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        final warningContainer = find.byKey(const Key('mode08_discovery_partial_warning'));
        expect(warningContainer, findsOneWidget);
        expect(
          find.descendant(
            of: warningContainer,
            matching: find.textContaining('Timeout on block 0x20'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: warningContainer,
            matching: find.textContaining('Uncompleted blocks: \$20'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: warningContainer,
            matching: find.textContaining('未查到不代表不支援'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('mode08_discovery_success_container')),
          findsOneWidget,
        );
        expect(find.text('TID \$01'), findsOneWidget);
        expect(find.text('TID \$02'), findsOneWidget);
      },
    );

    testWidgets(
      'Mode 08 discovery unsupported state renders unsupported message',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final result = Mode08DiscoveryResult(
          isSupported: false,
          supportStatus: EcuSupportStatus.unsupported,
          supportedTids: const {},
          queriedBlocks: const [0x00],
          discoveredAt: DateTime.utc(2026, 9, 14),
        );

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              obdSessionProvider.overrideWith(_ConnectedCanSession.new),
              serviceRecipesMatrixProvider.overrideWith(
                (ref) async => bundledMatrix,
              ),
              mode08DiscoveryStateProvider.overrideWith(
                () => _TestDiscoveryNotifier(
                  Mode08DiscoveryState.completed(result: result),
                ),
              ),
            ],
            child: localizedMaterialApp(
              home: const ServiceRecipesScreen(),
              locale: const Locale('en'),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          find.text('Mode 08 is not supported by this ECU'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Mode 08 discovery refused state renders refused message',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              obdSessionProvider.overrideWith(_ConnectedCanSession.new),
              serviceRecipesMatrixProvider.overrideWith(
                (ref) async => bundledMatrix,
              ),
              mode08DiscoveryStateProvider.overrideWith(
                () => _TestDiscoveryNotifier(
                  const Mode08DiscoveryState.refused(
                    reason: 'CAN bus required',
                  ),
                ),
              ),
            ],
            child: localizedMaterialApp(
              home: const ServiceRecipesScreen(),
              locale: const Locale('en'),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('CAN bus required'), findsOneWidget);
      },
    );
  });

  group('SettingsScreen navigation tile', () {
    testWidgets('contains service recipes entry in diagnostics section', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            obdSessionProvider.overrideWith(_DisconnectedSession.new),
          ],
          child: localizedMaterialApp(
            home: const SettingsScreen(),
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      final tile = find.byKey(const Key('settings_service_recipes_tile'));
      await tester.scrollUntilVisible(
        tile,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(tile, findsOneWidget);
      expect(find.text('Service Recipes & Active Tests'), findsOneWidget);
      expect(
        find.text(
          'Inspect workshop service recipes and discover supported Mode 08 tests',
        ),
        findsOneWidget,
      );
    });
  });
}
